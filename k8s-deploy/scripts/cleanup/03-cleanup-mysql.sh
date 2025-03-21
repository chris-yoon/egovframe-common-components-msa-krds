#!/bin/bash

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# MySQL 관련 리소스 제거
echo -e "${YELLOW}Removing MySQL resources...${NC}"

echo -e "${GREEN}Removing MySQL Service...${NC}"
kubectl delete -f ../../manifests/egov-db/mysql-service.yaml 2>/dev/null || true

echo -e "${GREEN}Removing MySQL StatefulSet...${NC}"
kubectl delete -f ../../manifests/egov-db/mysql-statefulset.yaml 2>/dev/null || true

echo -e "${GREEN}Removing MySQL Secret...${NC}"
kubectl delete -f ../../manifests/egov-db/mysql-secret.yaml 2>/dev/null || true

echo -e "${GREEN}Removing MySQL PV and PVC...${NC}"
kubectl delete pvc data-mysql-0 -n egov-db --force --grace-period=0 2>/dev/null || true
kubectl delete pv mysql-pv-0 --force --grace-period=0 2>/dev/null || true

# 리소스 제거 완료 대기
echo -e "\n${YELLOW}Waiting for MySQL resources to be terminated...${NC}"
kubectl wait --for=delete pods -l app=mysql -n egov-db --timeout=60s 2>/dev/null || true

# 최종 상태 확인
echo -e "\n${YELLOW}Checking remaining MySQL resources in egov-db:${NC}"
kubectl get pods -l app=mysql -n egov-db
echo -e "\n${YELLOW}Checking remaining MySQL PV/PVC:${NC}"
echo -e "${GREEN}PVCs in egov-db namespace:${NC}"
kubectl get pvc -n egov-db | grep mysql
echo -e "\n${GREEN}PVs:${NC}"
kubectl get pv | grep mysql

echo -e "\n${GREEN}MySQL cleanup completed!${NC}"