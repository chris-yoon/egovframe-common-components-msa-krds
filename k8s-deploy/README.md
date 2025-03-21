# Kubernetes 배포 환경 구축

## 디렉토리 구조

```
k8s-deploy/
├── README.md
├── docker-build.sh
├── bin/                    # 실행 가능한 바이너리 및 도구
│   └── istio-1.25.0/       # Istio 설치 용도 디렉토리
├── data/                   # 영구 데이터 저장소
│   ├── mysql/              # MySQL 데이터 디렉토리
│   └── opensearch/         # OpenSearch 데이터 디렉토리
│       └── nodes/          # OpenSearch 노드 데이터 디렉토리
├── manifests/
│   ├── egov-app/           # 애플리케이션 서비스 매니페스트
│   │   ├── egov-author-deployment.yaml
│   │   ├── egov-board-deployment.yaml
│   │   ├── egov-cmmncode-deployment.yaml
│   │   ├── egov-login-deployment.yaml
│   │   ├── egov-main-deployment.yaml
│   │   ├── egov-mobileid-deployment.yaml
│   │   ├── egov-questionnaire-deployment.yaml
│   │   └── egov-search-deployment.yaml
│   ├── egov-db/            # 데이터베이스 관련 매니페스트
│   │   ├── mysql-statefulset.yaml
│   │   └── opensearch-statefulset.yaml
│   ├── egov-infra/         # 인프라 서비스 매니페스트
│   │   ├── gatewayserver-deployment.yaml
│   │   └── rabbitmq-deployment.yaml
│   └── egov-monitoring/    # 모니터링 도구 매니페스트
│       ├── grafana.yaml
│       ├── jaeger.yaml
│       ├── kiali.yaml
│       └── prometheus.yaml
└── scripts/
    ├── setup/              # 설치 스크립트
    │   ├── 01-setup-istio.sh
    │   ├── 02-setup-namespaces.sh
    │   ├── 03-setup-monitoring.sh
    │   ├── 04-setup-database.sh
    │   ├── 05-setup-infrastructure.sh
    │   └── 06-setup-applications.sh
    ├── cleanup/            # 정리 스크립트
    │   ├── 01-cleanup-applications.sh
    │   ├── 02-cleanup-infrastructure.sh
    │   ├── 03-cleanup-database.sh
    │   ├── 04-cleanup-monitoring.sh
    │   ├── 05-cleanup-namespaces.sh
    │   └── 06-cleanup-istio.sh
    ├── setup.sh           # 전체 설치 스크립트
    └── cleanup.sh         # 전체 정리 스크립트
```

### 디렉토리 설명

- `bin/`: Kubernetes 클러스터 관리에 필요한 실행 파일들이 위치합니다.
  - `istioctl`: 서비스 메시 Istio를 관리하기 위한 명령줄 도구
  - `kubectl`: Kubernetes 클러스터를 관리하기 위한 명령줄 도구

- `data/`: 컨테이너의 영구 데이터를 저장하는 디렉토리입니다.
  - `mysql/`: MySQL 데이터베이스의 데이터 파일이 저장됩니다.
  - `opensearch/`: OpenSearch의 데이터와 설정 파일이 저장됩니다.

- `manifests/`: Kubernetes 리소스를 정의하는 YAML 파일들이 위치합니다.
  - `egov-app/`: 전자정부 프레임워크 애플리케이션 배포 정의
  - `egov-db/`: 데이터베이스 관련 배포 정의
  - `egov-infra/`: 인프라 서비스 배포 정의
  - `egov-monitoring/`: 모니터링 도구 배포 정의

- `scripts/`: 클러스터 설정 및 관리를 위한 스크립트들이 위치합니다.
  - `setup/`: 각 컴포넌트 설치 스크립트
  - `cleanup/`: 리소스 정리 스크립트

## Kubernetes 배포 가이드

### 1. 사전 준비사항

- Docker Desktop 설치 및 Kubernetes 활성화
- kubectl 설치
- 필요한 도구 설치 확인:
  ```bash
  kubectl version
  docker version
  ```

