# Staging 환경 (EKS)

EKS 클러스터(AWS)용 Helm values와 ArgoCD Application 정의.

## 특징

- **클러스터**: EKS (AWS)
- **브랜치**: `argocd-sync/staging`
- **용도**: AWS 연동 검증, 프로덕션 전 테스트

## 배포되는 컴포넌트

### 인프라 (core/)

| 컴포넌트 | 설명 |
|----------|------|
| namespaces | 네임스페이스 생성 |
| argocd-config | ArgoCD 설정 (OIDC, RBAC) |
| eso-config | ClusterSecretStore (IRSA 기반) |
| aws-lb-controller | ALB/NLB 프로비저닝 |
| external-dns | Route53 자동 DNS 등록 |
| karpenter | Node Auto Provisioning |

### Istio (istio/)

| 컴포넌트 | 설명 |
|----------|------|
| istio-base | Istio CRDs |
| istiod | Control Plane |
| istio-gateway | IngressGateway (ALB 연동) |
| istio-security | WAF EnvoyFilter |

### 모니터링 (monitoring/)

| 컴포넌트 | 설명 |
|----------|------|
| prometheus-stack | Prometheus + Grafana |
| loki | 로그 수집 |
| promtail | 로그 전송 |
| tempo | 분산 트레이싱 |
| opentelemetry-collector | OTLP 수신 |

### 앱 (apps/)

| 컴포넌트 | 설명 |
|----------|------|
| java-services | auth-guard, order-core, queue, seat |

## dev와 차이점

| 항목 | dev (kubeadm) | staging (EKS) |
|------|---------------|---------------|
| TLS | cert-manager + Let's Encrypt | ACM |
| 로드밸런서 | NodePort + DDNS | ALB + External DNS |
| DB | PostgreSQL Pod | RDS |
| Cache | Redis Pod | ElastiCache |
| Node Scaling | 수동 | Karpenter |
| ESO 인증 | IAM Access Key | IRSA |

## 디렉토리 구조

```
staging/
├── root/                      # ArgoCD Root App (App of Apps)
│   ├── Chart.yaml
│   └── templates/
├── charts/                    # EKS 전용 차트
└── values/
    ├── core/                  # namespaces, argocd-config, eso-config
    ├── apps/                  # java-services values
    ├── values-aws-lb-controller.yaml
    ├── values-external-dns.yaml
    ├── values-karpenter.yaml
    ├── values-istio.yaml
    ├── values-istio-gateway.yaml
    ├── values-istio-security.yaml
    ├── values-prometheus-stack.yaml
    ├── values-loki.yaml
    ├── values-tempo.yaml
    └── ...
```

## 도메인

| 도메인 | 용도 |
|--------|------|
| api.staging.playball.one | 백엔드 API |
| argocd.staging.playball.one | ArgoCD UI |
| grafana.staging.playball.one | Grafana |

## 트래픽 흐름

```
CloudFront → ALB → Istio IngressGateway → Services (Pods)
                                              │
                              ┌───────────────┴───────────────┐
                              ▼                               ▼
                        RDS PostgreSQL                  ElastiCache Redis
```

## 배포

```bash
# argocd-sync/staging 브랜치에 push하면 자동 배포
git checkout argocd-sync/staging
git merge main
git push

# 또는 ArgoCD UI에서 Sync
```

## 주의사항

- RDS/ElastiCache는 Terraform으로 프로비저닝 (301 레포)
- DB 초기화는 302 레포의 staging/db/db-init.sh 사용
- Karpenter NodePool/EC2NodeClass는 이 레포에서 관리
