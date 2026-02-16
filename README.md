# 303-goormgb-k8s-helm

Helm 차트와 ArgoCD Application 정의를 관리하는 GitOps 레포.

## 환경 구조

| 환경    | 클러스터         | 브랜치                | 용도                        |
| ------- | ---------------- | --------------------- | --------------------------- |
| dev     | kubeadm (MiniPC) | `argocd-sync/dev`     | 개발, HA 테스트, Istio 실험 |
| staging | EKS              | `argocd-sync/staging` | AWS 연동 검증               |
| prod    | EKS              | `argocd-sync/prod`    | 실서비스 운영               |

## 디렉토리 구조

```
.
├── common-charts/              # 공통 Helm 차트
│   ├── apps/                   # 앱 차트 (java-service, nextjs-app)
│   └── infra/                  # 인프라 차트 (argocd, istio, monitoring 등)
│
├── dev/                        # dev 환경 (kubeadm)
│   ├── apps/                   # ArgoCD Application 정의
│   │   ├── infra/              # 인프라 앱 (istio, monitoring 등)
│   │   ├── dev-applicationset.yaml
│   │   └── kustomization.yaml
│   ├── charts/                 # kubeadm 전용 차트 (data, ddns, waf)
│   └── values/                 # Helm values
│
├── staging/                    # staging 환경 (EKS)
│   ├── apps/
│   └── values/
│
└── prod/                       # prod 환경 (EKS)
    ├── apps/
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

1. 개발자가 서비스 코드 수정 후 PR 머지
2. CI (TeamCity)가 이미지 빌드 & ECR 푸시
3. CI가 values 파일 업데이트 후 `argocd-sync/dev` 브랜치에 커밋
4. ArgoCD가 변경 감지 후 자동 배포

## kubeadm vs EKS 차이

| 컴포넌트     | kubeadm (MiniPC)             | EKS (AWS)        |
| ------------ | ---------------------------- | ---------------- |
| TLS 인증서   | cert-manager + Let's Encrypt | ACM              |
| 데이터베이스 | PostgreSQL Pod               | RDS              |
| 캐시         | Redis Pod                    | ElastiCache      |
| WAF          | ModSecurity (in-cluster)     | AWS WAF          |
| DDNS         | Route53 CronJob              | 불필요 (고정 IP) |

## 도메인 (임시 도메인!)

| 도메인                   | 용도              |
| ------------------------ | ----------------- |
| dev.goormgb.help         | 프론트 (Vercel)   |
| api.dev.goormgb.help     | 백엔드 API        |
| argocd.goormgb.help      | ArgoCD UI         |
| grafana.goormgb.help     | Grafana           |
| kiali.goormgb.help       | Kiali             |
| cloudbeaver.goormgb.help | CloudBeaver DB UI |

## 관련 레포

| 레포                                                                                     | 용도                    |
| ---------------------------------------------------------------------------------------- | ----------------------- |
| [302-goormgb-k8s-bootstrap](https://github.com/goorm-gongbang/302-goormgb-k8s-bootstrap) | 1회성 부트스트랩        |
| **303-goormgb-k8s-helm**                                                                 | GitOps (ArgoCD가 watch) |
| [101-goormgb-frontend](https://github.com/goorm-gongbang/101-goormgb-frontend)           | Next.js 프론트엔드      |
| [102-goormgb-backend](https://github.com/goorm-gongbang/102-goormgb-backend)             | Java Spring Boot 백엔드 |

## 주의사항

- `argocd-sync/*` 브랜치에 push하면 즉시 배포됩니다
- 중요한 변경은 `main`에서 PR 리뷰 후 환경 브랜치로 머지하세요
- ArgoCD UI에서 수동 변경하면 다음 sync 때 되돌아갑니다 (GitOps)
