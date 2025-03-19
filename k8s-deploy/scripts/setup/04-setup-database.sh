#!/bin/bash

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# MySQL 설치
./04-1-setup-mysql.sh

# OpenSearch 설치
./04-2-setup-opensearch.sh

# 전체 데이터베이스 상태 확인
echo -e "\n${YELLOW}Checking all database resources:${NC}"
kubectl get pods,svc -n egov-db

echo -e "\n${GREEN}All database installations completed successfully!${NC}"
