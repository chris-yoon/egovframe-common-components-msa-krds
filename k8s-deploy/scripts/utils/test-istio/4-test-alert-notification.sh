#!/bin/bash

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 함수: 테스트 시작 전 상태 확인
check_prerequisites() {
    echo -e "${YELLOW}Checking prerequisites...${NC}"
    
    # AlertManager 상태 확인
    if ! kubectl get pods -n egov-monitoring -l app=alertmanager | grep -q "Running"; then
        echo -e "${RED}AlertManager is not running${NC}"
        return 1
    fi
    
    # Prometheus 상태 확인
    if ! kubectl get pods -n egov-monitoring -l app.kubernetes.io/name=prometheus | grep -q "Running"; then
        echo -e "${RED}Prometheus is not running${NC}"
        return 1
    fi
    
    echo -e "${GREEN}All prerequisites are met${NC}"
    return 0
}

# 함수: egov-hello 배포 삭제 (Deployment만 삭제, Service는 유지)
# 목적: egov-hello-error만 남겨 둘 수 있도록하여 의도적으로 에러를 발생시킬 수 있도록 하기 위함
delete_deployment_egov_hello() {
    echo -e "${YELLOW}Deleting egov-hello deployment...${NC}"
    kubectl delete deployment egov-hello -n egov-app || true
    echo -e "${GREEN}egov-hello deployment deleted${NC}"
    sleep 5
}

# 함수: destination rules 삭제
# 목적: Circuit Breaker를 비활성화
delete_destination_rules() {
    echo -e "${YELLOW}Deleting destination rules...${NC}"
    kubectl delete -f ../../../manifests/egov-app/destination-rules.yaml || true
    echo -e "${GREEN}Destination rules deleted${NC}"
    sleep 5
}

# 함수: 에러 요청 생성
# 목적: egov-hello-error를 통해 에러를 발생시킴
generate_error_requests() {
    local url="http://localhost:32314/a/b/c/hello"
    local count=20  # 충분한 에러를 발생시키기 위해 15회로 설정
    local errors=0
    
    echo -e "\n${YELLOW}Generating $count requests to trigger circuit breaker...${NC}"
    
    for i in $(seq 1 $count); do
        echo -e "\n${YELLOW}Request $i of $count${NC}"
        response=$(curl -s -w "\n%{http_code}" $url)
        http_code=$(echo "$response" | tail -n1)
        content=$(echo "$response" | sed \$d)
        
        if [[ "$http_code" =~ ^5 ]]; then
            ((errors++))
            echo -e "${RED}Error response (HTTP $http_code)${NC}"
            echo -e "${RED}Response: $content${NC}"
        else
            echo -e "${GREEN}Success response (HTTP $http_code)${NC}"
            echo -e "${GREEN}Response: $content${NC}"
        fi
        sleep 0.5  # 2초 간격으로 요청
    done
    
    echo -e "\n${YELLOW}Error generation summary:${NC}"
    echo -e "Total requests: $count"
    echo -e "Error responses: ${RED}$errors${NC}"
}

# 함수: 알림 상태 확인
check_alerts() {
    echo -e "${YELLOW}Checking alerts in AlertManager...${NC}"
    # AlertManager API를 통해 알림 상태 확인
    curl -s http://localhost:9093/api/v1/alerts | jq .
}

# AlertManager 연결 테스트 함수 추가
check_alertmanager_connection() {
    echo -e "${YELLOW}Testing AlertManager connection...${NC}"
    response=$(curl -s -w "\n%{http_code}" http://localhost:9093/-/healthy)
    http_code=$(echo "$response" | tail -n1)
    
    if [ "$http_code" == "200" ]; then
        echo -e "${GREEN}AlertManager is healthy${NC}"
        return 0
    else
        echo -e "${RED}AlertManager connection failed${NC}"
        return 1
    fi
}

# 메인 스크립트 시작
echo -e "${GREEN}Starting Alert Notification Test...${NC}"

# 1. 사전 조건 확인
echo -e "\n${GREEN}1. Checking Prerequisites${NC}"
check_prerequisites || exit 1

# 2. 기존 포트포워딩 정리
echo -e "\n${GREEN}2. Cleaning up existing port-forwards${NC}"
pkill -f "port-forward.*alertmanager" || true
sleep 2

# 3. 필요한 포트포워딩 설정
echo -e "\n${GREEN}3. Setting up port-forwards${NC}"
kubectl port-forward svc/alertmanager -n egov-monitoring 9093:9093 &
sleep 5
check_alertmanager_connection || exit 1

# 4. Destination Rules 삭제
echo -e "\n${GREEN}4. Removing Destination Rules${NC}"
delete_destination_rules

# 5. egov-hello 배포 삭제
echo -e "\n${GREEN}5. Removing egov-hello deployment${NC}"
delete_deployment_egov_hello

# 6. 현재 알림 상태 확인
echo -e "\n${GREEN}6. Checking current alert status${NC}"
check_alerts

# 7. 에러 요청 생성 (더 많은 요청 생성)
echo -e "\n${GREEN}7. Generating error requests${NC}"
for i in {1..3}; do
    generate_error_requests
    sleep 1
done

# 8. 알림 발생 대기
echo -e "\n${GREEN}8. Waiting for alerts to be generated...${NC}"
echo -e "${YELLOW}   - Prometheus rule evaluation: ~10s${NC}"
echo -e "${YELLOW}   - AlertManager grouping: ~10s${NC}"
echo -e "${YELLOW}   - Alert notification delay: ~10s${NC}"
sleep 30

# 9. 알림 상태 재확인
echo -e "\n${GREEN}9. Checking final alert status${NC}"
check_alerts

# 10. 정리
echo -e "\n${GREEN}10. Cleanup${NC}"
pkill -f "port-forward.*alertmanager" || true

echo -e "\n${GREEN}Alert Notification Test Complete!${NC}"
echo -e "${YELLOW}Please check your Slack channel '#egovalertmanager' for notifications${NC}"
echo -e "${YELLOW}To check alerts in AlertManager UI:${NC}"
echo -e "${YELLOW}1. Run: kubectl port-forward svc/alertmanager -n egov-monitoring 9093:9093${NC}"
echo -e "${YELLOW}2. Open: http://localhost:9093/#/alerts${NC}"

exit 0
