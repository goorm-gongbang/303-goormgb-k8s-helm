# 303-goormgb-k8s-helm

> **GitHub**: [goorm-gongbang/303-goormgb-k8s-helm](https://github.com/goorm-gongbang/303-goormgb-k8s-helm)

Helm 차트와 ArgoCD Application 정의를 관리하는 GitOps 레포.

## 환경 구조 (3-tier)

```
┌────────────────────────────────────────────────────────────────────────────┐
│  k3s 클러스터 (MiniPC 2노드, 64GB RAM)         브랜치: argocd-sync/k3s          │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  dev namespace                                                      │   │
│  │  • 개발 + 기능 테스트                                                   │   │
│  │  • 고가용성 테스트 (2노드)                                               │   │
│  │  • Istio 트래픽 실험 (카나리, A/B)                                      │   │
│  │  • Chaos Mesh 장애 주입                                               │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
└────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼ 이미지 태그 프로모션
┌────────────────────────────────────────────────────────────────────────────┐
│  EKS 클러스터 (staging)                        브랜치: argocd-sync/eks         │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  staging namespace                                                  │   │
│  │  • AWS 연동 검증 (RDS, ElastiCache)                                   │   │
│  │  • 프로덕션 미러 환경                                                   │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
└────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼ 검증 완료 후 프로모션
┌───────────────────────────────────────────────────────────────────────────┐
│  EKS 클러스터 (prod) - 별도 클러스터                                            │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  prod namespace                                                     │   │
│  │  • 실서비스 운영                                                       │   │
│  │  • 엄격한 보안 정책                                                     │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
└────────────────────────────────────────────────────────────────────────────┘
```

## 디렉토리 구조

```
.
├── common-charts/              # 공통 Helm 차트
│   ├── apps/                   # 앱 차트
│   │   ├── java-service/       # Java Spring Boot (5개 서비스)
│   │   └── nextjs-app/         # Next.js (1개)
│   └── infra/                  # 인프라 차트
│       ├── argocd/             # ArgoCD Gateway, OAuth
│       ├── eso/                # External Secrets Operator
│       ├── rbac/               # RBAC 설정
│       ├── namespaces/         # Namespace + Istio injection
│       ├── istio/              # base, istiod, gateway, kiali
│       └── monitoring/         # prometheus-stack, loki, tempo
│
├── k3s/                        # k3s 클러스터 (MiniPC)
│   ├── apps/                   # ArgoCD Application 정의
│   │   ├── infra/              # 인프라 앱
│   │   │   ├── namespaces.yaml
│   │   │   ├── istio.yaml
│   │   │   ├── monitoring.yaml
│   │   │   └── ...
│   │   ├── dev.yaml            # dev 워크로드
│   │   └── kustomization.yaml
│   ├── charts/                 # k3s 전용 차트
│   │   ├── data/               # PostgreSQL, Redis
│   │   ├── ddns/               # Route53 DDNS
│   │   ├── cert-manager/       # Let's Encrypt
│   │   └── waf/                # ModSecurity WAF
│   └── values/                 # Helm values
│       ├── common/             # 클러스터 공통 설정
│       │   ├── values-monitoring.yaml
│       │   ├── values-istio.yaml
│       │   └── ...
│       └── dev/                # dev 앱 설정
│           ├── values-auth-guard.yaml
│           └── ...
│
├── eks/                        # EKS 클러스터 (AWS)
│   ├── apps/                   # ArgoCD Application 정의
│   │   ├── infra/
│   │   └── kustomization.yaml
│   └── values/
│       ├── common/             # EKS 공통 설정
│       ├── staging/            # staging 앱 설정
│       └── prod/               # prod 앱 설정
│
└── docs/                       # 문서
```

## 브랜치 전략

**클러스터 단위로 브랜치 분리:**

```
main ─────────────────────────────────────────►  개발/PR 머지
  │
  ├── argocd-sync/k3s ────────────────────────►  k3s (dev namespace)
  │
  └── argocd-sync/eks ────────────────────────►  EKS (staging + prod)
```

| 브랜치 | 클러스터 | 환경 | 용도 |
|--------|----------|------|------|
| `argocd-sync/k3s` | k3s (MiniPC) | dev | 개발, HA 테스트, Istio 실험 |
| `argocd-sync/eks` | EKS (AWS) | staging, prod | AWS 연동, 프로덕션 |

## GitOps 워크플로우

```
개발자가 서비스 코드 수정 → PR 머지
                │
                ▼
┌────────────────────────────────────────────────────────────┐
│  CI (GitHub Actions)                                        │
│  1. 이미지 빌드 & ECR 푸시                                  │
│  2. k3s/values/dev/values-*.yaml 업데이트 (이미지 태그)     │
│  3. argocd-sync/k3s 브랜치에 자동 커밋                      │
└────────────────────────────────────────────────────────────┘
                │
                ▼
┌────────────────────────────────────────────────────────────┐
│  ArgoCD (k3s)                                               │
│  • argocd-sync/k3s 브랜치 watch                            │
│  • 변경 감지 → 자동 sync                                   │
│  • dev namespace에 배포                                    │
└────────────────────────────────────────────────────────────┘
```

## k3s vs EKS 차이

| 컴포넌트 | k3s (MiniPC) | EKS (AWS) |
|---------|--------------|-----------|
| TLS 인증서 | cert-manager + Let's Encrypt | ACM |
| 데이터베이스 | PostgreSQL Pod | RDS |
| 캐시 | Redis Pod | ElastiCache |
| WAF | ModSecurity (in-cluster) | AWS WAF |
| DDNS | Route53 CronJob | 불필요 (고정 IP) |
| Istio | ✅ sidecar injection | ✅ sidecar injection |

## Istio Sidecar Injection

모든 앱 namespace에 Istio sidecar 자동 주입:

```yaml
# common-charts/infra/namespaces/
apiVersion: v1
kind: Namespace
metadata:
  name: dev
  labels:
    istio-injection: enabled  # ← 자동 주입
```

## 레포 관계도

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         goorm-gongbang Organization                     │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌──────────────────────────┐       ┌──────────────────────────┐        │
│  │ 302-goormgb-k8s-bootstrap│       │ 303-goormgb-k8s-helm     │        │
│  │                          │       │ (이 레포)                  │        │
│  ├──────────────────────────┤       ├──────────────────────────┤        │
│  │ • MiniPC에 clone          │       │ • ArgoCD가 watch         │        │
│  │ • 1회성 부트스트랩           │       │ • 지속적 GitOps            │        │
│  │ • 수동 실행                │       │ • Git push → 자동 배포      │        │
│  └───────────┬──────────────┘       └──────────────┬───────────┘        │
│              │                                     │                    │
│              │ 1회 실행                              │ 계속 sync           │
│              ▼                                     ▼                     │
│  ┌───────────────────────────────────────────────────────────────┐       │
│  │                    k3s Cluster (MiniPC)                       │       │
│  │                                                               │       │
│  │   ArgoCD ◄────── watch ────── k3s/apps/                       │       │
│  │      │                                                        │       │
│  │      ├── k3s/apps/infra/*  ──► Istio, Monitoring, ESO...      │       │
│  │      └── k3s/apps/dev.yaml ──► auth-guard, order-core...      │       │
│  │                                                               │       │
│  └───────────────────────────────────────────────────────────────┘       │
│                                                                          │
└──────────────────────────────────────────────────────────────────────────┘
```

## 도메인

| 도메인 | 용도 |
|--------|------|
| goormgb.space | 루트 도메인 |
| dev.goormgb.space | k3s dev 환경 |
| api.dev.goormgb.space | k3s dev API |
| argocd.goormgb.space | ArgoCD UI |
| grafana.goormgb.space | Grafana |
| kiali.goormgb.space | Kiali (서비스 메시) |

## 소스코드 레포

| 레포 | 용도 | 차트 |
|------|------|------|
| [101-goormgb-frontend](https://github.com/goorm-gongbang/101-goormgb-frontend) | Next.js 프론트엔드 | `nextjs-app` |
| [102-goormgb-backend](https://github.com/goorm-gongbang/102-goormgb-backend) | Java Spring Boot 백엔드 | `java-service` |

## 주의사항

- `argocd-sync/*` 브랜치에 push하면 **즉시 배포**됩니다
- 중요한 변경은 `main`에서 PR 리뷰 후 환경 브랜치로 머지하세요
- ArgoCD UI에서 수동 변경하면 다음 sync 때 되돌아갑니다 (GitOps)

## 문서

- [Architecture Decisions](./docs/architecture-decisions.md) - 주요 아키텍처 결정 기록
- [Node Placement Strategy](./docs/node-placement-strategy.md) - 노드 배치 전략
