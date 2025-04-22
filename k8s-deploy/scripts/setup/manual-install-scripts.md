# 전자정부 표준프레임워크 MSA 공통컴포넌트 Kubernetes 수동 배포 스크립트

> 각 명령어는 **순서대로** 실행해야 합니다.  
> 각 단계에서 오류가 발생하면 다음 단계로 진행하기 전에 해결해야 합니다.  
> `kubectl wait` 명령어는 리소스가 준비될 때까지 대기합니다.  
> 실제 환경에 따라 일부 경로나 설정을 조정해야 할 수 있습니다.

## 1. Istio 설치

```bash
cd /{프로젝트 경로}/k8s-deploy/bin
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.25.0 TARGET_ARCH=arm64 sh -
cd istio-1.25.0
export PATH=$PWD/bin:$PATH
istioctl install --set profile=default -y
kubectl create namespace egov-app
kubectl label namespace egov-app istio-injection=enabled
kubectl apply -f ../../manifests/egov-istio/config.yaml
kubectl apply -f ../../manifests/egov-istio/telemetry.yaml
kubectl wait --for=condition=Ready pods --all -n istio-system --timeout=300s
```

## 2. 전역 설정 및 네임스페이스 생성

```bash
# 전역 ConfigMap 생성 (hostPath 경로)
kubectl apply -f ../../manifests/common/egov-global-configmap.yaml

# 네임스페이스 생성
kubectl create namespace egov-monitoring
kubectl create namespace egov-db
kubectl create namespace egov-infra
kubectl label namespace egov-infra istio-injection=enabled
kubectl create namespace egov-cicd

# ConfigMap 상태 확인
kubectl get configmap egov-global-config
kubectl get configmap egov-common-config

# ConfigMap에서 값 추출해서 환경 변수로 설정
export DATA_BASE_PATH=$(kubectl get configmap egov-global-config -o jsonpath='{.data.data_base_path}')

# 공통적으로 사용할 ConfigMap 생성
kubectl apply -f ../../manifests/common/egov-common-configmap.yaml -n egov-app
kubectl apply -f ../../manifests/common/egov-common-configmap.yaml -n egov-infra
```

## 3. 모니터링 설치

### cert-manager 설치
```bash
# 기존 cert-manager 설치 제거
kubectl delete -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.2/cert-manager.yaml --ignore-not-found
sleep 30

# cert-manager webhook configuration 임시 비활성화
kubectl delete validatingwebhookconfiguration cert-manager-webhook --ignore-not-found
kubectl delete mutatingwebhookconfiguration cert-manager-webhook --ignore-not-found
sleep 10

# cert-manager 재설치
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.2/cert-manager.yaml

# cert-manager pods가 완전히 준비될 때까지 대기
kubectl wait --for=condition=Ready pods -l app=cert-manager -n cert-manager --timeout=300s
kubectl wait --for=condition=Ready pods -l app=cainjector -n cert-manager --timeout=300s
kubectl wait --for=condition=Ready pods -l app=webhook -n cert-manager --timeout=300s
# 또는
kubectl wait --for=condition=Ready pods --all -n cert-manager --timeout=300s

# webhook이 완전히 준비될 때까지 추가 대기
sleep 90
```

### OpenTelemetry Operator 설치
```bash
# 기존 OpenTelemetry Operator 제거
kubectl delete -f https://github.com/open-telemetry/opentelemetry-operator/releases/download/v0.120.0/opentelemetry-operator.yaml --ignore-not-found
sleep 30

# OpenTelemetry Operator 재설치
kubectl apply -f https://github.com/open-telemetry/opentelemetry-operator/releases/download/v0.120.0/opentelemetry-operator.yaml

# OpenTelemetry Operator가 준비될 때까지 대기
kubectl wait --for=condition=Ready pods -l control-plane=controller-manager -n opentelemetry-operator-system --timeout=300s
```

### 모니터링 컴포넌트 설치
```bash
cd ../../manifests/egov-monitoring
kubectl apply -f alertmanager-config.yaml
kubectl apply -f circuit-breaker-alerts-configmap.yaml
kubectl apply -f prometheus.yaml
kubectl apply -f grafana.yaml
kubectl apply -f kiali.yaml
kubectl apply -f jaeger.yaml
kubectl apply -f loki.yaml
kubectl apply -f alertmanager.yaml
kubectl apply -f opentelemetry-collector.yaml
kubectl wait --for=condition=Ready pods --all -n egov-monitoring --timeout=300s
```

