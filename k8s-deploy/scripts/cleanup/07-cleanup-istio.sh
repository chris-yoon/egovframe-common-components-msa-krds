#!/bin/bash

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Istio 제거
echo -e "${YELLOW}Uninstalling Istio...${NC}"

# 모든 Istio 컴포넌트 제거
istioctl x uninstall --purge -y || {
    echo -e "${RED}Failed to uninstall Istio components${NC}"
}

# 네임스페이스 삭제
echo -e "${YELLOW}Removing namespaces...${NC}"
kubectl delete namespace istio-system --ignore-not-found=true
#kubectl delete namespace istio-operator --ignore-not-found=true

# Istio 바이너리 제거 (선택사항)
# ISTIO_DIR="../../bin/istio-1.25.0"
# if [ -d "$ISTIO_DIR" ]; then
#     read -p "$(echo -e "${YELLOW}Do you want to remove Istio binary? (y/N): ${NC}")" choice
#     case "$choice" in 
#         y|Y )
#             echo -e "${YELLOW}Removing Istio binary...${NC}"
#             rm -rf "$ISTIO_DIR"
#             echo -e "${GREEN}Istio binary removed${NC}"
#             ;;
#         * )
#             echo -e "${GREEN}Keeping Istio binary${NC}"
#             ;;
#     esac
# fi

echo -e "${GREEN}Istio cleanup completed!${NC}"
