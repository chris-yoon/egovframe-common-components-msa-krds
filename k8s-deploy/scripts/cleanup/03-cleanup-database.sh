#!/bin/bash

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Database 서비스 제거 (egov-db 네임스페이스)
echo -e "${YELLOW}Removing database services...${NC}"

# MySQL 정리
./03-1-cleanup-mysql.sh

# OpenSearch 정리
./03-2-cleanup-opensearch.sh

# 최종 상태 확인
echo -e "\n${YELLOW}Checking all remaining resources in egov-db:${NC}"
kubectl get all -n egov-db
echo -e "\n${YELLOW}Checking all remaining PV/PVC:${NC}"
echo -e "${GREEN}PVCs in egov-db namespace:${NC}"
kubectl get pvc -n egov-db
echo -e "\n${GREEN}PVs:${NC}"
kubectl get pv | grep -E 'mysql|opensearch'

echo -e "\n${GREEN}Database cleanup completed!${NC}"
