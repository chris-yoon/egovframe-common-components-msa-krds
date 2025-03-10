package egovframework.com.controller;

import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import reactor.core.publisher.Mono;

@RestController
public class FallbackController {

    @RequestMapping("/fallback/main")
    public Mono<String> mainFallback() {
        return Mono.just("Main Service is currently unavailable. Please try again later.");
    }

    @RequestMapping("/fallback/login")
    public Mono<String> loginFallback() {
        return Mono.just("Login Service is currently unavailable. Please try again later.");
    }

    @RequestMapping("/fallback/board")
    public Mono<String> boardFallback() {
        return Mono.just("Board Service is currently unavailable. Please try again later.");
    }
}