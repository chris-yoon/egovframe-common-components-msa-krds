# MSA 공통컴포넌트 Istio 테스트 가이드

## 1. 개요

이 문서는 전자정부 MSA 공통컴포넌트의 Istio 서비스 메시 기능을 테스트하는 방법을 설명합니다.

### 1.1 테스트 환경
- Kubernetes 클러스터
- Istio 1.25.0
- egov-hello 서비스 (테스트용 샘플 서비스)

### 1.2 테스트 시나리오
1. 로드밸런싱
2. 서킷브레이커
3. 트래픽 관리

## 2. 사전 준비

### 2.1 Istio 설치 확인
```bash
kubectl get pods -n istio-system
```

예상 출력:
```
NAME                                    READY   STATUS    RESTARTS   AGE
istio-ingressgateway-f45dd4788-2npn8   1/1     Running   0          24h
istiod-64989f484c-48r9z                1/1     Running   0          24h
```

### 2.2 테스트 스크립트 준비
```bash
cd k8s-deploy/scripts/utils/test-istio
chmod +x *.sh
```

## 3. 로드밸런싱 테스트

### 3.1 테스트 설정
로드밸런싱 테스트는 다음 구성요소를 사용합니다:

1. Gateway Service (`manifests/istio-system/gateway-service.yaml`)
   - Istio Ingress Gateway를 위한 Kubernetes Service 정의
   - NodePort 타입으로 외부 접근 허용 (포트 32314)
   - HTTP/2 프로토콜 지원
   ```yaml
   apiVersion: v1
   kind: Service
   metadata:
     name: istio-ingressgateway
     namespace: istio-system
   spec:
     type: NodePort
     selector:
       istio: ingressgateway
     ports:
       - name: http2
         port: 80
         targetPort: 8080
         nodePort: 32314
   ```

2. Virtual Service (`manifests/egov-app/virtual-services.yaml`)
   - 트래픽 라우팅 규칙 정의
   - URI 기반 라우팅 (/a/b/c/hello)
   - 게이트웨이 연결 설정
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

3. Destination Rule (`manifests/egov-app/destination-rules.yaml`)
   - 로드밸런싱 정책 설정
   - Circuit Breaker 설정
   - 트래픽 정책 정의
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
         simple: ROUND_ROBIN    # 라운드 로빈 방식의 로드밸런싱
       outlierDetection:        # Circuit Breaking 설정
         interval: 1s           # 장애 감지 주기
         consecutive5xxErrors: 3 # 연속 오류 허용 횟수
         baseEjectionTime: 30s  # 서비스 제외 시간
         maxEjectionPercent: 100 # 최대 제외 비율
   ```

이러한 구성요소들이 함께 작동하여:
- 외부에서 서비스 접근 가능 (Gateway Service)
- 트래픽을 적절한 서비스로 라우팅 (Virtual Service)
- 부하 분산 및 장애 대응 (Destination Rule)

### 3.2 테스트 실행
```bash
./1-test-loadbalancing.sh
```

### 3.3 테스트 시나리오
1. Gateway Service 설정 적용
2. Istio Ingress Gateway 상태 확인
3. Virtual Service 상태 확인
4. egov-hello 서비스 및 파드 상태 확인
5. 라우팅 설정 확인

### 3.4 결과 확인
- 요청이 여러 파드에 균등하게 분산되는지 확인
- 응답 시간과 성공률 모니터링

## 4. 서킷브레이커 테스트

### 4.1 테스트 설정
서킷브레이커 테스트는 다음 구성요소를 사용합니다:
- EgovHello Error Deployment (`manifests/egov-app/egov-hello-error-deployment.yaml`)
- Destination Rule with Circuit Breaker (`manifests/egov-app/destination-rules.yaml`)

### 4.2 테스트 실행
```bash
./2-test-circuitbreaking.sh
```

### 4.3 테스트 시나리오
1. EgovHello Error Deployment 적용
2. Destination Rule 적용
3. 초기 상태 테스트 (12회 요청) - 성공과 실패가 혼합되어야 함. 정상 POD 2개, Error POD 1개, 에러율 약 33% 
4. Circuit Breaker 동작 테스트 (빠른 요청 20회) - Circuit 이 Open 되어 대부분 성공해야 함
5. Circuit 다시 Closed 상태 확인 (30초 후 12회 요청) - 다시 Circuit 이 Closed 되어 성공과 실패가 혼합되어야 함
6. Gateway Server를 통한 테스트 (30초 후 12회 요청) - Gateway Server의 Circuit Breaker 동작 확인

### 4.4 Gateway Server 테스트
Gateway Server를 통한 테스트는 Istio의 Circuit Breaker가 Gateway Server의 트래픽에도 적용되는지 확인하는 단계입니다.

#### 4.4.1 Circuit Breaker 구성
Gateway Server의 요청도 동일한 Istio Destination Rule의 영향을 받습니다:

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

이 설정은 Gateway Server -> EgovHello 서비스 간의 통신에도 동일하게 적용됩니다.

#### 4.4.2 테스트 실행 및 결과 분석
```bash
# Gateway Server 엔드포인트 테스트
for i in {1..20}; do
    echo "Request $i:"
    curl -s http://localhost:9000/a/b/c/hello
    echo
    sleep 1
