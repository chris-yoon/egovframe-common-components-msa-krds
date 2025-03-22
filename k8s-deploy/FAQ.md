# 자주하는 질문

## Istio 관련 질문

### egov-db 네임스페이스에 istio-injection을 활성화하지 않는 이유는 무엇인가요?

egov-db 네임스페이스에 istio-injection을 활성화하지 않는 이유는 다음과 같습니다:

1. **StatefulSet 특성**: MySQL과 OpenSearch같은 상태 유지형 애플리케이션은 네트워크 지연이나 추가적인 프록시 계층에 민감할 수 있습니다. 이러한 데이터베이스들은 이미 자체적인 클러스터링과 통신 메커니즘을 가지고 있습니다.
2. **성능 고려사항**: Istio 사이드카는 추가적인 리소스를 소비하며, 데이터베이스 성능에 영향을 줄 수 있습니다. 데이터베이스 워크로드는 대개 네트워크 지연에 민감하므로, 추가적인 프록시 계층은 바람직하지 않습니다.
3. **보안 아키텍처**: 데이터베이스는 일반적으로 직접적인 서비스 메시 통신이 필요하지 않습니다. 데이터베이스 접근은 주로 내부 클러스터 네트워크를 통해 이루어지며, 이미 Kubernetes의 네트워크 정책으로 충분히 보호될 수 있습니다.

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

1. **메인 애플리케이션 컨테이너**: 실제 서비스를 실행하는 컨테이너
   - 예: `egov-main`, `egov-board`, `egov-login` 등

2. **Istio sidecar proxy**: 서비스 메시 기능을 제공하는 컨테이너
   - 이름: `istio-proxy`
   - 역할: 트래픽 라우팅, 모니터링, 보안 등의 서비스 메시 기능 제공

## PV/PVC 관련 질문

### 프로젝트의 PV/PVC 구성은 어떻게 되어있나요?

현재 프로젝트의 주요 PV/PVC 구성은 다음과 같습니다:

1. **egov-db 네임스페이스**:
   - MySQL: `mysql-pv-0` (1Gi)
   - OpenSearch: `opensearch-pv-0` (1Gi)

2. **egov-app 네임스페이스**:
   - EgovMobileId: `egov-mobileid-pv` (10Mi)
   - EgovSearch:
     - Config: `egov-search-config-pv` (1Mi)
     - Model: `egov-search-model-pv` (1Gi)
     - Example: `egov-search-example-pv` (1Mi)
     - Cacerts: `egov-search-cacerts-pv` (1Mi)

3. **egov-infra 네임스페이스**:
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

1. 먼저 기존 데이터를 백업합니다.
2. 관련 워크로드를 중지합니다.
3. PV/PVC를 삭제합니다.
4. YAML 파일에서 `spec.hostPath.path` 값을 수정합니다:

예시 (`k8s-deploy/manifests/egov-db/mysql-pv.yaml`):
```yaml
spec:
  hostPath:
    path: "/your/new/path/data/mysql"
```

5. 수정된 PV/PVC를 다시 생성합니다.
6. 워크로드를 재시작합니다.

### PV/PVC 용량을 변경하려면 어떻게 해야 하나요?

현재 구성에서는 PV/PVC 용량을 직접 변경할 수 없습니다. 다음 단계를 따라야 합니다:

1. 데이터 백업
2. 기존 워크로드 중지
3. 기존 PV/PVC 삭제
4. YAML 파일에서 용량 수정:
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
5. 새로운 PV/PVC 생성
6. 데이터 복원
7. 워크로드 재시작

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
