#!/bin/bash
set -e

#############################################
# Helm Charts → ECR Push Script
#############################################

AWS_ACCOUNT_ID="497012402578"
AWS_REGION="ap-northeast-2"
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

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
  helm repo update ${REPO_NAME} 2>/dev/null || helm repo update

  # 차트 다운로드
  cd ${WORK_DIR}
  helm pull ${REPO_NAME}/${chart_name} --version ${version}

  # ECR에 푸시 (차트 이름이 자동으로 경로에 추가됨)
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
# 각 차트 Push
#############################################

# Istio
push_chart "https://istio-release.storage.googleapis.com/charts" "base" "1.29.1"
push_chart "https://istio-release.storage.googleapis.com/charts" "istiod" "1.29.1"

# Kiali
push_chart "https://kiali.org/helm-charts" "kiali-server" "2.23.0"

# External Secrets
push_chart "https://charts.external-secrets.io" "external-secrets" "2.1.0"

# Calico
push_chart "https://docs.tigera.io/calico/charts" "tigera-operator" "v3.29.3"

# Grafana ecosystem
push_chart "https://grafana.github.io/helm-charts" "loki" "6.55.0"
push_chart "https://grafana.github.io/helm-charts" "promtail" "6.17.1"
push_chart "https://grafana.github.io/helm-charts" "alloy" "1.6.2"
push_chart "https://grafana.github.io/helm-charts" "k6-operator" "4.3.0"

# Prometheus
push_chart "https://prometheus-community.github.io/helm-charts" "kube-prometheus-stack" "82.10.3"

echo ""
echo "=== 완료! ==="
echo "ECR Registry: ${ECR_REGISTRY}"
