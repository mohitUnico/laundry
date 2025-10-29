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
    <artifactId>${serviceName}-infrastructure</artifactId>
    <name>${serviceName?cap_first} Infrastructure Module</name>
    <description>Infrastructure module for ${serviceName?cap_first} service.</description>
    <packaging>jar</packaging>
    
    <properties>
        <mapstruct.version>1.6.0</mapstruct.version>
        <testcontainers.version>1.19.7</testcontainers.version>
    </properties>
    
    <dependencies>
        <!-- DoorSync Core Library - provides base infrastructure patterns -->
        <dependency>
            <groupId>io.DoorSync</groupId>
            <artifactId>DoorSync-core</artifactId>
            <version>0.0.1-SNAPSHOT</version>
        </dependency>

        <!-- Domain module dependency - infrastructure implements domain interfaces -->
        <dependency>
            <groupId>io.DoorSync</groupId>
            <artifactId>${serviceName}-domain</artifactId>
            <version>0.0.1-SNAPSHOT</version>
        </dependency>

        <!-- Infrastructure should not depend on application at compile time -->
        <!-- Spring IoC will handle runtime wiring of implementations -->
        <!-- If you need shared models, consider moving them to the domain layer -->

<#if useDynamoDB>
        <!-- AWS SDK v2 DynamoDB dependencies (aligned with DoorSync-core) -->
        <dependency>
            <groupId>software.amazon.awssdk</groupId>
            <artifactId>dynamodb</artifactId>
        </dependency>
        <dependency>
            <groupId>software.amazon.awssdk</groupId>
            <artifactId>dynamodb-enhanced</artifactId>
        </dependency>
</#if>

<#if useJpa>
        <!-- JPA dependencies -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-data-jpa</artifactId>
        </dependency>
        <!-- H2 for testing -->
        <dependency>
            <groupId>com.h2database</groupId>
            <artifactId>h2</artifactId>
            <scope>test</scope>
        </dependency>
</#if>

<#if useEventPublishing>
        <!-- AWS SQS for event publishing (aligned with DoorSync-core) -->
        <dependency>
            <groupId>software.amazon.awssdk</groupId>
            <artifactId>sqs</artifactId>
        </dependency>
</#if>

<#if hasExternalServices>
        <!-- Spring WebClient for HTTP clients -->
        <dependency>
            <groupId>org.springframework</groupId>
            <artifactId>spring-webflux</artifactId>
        </dependency>
        <!-- Netty for WebClient -->
        <dependency>
            <groupId>io.netty</groupId>
            <artifactId>netty-resolver-dns-native-macos</artifactId>
            <classifier>osx-aarch_64</classifier>
            <scope>runtime</scope>
            <optional>true</optional>
        </dependency>
</#if>

        <!-- Mapping: templates default to manual mapper; MapStruct optional -->
        <dependency>
            <groupId>org.mapstruct</groupId>
            <artifactId>mapstruct</artifactId>
            <version>${mapstruct.version}</version>
            <optional>true</optional>
        </dependency>
        <dependency>
            <groupId>org.mapstruct</groupId>
            <artifactId>mapstruct-processor</artifactId>
            <version>${mapstruct.version}</version>
            <scope>provided</scope>
            <optional>true</optional>
        </dependency>

        <!-- Testing -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>

        <!-- TestContainers for integration testing -->
        <dependency>
            <groupId>org.testcontainers</groupId>
            <artifactId>junit-jupiter</artifactId>
            <version>${testcontainers.version}</version>
            <scope>test</scope>
        </dependency>
<#if useDynamoDB>
        <dependency>
            <groupId>org.testcontainers</groupId>
            <artifactId>localstack</artifactId>
            <version>${testcontainers.version}</version>
            <scope>test</scope>
        </dependency>
</#if>
<#if useJpa>
        <dependency>
            <groupId>org.testcontainers</groupId>
            <artifactId>postgresql</artifactId>
            <version>${testcontainers.version}</version>
            <scope>test</scope>
        </dependency>
</#if>

        <!-- Jackson for JSON processing (aligned with DoorSync-core) -->
        <dependency>
            <groupId>com.fasterxml.jackson.core</groupId>
            <artifactId>jackson-databind</artifactId>
        </dependency>
        <dependency>
            <groupId>com.fasterxml.jackson.datatype</groupId>
            <artifactId>jackson-datatype-jsr310</artifactId>
        </dependency>

        <!-- Micrometer for metrics (aligned with DoorSync-core) -->
        <dependency>
            <groupId>io.micrometer</groupId>
            <artifactId>micrometer-core</artifactId>
        </dependency>
        <dependency>
            <groupId>io.micrometer</groupId>
            <artifactId>micrometer-registry-prometheus</artifactId>
            <scope>runtime</scope>
            <optional>true</optional>
        </dependency>

        <!-- Validation API -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-validation</artifactId>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-compiler-plugin</artifactId>
                <version>3.11.0</version>
                <configuration>
                    <source>17</source>
                    <target>17</target>
                    <annotationProcessorPaths>
                        <path>
                            <groupId>org.projectlombok</groupId>
                            <artifactId>lombok</artifactId>
                            <version>${lombok.version}</version>
                        </path>
                        <path>
                            <groupId>org.mapstruct</groupId>
                            <artifactId>mapstruct-processor</artifactId>
                            <version>${mapstruct.version}</version>
                        </path>
                    </annotationProcessorPaths>
                </configuration>
            </plugin>
        </plugins>
    </build>
</project> 