### 2. 프로젝트 빌드

1. 전체 서비스 빌드
```bash
./build.sh
```

2. 특정 서비스만 빌드하는 경우
```bash
./build.sh EgovMain
./build.sh EgovBoard
```

3. 빌드 결과 확인
- 각 서비스의 `target` 폴더에 jar 파일이 생성되었는지 확인

### 3. Docker 이미지 빌드

1. OpenSearch 이미지 빌드 (OpenSearch 이미지에 Nori 플러그인 추가)
```bash
cd EgovSearch/docker-compose/Opensearch
docker build -t opensearch-with-nori:2.15.0 -f Dockerfile .
```

2. 전체 서비스 이미지 빌드 (k8s 태그로 빌드)
```bash
./docker-build.sh -k
```

3. 특정 서비스만 빌드하는 경우 (k8s 태그로 빌드)
```bash
./docker-build.sh -k EgovMain
./docker-build.sh -k EgovBoard
```

4. 이미지 생성 확인
```bash
docker images --format "{{.Repository}} {{.Tag}}" | grep " k8s$"  # k8s 태그로 빌드된 이미지만 조회
```

### 4. Kubernetes 배포

1. PersistentVolume 설정 확인 및 수정
각 PV의 hostPath를 로컬 환경에 맞게 수정해야 합니다:

a. MySQL PV 설정 (`k8s-deploy/manifests/egov-db/mysql-pv.yaml`):
```yaml
spec:
  hostPath:
    path: "/your/local/path/k8s-deploy/data/mysql"  # 로컬 절대 경로로 수정
```

b. OpenSearch PV 설정 (`k8s-deploy/manifests/egov-db/opensearch-pv.yaml`):
```yaml
spec:
  hostPath:
    path: "/your/local/path/k8s-deploy/data/opensearch"  # 로컬 절대 경로로 수정
```

c. EgovMobileId PV 설정 (`k8s-deploy/manifests/egov-app/egov-mobileid-pv.yaml`):
```yaml
spec:
  hostPath:
    path: "/your/local/path/EgovMobileId/config"  # 로컬 절대 경로로 수정
```

d. EgovSearch PV 설정 (`k8s-deploy/manifests/egov-app/egov-search-pv.yaml`):
```yaml
# Config PV
spec:
  hostPath:
    path: "/your/local/path/EgovSearch-config/config"  # 로컬 절대 경로로 수정

# Model PV
spec:
  hostPath:
    path: "/your/local/path/EgovSearch-config/model"  # 로컬 절대 경로로 수정

# Example PV
spec:
  hostPath:
    path: "/your/local/path/EgovSearch-config/example"  # 로컬 절대 경로로 수정

# Cacerts PV
spec:
  hostPath:
    path: "/your/local/path/EgovSearch-config/cacerts"  # 로컬 절대 경로로 수정
```

2. 데이터베이스 초기화 스크립트 실행
```bash
cd EgovMain/src/main/resources
./initdb.sh
```

3. 데이터베이스 초기화 확인


2. 설치 스크립트 실행
```bash
cd k8s-deploy/scripts/setup
./01-setup-istio.sh
./02-setup-namespaces.sh
./03-setup-monitoring.sh
./04-setup-mysql.sh
./05-setup-opensearch.sh
./06-setup-infrastructure.sh
./07-setup-applications.sh
```

설치 과정:
- Istio 서비스 메시 설치 (istio-system 네임스페이스)
- Namespace 생성 (egov-infra, egov-app, egov-db, egov-monitoring)
- 모니터링 도구 설치 (Prometheus, Grafana, Kiali, Jaeger)
- 데이터베이스 설치 (MySQL, OpenSearch, OpenSearch Dashboard)
- 인프라 서비스 설치 (Gateway, RabbitMQ)
- 애플리케이션 서비스 배포 (EgovMain, EgovBoard, EgovLogin, EgovAuthor, EgovMobileId, EgovQuestionnaire, EgovCmmnCode, EgovSearch)

### 5. 서비스 접근

