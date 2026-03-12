#!/bin/bash
set -e

#############################################
# Helm Charts → ECR Push Script
#############################################

# 환경 변수에서 읽기 (필수)
AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID:?AWS_ACCOUNT_ID 환경 변수를 설정해주세요.}"
AWS_REGION="${AWS_REGION:-ap-northeast-2}"
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

# 스크립트 디렉토리
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHARTS_FILE="${SCRIPT_DIR}/charts.txt"

# 임시 디렉토리
WORK_DIR=$(mktemp -d)
trap "rm -rf $WORK_DIR" EXIT

echo "=== ECR 로그인 ==="
aws ecr get-login-password --region ${AWS_REGION} | helm registry login --username AWS --password-stdin ${ECR_REGISTRY}

#############################################
# 차트 푸시 함수
#############################################
push_chart() {
  local repo_url=$1
  local chart_name=$2
  local version=$3

  echo ""
  echo "=== ${chart_name}:${version} ==="

  # Helm repo 추가
  REPO_NAME="temp-${chart_name}"
  helm repo add ${REPO_NAME} ${repo_url} 2>/dev/null || true
  helm repo update

  # 차트 다운로드
  cd ${WORK_DIR}
  helm pull ${REPO_NAME}/${chart_name} --version ${version}

  # ECR에 푸시
  TGZ_FILE=$(ls ${chart_name}-*.tgz 2>/dev/null | head -1)
  if [ -z "$TGZ_FILE" ]; then
    echo "ERROR: Chart file not found!"
    return 1
  fi

  echo "Pushing ${TGZ_FILE} → oci://${ECR_REGISTRY}/helm/${chart_name}"
  helm push ${TGZ_FILE} oci://${ECR_REGISTRY}/helm

  # 정리
  rm -f *.tgz
  helm repo remove ${REPO_NAME} 2>/dev/null || true
}

#############################################
# charts.txt 파일에서 차트 목록 읽기
#############################################

if [ ! -f "$CHARTS_FILE" ]; then
  echo "ERROR: charts.txt not found at $CHARTS_FILE"
  exit 1
fi

while IFS= read -r line || [ -n "$line" ]; do
  # 주석과 빈 줄 무시
  [[ "$line" =~ ^#.*$ ]] && continue
  [[ -z "$line" ]] && continue

  # 파싱: REPO_URL|CHART_NAME|VERSION
  IFS='|' read -r repo_url chart_name version <<< "$line"

  if [ -n "$repo_url" ] && [ -n "$chart_name" ] && [ -n "$version" ]; then
    push_chart "$repo_url" "$chart_name" "$version"
  fi
done < "$CHARTS_FILE"

echo ""
echo "=== 완료! ==="
echo "ECR Registry: ${ECR_REGISTRY}"
