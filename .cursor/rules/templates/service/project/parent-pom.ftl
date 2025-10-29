<?xml version="1.0" encoding="UTF-8"?>
<#include "constants.ftl">
<project xmlns="http://maven.apache.org/POM/4.0.0" 
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    
    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.2.4</version>
        <relativePath/>
    </parent>
    
    <groupId>io.DoorSync</groupId>
    <artifactId>${serviceName}</artifactId>
    <version>0.0.1-SNAPSHOT</version>
    <name>${serviceName?cap_first} Service</name>
    <description>${serviceDescription!'A microservice for the DoorSync platform'}</description>
    <packaging>pom</packaging>
    
    <properties>
        <java.version>17</java.version>
        <maven.compiler.source>${r"${java.version}"}</maven.compiler.source>
        <maven.compiler.target>${r"${java.version}"}</maven.compiler.target>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
        <DoorSync.core.version>${doorsyncCoreVersion}</DoorSync.core.version>
        <aws.lambda.java.version>${awsLambdaJavaVersion}</aws.lambda.java.version>
        <aws.lambda.events.version>${awsLambdaEventsVersion}</aws.lambda.events.version>
        <aws.java.sdk.version>${awsJavaSdkVersion}</aws.java.sdk.version>
        <aws.sdk.v2.version>${awsSdkV2Version}</aws.sdk.v2.version>
        <spring.cloud.aws.version>${springCloudAwsVersion}</spring.cloud.aws.version>
        <spring.cloud.function.version>${springCloudFunctionVersion}</spring.cloud.function.version>
        <checkstyle.version>${checkstyleVersion}</checkstyle.version>
        <maven-checkstyle-plugin.version>${mavenCheckstylePluginVersion}</maven-checkstyle-plugin.version>
        <maven-pmd-plugin.version>${mavenPmdPluginVersion}</maven-pmd-plugin.version>
        <spotbugs-maven-plugin.version>${spotbugsPluginVersion}</spotbugs-maven-plugin.version>
        <maven-formatter-plugin.version>${mavenFormatterPluginVersion}</maven-formatter-plugin.version>
        <impsort-maven-plugin.version>${impsortPluginVersion}</impsort-maven-plugin.version>
    </properties>
    
    <modules>
        <module>domain</module>
        <module>application</module>
        <module>infrastructure</module>
        <module>interface</module>
    </modules>
    
    <dependencyManagement>
        <dependencies>
            <!-- Module Dependencies -->
            <dependency>
                <groupId>${r"${project.groupId}"}</groupId>
                <artifactId>${serviceName}-domain</artifactId>
                <version>${r"${project.version}"}</version>
            </dependency>
            <dependency>
                <groupId>${r"${project.groupId}"}</groupId>
                <artifactId>${serviceName}-application</artifactId>
                <version>${r"${project.version}"}</version>
            </dependency>
            <dependency>
                <groupId>${r"${project.groupId}"}</groupId>
                <artifactId>${serviceName}-infrastructure</artifactId>
                <version>${r"${project.version}"}</version>
            </dependency>
            <dependency>
                <groupId>${r"${project.groupId}"}</groupId>
                <artifactId>${serviceName}-interface</artifactId>
                <version>${r"${project.version}"}</version>
            </dependency>
            
            <!-- DoorSync Core Library -->
            <dependency>
                <groupId>io.DoorSync</groupId>
                <artifactId>DoorSync-core</artifactId>
                <version>${r"${DoorSync.core.version}"}</version>
            </dependency>
            
            <!-- Spring Cloud Function -->
            <dependency>
                <groupId>org.springframework.cloud</groupId>
                <artifactId>spring-cloud-function-adapter-aws</artifactId>
                <version>${r"${spring.cloud.function.version}"}</version>
            </dependency>
            
            <!-- AWS Dependencies -->
            <dependency>
                <groupId>io.awspring.cloud</groupId>
                <artifactId>spring-cloud-aws-dependencies</artifactId>
                <version>${r"${spring.cloud.aws.version}"}</version>
                <type>pom</type>
                <scope>import</scope>
            </dependency>
        </dependencies>
    </dependencyManagement>
    
    <dependencies>
        <!-- DoorSync Core Library -->
        <dependency>
            <groupId>io.DoorSync</groupId>
            <artifactId>DoorSync-core</artifactId>
        </dependency>
        
        <!-- Lombok -->
        <dependency>
            <groupId>org.projectlombok</groupId>
            <artifactId>lombok</artifactId>
            <optional>true</optional>
        </dependency>
        
        <!-- Testing Dependencies -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>
    
    <build>
        <pluginManagement>
            <plugins>
                <plugin>
                    <groupId>org.apache.maven.plugins</groupId>
                    <artifactId>maven-compiler-plugin</artifactId>
                    <version>3.11.0</version>
                    <configuration>
                        <source>${r"${java.version}"}</source>
                        <target>${r"${java.version}"}</target>
                        <annotationProcessorPaths>
                            <path>
                                <groupId>org.projectlombok</groupId>
                                <artifactId>lombok</artifactId>
                                <version>${r"${lombok.version}"}</version>
                            </path>
                        </annotationProcessorPaths>
                    </configuration>
                </plugin>
                
                <!-- Code Quality Plugins -->
                <plugin>
                    <groupId>org.apache.maven.plugins</groupId>
                    <artifactId>maven-checkstyle-plugin</artifactId>
                    <version>${r"${maven-checkstyle-plugin.version}"}</version>
                    <dependencies>
                        <dependency>
                            <groupId>com.puppycrawl.tools</groupId>
                            <artifactId>checkstyle</artifactId>
                            <version>${r"${checkstyle.version}"}</version>
                        </dependency>
                    </dependencies>
                    <configuration>
                        <configLocation>google_checks.xml</configLocation>
                        <encoding>UTF-8</encoding>
                        <consoleOutput>true</consoleOutput>
                        <failsOnError>true</failsOnError>
                        <linkXRef>false</linkXRef>
                    </configuration>
                    <executions>
                        <execution>
                            <id>validate</id>
                            <phase>validate</phase>
                            <goals>
                                <goal>check</goal>
                            </goals>
                        </execution>
                    </executions>
                </plugin>
                
                <plugin>
                    <groupId>org.apache.maven.plugins</groupId>
                    <artifactId>maven-pmd-plugin</artifactId>
                    <version>${r"${maven-pmd-plugin.version}"}</version>
                    <configuration>
                        <failOnViolation>true</failOnViolation>
                        <printFailingErrors>true</printFailingErrors>
                        <linkXRef>false</linkXRef>
                    </configuration>
                    <executions>
                        <execution>
                            <goals>
                                <goal>check</goal>
                            </goals>
                        </execution>
                    </executions>
                </plugin>
                
                <plugin>
                    <groupId>com.github.spotbugs</groupId>
                    <artifactId>spotbugs-maven-plugin</artifactId>
                    <version>${r"${spotbugs-maven-plugin.version}"}</version>
                    <configuration>
                        <effort>Max</effort>
                        <threshold>Low</threshold>
                        <xmlOutput>true</xmlOutput>
                        <excludeFilterFile>spotbugs-exclude.xml</excludeFilterFile>
                    </configuration>
                    <executions>
                        <execution>
                            <goals>
                                <goal>check</goal>
                            </goals>
                        </execution>
                    </executions>
                </plugin>
                
                <plugin>
                    <groupId>net.revelc.code.formatter</groupId>
                    <artifactId>formatter-maven-plugin</artifactId>
                    <version>${r"${maven-formatter-plugin.version}"}</version>
                    <configuration>
                        <configFile>formatter.xml</configFile>
                    </configuration>
                    <executions>
                        <execution>
                            <goals>
                                <goal>format</goal>
                            </goals>
                        </execution>
                    </executions>
                </plugin>
                
                <plugin>
                    <groupId>net.revelc.code</groupId>
                    <artifactId>impsort-maven-plugin</artifactId>
                    <version>${r"${impsort-maven-plugin.version}"}</version>
                    <configuration>
                        <groups>java.,javax.,jakarta.,org.,com.</groups>
                        <staticGroups>java,javax,jakarta,org,com</staticGroups>
                    </configuration>
                    <executions>
                        <execution>
                            <goals>
                                <goal>sort</goal>
                            </goals>
                        </execution>
                    </executions>
                </plugin>
            </plugins>
        </pluginManagement>
        
        <plugins>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-compiler-plugin</artifactId>
            </plugin>
        </plugins>
    </build>
    
    <profiles>
        <profile>
            <id>quality</id>
            <activation>
                <activeByDefault>true</activeByDefault>
            </activation>
            <build>
                <plugins>
                    <plugin>
                        <groupId>org.apache.maven.plugins</groupId>
                        <artifactId>maven-checkstyle-plugin</artifactId>
                    </plugin>
                    <plugin>
                        <groupId>org.apache.maven.plugins</groupId>
                        <artifactId>maven-pmd-plugin</artifactId>
                    </plugin>
                    <plugin>
                        <groupId>com.github.spotbugs</groupId>
                        <artifactId>spotbugs-maven-plugin</artifactId>
                    </plugin>
                    <plugin>
                        <groupId>net.revelc.code.formatter</groupId>
                        <artifactId>formatter-maven-plugin</artifactId>
                    </plugin>
                    <plugin>
                        <groupId>net.revelc.code</groupId>
                        <artifactId>impsort-maven-plugin</artifactId>
                    </plugin>
                </plugins>
            </build>
        </profile>
    </profiles>
</project> 