#!/bin/bash
# 이 스크립트는 실행하지 않습니다. Istio 기능 테스트를 위한 수동 가이드로 사용하세요.

echo "============================================================"
echo "전자정부 표준프레임워크 MSA 공통컴포넌트 Istio 테스트 가이드"
echo "============================================================"

echo "1. 로드밸런싱 테스트"
echo "----------------------------------------"
echo "# Gateway 및 라우팅 설정 적용"
echo "kubectl apply -f ../../../manifests/istio-system/gateway.yaml"
echo "kubectl apply -f ../../../manifests/istio-system/gateway-service.yaml"
echo "kubectl apply -f ../../../manifests/egov-app/virtual-services.yaml"
echo "kubectl apply -f ../../../manifests/egov-app/destination-rules.yaml"

echo -e "\n# 상태 확인"
echo "kubectl get svc istio-ingressgateway -n istio-system"
echo "kubectl get virtualservice -n egov-app"
echo "kubectl get pods -n egov-app -l app=egov-hello"

echo -e "\n# 라우팅 설정 확인"
echo "istioctl proxy-config routes deploy/istio-ingressgateway -n istio-system"

echo -e "\n# 내부 서비스 테스트"
echo "kubectl run -i --rm --restart=Never curl-test --image=curlimages/curl -- curl http://egov-hello.egov-app/a/b/c/hello"

echo -e "\n# 외부 접근 테스트"
echo -e "\n# Gateway Server로 테스트"
echo "curl -v http://localhost:9000/a/b/c/hello"
echo -e "\n# Istio Ingress Gateway NodePort 테스트"
echo "curl -v http://localhost:32314/a/b/c/hello"

echo -e "\n# 로드밸런싱 테스트"
echo -e "\n위 URL을 여러 번 호출하여 로드밸런싱이 제대로 작동하는지 확인하세요."
echo -e "\nGrafana > Explorer > Loki 로그를 확인하세요. 검색조건은 {job="EgovHello",level="INFO"} 입니다."
echo -e "\nTraceID로 Jaeger를 통해 트레이싱을 확인하세요. net.sock.host.addr 값이 ROUND_ROBIN 방식으로 균등하게 분배되는지 확인하세요."

echo -e "\n2. 서킷브레이커 테스트"
echo "----------------------------------------"
echo "# egov-hello Deployment 배포"
echo "kubectl apply -f ../../../manifests/egov-app/egov-hello-deployment.yaml"
echo "kubectl wait --for=condition=Ready pods -l app=egov-hello -n egov-app --timeout=300s"

echo -e "\n# Error Deployment 배포"
echo "kubectl apply -f ../../../manifests/egov-app/egov-hello-error-deployment.yaml"
echo "kubectl wait --for=condition=Ready pods -l 'app=egov-hello,variant=error' -n egov-app --timeout=300s"

echo -e "\n# Virtual Service 적용"
echo "kubectl apply -f ../../../manifests/egov-app/virtual-services.yaml"

echo -e "\n# Destination Rule 적용"
echo "kubectl apply -f ../../../manifests/egov-app/destination-rules.yaml"

echo -e "\n# Gateway Service 설정"
echo "kubectl apply -f ../../../manifests/istio-system/gateway-service.yaml"

echo -e "\n# Circuit Breaker 동작 테스트"
echo -e "\n# 오류가 발생하다가 Circuit이 Open 되고 Outlier가 제거된 후 다시 정상적인 응답이 오는지 확인하세요."
echo "for i in {1..20}; do 
    echo "Request $i:"
    curl -s http://localhost:32314/a/b/c/hello
    echo
    sleep 0.5
done"

echo -e "\n3. 알림 테스트"
echo "----------------------------------------"
echo "# AlertManager 설정 확인"
echo "kubectl get pods -n egov-monitoring -l app=alertmanager"

echo -e "\n# Circuit Breaker 알림 규칙 적용"
echo "kubectl apply -f ../../../manifests/egov-monitoring/circuit-breaker-alerts-configmap.yaml"
echo "kubectl rollout restart deployment prometheus -n egov-monitoring"
echo "kubectl rollout status deployment prometheus -n egov-monitoring --timeout=300s"

echo -e "\n# AlertManager 설정 적용"
echo "kubectl apply -f ../../../manifests/egov-monitoring/alertmanager-config.yaml"
echo "kubectl apply -f ../../../manifests/egov-monitoring/alertmanager.yaml"
echo "kubectl rollout status deployment alertmanager -n egov-monitoring --timeout=300s"

echo -e "\n# AlertManager 포트포워딩"
echo "kubectl port-forward svc/alertmanager -n egov-monitoring 9093:9093"

echo -e "\n# AlertManager 연결 테스트"
echo "curl -s http://localhost:9093/-/healthy"

echo -e "\n4. 알림 통지 테스트"
echo "----------------------------------------"
echo "# 사전 조건 확인"
echo "kubectl get pods -n egov-monitoring -l app=alertmanager"
echo "kubectl get pods -n egov-monitoring -l app.kubernetes.io/name=prometheus"

echo -e "\n# egov-hello Deployment 삭제"
echo "kubectl delete deployment egov-hello -n egov-app"

echo -e "\n# Destination Rules 삭제"
echo "kubectl delete -f ../../../manifests/egov-app/destination-rules.yaml"

echo -e "\n# AlertManager 포트포워딩"
echo "kubectl port-forward svc/alertmanager -n egov-monitoring 9093:9093"

echo -e "\n테스트 결과 확인 방법:"
echo "1. AlertManager UI 확인"
echo "   - URL: http://localhost:9093/#/alerts"

echo "2. Slack 알림 확인"
echo "   - 채널: #egovalertmanager"

echo "3. Alerts 가 확인되지 않을 경우 Alert 조건이 충족되었는지 Prometheus를 통해 확인하세요."
echo "   - URL: http://localhost:30004"
echo "   - Expression: sum(increase(istio_requests_total{
            response_code=~\"5.*\",
            destination_service=\"egov-hello.egov-app.svc.cluster.local\"
          }[5m])) by (destination_service) > 0"

echo -e "\n주의사항:"
echo "1. 각 명령어는 순서대로 실행해야 합니다."
echo "2. 포트포워딩은 별도의 터미널에서 실행하세요."
echo "3. 테스트 중 오류가 발생하면 다음 단계로 진행하기 전에 해결하세요."
echo "4. AlertManager와 Prometheus가 정상 작동하는지 확인하세요."

echo -e "\n테스트 정리:"
echo "# 포트포워딩 프로세스 종료"
echo "pkill -f \"port-forward.*alertmanager\""

echo "# 테스트용 Deployment 정리"
echo "kubectl delete deployment egov-hello-error -n egov-app"

echo -e "\n모니터링 접근 정보:"
echo "- Kiali:        http://localhost:30001"
echo "- Grafana:      http://localhost:30002"
echo "- Jaeger:       http://localhost:30003"
echo "- Prometheus:   http://localhost:30004"
echo "- AlertManager: http://localhost:9093 (포트포워딩 필요)"
