#!/bin/bash

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

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

# OpenSearch PV/PVC 제거
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
echo -e "\n${YELLOW}Waiting for OpenSearch resources to be terminated...${NC}"
kubectl wait --for=delete pods -l app=opensearch -n egov-db --timeout=60s 2>/dev/null || true

# 최종 상태 확인
echo -e "\n${YELLOW}Checking remaining OpenSearch resources in egov-db:${NC}"
kubectl get pods -l app=opensearch -n egov-db
echo -e "\n${YELLOW}Checking remaining OpenSearch PV/PVC:${NC}"
echo -e "${GREEN}PVCs in egov-db namespace:${NC}"
kubectl get pvc -n egov-db | grep opensearch
echo -e "\n${GREEN}PVs:${NC}"
kubectl get pv | grep opensearch

echo -e "\n${GREEN}OpenSearch cleanup completed!${NC}"