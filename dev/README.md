# Dev 환경 (kubeadm)

kubeadm 클러스터(MiniPC)용 Helm values와 ArgoCD Application 정의.

## 특징

- **클러스터**: kubeadm 기반 온프레미스 (MiniPC)
- **브랜치**: `argocd-sync/dev`
- **용도**: 개발, HA 테스트, Istio 실험

## 배포되는 컴포넌트

### 인프라 (core/)

| 컴포넌트 | 설명 |
|----------|------|
| namespaces | 네임스페이스 생성 |
| argocd-config | ArgoCD 설정 (OIDC, RBAC) |
| cert-manager-config | ClusterIssuer (Let's Encrypt) |
| eso-config | ClusterSecretStore (AWS SM) |

### Istio (istio/)

| 컴포넌트 | 설명 |
|----------|------|
| istio-base | Istio CRDs |
| istiod | Control Plane |
| istio-gateway | IngressGateway (NodePort 80/443) |
| istio-security | WAF EnvoyFilter (SQL Injection, XSS 탐지) |

### 모니터링 (monitoring/)

| 컴포넌트 | 설명 |
|----------|------|
| prometheus-stack | Prometheus + Grafana |
| loki | 로그 수집 |
| promtail | 로그 전송 |
| tempo | 분산 트레이싱 |
| opentelemetry-collector | OTLP 수신 |

### 데이터 (data/)

| 컴포넌트 | 설명 |
|----------|------|
| postgresql | PostgreSQL Pod |
| redis | Redis Pod |
| cloudbeaver | DB 관리 UI |

### 앱 (apps/)

| 컴포넌트 | 설명 |
|----------|------|
| java-services | auth-guard, order-core, queue, seat |

## 디렉토리 구조

```
dev/
├── root/                      # ArgoCD Root App (App of Apps)
│   ├── Chart.yaml
│   └── templates/
├── charts/                    # kubeadm 전용 차트
│   ├── data/                  # PostgreSQL, Redis
│   └── ddns/                  # Route53 DDNS CronJob
└── values/
    ├── core/                  # namespaces, argocd-config, eso-config
    ├── istio/                 # istio-base, istiod, gateway, security
    ├── monitoring/            # prometheus, loki, grafana
    ├── data/                  # postgresql, redis
    ├── apps/                  # java-services values
    └── security/              # rbac, network policies
```

## 도메인

| 도메인 | 용도 |
|--------|------|
| api.dev.goormgb.space | 백엔드 API |
| argocd.goormgb.space | ArgoCD UI |
| grafana.goormgb.space | Grafana |
| kiali.goormgb.space | Kiali |
| cloudbeaver.goormgb.space | CloudBeaver DB UI |

## Security Filter (WAF)

Istio IngressGateway에서 L7 요청을 검사하여 공격 패턴을 탐지/차단합니다.

### 탐지 항목
- **SQL Injection**: UNION SELECT, DROP TABLE, OR 1=1 등
- **XSS**: `<script>`, `javascript:`, `onerror=` 등
- **Path Traversal**: `../`, `%2e%2e` 등

### 모드 전환
```yaml
# dev/values/istio/values-istio-security.yaml
mode: detect  # 로그만 (기본값)
mode: block   # 403 차단
```

### 로그 확인 (Grafana → Loki)
```
{namespace="istio-system", container="istio-proxy"} |= "security"
```

## 배포

```bash
# argocd-sync/dev 브랜치에 push하면 자동 배포
git checkout argocd-sync/dev
git merge main
git push

# 또는 ArgoCD UI에서 Sync
```
