FROM eclipse-temurin:17-jre-jammy
WORKDIR /app

RUN apt-get update && \
    apt-get install -y curl && \
    rm -rf /var/lib/apt/lists/*

COPY target/*.jar /app/app.jar

ENV SERVER_PORT=8088 \
    SPRING_APPLICATION_NAME=EgovSearch \
    SPRING_PROFILES_ACTIVE=docker \
    SPRING_CLOUD_CONFIG_URI=http://config-server:8888

HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -f http://localhost:8088/actuator/health || exit 1

EXPOSE 8088

ENTRYPOINT ["java", \
    "-jar", "/app/app.jar"]
