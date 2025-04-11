#!/bin/bash

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 함수: 서비스 상태 확인
check_service() {
    local namespace=$1
    local service=$2
    echo -e "${YELLOW}Checking service $service in namespace $namespace...${NC}"
    kubectl get svc $service -n $namespace
}

# 함수: 파드 상태 확인
check_pods() {
    local namespace=$1
    local label=$2
    echo -e "${YELLOW}Checking pods with label $label in namespace $namespace...${NC}"
    kubectl get pods -n $namespace -l $label
}

# 함수: HTTP 요청 테스트
test_endpoint() {
    local url=$1
    local attempts=${2:-1}
    
    echo -e "${YELLOW}Testing endpoint: $url${NC}"
    for i in $(seq 1 $attempts); do
        echo -e "${YELLOW}Request $i:${NC}"
        curl -v $url
        echo
    done
}

# 메인 테스트 시작
echo -e "${GREEN}Starting Load Balancing and Port Forward Test...${NC}"

# 1. Istio Ingress Gateway 상태 확인
echo -e "\n${GREEN}1. Checking Istio Ingress Gateway Status${NC}"
check_service "istio-system" "istio-ingressgateway"

# 2. Virtual Service 상태 확인
echo -e "\n${GREEN}2. Checking Virtual Service Status${NC}"
kubectl get virtualservice -n egov-app

# 3. egov-hello 서비스 및 파드 상태 확인
echo -e "\n${GREEN}3. Checking egov-hello Service and Pods${NC}"
check_service "egov-app" "egov-hello"
check_pods "egov-app" "app=egov-hello"

# 4. 라우팅 설정 확인
echo -e "\n${GREEN}4. Checking Routing Configuration${NC}"
istioctl proxy-config routes deploy/istio-ingressgateway -n istio-system

# 5. 내부 서비스 테스트
echo -e "\n${GREEN}5. Testing Internal Service Access${NC}"
kubectl run -i --rm --restart=Never curl-test --image=curlimages/curl -- curl http://egov-hello.egov-app/a/b/c/hello

# 6. 외부 접근 테스트 (다양한 포트)
echo -e "\n${GREEN}6. Testing External Access${NC}"

# 80 포트 테스트
echo -e "\n${YELLOW}Testing port 80:${NC}"
test_endpoint "http://localhost:80/a/b/c/hello" 3

# NodePort 테스트
echo -e "\n${YELLOW}Testing NodePort 32314:${NC}"
test_endpoint "http://localhost:32314/a/b/c/hello" 3

# 결과 요약
echo -e "\n${GREEN}Test Summary:${NC}"
echo -e "1. Istio Ingress Gateway: NodePort HTTP(80:$(kubectl get svc istio-ingressgateway -n istio-system -o jsonpath='{.spec.ports[?(@.port==80)].nodePort}'))"
echo -e "2. Virtual Services: $(kubectl get virtualservice -n egov-app -o jsonpath='{.items[*].metadata.name}')"
echo -e "3. egov-hello Pods: $(kubectl get pods -n egov-app -l app=egov-hello -o jsonpath='{.items[*].status.phase}' | tr ' ' ',')"

exit 0