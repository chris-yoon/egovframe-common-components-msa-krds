#!/bin/bash

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# MySQL 상태 확인 및 시작 함수
check_mysql() {
    # MySQL 프로세스 확인
    if ! pgrep -f mysqld > /dev/null; then
        echo -e "${RED}MySQL is not running. Attempting to start MySQL...${NC}"
        
        MYSQL_START_SCRIPT="/Users/EGOVEDU/eGovFrame-4.2.0/bin/mysql/start.sh"
        
        # 시작 스크립트 존재 확인
        if [ -f "$MYSQL_START_SCRIPT" ]; then
            # 실행 권한 확인 및 부여
            if [ ! -x "$MYSQL_START_SCRIPT" ]; then
                chmod +x "$MYSQL_START_SCRIPT"
            fi
            
            # MySQL 시작
            "$MYSQL_START_SCRIPT"
            
            # MySQL 시작 대기
            echo "Waiting for MySQL to start..."
            sleep 10
            
            # MySQL 시작 확인
            if ! pgrep -f mysqld > /dev/null; then
                echo -e "${RED}Failed to start MySQL. Please start it manually.${NC}"
                exit 1
            fi
            echo -e "${GREEN}MySQL started successfully.${NC}"
        else
            echo -e "${RED}MySQL start script not found at $MYSQL_START_SCRIPT${NC}"
            echo -e "${RED}Please start MySQL manually.${NC}"
            exit 1
        fi
    else
        echo -e "${GREEN}MySQL is already running.${NC}"
    fi
}

# 로그 디렉토리 생성
mkdir -p logs

# MySQL 상태 확인
check_mysql

# 기본 서비스 순서 정의
core_services=(
    "ConfigServer"
    "EurekaServer"
    "GatewayServer"
)

# 일반 서비스 정의
services=(
    "EgovAuthor"
    "EgovBoard"
    "EgovCmmnCode"
    "EgovLogin"
    "EgovMain"
    "EgovQuestionnaire"
    "EgovMobileId"
    "EgovSearch"
)

# 서비스의 프로파일 반환 함수
get_profile() {
    local service=$1
    case $service in
        "ConfigServer") echo "native" ;;
        "EurekaServer") echo "default" ;;
        "GatewayServer") echo "local" ;;
        *) echo "local" ;;
    esac
}

# 각 서비스 시작 함수
start_service() {
    local jar_path=$1
    local log_file=$2
    local profile=${3:-local}  # 세 번째 인자가 없으면 'local'을 기본값으로 사용
    local service_name=$(basename $jar_path .jar)
    
    if [ "$service_name" == "ConfigServer" ]; then
        echo "Starting $service_name with profile '$profile' and config path..."
        nohup java -jar $jar_path \
            --spring.profiles.active=$profile \
            --spring.cloud.config.server.native.search-locations=file:./ConfigServer-config \
            > $log_file 2>&1 &
    else
        echo "Starting $service_name with profile '$profile'..."
        nohup java -jar $jar_path --spring.profiles.active=$profile > $log_file 2>&1 &
    fi
    
    # 프로세스가 시작되었는지 확인
    sleep 5
    if ! ps aux | grep -v grep | grep "$jar_path" > /dev/null; then
        echo -e "${RED}Failed to start $service_name. Check logs at $log_file${NC}"
        return 1
    fi
    echo -e "${GREEN}$service_name started successfully${NC}"
    return 0
}

# 서비스 존재 여부 확인 함수
is_valid_service() {
    local service=$1
    for s in "${core_services[@]}" "${services[@]}"; do
        if [ "$s" == "$service" ]; then
            return 0
        fi
    done
    return 1
}

# 코어 서비스 시작 함수
start_core_services() {
    # Config Server 시작
    if start_service "ConfigServer/target/ConfigServer.jar" "logs/ConfigServer.log" "native"; then
        echo -e "${GREEN}Config Server is available at: http://localhost:8888/application/local${NC}"
    else
        echo -e "${RED}Failed to start Config Server${NC}"
        exit 1
    fi
    sleep 10

    # Discovery Server 시작
    if start_service "EurekaServer/target/EurekaServer.jar" "logs/EurekaServer.log" "default"; then
        echo -e "${GREEN}Eureka Server Dashboard is available at: http://localhost:8761${NC}"
    else
        echo -e "${RED}Failed to start Eureka Server${NC}"
        exit 1
    fi
    sleep 20

    # Gateway 시작
    if start_service "GatewayServer/target/GatewayServer.jar" "logs/GatewayServer.log" "local"; then
        echo -e "${GREEN}Gateway Server started successfully${NC}"
    else
        echo -e "${RED}Failed to start Gateway Server${NC}"
        exit 1
    fi
    sleep 15
}

# 단일 서비스 시작 함수
start_single_service() {
    local service=$1
    local profile=$(get_profile "$service")
    
    # 코어 서비스가 아닌 경우 코어 서비스들이 실행 중인지 확인
    if [[ ! " ${core_services[@]} " =~ " ${service} " ]]; then
        for core_service in "${core_services[@]}"; do
            if ! pgrep -f "$core_service.jar" > /dev/null; then
                echo -e "${RED}Error: Core service $core_service is not running. Please start it first.${NC}"
                exit 1
            fi
        done
    fi
    
    start_service "$service/target/$service.jar" "logs/$service.log" "$profile"
    
    # EgovMain 서비스가 시작되면 접속 URL 표시
    if [ "$service" == "EgovMain" ]; then
        echo "EgovMain is available at: http://localhost:9000/"
    fi
}

# 메인 로직
if [ $# -eq 1 ]; then
    # 서비스 이름이 유효한지 확인
    if ! is_valid_service "$1"; then
        echo -e "${RED}Error: Invalid service name '$1'${NC}"
        echo "Available services:"
        echo "Core services:"
        printf '%s\n' "${core_services[@]}"
        echo "Regular services:"
        printf '%s\n' "${services[@]}"
        exit 1
    fi

    # 특정 서비스 시작
    start_single_service "$1"
else
    # 모든 서비스 시작
    start_core_services

    # 나머지 서비스들 시작
    for service in "${services[@]}"; do
        if start_service "$service/target/$service.jar" "logs/$service.log"; then
            if [ "$service" == "EgovMain" ]; then
                echo -e "${GREEN}EgovMain is available at: http://localhost:9000/${NC}"
            fi
        else
            echo -e "${RED}Failed to start $service${NC}"
            exit 1
        fi
        sleep 5
    done
    echo -e "${GREEN}All services have been started. Check individual log files in logs/ directory${NC}"
fi
