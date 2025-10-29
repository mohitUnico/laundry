<?xml version="1.0" encoding="UTF-8"?>
<#include "../project/constants.ftl">
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    
    <parent>
        <groupId>io.DoorSync</groupId>
        <artifactId>${serviceName}</artifactId>
        <version>0.0.1-SNAPSHOT</version>
        <relativePath>../</relativePath>
    </parent>
    
    <artifactId>${serviceName}-interfaces</artifactId>
    <name>${serviceName?cap_first} Interfaces Module</name>
    <description>Interface module for ${serviceName?cap_first} service - Lambda handlers and DTOs.</description>
    <packaging>jar</packaging>
    
    <dependencies>
        <!-- DoorSync Core Library - Primary dependency that provides all base classes and utilities -->
        <dependency>
            <groupId>io.DoorSync</groupId>
            <artifactId>DoorSync-core</artifactId>
            <version>${r"${project.version}"}</version>
        </dependency>
        
        <!-- Application module provides handlers and DTOs contracts -->
        <dependency>
            <groupId>io.DoorSync</groupId>
            <artifactId>${serviceName}-application</artifactId>
            <version>${r"${project.version}"}</version>
        </dependency>

        <!-- Interfaces should not directly depend on infrastructure or domain -->
        
        <!-- Spring Cloud Function AWS adapter (explicit to ensure present in interfaces JAR) -->
        <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-function-adapter-aws</artifactId>
        </dependency>

        <!-- Remaining dependencies are either Lombok for annotation processing
             or test-scoped libraries. The rest is supplied transitively by DoorSync-core. -->
       
        <!-- Lombok - Version managed by Spring Boot via DoorSync-core -->
        <dependency>
            <groupId>org.projectlombok</groupId>
            <artifactId>lombok</artifactId>
            <scope>provided</scope>
        </dependency>

        <!-- Test Dependencies - Versions managed by Spring Boot via DoorSync-core -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
        <dependency>
            <groupId>org.junit.jupiter</groupId>
            <artifactId>junit-jupiter</artifactId>
            <scope>test</scope>
        </dependency>
        <dependency>
            <groupId>org.mockito</groupId>
            <artifactId>mockito-core</artifactId>
            <scope>test</scope>
        </dependency>
        <dependency>
            <groupId>org.mockito</groupId>
            <artifactId>mockito-junit-jupiter</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <!-- Maven Compiler Plugin - versions managed upstream -->
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-compiler-plugin</artifactId>
                <configuration>
                    <source>${r"${java.version}"}</source>
                    <target>${r"${java.version}"}</target>
                    <annotationProcessorPaths>
                        <path>
                            <groupId>org.projectlombok</groupId>
                            <artifactId>lombok</artifactId>
                            <version>${r"${lombok.version}"}</version>
                        </path>
                        <path>
                            <groupId>org.hibernate.validator</groupId>
                            <artifactId>hibernate-validator-annotation-processor</artifactId>
                            <version>${r"${hibernate-validator.version}"}</version>
                        </path>
                    </annotationProcessorPaths>
                </configuration>
            </plugin>
            
            <!-- Surefire Plugin for Unit Tests -->
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-surefire-plugin</artifactId>
                <configuration>
                    <includes>
                        <include>**/*Test.java</include>
                        <include>**/*Tests.java</include>
                    </includes>
                </configuration>
            </plugin>
            
            <!-- Failsafe Plugin for Integration Tests -->
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-failsafe-plugin</artifactId>
                <configuration>
                    <includes>
                        <include>**/*IT.java</include>
                        <include>**/*IntegrationTest.java</include>
                    </includes>
                </configuration>
                <executions>
                    <execution>
                        <goals>
                            <goal>integration-test</goal>
                            <goal>verify</goal>
                        </goals>
                    </execution>
                </executions>
            </plugin>
            
            <!-- Shade plugin for AWS Lambda packaging, if not handled globally -->
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-shade-plugin</artifactId>
                <version>3.5.0</version>
                <executions>
                    <execution>
                        <phase>package</phase>
                        <goals>
                            <goal>shade</goal>
                        </goals>
                        <configuration>
                            <createDependencyReducedPom>false</createDependencyReducedPom>
                            <shadedArtifactAttached>true</shadedArtifactAttached>
                            <shadedClassifierName>aws</shadedClassifierName>
                        </configuration>
                    </execution>
                </executions>
            </plugin>
        </plugins>
    </build>
</project> 