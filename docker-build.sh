#!/bin/bash

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 시작 시간 기록
start_time=$(date +%s)

# 서비스 배열 정의
services=(
    "ConfigServer"
    "EurekaServer"
    "GatewayServer"
    "EgovAuthor"
    "EgovBoard"
    "EgovCmmnCode"
    "EgovLogin"
    "EgovMain"
    "EgovMobileId"
    "EgovQuestionnaire"
    "EgovSearch"
)

# 이미지 태그 정의
IMAGE_TAG="latest"

# 결과 저장을 위한 임시 파일
RESULT_FILE="/tmp/build_results.txt"
> $RESULT_FILE

# 빌드 함수
build_service() {
    local service=$1
    echo -e "\n${BLUE}Building ${service}...${NC}"
    
    # 디렉토리 존재 확인
    if [ ! -d "$service" ]; then
        echo -e "${RED}Error: Directory $service not found${NC}"
        echo "${service}:Failed: Directory not found" >> $RESULT_FILE
        return 1
    fi
    
    # JAR 파일 존재 확인
    if [ ! -f "$service/target/"*.jar ]; then
        echo -e "${RED}Error: JAR file not found in $service/target/${NC}"
        echo "${service}:Failed: JAR file not found" >> $RESULT_FILE
        return 1
    fi

    # 서비스 디렉토리로 이동
    cd $service

    # Docker 이미지 빌드
    echo -e "${YELLOW}Building Docker image for $service...${NC}"
    image_name=$(echo $service | tr '[:upper:]' '[:lower:]')
    if ! docker build -t $image_name:$IMAGE_TAG .; then
        echo -e "${RED}Docker build failed for $service${NC}"
        cd ..
        echo "${service}:Failed: Docker build failed" >> $RESULT_FILE
        return 1
    fi

    cd ..
    echo "${service}:Success" >> $RESULT_FILE
    echo -e "${GREEN}Successfully built $service${NC}"
    return 0
}

# 결과 출력 함수
print_summary() {
    echo -e "\n${BLUE}=== Build Summary ===${NC}"
    echo -e "Build started at: $(date -d @$start_time)"
    echo -e "Build finished at: $(date)"
    
    local duration=$(($(date +%s) - start_time))
    echo -e "Total build time: $((duration / 60))m $((duration % 60))s\n"
    
    echo -e "${BLUE}Build Results:${NC}"
    while IFS=: read -r service status; do
        if [ "$status" == "Success" ]; then
            echo -e "${GREEN}✓ $service: $status${NC}"
        else
            echo -e "${RED}✗ $service: $status${NC}"
        fi
    done < $RESULT_FILE
}

# Docker 네트워크 생성 (없는 경우)
echo -e "${YELLOW}Checking Docker network...${NC}"
if ! docker network ls | grep -q "egov-msa-com-network"; then
    echo -e "${YELLOW}Creating egov-msa-com-network...${NC}"
    docker network create egov-msa-com-network
fi

# 인자 확인 및 유효성 검사
if [ $# -eq 1 ]; then
    # 서비스 이름이 유효한지 확인
    valid_service=false
    for service in "${services[@]}"; do
        if [ "$1" == "$service" ]; then
            valid_service=true
            break
        fi
    done

    if [ "$valid_service" = true ]; then
        echo -e "${BLUE}Starting build process for $1...${NC}"
        build_service "$1"
    else
        echo -e "${RED}Error: Invalid service name '$1'${NC}"
        echo "Available services:"
        printf '%s\n' "${services[@]}"
        rm -f $RESULT_FILE
        exit 1
    fi
else
    # 인자가 없는 경우 모든 서비스 빌드
    echo -e "${BLUE}Starting build process for all services...${NC}"
    echo -e "Services to build: ${services[@]}\n"

    for service in "${services[@]}"; do
        build_service "$service"
    done
fi

# 빌드 결과 출력
print_summary

# 최종 상태 확인
FAILED=0
while IFS=: read -r service status; do
    if [ "$status" != "Success" ]; then
        FAILED=1
        break
    fi
done < $RESULT_FILE

# 임시 파일 삭제
rm -f $RESULT_FILE

if [ $FAILED -eq 1 ]; then
    echo -e "\n${RED}Some builds failed. Please check the build summary above.${NC}"
    exit 1
fi

echo -e "\n${GREEN}All services built successfully!${NC}"
echo -e "You can now use 'docker-compose up' to start the services."