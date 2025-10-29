<?xml version="1.0" encoding="UTF-8"?>
<#include "../project/constants.ftl">
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd"
>
    <modelVersion>4.0.0</modelVersion>
    <parent>
        <groupId>io.DoorSync</groupId>
        <artifactId>${serviceName}</artifactId>
        <version>0.0.1-SNAPSHOT</version>
        <relativePath>../</relativePath>
    </parent>
    <artifactId>${serviceName}-domain</artifactId>
    <name>${serviceName?cap_first} Domain Module</name>
    <description>Domain module for ${serviceName?cap_first} service.</description>
    <packaging>jar</packaging>
    <dependencies>
        <!-- DoorSync Core -->
        <dependency>
            <groupId>io.DoorSync</groupId>
            <artifactId>DoorSync-core</artifactId>
        </dependency>

        <!-- Validation -->
        <dependency>
            <groupId>jakarta.validation</groupId>
            <artifactId>jakarta.validation-api</artifactId>
        </dependency>

        <!-- Lombok -->
        <dependency>
            <groupId>org.projectlombok</groupId>
            <artifactId>lombok</artifactId>
            <scope>provided</scope>
        </dependency>

        <#if includeJacksonAnnotationsForEvents?? && includeJacksonAnnotationsForEvents>
        <!-- Jackson Annotations (for domain event JSON creator annotations) -->
        <dependency>
            <groupId>com.fasterxml.jackson.core</groupId>
            <artifactId>jackson-annotations</artifactId>
        </dependency>
        </#if>

        <!-- Testing -->
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
    </dependencies>
</project> 
