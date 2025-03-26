#!/bin/bash

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Istio 매니페스트 정리
echo -e "${YELLOW}Removing Istio manifests...${NC}"
kubectl delete -f ../../manifests/egov-istio/telemetry.yaml --ignore-not-found=true
kubectl delete -f ../../manifests/egov-istio/config.yaml --ignore-not-found=true

# Istio injection 레이블 제거
echo -e "${YELLOW}Removing Istio injection labels from namespaces...${NC}"
kubectl label namespace egov-app istio-injection- 2>/dev/null || true

# Istio 제거
echo -e "${YELLOW}Uninstalling Istio...${NC}"

# 모든 Istio 컴포넌트 제거 시도
if ! istioctl uninstall -y; then
    echo -e "${YELLOW}Trying alternative uninstall method...${NC}"
    # Istio 관련 리소스 직접 제거
    kubectl delete istiooperators --all-namespaces --all
    kubectl delete mutatingwebhookconfiguration istio-sidecar-injector --ignore-not-found=true
    kubectl delete validatingwebhookconfiguration istiod-istio-system --ignore-not-found=true
    kubectl delete -n istio-system --all
fi

# 네임스페이스 삭제
echo -e "${YELLOW}Removing namespaces...${NC}"
kubectl delete namespace istio-system --ignore-not-found=true

echo -e "${GREEN}Istio cleanup completed!${NC}"
