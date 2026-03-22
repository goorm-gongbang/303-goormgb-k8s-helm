# 303-goormgb-k8s-helm

Helm 차트와 ArgoCD Application 정의를 관리하는 GitOps 레포.

## 환경별 구성

| 환경 | 클러스터 | 브랜치 | 사용법 |
|------|----------|--------|--------|
| dev | kubeadm (MiniPC) | `argocd-sync/dev` | [dev/README.md](./dev/README.md) |
| staging | EKS (AWS) | `argocd-sync/staging` | [staging/README.md](./staging/README.md) |
| prod | EKS (AWS) | `argocd-sync/prod` | - |

## 디렉토리 구조

```
.
├── common-charts/              # 공통 Helm 차트
│   ├── apps/                   # 앱 차트 (java-service)
│   └── infra/                  # 인프라 차트 (argocd, istio, monitoring 등)
│
├── dev/                        # dev 환경 (kubeadm)
│   ├── root/                   # ArgoCD Root App (App of Apps)
│   ├── charts/                 # kubeadm 전용 차트 (data, ddns)
│   └── values/                 # Helm values
│
├── staging/                    # staging 환경 (EKS)
│   ├── root/                   # ArgoCD Root App
│   ├── charts/                 # EKS 전용 차트
│   └── values/                 # Helm values
│
└── prod/                       # prod 환경 (EKS)
    ├── root/
    └── values/
```

## 브랜치 전략

```
main                          # 개발/PR 머지
  ├── argocd-sync/dev         # kubeadm 클러스터 배포
  ├── argocd-sync/staging     # EKS Staging 배포
  └── argocd-sync/prod        # EKS Prod 배포
```

`argocd-sync/*` 브랜치에 push하면 ArgoCD가 자동 감지하여 배포합니다.

## GitOps 워크플로우

```
1. 개발자가 서비스 코드 수정 후 PR 머지
2. CI (TeamCity)가 이미지 빌드 & ECR 푸시
3. CI가 values 파일 업데이트 후 argocd-sync/* 브랜치에 커밋
4. ArgoCD가 변경 감지 후 자동 배포
```

## 환경별 차이

| 컴포넌트 | kubeadm (dev) | EKS (staging/prod) |
|----------|---------------|---------------------|
| TLS 인증서 | cert-manager + Let's Encrypt | ACM |
| 데이터베이스 | PostgreSQL Pod | RDS |
| 캐시 | Redis Pod | ElastiCache |
| 스토리지 | Local Path Provisioner | EBS CSI |
| DDNS | Route53 CronJob | 불필요 (고정 IP) |

## 관련 레포

| 레포 | 용도 |
|------|------|
| 301-goormgb-terraform | AWS 인프라 (EKS, RDS 등) |
| 302-goormgb-k8s-bootstrap | 클러스터 부트스트랩 |
| **303-goormgb-k8s-helm** | GitOps (ArgoCD가 watch) |
| 101-goormgb-frontend | Next.js 프론트엔드 |
| 102-goormgb-backend | Java Spring Boot 백엔드 |

## 주의사항

- `argocd-sync/*` 브랜치에 push하면 즉시 배포됩니다
- 중요한 변경은 `main`에서 PR 리뷰 후 환경 브랜치로 머지하세요
- ArgoCD UI에서 수동 변경하면 다음 sync 때 되돌아갑니다 (GitOps)
