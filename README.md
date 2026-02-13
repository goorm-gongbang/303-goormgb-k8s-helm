# 302-goormgb-k8s-bootstrap

> **GitHub**: [goorm-gongbang/302-goormgb-k8s-bootstrap](https://github.com/goorm-gongbang/302-goormgb-k8s-bootstrap)

k3s 클러스터에 ArgoCD 환경을 구성하는 부트스트랩 스크립트.

## 레포 관계도

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         goorm-gongbang Organization                      │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌──────────────────────────┐       ┌──────────────────────────┐        │
│  │ 302-goormgb-k8s-bootstrap│       │ 303-goormgb-k8s-helm     │        │
│  │ (이 레포)                 │       │                          │        │
│  ├──────────────────────────┤       ├──────────────────────────┤        │
│  │ • MiniPC에 clone         │       │ • ArgoCD가 watch         │        │
│  │ • 1회성 부트스트랩        │       │ • 지속적 GitOps          │        │
│  │ • 수동 실행              │       │ • Git push → 자동 배포    │        │
│  └───────────┬──────────────┘       └──────────────┬───────────┘        │
│              │                                      │                    │
│              │ make install-all                     │ ArgoCD sync        │
│              ▼                                      ▼                    │
│  ┌──────────────────────────────────────────────────────────────┐       │
│  │                    k3s Cluster (MiniPC)                       │       │
│  │  ┌─────────────────────────────────────────────────────────┐ │       │
│  │  │ Bootstrap 설치:                                          │ │       │
│  │  │  • ESO (External Secrets Operator)                      │ │       │
│  │  │  • cert-manager                                         │ │       │
│  │  │  • Istio                                                │ │       │
│  │  │  • ArgoCD ◄─────── Root App 등록                        │ │       │
│  │  └─────────────────────────────────────────────────────────┘ │       │
│  │                           │                                   │       │
│  │                           ▼                                   │       │
│  │  ┌─────────────────────────────────────────────────────────┐ │       │
│  │  │ ArgoCD가 303 레포에서 자동 배포:                         │ │       │
│  │  │  • PostgreSQL, Redis                                    │ │       │
│  │  │  • DDNS (Route53)                                       │ │       │
│  │  │  • ArgoCD 추가 설정 (OAuth, Gateway 등)                 │ │       │
│  │  │  • 앱 배포 (frontend, api 등)                           │ │       │
│  │  └─────────────────────────────────────────────────────────┘ │       │
│  └──────────────────────────────────────────────────────────────┘       │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

## 워크플로우

```
1. MiniPC에 k3s 설치 (별도)
        │
        ▼
2. 이 레포 clone
   git clone https://github.com/goorm-gongbang/302-goormgb-k8s-bootstrap.git
        │
        ▼
3. Bootstrap 실행
   sudo KUBECONFIG=/etc/rancher/k3s/k3s.yaml make install-all
        │
        ├── ESO 설치
        ├── AWS credentials 등록
        ├── cert-manager 설치
        ├── Istio 설치
        ├── ArgoCD 설치
        ├── Root Application 배포 ──────► ArgoCD가 303 레포 watch 시작
        └── DDNS 업데이트
        │
        ▼
4. 이후 모든 변경은 303-goormgb-k8s-helm 레포에서!
   - Git push → ArgoCD 자동 sync
```

## 사용법

### 전체 설치 (권장)

```bash
git clone https://github.com/goorm-gongbang/302-goormgb-k8s-bootstrap.git
cd 302-goormgb-k8s-bootstrap

# admin 권한으로 실행
sudo KUBECONFIG=/etc/rancher/k3s/k3s.yaml make install-all
```

### 개별 설치

```bash
make help              # 명령어 목록

make install-eso       # External Secrets Operator
make bootstrap-aws     # AWS credentials 등록 (대화형)
make install-cert-manager
make install-istio
make install-argocd
make deploy-root-app   # ArgoCD Root Application
make run-ddns          # DDNS 업데이트
```

### 유틸리티

```bash
make ddns-update       # DDNS 수동 업데이트
make ddns-test         # Route53 API 테스트
make rbac-create-users # 팀원 kubeconfig 생성
make clean-all         # 전체 초기화 (k3s 유지)
```

## 디렉토리 구조

```
.
├── Makefile                    # 설치 명령어 모음
├── scripts/
│   ├── argocd/install.sh       # ArgoCD Helm 설치
│   ├── cert-manager/install.sh # cert-manager 설치
│   ├── eso/
│   │   ├── install.sh          # ESO 설치
│   │   └── bootstrap-aws.sh    # AWS credentials 등록
│   ├── istio/
│   │   ├── install.sh          # Istio 설치
│   │   ├── uninstall.sh
│   │   └── fix-port-conflict.sh
│   ├── k3s/
│   │   ├── clean-all.sh        # 전체 초기화
│   │   └── disable-traefik.sh
│   ├── rbac/
│   │   ├── create-all-users.sh
│   │   └── create-user-kubeconfig.sh
│   └── ddns/
│       ├── test-api.sh
│       └── update-now.sh
└── argocd/
    └── root-application.yaml   # App of Apps 루트 (303 레포를 가리킴)
```

## 관련 레포

| 레포 | 용도 | 실행 위치 |
|------|------|----------|
| **302-goormgb-k8s-bootstrap** (이 레포) | ArgoCD 환경 부트스트랩 | MiniPC에서 1회 |
| [303-goormgb-k8s-helm](https://github.com/goorm-gongbang/303-goormgb-k8s-helm) | Helm 차트 + GitOps | ArgoCD가 watch |

## 설치 후 확인

```bash
# ArgoCD UI 접속
https://argocd.goormgb.space

# admin 비밀번호
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d

# Application 상태 확인
kubectl get applications -n argocd
```
