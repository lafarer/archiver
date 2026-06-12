package com.github.lafarer.archiver;

import com.github.lafarer.archiver.config.ArchiverProperties;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.scheduling.annotation.EnableAsync;

@SpringBootApplication
@EnableConfigurationProperties(ArchiverProperties.class)
@EnableAsync
public class ArchiverApplication {

    public static void main(String[] args) {
        SpringApplication.run(ArchiverApplication.class, args);
    }
}
