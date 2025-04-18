#!/bin/bash

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# MySQL 설치 (egov-db 네임스페이스)
echo -e "${YELLOW}Installing MySQL...${NC}"

# MySQL 리소스 생성
echo -e "${GREEN}Creating MySQL PV and PVC...${NC}"
export DATA_BASE_PATH=$(kubectl get configmap egov-global-config -o jsonpath='{.data.data_base_path}')
envsubst '${DATA_BASE_PATH}' < ../../manifests/egov-db/mysql-pv.yaml | kubectl apply -f -

echo -e "${GREEN}Creating MySQL Secret...${NC}"
kubectl apply -f ../../manifests/egov-db/mysql-secret.yaml

echo -e "${GREEN}Creating MySQL StatefulSet...${NC}"
kubectl apply -f ../../manifests/egov-db/mysql-statefulset.yaml

echo -e "${GREEN}Creating MySQL Service...${NC}"
kubectl apply -f ../../manifests/egov-db/mysql-service.yaml

# MySQL 배포 상태 확인
echo -e "${YELLOW}Waiting for MySQL StatefulSet...${NC}"
kubectl rollout status statefulset/mysql -n egov-db --timeout=300s

# MySQL 상태 확인
echo -e "\n${YELLOW}Checking MySQL pod status:${NC}"
kubectl get pods -n egov-db -l app=mysql -o wide

# MySQL 로그 확인
echo -e "\n${YELLOW}Checking MySQL logs:${NC}"
MYSQL_POD=$(kubectl get pods -n egov-db -l app=mysql -o jsonpath='{.items[0].metadata.name}')
kubectl logs $MYSQL_POD -n egov-db

# 접근 URL 출력
echo -e "\n${YELLOW}Access URLs:${NC}"
MYSQL_PORT=$(kubectl get svc mysql -n egov-db -o jsonpath='{.spec.ports[0].nodePort}')
echo -e "${GREEN}MySQL: localhost:${MYSQL_PORT}${NC}"

echo -e "\n${GREEN}MySQL installation completed successfully!${NC}"