1. Gateway 서비스 접근 정보 확인
```bash
kubectl get svc gateway-server -n egov-infra
```

2. 모니터링 도구 접근

각 모니터링 도구의 역할과 접근 URL:

- Kiali (http://localhost:30001)
  - Istio 서비스 메시 시각화 및 모니터링 도구
  - 마이크로서비스 간의 통신 흐름과 의존성 확인
  - 트래픽 흐름, 서비스 헬스 체크, 설정 검증 기능 제공

- Grafana (http://localhost:30002)
  - 데이터 시각화 및 모니터링 대시보드 제공
  - Prometheus의 메트릭을 기반으로 다양한 차트와 그래프 생성
  - 사용자 정의 대시보드 생성 및 알림 설정 가능

- Jaeger (http://localhost:30003)
  - 분산 트레이싱 시스템
  - 마이크로서비스 간의 요청 추적 및 성능 병목 지점 분석
  - 요청의 전체 처리 과정과 각 단계별 소요 시간 확인

- Prometheus (http://localhost:30004)
  - 메트릭 수집 및 저장을 담당하는 시계열 데이터베이스
  - CPU, 메모리 사용량, 요청 수, 응답 시간 등 시스템 메트릭 모니터링
  - 알림 규칙 설정 및 관리 기능 제공

기본 접속 정보:
- Grafana: admin/admin (초기 접속 시 비밀번호 변경 필요)
- Kiali: admin/admin (기본값)

### 6. 문제 해결

1. 파드 상태 확인
```bash
kubectl describe pod <pod-name> -n <namespace>
```

2. 로그 확인
```bash
kubectl logs <pod-name> -n <namespace>
```

3. 파드 재시작
```bash
kubectl rollout restart deployment <deployment-name> -n <namespace>
```

### 7. 리소스 정리

1. 전체 리소스 정리
```bash
cd k8s-deploy/scripts/cleanup
./01-cleanup-applications.sh
./02-cleanup-infrastructure.sh
./03-cleanup-mysql.sh
./04-cleanup-opensearch.sh
./05-cleanup-monitoring.sh
./06-cleanup-namespaces.sh
./07-cleanup-istio.sh
```

정리 과정:
- Applications 정리 (egov-app 네임스페이스)
- Infrastructure 정리 (egov-infra 네임스페이스)
- Database 정리 (egov-db 네임스페이스)
- Monitoring 정리 (egov-monitoring 네임스페이스)
- Namespaces 정리 (egov-infra, egov-app, egov-db, egov-monitoring)
- Istio 정리 (istio-system 네임스페이스)

2. 정리 완료 후 확인
```bash
# 남아있는 네임스페이스 확인
kubectl get namespaces

# 남아있는 PV 확인
kubectl get pv

# 남아있는 PVC 확인
kubectl get pvc --all-namespaces
```

3. 특정 네임스페이스만 정리해야 하는 경우
```bash
kubectl delete namespace egov-app
kubectl delete namespace egov-infra
kubectl delete namespace egov-db
kubectl delete namespace egov-monitoring
```

4. 문제 해결
- PV/PVC가 Terminating 상태에서 멈춘 경우:
```bash
# PVC 강제 삭제
kubectl delete pvc <pvc-name> -n <namespace> --force --grace-period=0

# PV 강제 삭제
kubectl patch pv <pv-name> -p '{"metadata":{"finalizers":null}}'
kubectl delete pv <pv-name> --force --grace-period=0
```

### 8. 주의사항

- 배포 전 도커 이미지가 모두 빌드되어 있는지 확인
- 네임스페이스별 리소스 할당량 확인
- 데이터베이스 초기화 스크립트 실행 여부 확인
- 서비스 간 의존성을 고려한 배포 순서 준수

### 9. 환경별 설정

- 개발 환경: `SPRING_PROFILES_ACTIVE=k8s-dev`
- 테스트 환경: `SPRING_PROFILES_ACTIVE=k8s-test`
- 운영 환경: `SPRING_PROFILES_ACTIVE=k8s-prod`

각 환경별 설정은 ConfigMap을 통해 관리됩니다.