## 4. MySQL 설치

```bash
cd ../egov-db
envsubst '${DATA_BASE_PATH}' < mysql-pv.yaml | kubectl apply -f -
kubectl apply -f mysql-secret.yaml
kubectl apply -f mysql-statefulset.yaml
kubectl apply -f mysql-service.yaml
kubectl rollout status statefulset/mysql -n egov-db --timeout=300s
```

## 5. OpenSearch 설치

```bash
envsubst '${DATA_BASE_PATH}' < opensearch-pv.yaml | kubectl apply -f -
kubectl apply -f opensearch-configmap.yaml
kubectl apply -f opensearch-secret.yaml
kubectl apply -f opensearch-certs-secret.yaml
kubectl apply -f opensearch-statefulset.yaml
kubectl apply -f opensearch-service.yaml
kubectl apply -f opensearch-dashboard-deployment.yaml
kubectl rollout status statefulset/opensearch -n egov-db --timeout=300s
```

## 6. 인프라 서비스 설치

```bash
cd ../egov-infra
kubectl apply -f rabbitmq-configmap.yaml
envsubst '${DATA_BASE_PATH}' < rabbitmq-pv.yaml | kubectl apply -f -
kubectl apply -f rabbitmq-deployment.yaml
kubectl apply -f rabbitmq-service.yaml
kubectl rollout status deployment/rabbitmq -n egov-infra --timeout=300s
kubectl apply -f gatewayserver-deployment.yaml
kubectl rollout status deployment/gateway-server -n egov-infra --timeout=300s
```

## 7. 애플리케이션 서비스 설치

### MySQL Secret 복사 (egov-db -> egov-app)
```bash
cd ../egov-app
kubectl get secret mysql-secret -n egov-db -o yaml | sed 's/namespace: egov-db/namespace: egov-app/' | kubectl apply -f -
export MOBILEID_CONFIG_PATH=$(kubectl get configmap egov-global-config -o jsonpath='{.data.mobileid_config_path}')
envsubst '${MOBILEID_CONFIG_PATH}' < egov-mobileid-pv.yaml | kubectl apply -f -
export SEARCH_BASE_PATH=$(kubectl get configmap egov-global-config -o jsonpath='{.data.search_base_path}')
envsubst '${SEARCH_BASE_PATH}' < egov-search-pv.yaml | kubectl apply -f -
```

### 각 서비스 배포
```bash
kubectl apply -f egov-hello-deployment.yaml
kubectl apply -f egov-main-deployment.yaml
kubectl apply -f egov-board-deployment.yaml
kubectl apply -f egov-login-deployment.yaml
kubectl apply -f egov-author-deployment.yaml
kubectl apply -f egov-mobileid-deployment.yaml
kubectl apply -f egov-questionnaire-deployment.yaml
kubectl apply -f egov-cmmncode-deployment.yaml
kubectl apply -f egov-search-deployment.yaml
```

## 8. CICD 설치

```bash
cd ../egov-cicd
kubectl apply -f jenkins-rbac.yaml
export DATA_BASE_PATH=$(kubectl get configmap egov-global-config -o jsonpath='{.data.data_base_path}')
envsubst '${DATA_BASE_PATH}' < jenkins-statefulset.yaml | kubectl apply -f -
envsubst '${DATA_BASE_PATH}' < gitlab-statefulset.yaml | kubectl apply -f -
envsubst '${DATA_BASE_PATH}' < sonarqube-deployment.yaml | kubectl apply -f -
envsubst '${DATA_BASE_PATH}' < nexus-statefulset.yaml | kubectl apply -f -
kubectl apply -f cicd-services.yaml
kubectl rollout status statefulset/jenkins -n egov-cicd --timeout=300s
```

## 9. PostgreSQL 설치

```bash
cd ../egov-db
kubectl apply -f postgresql-secret.yaml
envsubst '${DATA_BASE_PATH}' < postgresql-pv.yaml | kubectl apply -f -
kubectl apply -f postgresql-statefulset.yaml
kubectl apply -f postgresql-service.yaml
kubectl rollout status statefulset/postgresql -n egov-db --timeout=300s
```

## 설치 상태 확인

```bash
kubectl get pods --all-namespaces
```

## 접근 정보 확인

```bash
cd ../../scripts/setup
./09-show-access-info.sh
```
