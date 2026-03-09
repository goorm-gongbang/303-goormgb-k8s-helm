# DEV Monitoring Baseline (As-Is)

Last updated: 2026-03-09
Owner: Cloud Team

이 문서는 현재 `dev` 환경에 실제 배포된 대시보드/알림 설정 기준으로 운영 지표를 정리한 문서다.
문서가 구현을 앞서가지 않도록 "현재 동작 중인 항목"만 남긴다.

## 1. Alerting (현재 운영 기준)

### 1.1 활성 알림
- `DevHttp5xxDetected` (Critical)
  - 식: `sum(increase(http_server_request_duration_seconds_count{job=~"...", http_response_status_code=~"5.."}[5m])) > 0`
  - `for: 1m`
  - 수신: `discord-critical` (`#alerts-critical` webhook)

### 1.2 라우팅
- 기본 receiver: `null` (드롭)
- 현재는 `DevHttp5xxDetected`만 Discord 전송
- Warning/Info receiver는 준비되어 있으나 현재 룰 미연결

## 2. Dashboards (현재 구성 기준)

### 2.1 Application Monitoring (Spring Boot)
File: `common-charts/infra/monitoring/prometheus-stack/files/grafana-dashboards/dev-team-observability/application-monitoring-springboot.json`

유지 지표:
- `http_server_request_duration_seconds_count` 기반 RPS
- 2xx/4xx/5xx 비율
- `http_server_request_duration_seconds_bucket` 기반 P95/P99
- 총 요청 수 / 총 5xx 수
- route별 평균 응답시간 Top N

### 2.2 HTTP Status Analysis
File: `common-charts/infra/monitoring/prometheus-stack/files/grafana-dashboards/dev-team-observability/http-status-analysis.json`

유지 지표:
- 상태코드 클래스(2xx/3xx/4xx/5xx) 요청 추이
- 4xx/5xx 주요 경로 Top N
- 상태코드별 누적 건수

### 2.3 Redis (Cache/Queue)
File: `common-charts/infra/monitoring/prometheus-stack/files/grafana-dashboards/dev-team-observability/cache-queue-monitoring-redis.json`

유지 지표:
- `redis_up`
- command/sec, command latency
- hit ratio
- memory used/max/rss, fragmentation
- evicted keys/sec
- connected/blocked clients
- key count/expiring keys

### 2.4 PostgreSQL
File: `common-charts/infra/monitoring/prometheus-stack/files/grafana-dashboards/dev-team-observability/database-monitoring-postgresql.json`

유지 지표:
- max connections, active/idle sessions
- process cpu/memory/open fds
- commit/rollback, lock, conflict/deadlock
- cache hit rate, temp bytes
- checkpoint time, bgwriter buffers

### 2.5 Loki Logs
File: `common-charts/infra/monitoring/prometheus-stack/files/grafana-dashboards/dev-team-observability/logs-loki-kubernetes.json`

유지 지표:
- 로그 건수 추이
- log stream 조회

## 3. 문서에서 당장 제외(백로그로 이동)

아래는 현재 dev 대시보드/알림에 직접 반영되지 않았으므로 "운영 기준"에서 제외하고 백로그로 관리한다.

- 비즈니스 KPI 알림:
  - 대기열 이탈률, 대기시간 P99, 현재 대기 인원
  - 좌석 추천 실패율/처리시간/락 대기시간
  - 결제 성공률/응답시간
  - 인증 성공률
  - 매크로 탐지/차단 IP
- 앱 리소스 임계값 알림:
  - 앱 CPU/메모리/DB 커넥션 풀 경보
- `ticketing_queue_waiting_users` (현재 메트릭 미정의)

## 4. 다음 확장 원칙

- Rule first: 알림은 문서보다 먼저 Helm/PrometheusRule로 코드화
- Dashboard parity: 룰 추가 시 관련 패널/탐색 패널 동시 추가
- Channel policy:
  - Critical -> `#alerts-critical`
  - Warning -> `#alerts-warning`
  - Info -> `#alerts-info`
- UI 수동 설정 금지: Grafana/Alertmanager는 GitOps 기준 유지
