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
    <artifactId>${serviceName}-application</artifactId>
    <name>${serviceName?cap_first} Application Module</name>
    <description>Application module for ${serviceName?cap_first} service.</description>
    <packaging>jar</packaging>
    <dependencies>
        <!-- DoorSync Core Library -->
        <dependency>
            <groupId>io.DoorSync</groupId>
            <artifactId>DoorSync-core</artifactId>
        </dependency>

        <!-- Spring Boot Validation (provides jakarta.validation.Validator at runtime) -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-validation</artifactId>
        </dependency>

        <!-- Domain Module Dependency -->
        <dependency>
            <groupId>io.DoorSync</groupId>
            <artifactId>${serviceName}-domain</artifactId>
            <version>0.0.1-SNAPSHOT</version>
        </dependency>

        <!-- Test Dependencies -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>

        <!-- Lombok for annotations used in generated code (@Slf4j, builders) -->
        <dependency>
            <groupId>org.projectlombok</groupId>
            <artifactId>lombok</artifactId>
            <scope>provided</scope>
        </dependency>

        <#-- MapStruct (optional). Include when useMapstruct=true in generation params. -->
        <#if useMapstruct?? && useMapstruct>
        <dependency>
            <groupId>org.mapstruct</groupId>
            <artifactId>mapstruct</artifactId>
            <version>1.5.5.Final</version>
        </dependency>
        <dependency>
            <groupId>org.mapstruct</groupId>
            <artifactId>mapstruct-processor</artifactId>
            <version>1.5.5.Final</version>
            <scope>provided</scope>
        </dependency>
        </#if>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-compiler-plugin</artifactId>
                <configuration>
                    <source>${javaVersion}</source>
                    <target>${javaVersion}</target>
                    <annotationProcessorPaths>
                        <path>
                            <groupId>org.projectlombok</groupId>
                            <artifactId>lombok</artifactId>
                            <version>${lombokVersion}</version>
                        </path>
                        <path>
                            <groupId>org.hibernate.validator</groupId>
                            <artifactId>hibernate-validator-annotation-processor</artifactId>
                            <version>8.0.1.Final</version>
                        </path>
                        <#if useMapstruct?? && useMapstruct>
                        <path>
                            <groupId>org.mapstruct</groupId>
                            <artifactId>mapstruct-processor</artifactId>
                            <version>1.5.5.Final</version>
                        </path>
                        </#if>
                    </annotationProcessorPaths>
                </configuration>
            </plugin>
        </plugins>
    </build>
</project> 