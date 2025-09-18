package com.garageservice;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.domain.EntityScan;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;

@SpringBootApplication
@EntityScan(basePackages = "com.garageservice.model")
@EnableJpaRepositories(basePackages = "com.garageservice.repository")
public class GarageServiceApplication {
    public static void main(String[] args) {
        SpringApplication.run(GarageServiceApplication.class, args);
    }
}