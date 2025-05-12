package egovframework.com.config;

import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import io.swagger.v3.oas.models.servers.Server;

@Configuration
public class EgovSearchSwagger {

    @Value("${app.openapi.server-url}")
    private String serverUrl;

    @Bean
    public OpenAPI api() {
        Info info = new Info()
                .title("Open Search 연동 API Document")
                .version("v0.0.1")
                .description("Open Search - Spring Boot 연동의 API 명세서입니다.");

                Server server = new Server()
                .url(serverUrl)
                .description("동적으로 주입된 K8s Gateway 주소");

        return new OpenAPI()
                .components(new Components())
                .info(info)
                .addServersItem(server);
    }

}