done
```

예상되는 결과:
1. Gateway Server를 통한 요청도 Istio Circuit Breaker의 보호를 받음
2. Error POD로 인한 오류 발생 시 해당 POD가 Circuit Breaker에 의해 제외됨 (연속 오류 3회 이후 30초 동안 제외)
3. 정상 POD들로만 트래픽이 전달되어 안정적인 서비스 제공

#### 4.4.3 모니터링 및 분석
Istio의 Circuit Breaker 동작을 다음 명령어로 확인할 수 있습니다:
```bash
# Circuit Breaker 상태 확인
kubectl get destinationrule -n egov-app egov-hello -o yaml

# Envoy 설정 확인
istioctl proxy-config cluster deploy/gateway-server -n egov-infra

# 서비스 매쉬 시각화 (Kiali)
kubectl port-forward svc/kiali -n istio-system 20001:20001
```

### 4.5 결과 확인
```bash
# Istio Proxy 로그 확인 (Gateway Server)
kubectl logs -l app=gateway-server -c istio-proxy -n egov-infra

# Istio Proxy 로그 확인 (EgovHello)
kubectl logs -l app=egov-hello -c istio-proxy -n egov-app

# 애플리케이션 로그 확인
kubectl logs -l app=egov-hello -c egov-hello -n egov-app
```

## 5. 트래픽 관리

### 5.1 가중치 기반 라우팅
Virtual Service에서 가중치 설정:
```yaml
apiVersion: networking.istio.io/v1alpha3
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
        subset: v1
      weight: 80
    - destination:
        host: egov-hello
        subset: v2
      weight: 20
```

### 5.2 Fault Injection
에러 주입 테스트:
```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: egov-hello
spec:
  hosts:
  - egov-hello
  http:
  - fault:
      delay:
        percentage:
          value: 100
        fixedDelay: 5s
    route:
    - destination:
        host: egov-hello
```

## 6. 모니터링

### 6.1 Kiali 대시보드
```bash
kubectl port-forward svc/kiali -n istio-system 20001:20001
```
접속: http://localhost:20001

### 6.2 Grafana 대시보드
```bash
kubectl port-forward svc/grafana -n istio-system 3000:3000
```
접속: http://localhost:3000

### 6.3 Jaeger 추적
```bash
kubectl port-forward svc/jaeger-query -n istio-system 16686:16686
```
접속: http://localhost:16686

## 7. 문제 해결

### 7.1 일반적인 문제
1. Gateway Service 연결 실패
   ```bash
   kubectl get svc istio-ingressgateway -n istio-system
   kubectl logs -l app=istio-ingressgateway -n istio-system
   ```

2. Virtual Service 설정 확인
   ```bash
   istioctl analyze
   kubectl get virtualservice -n egov-app
   ```

3. Circuit Breaker 상태 확인
   ```bash
   kubectl get destinationrule -n egov-app
   istioctl proxy-config cluster deploy/egov-hello -n egov-app
   ```

### 7.2 로그 확인
```bash
# Istio Proxy 로그
kubectl logs <pod-name> -c istio-proxy -n egov-app

# 애플리케이션 로그
kubectl logs <pod-name> -c egov-hello -n egov-app
```

## 8. 참고 자료

- [Istio Documentation](https://istio.io/latest/docs/)
- [Istio Traffic Management](https://istio.io/latest/docs/concepts/traffic-management/)
- [Istio Circuit Breaking](https://istio.io/latest/docs/tasks/traffic-management/circuit-breaking/)
- [Istio Fault Injection](https://istio.io/latest/docs/tasks/traffic-management/fault-injection/)
