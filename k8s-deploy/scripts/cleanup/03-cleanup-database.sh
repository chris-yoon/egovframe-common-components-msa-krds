#!/bin/bash

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Database 서비스 제거 (egov-db 네임스페이스)
echo -e "${YELLOW}Removing database services...${NC}"

# MySQL 관련 리소스 제거
echo -e "${GREEN}Removing MySQL Service...${NC}"
kubectl delete -f ../../manifests/egov-db/mysql-service.yaml 2>/dev/null || true

echo -e "${GREEN}Removing MySQL StatefulSet...${NC}"
kubectl delete -f ../../manifests/egov-db/mysql-statefulset.yaml 2>/dev/null || true

echo -e "${GREEN}Removing MySQL Secret...${NC}"
kubectl delete -f ../../manifests/egov-db/mysql-secret.yaml 2>/dev/null || true

echo -e "${GREEN}Removing MySQL PV and PVC...${NC}"
kubectl delete pvc data-mysql-0 -n egov-db --force --grace-period=0 2>/dev/null || true
kubectl delete pv mysql-pv-0 --force --grace-period=0 2>/dev/null || true

# OpenSearch 관련 리소스 제거
echo -e "${YELLOW}Removing OpenSearch resources...${NC}"

echo -e "${GREEN}Removing OpenSearch Dashboard...${NC}"
kubectl delete -f ../../manifests/egov-db/opensearch-dashboard-deployment.yaml 2>/dev/null || true

echo -e "${GREEN}Removing OpenSearch StatefulSet and Services...${NC}"
kubectl delete -f ../../manifests/egov-db/opensearch-statefulset.yaml 2>/dev/null || true
kubectl delete -f ../../manifests/egov-db/opensearch-service.yaml 2>/dev/null || true

echo -e "${GREEN}Removing OpenSearch Secret...${NC}"
kubectl delete -f ../../manifests/egov-db/opensearch-secret.yaml 2>/dev/null || true

echo -e "${GREEN}Removing OpenSearch ConfigMap...${NC}"
kubectl delete -f ../../manifests/egov-db/opensearch-configmap.yaml 2>/dev/null || true

# OpenSearch PV/PVC 제거 로직 추가
echo -e "${GREEN}Removing OpenSearch PV and PVC...${NC}"
kubectl delete pvc data-opensearch-0 -n egov-db --force --grace-period=0 2>/dev/null || true
kubectl delete pvc data-opensearch-1 -n egov-db --force --grace-period=0 2>/dev/null || true

# PV가 Terminating 상태인 경우 강제 삭제
for pv in $(kubectl get pv | grep opensearch | awk '{print $1}'); do
    if kubectl get pv $pv 2>/dev/null | grep Terminating; then
        echo -e "${YELLOW}PV $pv stuck in Terminating state, forcing deletion...${NC}"
        kubectl patch pv $pv -p '{"metadata":{"finalizers":null}}'
        kubectl delete pv $pv --force --grace-period=0
    fi
done

# 리소스 제거 완료 대기
echo -e "\n${YELLOW}Waiting for resources to be terminated...${NC}"
echo -e "${YELLOW}Waiting for egov-db resources...${NC}"
kubectl wait --for=delete pods --all -n egov-db --timeout=60s 2>/dev/null || true

# 최종 상태 확인
echo -e "\n${YELLOW}Checking remaining resources in egov-db:${NC}"
kubectl get all -n egov-db
echo -e "\n${YELLOW}Checking remaining PV/PVC:${NC}"
echo -e "${GREEN}PVCs in egov-db namespace:${NC}"
kubectl get pvc -n egov-db
echo -e "\n${GREEN}PVs:${NC}"
kubectl get pv | grep -E 'mysql|opensearch'

echo -e "\n${GREEN}Database cleanup completed!${NC}"
