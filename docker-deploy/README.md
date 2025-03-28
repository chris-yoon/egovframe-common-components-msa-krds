# Docker 배포 가이드

## 사전 준비사항

- Docker Desktop 설치
- Docker Compose 설치
- 필요한 도구 설치 확인:
  ```bash
  docker version
  docker-compose version
  ```

## 빌드 전 설정

1. 프로젝트 루트 디렉토리에서 모든 서비스 빌드
```bash
./build.sh
```

2. 각 서비스의 target 폴더에 jar 파일이 생성되었는지 확인

3. OpenSearch 이미지 빌드 (Nori 플러그인 추가)
```bash
cd EgovSearch/docker-compose/Opensearch
docker build -t opensearch-with-nori:2.15.0 -f Dockerfile .
```

## Docker 이미지 빌드

1. 전체 서비스 이미지 빌드
```bash
./docker-build.sh
```

2. 특정 서비스만 빌드
```bash
./docker-build.sh EgovMain
./docker-build.sh EgovBoard
```

3. 이미지 생성 확인
```bash
docker images
```

## Docker Compose 실행

1. 전체 서비스 실행
```bash
docker-compose up -d
```

2. 특정 서비스만 실행
```bash
docker-compose up -d egov-main
docker-compose up -d egov-board
```

3. 서비스 스케일링 (게시판 서비스)
```bash
docker-compose -f docker-compose.yml -f docker-compose.board-scale.yml up -d
```

## 서비스 접근

1. 서비스 상태 확인
```bash
docker-compose ps
```

2. 서비스 로그 확인
```bash
docker-compose logs -f [서비스명]
```

3. 접근 URL
- Gateway Server: http://localhost:9000
- Config Server: http://localhost:8888
- 각 서비스 포트:
  - EgovAuthor: 8081
  - EgovBoard: 8082
  - EgovMain: 8085
  - EgovMobileId: 8086
  - EgovQuestionnaire: 8087

4. 로그인 정보
- 일반 계정: USER/rhdxhd12
- 업무 계정: TEST1/rhdxhd12

## 서비스 중지 및 정리

1. 서비스 중지
```bash
docker-compose down
```

2. 특정 서비스만 중지
```bash
docker-compose stop egov-main
```

3. 컨테이너 및 이미지 삭제
```bash
docker-compose down --rmi all
```

4. 볼륨 포함 전체 삭제
```bash
docker-compose down --rmi all -v
```

## 문제 해결

1. 컨테이너 상태 확인
```bash
docker ps -a
```

2. 컨테이너 로그 확인
```bash
docker logs [컨테이너ID 또는 이름]
```

3. 컨테이너 재시작
```bash
docker-compose restart [서비스명]
```

4. 네트워크 확인
```bash
docker network ls
docker network inspect egov-msa-com-network
```

## 환경별 설정

- 개발 환경: `SPRING_PROFILES_ACTIVE=docker`
- 테스트 환경: `SPRING_PROFILES_ACTIVE=docker-test`
- 운영 환경: `SPRING_PROFILES_ACTIVE=docker-prod`

각 환경별 설정은 Config Server를 통해 관리됩니다.