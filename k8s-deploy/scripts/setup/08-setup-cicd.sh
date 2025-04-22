
#!/bin/bash

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 스크립트 디렉토리 설정
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# 함수: 오류 체크
check_error() {
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error occurred in $1${NC}"
        exit 1
    fi
}

# 함수: 리소스 대기
wait_for_resource() {
    local resource_type=$1
    local resource_name=$2
    local namespace=$3
    local timeout=$4

    echo -e "${YELLOW}Waiting for ${resource_type} ${resource_name} to be ready...${NC}"
    kubectl wait --for=condition=Ready ${resource_type}/${resource_name} -n ${namespace} --timeout=${timeout}s
    check_error "waiting for ${resource_type} ${resource_name}"
}

# 함수: 데이터 디렉토리 생성
create_data_directories() {
    echo -e "${YELLOW}Creating data directories...${NC}"
    
    # ConfigMap에서 DATA_BASE_PATH 가져오기
    DATA_BASE_PATH=$(kubectl get configmap egov-global-config -o jsonpath='{.data.data_base_path}')
    
    if [ -z "$DATA_BASE_PATH" ]; then
        echo -e "${RED}DATA_BASE_PATH not found in ConfigMap${NC}"
        exit 1
    fi

    mkdir -p ${DATA_BASE_PATH}/{jenkins,harbor,sonarqube,nexus}
    chmod 777 ${DATA_BASE_PATH}/{jenkins,harbor,sonarqube,nexus}
    
    echo -e "${GREEN}Data directories created successfully${NC}"
}

# CICD 네임스페이스 생성
echo -e "\n${YELLOW}Creating egov-cicd namespace...${NC}"
kubectl create namespace egov-cicd 2>/dev/null || true

# RBAC 설정
echo -e "\n${YELLOW}Setting up RBAC for Jenkins...${NC}"
kubectl apply -f ${BASE_DIR}/manifests/egov-cicd/jenkins-rbac.yaml
check_error "Jenkins RBAC setup"

# 데이터 디렉토리 생성
create_data_directories
check_error "Creating data directories"

# Jenkins StatefulSet 배포
echo -e "\n${YELLOW}Deploying Jenkins StatefulSet...${NC}"
export DATA_BASE_PATH=$(kubectl get configmap egov-global-config -o jsonpath='{.data.data_base_path}')
envsubst < ${BASE_DIR}/manifests/egov-cicd/jenkins-statefulset.yaml | kubectl apply -f -
check_error "Jenkins statefulset deployment"

# GitLab 설치
echo -e "\n${YELLOW}Installing GitLab...${NC}"
envsubst < ${BASE_DIR}/manifests/egov-cicd/gitlab-statefulset.yaml | kubectl apply -f -
check_error "GitLab installation"

# SonarQube 설치
echo -e "\n${YELLOW}Installing SonarQube...${NC}"
envsubst < ${BASE_DIR}/manifests/egov-cicd/sonarqube-deployment.yaml | kubectl apply -f -
check_error "SonarQube installation"

# Nexus 설치
echo -e "\n${YELLOW}Installing Nexus...${NC}"
envsubst < ${BASE_DIR}/manifests/egov-cicd/nexus-statefulset.yaml | kubectl apply -f -
check_error "Nexus installation"

# 서비스 설정
echo -e "\n${YELLOW}Setting up CICD services...${NC}"
kubectl apply -f ${BASE_DIR}/manifests/egov-cicd/cicd-services.yaml
check_error "CICD services setup"

# 리소스 준비 대기
echo -e "\n${YELLOW}Waiting for CICD resources to be ready...${NC}"
wait_for_resource statefulset jenkins egov-cicd 300
wait_for_resource statefulset gitlab egov-cicd 300
wait_for_resource deployment sonarqube egov-cicd 300
wait_for_resource statefulset nexus egov-cicd 300

# Jenkins 초기 비밀번호 출력
echo -e "\n${YELLOW}Jenkins initial admin password:${NC}"
kubectl exec -n egov-cicd jenkins-0 -- cat /var/jenkins_home/secrets/initialAdminPassword

# 설치 완료 메시지 및 접근 정보
echo -e "\n${GREEN}CICD setup completed successfully!${NC}"
echo -e "\n${BLUE}Access Information:${NC}"
echo -e "Jenkins:   http://localhost:30011"
echo -e "GitLab:    http://localhost:30012"
echo -e "SonarQube: http://localhost:30013"
echo -e "Nexus:     http://localhost:30014"

echo -e "\n${YELLOW}Please check the status of all pods:${NC}"
kubectl get pods -n egov-cicd

