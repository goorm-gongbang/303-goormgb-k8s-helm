# 303-goormgb-k8s-helm

> **GitHub**: [goorm-gongbang/303-goormgb-k8s-helm](https://github.com/goorm-gongbang/303-goormgb-k8s-helm)

Helm 차트와 ArgoCD Application 정의를 관리하는 GitOps 레포.

## 레포 관계도

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         goorm-gongbang Organization                      │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌──────────────────────────┐       ┌──────────────────────────┐        │
│  │ 302-goormgb-k8s-bootstrap│       │ 303-goormgb-k8s-helm     │        │
│  │                          │       │ (이 레포)                 │        │
│  ├──────────────────────────┤       ├──────────────────────────┤        │
│  │ • MiniPC에 clone         │       │ • ArgoCD가 watch         │        │
│  │ • 1회성 부트스트랩        │       │ • 지속적 GitOps          │        │
│  │ • 수동 실행              │       │ • Git push → 자동 배포    │        │
│  └───────────┬──────────────┘       └──────────────┬───────────┘        │
│              │                                      │                    │
│              │ 1회 실행                              │ 계속 sync          │
│              ▼                                      ▼                    │
│  ┌──────────────────────────────────────────────────────────────┐       │
│  │                    k3s Cluster (MiniPC)                       │       │
│  │                                                                │       │
│  │   ArgoCD ◄────── watch ────── 이 레포                         │       │
│  │      │                                                         │       │
│  │      ├── argocd/k3s/infra/* ──► Prometheus, Grafana, Istio... │       │
│  │      └── argocd/k3s/apps/*  ──► auth-guard, order-core...     │       │
│  │                                                                │       │
│  └──────────────────────────────────────────────────────────────┘       │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

## 소스코드 레포

애플리케이션 소스코드는 별도 레포에서 관리됩니다:

| 레포                                                                           | 용도                    | 차트           |
| ------------------------------------------------------------------------------ | ----------------------- | -------------- |
| [101-goormgb-frontend](https://github.com/goorm-gongbang/101-goormgb-frontend) | Next.js 프론트엔드      | `nextjs-app`   |
| [102-goormgb-backend](https://github.com/goorm-gongbang/102-goormgb-backend)   | Java Spring Boot 백엔드 | `java-service` |

## GitOps 워크플로우

```
개발자가 Git push
      │
      ▼
┌─────────────────────────────────────────┐
│           GitHub (이 레포)               │
│                                          │
│  charts/      ──┐                        │
│  environments/ ─┼──► ArgoCD가 감지       │
│  argocd/       ─┘                        │
└─────────────────────────────────────────┘
      │
      │ webhook / polling (3분)
      ▼
┌─────────────────────────────────────────┐
│              ArgoCD                      │
│                                          │
│  1. argocd/* 변경 감지                  │
│  2. charts/ + environments/ 조합        │
│  3. K8s에 배포                          │
└─────────────────────────────────────────┘
      │
      ▼
   K8s Cluster 업데이트 완료!
```

## 디렉토리 구조

```
.
├── charts/                      # Helm 차트
│   ├── apps/
│   │   ├── java-service/       # Java Spring Boot 공통 (5개 서비스)
│   │   └── nextjs-app/         # Next.js 전용 (1개)
│   └── infra/
│       ├── argocd/             # ArgoCD Gateway, OAuth
│       ├── prometheus-stack/   # Prometheus + Grafana
│       ├── loki/               # 로그 수집
│       ├── tempo/              # 분산 트레이싱
│       ├── istio-base/         # Istio CRDs
│       ├── istiod/             # Istio Control Plane
│       ├── istio-gateway/      # Istio Ingress Gateway
│       ├── kiali/              # 서비스 메시 시각화
│       ├── cert-manager/       # TLS 인증서 관리
│       ├── postgresql/         # PostgreSQL
│       └── redis/              # Redis
│
├── environments/                # Values 파일 (환경별)
│   ├── apps/
│   │   ├── dev/                # k3s 개발 환경
│   │   ├── qa/                 # k3s QA 환경 (HA, 부하테스트)
│   │   ├── staging/            # EKS 스테이징 (TODO)
│   │   └── prod/               # EKS 운영 (TODO)
│   └── clusters/
│       ├── k3s/                # MiniPC k3s 클러스터
│       └── eks/                # AWS EKS 클러스터
│
├── argocd/                      # ArgoCD Application 정의
│   ├── k3s/                    # k3s ArgoCD가 watch
│   │   ├── infra/             # 인프라 앱
│   │   │   ├── argocd.yaml
│   │   │   ├── prometheus-stack.yaml
│   │   │   ├── loki.yaml
│   │   │   ├── tempo.yaml
│   │   │   └── istio.yaml
│   │   └── apps/              # 서비스 앱
│   │       ├── dev.yaml       # dev 환경 (branch: dev)
│   │       └── qa.yaml        # qa 환경 (branch: qa)
│   └── eks/                    # EKS ArgoCD가 watch (TODO)
│       ├── infra/
│       └── apps/
│
└── docs/                        # 문서
    ├── architecture-decisions.md
    └── node-placement-strategy.md
```

## 브랜치 전략

**argocd-sync/** prefix로 ArgoCD 전용 브랜치:

```
main ───────────────────────────────►  개발/PR 머지
  │
  ├── argocd-sync/dev ─────────────►  k3s (dev namespace)
  ├── argocd-sync/qa ──────────────►  k3s (qa namespace)
  ├── argocd-sync/staging ─────────►  EKS (staging namespace) [TODO]
  └── argocd-sync/prod ────────────►  EKS (prod namespace) [TODO]
```

### 클러스터-환경 매핑

| 클러스터     | 환경    | 용도                                          |
| ------------ | ------- | --------------------------------------------- |
| k3s (MiniPC) | dev     | 개발 테스트, 빠른 반복                        |
| k3s (MiniPC) | qa      | HA 테스트, WAF, 부하테스트, Chaos Engineering |
| EKS (AWS)    | staging | 프로덕션 미러, 최종 검증                      |
| EKS (AWS)    | prod    | 실 서비스 운영                                |

### 배포 흐름

```
1. feature/* → main (PR)
2. main → argocd-sync/dev (k3s 개발 환경)
3. dev 검증 후 → argocd-sync/qa (k3s QA 환경)
4. qa 검증 후 → argocd-sync/staging (EKS 스테이징)
5. staging 검증 후 → argocd-sync/prod (EKS 프로덕션)
```

## ArgoCD Application 예시

```yaml
# argocd/k3s/apps/dev.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: dev-auth-guard
  namespace: argocd
spec:
  source:
    repoURL: https://github.com/goorm-gongbang/303-goormgb-k8s-helm.git
    targetRevision: argocd-sync/dev # ArgoCD sync 브랜치
    path: charts/apps/java-service # 타입별 차트
    helm:
      valueFiles:
        - ../../../environments/apps/dev/values-auth-guard.yaml
  destination:
    server: https://kubernetes.default.svc
    namespace: dev # NS = 환경
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

## 멀티 클러스터 구조

```
┌─────────────────────────────────────────────────────────────────┐
│                   303-goormgb-k8s-helm                          │
│                                                                  │
│  argocd/k3s/  ◄──────  k3s ArgoCD (argocd.goormgb.space)       │
│  argocd/eks/  ◄──────  EKS ArgoCD (argocd.eks.goormgb.space)   │
│                                                                  │
│  charts/           ─────────►  공통 Helm 차트                    │
│  environments/clusters/k3s/    k3s용 values                     │
│  environments/clusters/eks/    EKS용 values                     │
└─────────────────────────────────────────────────────────────────┘
```

| 클러스터     | ArgoCD 도메인            | watch 경로 | 앱 브랜치                 |
| ------------ | ------------------------ | ---------- | ------------------------- |
| k3s (MiniPC) | argocd.goormgb.space     | argocd/k3s | argocd-sync/dev, qa       |
| EKS (AWS)    | argocd.eks.goormgb.space | argocd/eks | argocd-sync/staging, prod |

## 도메인

| 도메인                | 용도              |
| --------------------- | ----------------- |
| goormgb.space         | 루트 도메인       |
| dev.goormgb.space     | k3s 개발 환경     |
| qa.goormgb.space      | k3s QA 환경       |
| staging.goormgb.space | EKS 스테이징 환경 |
| argocd.goormgb.space  | ArgoCD UI (k3s)   |
| grafana.goormgb.space | Grafana           |

## 관련 레포

| 레포                                                                                     | 용도                   | 실행 위치      |
| ---------------------------------------------------------------------------------------- | ---------------------- | -------------- |
| [302-goormgb-k8s-bootstrap](https://github.com/goorm-gongbang/302-goormgb-k8s-bootstrap) | ArgoCD 환경 부트스트랩 | MiniPC에서 1회 |
| **303-goormgb-k8s-helm** (이 레포)                                                       | Helm 차트 + GitOps     | ArgoCD가 watch |

## 주의사항

- `argocd-sync/*` 브랜치에 push하면 **즉시 배포**됩니다
- 중요한 변경은 `main`에서 PR 리뷰 후 환경 브랜치로 머지하세요
- ArgoCD UI에서 수동 변경하면 다음 sync 때 되돌아갑니다 (GitOps)

## 문서

- [Architecture Decisions](./docs/architecture-decisions.md) - 주요 아키텍처 결정 기록
- [Node Placement Strategy](./docs/node-placement-strategy.md) - 노드 배치 전략
