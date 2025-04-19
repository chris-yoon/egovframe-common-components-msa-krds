# 자주하는 질문 (FAQ)

이 FAQ는 전자정부 표준프레임워크의 Kubernetes 배포 환경에서 자주 묻는 질문에 대한 답변을 제공합니다.
- [1. 기본 리소스](#1-기본-리소스)
- [2. 스토리지](#2-스토리지)
- [3. 네트워킹](#3-네트워킹)
- [4. 모니터링과 로깅](#4-모니터링과-로깅)
- [5. 서비스 메시 (Istio)](#5-서비스-메시-istio)
- [6. 운영 관리](#6-운영-관리)
- [7. 보안](#7-보안)
- [8. 배포와 관리](#8-배포와-관리)

## 1. 기본 리소스
- Deployment, StatefulSet, DaemonSet 차이점
- Pod와 Container
- Service 유형 (ClusterIP, NodePort, LoadBalancer)
- ConfigMap과 Secret
- Label과 Annotation

### 이 프로젝트에서는 어떤 Kubernetes 리소스들이 사용되나요?

프로젝트의 주요 Kubernetes 리소스는 다음과 같습니다:

- **egov-db 네임스페이스**:
   - MySQL: StatefulSet, Service, ConfigMap, PersistentVolumeClaim
   - OpenSearch: StatefulSet, Service, ConfigMap, PersistentVolumeClaim

- **egov-app 네임스페이스**:
   - 애플리케이션 서비스들: Deployment, Service, HorizontalPodAutoscaler
   - 설정: ConfigMap, Secret
   - 네트워크 정책: NetworkPolicy

- **egov-infra 네임스페이스**:
   - RabbitMQ: Deployment, Service, PersistentVolumeClaim
   - 모니터링 도구들: Deployment, Service

- **egov-monitoring 네임스페이스**:
   - OpenTelemetry Collector: DaemonSet (Operator 관리)
   - Prometheus: StatefulSet
   - Grafana: Deployment

### StatefulSet과 Deployment 그리고 DaemonSet 의 차이는 무엇인가요?

**StatefulSet**:
- 상태를 가진 애플리케이션에 적합
- 순차적인 배포와 스케일링
- 고정된 네트워크 식별자 (mysql-0, mysql-1, opensearch-0, opensearch-1)
- 안정적인 영구 스토리지
- 사용 예: MySQL, OpenSearch 

**Deployment**:
- 상태가 없는 애플리케이션에 적합
- 자유로운 배포와 스케일링
- 동적인 네트워크 식별자
- 임시 스토리지 사용 가능
- 사용 예: 웹 서버, API 서버

**DaemonSet**:
- 모든 노드에 하나의 Pod를 배포
- 사용 예: 로그 수집기, 모니터링 에이전트

### replicas 설정은 어떤 리소스에서 사용할 수 있나요?

**Deployment**:
- `replicas` 설정 가능
- 자유롭게 스케일 업/다운 가능
- 예시:
  ```yaml
  apiVersion: apps/v1
  kind: Deployment
  spec:
    replicas: 3    # 원하는 수만큼 설정 가능
  ```

**StatefulSet**:
- `replicas` 설정 가능
- 순차적으로 스케일 업/다운 (0-1-2...)
- 예시:
  ```yaml
  apiVersion: apps/v1
  kind: StatefulSet
  spec:
    replicas: 3    # 순차적으로 생성/삭제됨
  ```

**DaemonSet**:
- `replicas` 설정 불가
- 노드 당 자동으로 1개의 Pod 배포
- 노드 추가/삭제에 따라 자동으로 Pod 수 조정
- 예시:
  ```yaml
  apiVersion: apps/v1
  kind: DaemonSet
  spec:
    # replicas 설정 없음
    # 노드 수에 따라 자동으로 결정됨
  ```

주의사항:
- DaemonSet은 노드 수에 따라 자동으로 Pod 수가 결정되므로 replicas 설정이 무의미합니다.
- StatefulSet의 경우 순차적 배포/삭제가 중요한 경우에 사용합니다 (예: 데이터베이스 클러스터).
- Deployment는 가장 유연한 스케일링을 제공합니다.

### MySQL StatefulSet의 replicas가 3인 경우는 어떤 상황인가요?

MySQL StatefulSet에서 replicas: 3은 일반적으로 MySQL 복제(Replication) 구성을 의미합니다:

**구성 예시**:
```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mysql
spec:
  serviceName: mysql
  replicas: 3    # 1개의 Primary와 2개의 Secondary
  ...
```

**Pod 생성 순서**:
- `mysql-0`: Primary (Master) 노드
   - 읽기/쓰기 작업 수행
   - 데이터 변경사항을 복제 로그에 기록
- `mysql-1`: Secondary (Slave) 노드
   - Primary의 복제 로그를 실시간 동기화
   - 읽기 전용 작업 수행
- `mysql-2`: Secondary (Slave) 노드
   - Primary의 복제 로그를 실시간 동기화
   - 읽기 전용 작업 수행

**장점**:
- 고가용성 (HA) 확보
- 읽기 작업 분산 처리
- 데이터 백업 및 복구 용이

**사용 사례**:
- 대규모 읽기 작업이 필요한 경우
- 무중단 서비스가 필요한 경우
- 데이터 안정성이 중요한 경우

**주의사항**:
- 복잡한 설정이 필요 (복제 구성, 자동 장애 조치 등)
- 더 많은 리소스 필요 (CPU, 메모리, 스토리지)
- 네트워크 대역폭 고려 필요

### ConfigMap과 Secret의 차이는 무엇인가요?

**ConfigMap**:
- 일반적인 설정 데이터 저장
- Base64 인코딩되지 않음
- 평문으로 저장됨
- 사용 예: 
  ```yaml
  apiVersion: v1
  kind: ConfigMap
  metadata:
    name: app-config
  data:
    app.properties: |
      server.port=8080
      logging.level.root=INFO
  ```

**Secret**:
- 민감한 정보 저장
- Base64 인코딩됨
- 암호화 가능 (별도 설정 필요)
- 사용 예:
  ```yaml
  apiVersion: v1
  kind: Secret
  metadata:
    name: db-credentials
  type: Opaque
  data:
    username: YWRtaW4=  # admin
    password: cGFzc3dvcmQ=  # password
  ```

### Service의 종류와 차이점은 무엇인가요?

- **ClusterIP** (기본값):
   - 클러스터 내부 통신용
   - 외부에서 접근 불가
   - 사용 예: 내부 API 서버

- **NodePort**:
   - 모든 노드의 특정 포트로 노출
   - 포트 범위: 30000-32767
   - 사용 예: 개발 환경의 웹 서버

- **LoadBalancer**:
   - 클라우드 로드밸런서와 연동
   - 외부에서 접근 가능
   - 사용 예: 프로덕션 환경의 웹 서버

- **ExternalName**:
   - 외부 서비스에 대한 DNS 별칭
   - CNAME 레코드 생성
   - 사용 예: 외부 데이터베이스 연결

### 리소스 요청(requests)과 제한(limits)은 어떻게 설정하나요?

리소스 요청과 제한은 Pod의 컨테이너에 대한 리소스 관리를 위해 설정합니다:

```yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "100m"
  limits:
    memory: "512Mi"
    cpu: "200m"
```

**설정 기준**:
- requests: 최소 보장 리소스
- limits: 최대 사용 가능 리소스
- cpu: 1 CPU = 1000m (밀리코어)
- memory: Mi (메비바이트) 또는 Gi (기비바이트)

**주의사항**:
- requests는 너무 높게 설정하지 않기
- limits는 실제 사용량을 고려하여 설정
- memory limits 초과 시 Pod 종료됨
- cpu limits 초과 시 스로틀링됨

### 리소스 상태를 모니터링하려면 어떻게 해야 하나요?

- **기본 명령어**:
```bash
# Pod 상태 확인
kubectl get pods -n <namespace>

# 상세 정보 확인
kubectl describe pod <pod-name> -n <namespace>

# 리소스 사용량 확인
kubectl top pod -n <namespace>
kubectl top node
```

- **로그 확인**:
```bash
# Pod 로그 확인
kubectl logs <pod-name> -n <namespace>

# 이전 로그 확인
kubectl logs <pod-name> -n <namespace> --previous

# 실시간 로그 확인
kubectl logs -f <pod-name> -n <namespace>
```

**모니터링 도구**:
- Prometheus: 메트릭 수집
- Grafana: 대시보드 및 시각화
- OpenTelemetry: 분산 추적

### Label과 Annotation의 차이점은 무엇인가요?

**Label**:
- 리소스 식별과 선택을 위한 메타데이터
- 검색과 필터링에 사용
- 간단한 키-값 쌍 구조
- 예시:
```yaml
metadata:
  labels:
    app: mysql
    tier: database
    environment: production
```

**주요 Label 사용 사례**:
- Pod 선택자 (Selector)
```yaml
# Service에서 Pod 선택
spec:
  selector:
    app: mysql
```
- 노드 선택 (Node Selector)
```yaml
# Pod를 특정 노드에 배포
spec:
  nodeSelector:
    disk: ssd
```
- 리소스 그룹화
```yaml
# kubectl get pods -l app=mysql,tier=database
```

**Annotation**:
- 리소스에 대한 추가 정보 제공
- 비식별용 메타데이터
- 더 큰 데이터 구조 가능
- 예시:
```yaml
metadata:
  annotations:
    kubernetes.io/ingress-bandwidth: 1M
    prometheus.io/scrape: 'true'
    deployment.kubernetes.io/revision: '2'
```

**주요 Annotation 사용 사례**:
- 빌드/릴리스 정보
```yaml
annotations:
  build.company.io/git-commit: abc123
  build.company.io/pipeline-id: pipeline-456
```
- 설정 정보
```yaml
annotations:
  config.company.io/refresh-interval: "30s"
  config.company.io/log-level: "debug"
```
- 도구 설정
```yaml
annotations:
  prometheus.io/port: "9090"
  prometheus.io/path: "/metrics"
```

**주요 차이점**:

- **용도**:
   - Label: 리소스 식별과 선택
   - Annotation: 추가 정보 제공

- **검색 가능성**:
   - Label: kubectl로 검색/필터링 가능
   - Annotation: 검색/필터링에 사용 불가

- **제한사항**:
   - Label: 키-값이 63자 이하
   - Annotation: 더 큰 데이터 허용

- **사용 예시**:
   - Label:
     ```yaml
     labels:
       app: nginx
       environment: prod
     ```
   - Annotation:
     ```yaml
     annotations:
       description: "이 서비스는 사용자 인증을 처리합니다"
       maintainer: "team-auth@company.com"
     ```

**모범 사례**:
- Label은 간단하고 명확하게 유지
- Annotation은 상세 정보에 사용
- Label 키에 네임스페이스 사용 권장 (예: company.io/tier)
- 자동화된 도구가 사용할 정보는 Annotation으로 관리


## 2. 스토리지
- Volume과 VolumeMount
- PersistentVolume (PV)
- PersistentVolumeClaim (PVC)
- StorageClass
- Backup과 Restore
### Volume과 VolumeMount의 차이는 무엇인가요?

**Volume**:
- Pod 레벨에서 정의되는 저장소
- 실제 저장소의 유형과 속성을 정의
- 여러 컨테이너에서 공유 가능
```yaml
apiVersion: v1
kind: Pod
spec:
  volumes:                         # Volume 정의
  - name: config-volume           
    configMap:                     # ConfigMap을 Volume으로 사용
      name: app-config
  - name: data-volume
    persistentVolumeClaim:         # PVC를 Volume으로 사용
      claimName: mysql-pvc
```

**VolumeMount**:
- 컨테이너 레벨에서 정의
- Volume을 컨테이너의 특정 경로에 마운트
- 각 컨테이너마다 다른 경로에 마운트 가능
```yaml
spec:
  containers:
  - name: app
    volumeMounts:                  # VolumeMount 정의
    - name: config-volume          # Volume의 이름
      mountPath: /app/config       # 컨테이너 내부 경로
    - name: data-volume
      mountPath: /var/lib/mysql
```

### 어떤 종류의 Volume들이 있나요?

**1. ConfigMap Volume**:
- 설정 파일을 Volume으로 마운트
- 동적 업데이트 가능
```yaml
volumes:
- name: config-volume
  configMap:
    name: app-config
    items:                         # 특정 키만 선택적 마운트
    - key: app.properties
      path: application.properties
```

**2. Secret Volume**:
- 민감한 정보를 Volume으로 마운트
- 메모리에 저장됨
```yaml
volumes:
- name: secret-volume
  secret:
    secretName: app-secrets
```

**3. PersistentVolume (PV/PVC)**:
- 영구적인 데이터 저장
- 컨테이너/Pod 생명주기와 독립적
```yaml
volumes:
- name: data-volume
  persistentVolumeClaim:
    claimName: mysql-pvc
```

**4. emptyDir**:
- Pod 임시 저장소
- Pod가 삭제되면 함께 삭제됨
```yaml
volumes:
- name: cache-volume
  emptyDir: {}
```

### ConfigMap을 Volume으로 사용하는 예시

**1. ConfigMap 생성**:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  app.properties: |
    server.port=8080
    spring.profiles.active=prod
  logging.properties: |
    log.level=INFO
```

**2. Pod에서 ConfigMap Volume 사용**:
```yaml
apiVersion: v1
kind: Pod
spec:
  volumes:
  - name: config-volume
    configMap:
      name: app-config
  containers:
  - name: app
    volumeMounts:
    - name: config-volume
      mountPath: /app/config
      readOnly: true    # 읽기 전용으로 마운트
```

**결과 디렉토리 구조**:
```
/app/config/
  ├── app.properties
  └── logging.properties
```

**장점**:
- ConfigMap 업데이트 시 자동 반영
- 여러 컨테이너에서 공유 가능
- 읽기 전용으로 마운트 가능

**주의사항**:
- ConfigMap 업데이트 후 반영에 시간이 걸릴 수 있음
- 큰 용량의 데이터는 PV/PVC 사용 권장

### 프로젝트의 PV/PVC 구성은 어떻게 되어있나요?

현재 프로젝트의 주요 PV/PVC 구성은 다음과 같습니다:

- **egov-db 네임스페이스**:
   - MySQL: `mysql-pv-0` (1Gi)
   - OpenSearch: `opensearch-pv-0` (1Gi)

- **egov-app 네임스페이스**:
   - EgovMobileId: `egov-mobileid-pv` (10Mi)
   - EgovSearch:
     - Config: `egov-search-config-pv` (1Mi)
     - Model: `egov-search-model-pv` (1Gi)
     - Example: `egov-search-example-pv` (1Mi)
     - Cacerts: `egov-search-cacerts-pv` (1Mi)

- **egov-infra 네임스페이스**:
   - RabbitMQ: `rabbitmq-pv` (10Gi)

### PV/PVC가 Terminating 상태에서 멈춘 경우 어떻게 해야 하나요?

다음 명령어로 강제 삭제할 수 있습니다:

```bash
# PVC 강제 삭제
kubectl delete pvc <pvc-name> -n <namespace> --force --grace-period=0

# PV 강제 삭제
kubectl patch pv <pv-name> -p '{"metadata":{"finalizers":null}}'
kubectl delete pv <pv-name> --force --grace-period=0
```

### PV/PVC 강제 삭제 시 finalizers를 먼저 제거하는 이유는 무엇인가요?

`finalizers`는 Kubernetes의 리소스 보호 메커니즘으로, PV를 강제로 삭제할 때 `finalizers`를 먼저 제거하는 이유는 다음과 같습니다:

- **Finalizers의 목적**:
   - 리소스가 삭제되기 전에 필요한 정리 작업을 보장합니다
   - 연관된 리소스들의 안전한 삭제를 보장합니다
   - 데이터 손실을 방지합니다

- **PV 삭제 과정**:
   - PV에 `finalizers`가 있으면 Kubernetes는 실제 삭제를 보류합니다
   - `Terminating` 상태로 유지되며 삭제가 완료되지 않습니다

- **강제 삭제가 필요한 상황**:
   - PV가 `Terminating` 상태에서 멈춘 경우
   - 연관된 리소스가 이미 손상되거나 삭제된 경우
   - 정상적인 삭제 프로세스가 실패한 경우

- **주의사항**:
   - 강제 삭제는 마지막 수단으로만 사용해야 합니다
   - 데이터 손실 가능성이 있습니다
   - 클러스터 상태의 불일치를 초래할 수 있습니다

예시 명령어:
```bash
# 1. finalizers 제거
kubectl patch pv <pv-name> -p '{"metadata":{"finalizers":null}}'

# 2. 강제 삭제
kubectl delete pv <pv-name> --force --grace-period=0
```

따라서 `finalizers`를 먼저 제거하는 것은 PV의 강제 삭제를 가능하게 하는 필수 단계입니다.

### PV/PVC 상태를 확인하려면 어떻게 해야 하나요?

```bash
# 모든 네임스페이스의 PVC 확인
kubectl get pvc --all-namespaces

# 특정 네임스페이스의 PVC 확인
kubectl get pvc -n <namespace>

# 모든 PV 확인
kubectl get pv

# PV/PVC 상세 정보 확인
kubectl describe pv <pv-name>
kubectl describe pvc <pvc-name> -n <namespace>
```

### hostPath 타입 PV의 경로를 변경하려면 어떻게 해야 하나요?

- 먼저 기존 데이터를 백업합니다.
- 관련 워크로드를 중지합니다.
- PV/PVC를 삭제합니다.
- YAML 파일에서 `spec.hostPath.path` 값을 수정합니다:

예시 (`k8s-deploy/manifests/egov-db/mysql-pv.yaml`):
```yaml
spec:
  hostPath:
    path: "/your/new/path/data/mysql"
```

- 수정된 PV/PVC를 다시 생성합니다.
- 워크로드를 재시작합니다.

### PV/PVC 용량을 변경하려면 어떻게 해야 하나요?

현재 구성에서는 PV/PVC 용량을 직접 변경할 수 없습니다. 다음 단계를 따라야 합니다:

- 데이터 백업
- 기존 워크로드 중지
- 기존 PV/PVC 삭제
- YAML 파일에서 용량 수정:
```yaml
spec:
  capacity:
    storage: <새로운_용량>
  ...
spec:
  resources:
    requests:
      storage: <새로운_용량>
```
- 새로운 PV/PVC 생성
- 데이터 복원
- 워크로드 재시작

### PV/PVC가 올바르게 연결되었는지 확인하려면 어떻게 해야 하나요?

```bash
# PVC 상태 확인
kubectl get pvc <pvc-name> -n <namespace>

# Pod의 볼륨 마운트 상태 확인
kubectl describe pod <pod-name> -n <namespace>

# Pod의 이벤트 로그 확인
kubectl get events -n <namespace> | grep <pod-name>
```

정상적으로 연결된 경우:
- PVC 상태가 "Bound"로 표시됨
- Pod 설명에서 볼륨이 올바르게 마운트된 것을 확인할 수 있음
- 관련 오류 이벤트가 없음

## 3. 네트워킹
- Service Discovery
- Ingress와 Gateway
- NetworkPolicy
- DNS 설정
- 로드밸런싱

### Kubernetes 클러스터 내부 DNS 이름 규칙은 어떻게 되나요?

Kubernetes의 DNS 이름은 다음과 같은 형식을 따릅니다:

**기본 형식**: `<서비스이름>.<네임스페이스>.svc.cluster.local`

**예시**:
- `mysql.egov-db.svc.cluster.local`
- `opensearch.egov-db.svc.cluster.local`
- `egov-gateway.egov-app.svc.cluster.local`

**각 부분의 의미**:
- `서비스이름`: Service 리소스의 metadata.name
- `네임스페이스`: Service가 속한 namespace
- `svc`: Service의 약자 (고정값)
- `cluster.local`: 클러스터의 기본 DNS 도메인 (고정값)

**DNS 조회 규칙**:
- 같은 네임스페이스 내:
   - 짧은 이름 사용 가능: `mysql`
   ```yaml
   spring:
     datasource:
       url: jdbc:mysql://mysql:3306/com
   ```

- 다른 네임스페이스:
   - 네임스페이스까지 포함: `mysql.egov-db`
   ```yaml
   spring:
     datasource:
       url: jdbc:mysql://mysql.egov-db:3306/com
   ```

- 전체 주소:
   - 전체 DNS 이름 사용: `mysql.egov-db.svc.cluster.local`
   ```yaml
   spring:
     datasource:
       url: jdbc:mysql://mysql.egov-db.svc.cluster.local:3306/com
   ```

**실제 사용 예시**:

- **MySQL 서비스**:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: mysql
  namespace: egov-db
spec:
  ports:
  - port: 3306
  selector:
    app: mysql
```

- **OpenSearch 서비스**:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: opensearch
  namespace: egov-db
spec:
  ports:
  - port: 9200
  selector:
    app: opensearch
```

- **서비스 접근**:
```yaml
# egov-app 네임스페이스의 애플리케이션에서
spring:
  datasource:
    url: jdbc:mysql://mysql.egov-db:3306/com
  opensearch:
    urls: http://opensearch.egov-db:9200
```

**장점**:
- 서비스 디스커버리 자동화
- 네임스페이스 기반 격리
- IP 변경에도 안정적인 연결
- 클러스터 내부 통신 단순화

**주의사항**:
- 클러스터 외부에서는 DNS 이름 사용 불가
- 네임스페이스 간 통신은 명시적으로 허용 필요
- 로컬 개발 환경에서는 다른 설정 필요

**권장 사항**:
- 가능한 전체 DNS 이름 사용 (명확성)
- 네임스페이스 간 통신 규칙 문서화
- NetworkPolicy로 통신 제어

## 4. 모니터링과 로깅
- OpenTelemetry 설정
- Prometheus와 Grafana
- Loki를 통한 로그 수집
- 알림 설정
- 대시보드 구성

### OpenTelemetry Collector는 무엇인가요?

OpenTelemetry Collector는 텔레메트리 데이터(로그, 메트릭, 트레이스)를 수집, 처리, 내보내는 핵심 컴포넌트입니다. 주요 구성요소는 다음과 같습니다:

- **Receivers (수신기)**:
   - 텔레메트리 데이터를 수신하는 입구
   - OTLP, Prometheus, filelog 등 다양한 형식 지원

- **Processors (처리기)**:
   - 수신된 데이터를 가공하고 처리
   - 메모리 제한, 배치 처리, 속성 추가/수정 등

- **Exporters (내보내기)**:
   - 처리된 데이터를 외부 시스템으로 전송
   - Jaeger, Prometheus, Loki 등으로 전송

- **Service (서비스)**:
   - 파이프라인 구성 및 컴포넌트 연결
   - 텔레메트리 설정

### OpenTelemetry Collector는 어떻게 설치되나요?

- Operator 설치:
```bash
kubectl apply -f https://github.com/open-telemetry/opentelemetry-operator/releases/download/v0.120.0/opentelemetry-operator.yaml
```

- Collector 설정 적용:
```bash
kubectl apply -f k8s-deploy/manifests/egov-monitoring/opentelemetry-collector.yaml
```

- 설치 확인:
```bash
kubectl get pods -n egov-monitoring | grep otel-collector
```

### 애플리케이션에서 OpenTelemetry를 어떻게 설정하나요?

- **application.yml 설정**:
```yaml
otel:
  exporter:
    otlp:
      endpoint: http://otel-collector.egov-monitoring.svc.cluster.local:4317
  service:
    name: ${spring.application.name}
  traces:
    exporter: otlp
  metrics:
    exporter: otlp
  logs:
    exporter: otlp
```

- **로깅 설정** (logback-spring.xml):
```xml
<appender name="OTEL" class="io.opentelemetry.instrumentation.logback.appender.v1_0.OpenTelemetryAppender">
    <encoder>
        <pattern>%d{yyyy-MM-dd HH:mm:ss.SSS} [%thread] %-5level %logger{36} - %msg%n</pattern>
    </encoder>
</appender>

<root level="INFO">
    <appender-ref ref="CONSOLE"/>
    <appender-ref ref="OTEL"/>
</root>
```

### OpenTelemetry Collector가 정상 작동하는지 확인하려면 어떻게 해야 하나요?

- **Pod 상태 확인**:
```bash
kubectl get pods -n egov-monitoring | grep otel-collector
```

- **로그 확인**:
```bash
kubectl logs -n egov-monitoring -l app=opentelemetry-collector
```

- **서비스 엔드포인트 확인**:
```bash
kubectl get svc -n egov-monitoring otel-collector
```

### 수집된 텔레메트리 데이터는 어디서 확인할 수 있나요?

- **트레이스**: Jaeger UI (기본 포트: 30686)
   - 분산 트레이싱 정보 확인
   - 서비스 간 호출 관계 분석

- **메트릭**: Prometheus/Grafana (기본 포트: 30000)
   - 시스템 및 애플리케이션 메트릭 확인
   - 대시보드를 통한 시각화

- **로그**: Grafana Loki (Grafana를 통해 접근)
   - 중앙화된 로그 수집 및 조회
   - 예시 쿼리: `{job="EgovHello",level="INFO"}`

### OpenTelemetry Collector 설정을 변경하려면 어떻게 해야 하나요?

- `k8s-deploy/manifests/egov-monitoring/opentelemetry-collector.yaml` 파일을 수정

- 변경사항 적용:
```bash
kubectl apply -f k8s-deploy/manifests/egov-monitoring/opentelemetry-collector.yaml
```

- Pod 재시작 확인:
```bash
kubectl get pods -n egov-monitoring | grep otel-collector
```

주의사항: 설정 변경 시 일시적인 텔레메트리 데이터 수집 중단이 발생할 수 있습니다.

### OpenTelemetry Collector 설치 시 Operator를 먼저 설치하는 이유는 무엇인가요?

OpenTelemetry Operator를 먼저 설치하는 것은 Kubernetes에서 OpenTelemetry Collector를 효과적으로 관리하기 위해서입니다. Operator는 다음과 같은 중요한 기능들을 제공합니다:

- **CRD (Custom Resource Definition) 관리**:
   - OpenTelemetryCollector CRD를 등록하고 관리
   - Kubernetes에서 OpenTelemetry 리소스를 네이티브하게 처리 가능
   - `kubectl get otelcol` 같은 명령어 사용 가능

- **Collector 라이프사이클 관리**:
   - Collector의 배포, 업데이트, 삭제를 자동화
   - 설정 변경 시 자동으로 Pod 재시작
   - 버전 업그레이드 관리

- **설정 자동화**:
   - 설정 변경 감지 및 자동 적용
   - 여러 Collector 인스턴스의 일관된 설정 유지
   - 설정 오류 검증

- **모니터링 및 자동 복구**:
   - Collector의 상태 모니터링
   - 문제 발생 시 자동 복구
   - 리소스 사용량 최적화

설치 순서 예시:
```bash
# 1. Operator 설치
kubectl apply -f https://github.com/open-telemetry/opentelemetry-operator/releases/download/v0.120.0/opentelemetry-operator.yaml

# 2. Operator 설치 확인
kubectl wait --for=condition=Ready pods -l control-plane=controller-manager -n opentelemetry-operator-system --timeout=300s

# 3. CRD 설치 확인
kubectl get crd opentelemetrycollectors.opentelemetry.io

# 4. Collector 설정 적용
kubectl apply -f k8s-deploy/manifests/egov-monitoring/opentelemetry-collector.yaml
```

만약 Operator 없이 Collector를 직접 배포할 경우:
- 수동으로 모든 리소스를 관리해야 함
- 설정 변경 시 수동 업데이트 필요
- 버전 관리가 복잡해짐
- 자동화된 관리 기능 사용 불가

### 이 프로젝트에서는 어떤 Operator들이 사용되나요?

이 프로젝트에서는 두 가지 주요 Operator가 사용됩니다:

- **OpenTelemetry Operator**:
   - 용도: 텔레메트리 데이터 수집 관리
   - 주요 리소스:
     ```yaml
     apiVersion: opentelemetry.io/v1beta1
     kind: OpenTelemetryCollector
     metadata:
       name: otel-collector
       namespace: egov-monitoring
     ```
   - 설치 위치: `k8s-deploy/scripts/setup/03-setup-monitoring.sh`
   - 설정 파일: `k8s-deploy/manifests/egov-monitoring/opentelemetry-collector.yaml`

- **Istio Operator**:
   - 용도: 서비스 메시 관리
   - 주요 리소스:
     ```yaml
     apiVersion: telemetry.istio.io/v1alpha1
     kind: Telemetry
     metadata:
       name: egov-apps-telemetry
       namespace: egov-app
     ```
   - 설치 위치: `k8s-deploy/scripts/setup/01-setup-istio.sh`
   - 설정 파일: `k8s-deploy/manifests/egov-istio/telemetry.yaml`

### 다른 컴포넌트들은 Operator를 사용하지 않나요?

다음 컴포넌트들은 일반적인 Kubernetes 리소스로 관리됩니다:
- MySQL (StatefulSet)
- OpenSearch (StatefulSet)
- RabbitMQ (Deployment)
- 기타 애플리케이션 서비스들 (Deployment)

이러한 컴포넌트들은 특별한 Operator 없이도 기본적인 Kubernetes 기능으로 충분히 관리가 가능하기 때문에 별도의 Operator를 사용하지 않습니다.

### Operator를 사용하는 것과 사용하지 않는 것의 차이는 무엇인가요?

**Operator 사용 시 장점**:
- 복잡한 애플리케이션의 자동화된 관리
- 커스텀 리소스를 통한 선언적 관리
- 자동화된 운영 작업 (백업, 복구, 스케일링 등)
- 애플리케이션 특화된 로직 구현 가능

**일반 Kubernetes 리소스 사용 시 장점**:
- 간단한 설정과 관리
- 적은 리소스 사용
- 학습 곡선이 낮음
- 기본 Kubernetes 기능으로 충분한 경우 적합

선택 기준:
- 애플리케이션의 복잡도
- 자동화가 필요한 운영 작업의 수준
- 리소스 사용량
- 관리 용이성

## 5. 서비스 메시 (Istio)
- VirtualService와 DestinationRule
- Gateway 설정
- 트래픽 관리
- 보안 설정
- 모니터링 통합
### Virtual Service와 Destination Rule은 각각 어떤 역할을 하나요?

**Virtual Service**:
- 트래픽 라우팅 규칙을 정의
- URI 기반 라우팅, 가중치 기반 라우팅 등 지원
- Gateway와 연동하여 외부 트래픽 처리
- 사용 예:
  ```yaml
  apiVersion: networking.istio.io/v1beta1
  kind: VirtualService
  metadata:
    name: egov-hello
    namespace: egov-app
  spec:
    hosts:
    - "*"
    gateways:
    - istio-system/istio-ingressgateway
    http:
    - match:
      - uri:
          prefix: /a/b/c/hello
      route:
      - destination:
          host: egov-hello
          port:
            number: 80
  ```

**Destination Rule**:
- 트래픽 정책을 정의
- 로드밸런싱 설정
- Circuit Breaker 설정
- 사용 예:
  ```yaml
  apiVersion: networking.istio.io/v1beta1
  kind: DestinationRule
  metadata:
    name: egov-hello
    namespace: egov-app
  spec:
    host: egov-hello
    trafficPolicy:
      loadBalancer:
        simple: ROUND_ROBIN
      outlierDetection:
        interval: 1s
        consecutive5xxErrors: 3
        baseEjectionTime: 30s
        maxEjectionPercent: 100
  ```

### Circuit Breaker는 어떻게 동작하나요?

Circuit Breaker는 Destination Rule의 `outlierDetection` 설정을 통해 구현됩니다:

- **동작 방식**:
  - 연속된 5xx 에러 발생 시 해당 Pod를 트래픽에서 제외
  - 일정 시간 후 자동으로 트래픽 재개
  - 장애 Pod의 격리를 통한 시스템 안정성 확보

- **주요 설정**:
  - `interval`: 장애 감지 주기
  - `consecutive5xxErrors`: 연속 오류 허용 횟수
  - `baseEjectionTime`: 트래픽 제외 시간
  - `maxEjectionPercent`: 최대 제외 가능한 Pod 비율

### 트래픽 미러링은 어떻게 설정하나요?

Virtual Service에서 `mirror`와 `mirrorPercentage` 설정을 통해 구현합니다:

```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: egov-hello
  namespace: egov-app
spec:
  hosts:
  - "*"
  http:
  - route:
    - destination:
        host: egov-hello
        subset: v1
    mirror:
      host: egov-hello
      subset: v2
    mirrorPercentage:
      value: 100
```

- **용도**:
  - 실제 트래픽을 복제하여 테스트 환경으로 전송
  - 새로운 버전의 서비스 검증
  - 성능 테스트 및 문제 분석

### egov-db 네임스페이스에 istio-injection을 활성화하지 않는 이유는 무엇인가요?

egov-db 네임스페이스에 istio-injection을 활성화하지 않는 이유는 다음과 같습니다:

- **StatefulSet 특성**: MySQL과 OpenSearch같은 상태 유지형 애플리케이션은 네트워크 지연이나 추가적인 프록시 계층에 민감할 수 있습니다. 이러한 데이터베이스들은 이미 자체적인 클러스터링과 통신 메커니즘을 가지고 있습니다.
- **성능 고려사항**: Istio 사이드카는 추가적인 리소스를 소비하며, 데이터베이스 성능에 영향을 줄 수 있습니다. 데이터베이스 워크로드는 대개 네트워크 지연에 민감하므로, 추가적인 프록시 계층은 바람직하지 않습니다.
- **보안 아키텍처**: 데이터베이스는 일반적으로 직접적인 서비스 메시 통신이 필요하지 않습니다. 데이터베이스 접근은 주로 내부 클러스터 네트워크를 통해 이루어지며, 이미 Kubernetes의 네트워크 정책으로 충분히 보호될 수 있습니다.

### Istio와 Kubernetes의 서비스 디스커버리는 어떤 관계가 있나요?

Istio는 Kubernetes의 기본 서비스 디스커버리를 확장하여 더 강력한 기능을 제공합니다.

**1. Istio의 서비스 디스커버리 동작 방식**:

- **사이드카 프록시 (Envoy)**:
  - 모든 Pod에 자동 주입
  - 서비스 간 모든 트래픽을 중개
  - 동적 서비스 디스커버리 수행

- **Istiod (Control Plane)**:
  - Kubernetes API 감시
  - 서비스/엔드포인트 변경 탐지
  - 설정 변경을 Envoy에 실시간 전파

**2. Kubernetes vs Istio 서비스 디스커버리 비교**:

Kubernetes만 사용할 때:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: egov-hello
  namespace: egov-app
spec:
  ports:
  - port: 8080
  selector:
    app: egov-hello
```

Istio를 추가로 사용할 때:
```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: egov-hello
  namespace: egov-app
spec:
  hosts:
  - egov-hello
  http:
  - route:
    - destination:
        host: egov-hello
        subset: v1
```

**3. Istio가 추가하는 기능**:

- **고급 라우팅**:
  - 버전 기반 라우팅
  - 가중치 기반 트래픽 분배
  - A/B 테스팅
  ```yaml
  spec:
    http:
    - route:
      - destination:
          host: egov-hello
          subset: v1
        weight: 90
      - destination:
          host: egov-hello
          subset: v2
        weight: 10
  ```

- **트래픽 제어**:
  - 서킷브레이커
  - 타임아웃/재시도
  - 폴트 인젝션
  ```yaml
  apiVersion: networking.istio.io/v1beta1
  kind: DestinationRule
  metadata:
    name: egov-hello
  spec:
    host: egov-hello
    trafficPolicy:
      connectionPool:
        tcp:
          maxConnections: 100
        http:
          http1MaxPendingRequests: 1
          maxRequestsPerConnection: 1
      outlierDetection:
        consecutive5xxErrors: 1
        interval: 1s
        baseEjectionTime: 3m
  ```

- **보안**:
  - mTLS 자동 설정
  - 인증/인가
  - 트래픽 암호화

**4. 실제 사용 예시**:

- **기본 서비스 디스커버리**:
```yaml
# Kubernetes Service
apiVersion: v1
kind: Service
metadata:
  name: egov-hello
  namespace: egov-app
spec:
  ports:
  - port: 8080
  selector:
    app: egov-hello

# Istio VirtualService
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: egov-hello
spec:
  hosts:
  - egov-hello
  http:
  - route:
    - destination:
        host: egov-hello
```

- **버전 기반 라우팅**:
```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: egov-hello
spec:
  hosts:
  - egov-hello
  http:
  - match:
    - headers:
        version:
          exact: "v2"
    route:
    - destination:
        host: egov-hello
        subset: v2
  - route:
    - destination:
        host: egov-hello
        subset: v1
```

**5. 모니터링 및 관찰성**:

- **Kiali**:
  - 서비스 메시 시각화
  - 트래픽 흐름 모니터링
  - 서비스 의존성 파악

- **Jaeger**:
  - 분산 트레이싱
  - 서비스 간 호출 추적
  - 지연 시간 분석

**6. 주의사항**:

- Istio 사이드카 리소스 오버헤드 고려
- 적절한 타임아웃/재시도 설정
- 서비스 메시 복잡성 관리

### Istio가 설치되어 있는지 확인하려면 어떻게 해야 하나요?

다음 명령어로 Istio의 설치 상태를 확인할 수 있습니다:

```bash
kubectl get pods -n istio-system
```

정상적으로 설치된 경우 istiod, istio-ingressgateway 등의 pod가 Running 상태로 표시됩니다.

### 특정 네임스페이스에 istio-injection이 활성화되어 있는지 확인하려면 어떻게 해야 하나요?

다음 명령어로 확인할 수 있습니다:

```bash
kubectl get namespace -L istio-injection
```

istio-injection=enabled로 표시된 네임스페이스는 사이드카 주입이 활성화된 상태입니다.

### Pod에 Istio 사이드카가 주입되었는지 확인하려면 어떻게 해야 하나요?

다음 명령어로 특정 Pod의 컨테이너 목록을 확인할 수 있습니다:

```bash
kubectl get pod [pod-name] -n [namespace] -o jsonpath='{.spec.containers[*].name}'
```

istio-proxy 컨테이너가 목록에 포함되어 있다면 사이드카가 정상적으로 주입된 상태입니다.

### Istio 사이드카 주입을 특정 Pod에서만 비활성화하려면 어떻게 해야 하나요?

Pod의 annotation에 다음을 추가하면 해당 Pod에서만 사이드카 주입이 비활성화됩니다:

```yaml
metadata:
  annotations:
    sidecar.istio.io/inject: "false"
```

### egov-app 네임스페이스의 Pod에 컨테이너가 2개씩 표시되는 이유는 무엇인가요?

egov-app 네임스페이스의 각 Pod에 2개의 컨테이너가 표시되는 것은 정상입니다. 이는 다음과 같은 구성 때문입니다:

- **메인 애플리케이션 컨테이너**: 실제 서비스를 실행하는 컨테이너
   - 예: `egov-main`, `egov-board`, `egov-login` 등

- **Istio sidecar proxy**: 서비스 메시 기능을 제공하는 컨테이너
   - 이름: `istio-proxy`
   - 역할: 트래픽 라우팅, 모니터링, 보안 등의 서비스 메시 기능 제공

### Istio Ingress Gateway에 DNS로 접속하려면 어떻게 해야 하나요?

현재 설정에서는 `localhost:32314`로만 접속 가능합니다. DNS로 접속하려면 다음 방법들을 사용할 수 있습니다:

1. **로컬 개발 환경**:
   - hosts 파일에 다음 항목 추가:
     - Linux/macOS: `/etc/hosts` 파일 수정
       ```bash
       # macOS에서는 sudo 권한 필요
       sudo vi /etc/hosts
       ```
     - Windows: `C:\Windows\System32\drivers\etc\hosts` 파일 수정
     ```
     127.0.0.1   egov-msa.example.com
     ```
   - Gateway 리소스의 hosts 설정 수정:
     ```yaml
     apiVersion: networking.istio.io/v1beta1
     kind: Gateway
     metadata:
       name: istio-ingressgateway
       namespace: istio-system
     spec:
       selector:
         istio: ingressgateway
       servers:
       - port:
           number: 80
           name: http
           protocol: HTTP
         hosts:
         - "*" # 모든 도메인에 대한 트래픽을 허용. 운영 환경에서는 보안을 위해 특정 도메인으로 제한하는 것을 권장합니다.
     ```

2. **운영 환경**:
   - 실제 도메인 구매 및 DNS A 레코드 설정
   - LoadBalancer 타입 서비스로 변경:
     ```yaml
     apiVersion: v1
     kind: Service
     metadata:
       name: istio-ingressgateway
       namespace: istio-system
     spec:
       type: LoadBalancer  # NodePort에서 변경
       selector:
         istio: ingressgateway
       ports:
         - name: http2
           port: 80
           targetPort: 8080
     ```

설정 후에는 다음과 같이 접속 가능합니다:
```bash
curl http://egov-msa.example.com/a/b/c/hello
```

주의: 실제 운영 환경에서는 HTTPS 설정을 추가하는 것을 권장합니다.

### Kubernetes Ingress와 Istio Ingress Gateway의 차이점은 무엇인가요?

#### 기본 구조와 동작 방식

**Kubernetes Ingress**:
- Kubernetes 네이티브 리소스
- Ingress Controller가 필요 (nginx, traefik 등)
- HTTP/HTTPS 트래픽만 처리
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: example-ingress
spec:
  rules:
  - host: api.example.com
    http:
      paths:
      - path: /users
        pathType: Prefix
        backend:
          service:
            name: user-service
            port:
              number: 80
```

**Istio Ingress Gateway**:
- Istio 서비스 메시의 일부
- Envoy 프록시 기반
- 다양한 프로토콜 지원 (HTTP, HTTPS, TCP, gRPC 등)
```yaml
apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
  name: example-gateway
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "api.example.com"
---
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: user-service-vs
spec:
  hosts:
  - "api.example.com"
  gateways:
  - example-gateway
  http:
  - match:
    - uri:
        prefix: /users
    route:
    - destination:
        host: user-service
        port:
          number: 80
```

#### 주요 차이점

- **트래픽 관리 기능**:
   - Kubernetes Ingress:
     - 기본적인 라우팅 규칙
     - 단순한 경로 기반 라우팅
     - SSL/TLS 종료

   - Istio Ingress Gateway:
     - 고급 트래픽 관리
     - 가중치 기반 라우팅
     - 카나리 배포
     - 트래픽 미러링
     - 서킷 브레이커
     - 타임아웃/재시도 정책

- **프로토콜 지원**:
   - Kubernetes Ingress:
     - HTTP/HTTPS만 지원

   - Istio Ingress Gateway:
     - HTTP/HTTPS
     - TCP/UDP
     - gRPC
     - WebSocket
     - MongoDB
     - MySQL

- **보안 기능**:
   - Kubernetes Ingress:
     - 기본적인 TLS 설정
     - 인증은 제한적

   - Istio Ingress Gateway:
     - mTLS (상호 TLS)
     - JWT 검증
     - RBAC
     - 상세한 인증/인가 정책
     - 요청/응답 수정

- **모니터링과 관찰성**:
   - Kubernetes Ingress:
     - 기본적인 로깅
     - 제한된 메트릭

   - Istio Ingress Gateway:
     - 상세한 트래픽 메트릭
     - 분산 추적
     - 접근 로그
     - Kiali 대시보드
     - Grafana 통합

#### 사용 시나리오

**Kubernetes Ingress 사용**:
- 간단한 웹 애플리케이션
- HTTP/HTTPS 트래픽만 처리
- 기본적인 라우팅만 필요한 경우
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: simple-fanout
spec:
  rules:
  - host: example.com
    http:
      paths:
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: api-service
            port:
              number: 80
      - path: /web
        pathType: Prefix
        backend:
          service:
            name: web-service
            port:
              number: 80
```

**Istio Ingress Gateway 사용**:
- 마이크로서비스 아키텍처
- 복잡한 라우팅 요구사항
- 고급 트래픽 관리 필요
```yaml
apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
  name: microservices-gateway
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "example.com"
---
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: complex-routing
spec:
  hosts:
  - "example.com"
  gateways:
  - microservices-gateway
  http:
  - match:
    - uri:
        prefix: /api
      headers:
        version:
          exact: "v2"
    route:
    - destination:
        host: api-service-v2
        port:
          number: 80
      weight: 90
    - destination:
        host: api-service-v1
        port:
          number: 80
      weight: 10
```

#### 본 프로젝트에서의 Istio Ingress Gateway 사용

- `k8s-deploy/manifests/istio-system/gateway.yaml` 파일에서 Istio Ingress Gateway를 정의합니다.
- `k8s-deploy/manifests/istio-system/gateway-service.yaml` 파일에서 Istio Ingress Gateway를 위한 Kubernetes Service를 정의합니다.
- `k8s-deploy/manifests/egov-app/virtual-services.yaml` 파일에서 Istio Ingress Gateway를 위한 VirtualService를 정의합니다.

#### 권장 사항

- **Kubernetes Ingress 선택 시**:
   - 단순한 HTTP 라우팅만 필요할 때
   - 가벼운 인프라를 원할 때
   - 서비스 메시가 필요없을 때

- **Istio Ingress Gateway 선택 시**:
   - 마이크로서비스 아키텍처 사용
   - 고급 트래픽 관리 필요
   - 상세한 모니터링 필요
   - mTLS 등 고급 보안 기능 필요

## 6. 운영 관리
- 스케일링 (HPA/VPA)
- 롤링 업데이트
- 헬스체크와 프로브
- 리소스 관리 (CPU/Memory)
- 장애 처리

## 7. 보안
- RBAC 설정
- ServiceAccount
- SecurityContext
- NetworkPolicy
- TLS/SSL 설정

## 8. 배포와 관리
- CI/CD 파이프라인
- GitOps
- 환경 분리
- 설정 관리
- 백업과 복구

### 환경변수는 어떻게 애플리케이션까지 전달되나요?

환경변수는 다음 3단계를 거쳐 애플리케이션에 전달됩니다:

- **Dockerfile 레벨** (기본값):
```dockerfile
ENV SERVER_PORT=8086 \
    SPRING_PROFILES_ACTIVE=docker
```

- **ConfigMap 레벨** (환경별 설정):
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: egov-hello-config
data:
  SPRING_PROFILES_ACTIVE: k8s
```

- **Deployment 레벨** (최종 설정):
```yaml
spec:
  containers:
  - name: egov-hello
    env:
    - name: SERVER_PORT
      value: "80"
    envFrom:
    - configMapRef:
        name: egov-hello-config
```

**우선순위**:
- Deployment의 env (최우선)
- ConfigMap (envFrom)
- Dockerfile의 ENV (최하위)

**Spring Boot에서의 사용**:
```yaml
server:
  port: ${SERVER_PORT:8086}
spring:
  profiles:
    active: ${SPRING_PROFILES_ACTIVE:local}
```


위 예시에서 우선순위에 따라 최종적으로 애플리케이션에 전달되는 값은:

- SERVER_PORT: "80"
  - Deployment의 env에서 직접 정의된 값 ("80")이 최우선
  - Dockerfile의 값 ("8086")은 무시됨
- SPRING_PROFILES_ACTIVE: "k8s"
  - ConfigMap에서 정의된 값 ("k8s")이 적용
  - Dockerfile의 값 ("docker")은 무시됨
  - Deployment에서는 이 값을 정의하지 않았고 따라서 ConfigMap의 값이 사용됨
  
이렇게 결정되는 이유는 우선순위 규칙 때문입니다:
- Deployment의 env가 가장 높은 우선순위
- ConfigMap의 envFrom이 중간 우선순위
- Dockerfile의 ENV가 가장 낮은 우선순위

**모범 사례**:
- 공통 설정은 Dockerfile에 정의
- 환경별 설정은 ConfigMap 사용
- 민감정보는 Secret 사용
- 런타임 설정은 Deployment에서 관리

### ConfigMap의 환경변수를 Spring Boot에서 사용할 때 envFrom과 env를 같이 사용하는 이유는 무엇인가요?

이는 Spring Boot의 속성 명명 규칙과 관련이 있습니다.

**envFrom의 동작 방식**:
```yaml
envFrom:
- configMapRef:
    name: egov-common-config
```
- ConfigMap의 키 이름이 그대로 환경변수로 전달됨
- 예: `TOKEN_ACCESS_SECRET` → `TOKEN_ACCESS_SECRET`

**개별 env 매핑의 필요성**:
```yaml
env:
- name: token.accessSecret    # Spring Boot 명명 규칙
  valueFrom:
    configMapKeyRef:
      name: egov-common-config
      key: TOKEN_ACCESS_SECRET  # ConfigMap 키 이름
```
- Spring Boot는 점(.)으로 구분된 속성 이름을 사용
- Java 코드에서 다음과 같이 참조:
  ```java
  @Value("${token.accessSecret}")
  private String accessSecret;
  ```

**장점**:
- Spring Boot 컨벤션을 따르는 일관된 코드 작성 가능
- 속성 이름의 명확한 계층 구조 유지
- IDE의 자동 완성 기능 활용 가능

**주의사항**:
- 동일한 ConfigMap 값을 두 가지 방식으로 참조하므로 관리 시 주의 필요
- 매핑 관계를 문서화하여 유지보수성 확보

### Spring Boot의 프로파일 설정은 어떻게 동작하나요?

다음 두 설정의 차이를 이해하는 것이 중요합니다:

**1. 환경변수 참조 방식**:
```yaml
spring:
  profiles:
    active: ${SPRING_PROFILES_ACTIVE:local}
```
- 환경변수 `SPRING_PROFILES_ACTIVE` 값을 사용
- 환경변수가 없으면 `local` 사용
- Kubernetes, Docker 등 다양한 환경에서 유연하게 설정 가능

**2. 고정 값 방식**:
```yaml
spring:
  profiles:
    active: local
```
- 항상 `local` 프로파일 사용
- 환경변수 무시
- 유연성이 떨어지지만 명시적인 설정 가능

**권장 사항**:
- 개발/테스트 환경: 환경변수 참조 방식 사용
- 운영 환경: Kubernetes ConfigMap을 통한 프로파일 설정
```yaml
env:
- name: SPRING_PROFILES_ACTIVE
  value: "k8s"
```

### ConfigMap의 데이터베이스 설정은 어떻게 Spring Boot에서 인식되나요?

**ConfigMap 설정**:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: egov-common-config
data:
  SPRING_DATASOURCE_DRIVER_CLASS_NAME: "com.mysql.cj.jdbc.Driver"
  SPRING_DATASOURCE_URL: "jdbc:mysql://mysql.egov-db.svc.cluster.local:3306/com"
```

Spring Boot에서는 두 가지 방식 모두 사용 가능합니다:

**1. 환경변수 직접 참조 방식**:
```yaml
spring:
  datasource:
    driver-class-name: ${SPRING_DATASOURCE_DRIVER_CLASS_NAME:com.mysql.cj.jdbc.Driver}
    url: ${SPRING_DATASOURCE_URL:jdbc:mysql://localhost:3306/com}
```

**2. 속성 참조 방식**:
```yaml
spring:
  datasource:
    driver-class-name: ${datasource.driver-class-name:com.mysql.cj.jdbc.Driver}
    url: ${datasource.url:jdbc:mysql://localhost:3306/com}
```

두 방식 모두 작동하는 이유:
- Spring Boot는 환경변수를 속성으로 자동 변환
  - `SPRING_DATASOURCE_URL` → `spring.datasource.url`
  - `SPRING_DATASOURCE_DRIVER_CLASS_NAME` → `spring.datasource.driver-class-name`
- 따라서 `${datasource.url}`로 참조해도 환경변수 값을 찾을 수 있음

**권장 사항**:
- 일관성을 위해 한 프로젝트 내에서는 동일한 방식 사용
- 팀 내 컨벤션을 정하고 문서화하여 유지보수성 확보
