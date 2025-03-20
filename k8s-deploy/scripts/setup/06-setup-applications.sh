#!/bin/bash

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# 함수: 배포 상태 확인
check_deployment() {
    local ns=$1
    local deploy=$2
    echo -e "${YELLOW}Waiting for deployment ${deploy} in namespace ${ns}...${NC}"
    kubectl wait --for=condition=Available deployment/${deploy} -n ${ns} --timeout=30s
}

# Application 서비스 설치 (egov-app 네임스페이스)
echo -e "${YELLOW}Installing application services...${NC}"

# MySQL Secret 복사 (egov-db -> egov-app)
echo -e "${GREEN}Copying MySQL Secret from egov-db to egov-app namespace...${NC}"
kubectl get secret mysql-secret -n egov-db -o yaml | sed 's/namespace: egov-db/namespace: egov-app/' | kubectl apply -f -

# Common ConfigMap 생성
echo -e "${GREEN}Creating Common ConfigMap...${NC}"
kubectl apply -f "../../manifests/egov-app/egov-common-configmap.yaml"

# MobileId PV/PVC 생성
echo -e "${GREEN}Creating MobileId PV and PVC...${NC}"
kubectl apply -f "../../manifests/egov-app/egov-mobileid-pv.yaml"

# EgovSearch PV/PVC 생성
echo -e "${GREEN}Creating EgovSearch PV and PVC...${NC}"
kubectl apply -f "../../manifests/egov-app/egov-search-pv.yaml"

# 각 서비스 배포
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
    echo -e "${GREEN}Installing ${service}...${NC}"
    kubectl apply -f "../../manifests/egov-app/${service}-deployment.yaml"
    check_deployment "egov-app" "${service}"
done

# 상태 확인
echo -e "\n${YELLOW}Checking application services status:${NC}"
kubectl get pods,svc -n egov-app

# PV/PVC 상태 확인
echo -e "\n${YELLOW}Checking EgovMobileId PV/PVC status:${NC}"
echo -e "${GREEN}PVCs in egov-app namespace:${NC}"
kubectl get pvc -n egov-app | grep mobileid
echo -e "\n${GREEN}PVs:${NC}"
kubectl get pv | grep mobileid

echo -e "\n${YELLOW}Checking EgovSearch PV/PVC status:${NC}"
echo -e "${GREEN}PVCs in egov-app namespace:${NC}"
kubectl get pvc -n egov-app | grep search
echo -e "\n${GREEN}PVs:${NC}"
kubectl get pv | grep search

echo -e "\n${GREEN}Application services installation completed successfully!${NC}"
