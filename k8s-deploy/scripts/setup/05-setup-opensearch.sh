#!/bin/bash

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# OpenSearch 설치
echo -e "${YELLOW}Installing OpenSearch...${NC}"

echo -e "${GREEN}Creating OpenSearch PV and PVC...${NC}"
kubectl apply -f ../../manifests/egov-db/opensearch-pv.yaml

echo -e "${GREEN}Creating OpenSearch ConfigMap...${NC}"
kubectl apply -f ../../manifests/egov-db/opensearch-configmap.yaml

echo -e "${GREEN}Creating OpenSearch Secret...${NC}"
kubectl apply -f ../../manifests/egov-db/opensearch-secret.yaml

echo -e "${GREEN}Creating OpenSearch Certificates Secret...${NC}"
kubectl apply -f ../../manifests/egov-db/opensearch-certs-secret.yaml

echo -e "${GREEN}Creating OpenSearch StatefulSet and Services...${NC}"
kubectl apply -f ../../manifests/egov-db/opensearch-service.yaml
kubectl apply -f ../../manifests/egov-db/opensearch-statefulset.yaml

echo -e "${GREEN}Creating OpenSearch Dashboard...${NC}"
kubectl apply -f ../../manifests/egov-db/opensearch-dashboard-deployment.yaml

# OpenSearch 배포 상태 확인
echo -e "${YELLOW}Waiting for OpenSearch StatefulSet...${NC}"
kubectl rollout status statefulset/opensearch -n egov-db --timeout=390s

echo -e "${YELLOW}Waiting for OpenSearch Dashboard...${NC}"
kubectl rollout status deployment/opensearch-dashboards -n egov-db --timeout=300s

# 상태 확인
echo -e "\n${YELLOW}Checking OpenSearch status:${NC}"
kubectl get pods,svc -n egov-db -l app=opensearch

# 접근 URL 출력
echo -e "\n${YELLOW}Access URLs:${NC}"
OPENSEARCH_PORT=$(kubectl get svc opensearch -n egov-db -o jsonpath='{.spec.ports[0].nodePort}')
DASHBOARD_PORT=$(kubectl get svc opensearch-dashboards -n egov-db -o jsonpath='{.spec.ports[0].nodePort}')

echo -e "${GREEN}OpenSearch API: https://localhost:${OPENSEARCH_PORT}${NC}"
echo -e "${GREEN}OpenSearch Dashboard: http://localhost:${DASHBOARD_PORT}${NC}"

echo -e "\n${GREEN}OpenSearch installation completed successfully!${NC}"
