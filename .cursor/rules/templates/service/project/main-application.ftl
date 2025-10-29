package ${basePackage};

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * Main application class for the ${serviceName?cap_first} Service.
 * Bootstraps the Spring Boot application.
 */
@SpringBootApplication
public class ${serviceName?replace('-', '')?cap_first}Application {

  public static void main(String[] args) {
    SpringApplication.run(${serviceName?replace('-', '')?cap_first}Application.class, args);
  }
} 