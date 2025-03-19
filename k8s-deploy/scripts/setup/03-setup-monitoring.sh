#!/bin/bash

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# egov-monitoring 네임스페이스 확인 및 생성
if ! kubectl get namespace egov-monitoring >/dev/null 2>&1; then
    echo -e "${YELLOW}Creating egov-monitoring namespace...${NC}"
    kubectl create namespace egov-monitoring
fi

# Istio 애드온 설치
echo -e "${YELLOW}Installing monitoring addons in egov-monitoring namespace...${NC}"

# Prometheus 서비스 먼저 제거 (이미 존재하는 경우)
kubectl delete service prometheus -n egov-monitoring 2>/dev/null || true

# 각 애드온 설치
for addon in prometheus grafana kiali jaeger; do
    echo -e "${GREEN}Installing ${addon}...${NC}"
    kubectl apply -f "../../manifests/egov-monitoring/${addon}.yaml"
done

# 설치 완료까지 대기
echo -e "${YELLOW}Waiting for pods to be ready...${NC}"
kubectl wait --for=condition=Ready pods --all -n egov-monitoring --timeout=300s

# 설치된 pods 확인
echo -e "${GREEN}Checking installed pods:${NC}"
kubectl get pods -n egov-monitoring

# 서비스 확인
echo -e "${GREEN}Checking services:${NC}"
kubectl get svc -n egov-monitoring

echo -e "${GREEN}Addons installation completed in egov-monitoring namespace!${NC}"

# 접근 URL 출력
echo -e "${YELLOW}Access URLs:${NC}"
echo "Kiali:      http://localhost:30001"
echo "Grafana:    http://localhost:30002"
echo "Jaeger:     http://localhost:30003"
echo "Prometheus: http://localhost:30004"
