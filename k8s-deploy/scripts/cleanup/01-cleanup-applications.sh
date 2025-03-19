#!/bin/bash

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Application 서비스 제거 (egov-app 네임스페이스)
echo -e "${YELLOW}Removing application services...${NC}"

# 각 서비스 제거
SERVICES=(
    "egov-main"
    "egov-board"
    "egov-login"
    "egov-author"
    "egov-mobileid"
    "egov-questionnaire"
    "egov-cmmncode"
    "egov-search"
)

for service in "${SERVICES[@]}"; do
    echo -e "${GREEN}Removing ${service}...${NC}"
    kubectl delete -f "../../manifests/egov-app/${service}-deployment.yaml" 2>/dev/null || true
done

# ConfigMap 제거
echo -e "${GREEN}Removing ConfigMaps in egov-app namespace...${NC}"
kubectl delete configmap -n egov-app --all

# MySQL Secret 제거
echo -e "${GREEN}Removing MySQL Secret in egov-app namespace...${NC}"
kubectl delete secret mysql-secret -n egov-app 2>/dev/null || true

# 리소스 제거 완료 대기
echo -e "\n${YELLOW}Waiting for resources to be terminated...${NC}"
echo -e "${YELLOW}Waiting for egov-app resources...${NC}"
kubectl wait --for=delete pods --all -n egov-app --timeout=60s 2>/dev/null || true

# 최종 상태 확인
echo -e "\n${YELLOW}Checking remaining resources in egov-app:${NC}"
kubectl get all -n egov-app

# ConfigMap 상태 확인
echo -e "\n${YELLOW}Checking remaining ConfigMaps in egov-app:${NC}"
kubectl get configmap -n egov-app

echo -e "\n${GREEN}Application cleanup completed!${NC}"
