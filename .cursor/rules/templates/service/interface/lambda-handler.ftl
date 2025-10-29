package ${basePackage}.handler;

import com.fasterxml.jackson.databind.ObjectMapper;
import io.micrometer.core.instrument.MeterRegistry;
import io.DoorSync.core.interfaces.function.BaseApiGatewayFunction;
import io.DoorSync.core.interfaces.function.BaseAuthenticatedApiGatewayFunction;
import io.DoorSync.core.interfaces.lambda.RequestContext;
<#if requiresAuthentication?? && requiresAuthentication>
import io.DoorSync.core.security.auth.CognitoJwtProcessor;
import io.DoorSync.core.security.authorization.AuthorizationService;
</#if>
<#-- Imports for request/response classes supplied by variables -->
import ${basePackage}.dto.${serviceType}.${requestClassName};
import ${basePackage}.dto.response.${responseClassName};
<#if serviceType == "command">
import ${basePackage?replace(".interfaces", ".application")}.command.${operationName}${resourceName}CommandHandler;
<#else>
import ${basePackage?replace(".interfaces", ".application")}.query.${operationName}${resourceName}QueryHandler;
</#if>
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.stereotype.Component;
import java.util.function.Function;

@Component
<#if serviceType == "command">
<#if requiresAuthentication?? && requiresAuthentication>
class ${operationName}${resourceName}FunctionHandler extends BaseAuthenticatedApiGatewayFunction<${requestClassName}, ${responseClassName}> {
    private final ${operationName}${resourceName}CommandHandler commandHandler;
    public ${operationName}${resourceName}FunctionHandler(ObjectMapper objectMapper, MeterRegistry meterRegistry,
            ${operationName}${resourceName}CommandHandler commandHandler, CognitoJwtProcessor cognitoJwtProcessor,
            AuthorizationService authorizationService) {
        super(objectMapper, ${requestClassName}.class, meterRegistry, cognitoJwtProcessor, authorizationService);
        this.commandHandler = commandHandler;
    }
    @Override protected ${responseClassName} handle(${requestClassName} command, RequestContext requestContext) {
        return commandHandler.handle(command, requestContext);
    }
}
<#else>
class ${operationName}${resourceName}FunctionHandler extends BaseApiGatewayFunction<${requestClassName}, ${responseClassName}> {
    private final ${operationName}${resourceName}CommandHandler commandHandler;
    public ${operationName}${resourceName}FunctionHandler(ObjectMapper objectMapper, MeterRegistry meterRegistry,
            ${operationName}${resourceName}CommandHandler commandHandler) {
        super(objectMapper, ${requestClassName}.class, meterRegistry);
        this.commandHandler = commandHandler;
    }
    @Override protected ${responseClassName} handle(${requestClassName} command, RequestContext requestContext) {
        return commandHandler.handle(command, requestContext);
    }
}
</#if>
<#else>
<#if requiresAuthentication?? && requiresAuthentication>
class ${operationName}${resourceName}FunctionHandler extends BaseAuthenticatedApiGatewayFunction<${requestClassName}, ${responseClassName}> {
    private final ${operationName}${resourceName}QueryHandler queryHandler;
    public ${operationName}${resourceName}FunctionHandler(ObjectMapper objectMapper, MeterRegistry meterRegistry,
            ${operationName}${resourceName}QueryHandler queryHandler, CognitoJwtProcessor cognitoJwtProcessor,
            AuthorizationService authorizationService) {
        super(objectMapper, ${requestClassName}.class, meterRegistry, cognitoJwtProcessor, authorizationService);
        this.queryHandler = queryHandler;
    }
    @Override protected ${responseClassName} handle(${requestClassName} query, RequestContext requestContext) {
        return queryHandler.handle(query, requestContext);
    }
}
<#else>
class ${operationName}${resourceName}FunctionHandler extends BaseApiGatewayFunction<${requestClassName}, ${responseClassName}> {
    private final ${operationName}${resourceName}QueryHandler queryHandler;
    public ${operationName}${resourceName}FunctionHandler(ObjectMapper objectMapper, MeterRegistry meterRegistry,
            ${operationName}${resourceName}QueryHandler queryHandler) {
        super(objectMapper, ${requestClassName}.class, meterRegistry);
        this.queryHandler = queryHandler;
    }
    @Override protected ${responseClassName} handle(${requestClassName} query, RequestContext requestContext) {
        return queryHandler.handle(query, requestContext);
    }
}
</#if>
</#if>

@Configuration
class ${operationName}${resourceName}FunctionConfig {
    @Bean
    Function<com.amazonaws.services.lambda.runtime.events.APIGatewayProxyRequestEvent,
             com.amazonaws.services.lambda.runtime.events.APIGatewayProxyResponseEvent>
    ${operationName?uncap_first}${resourceName}Function(${operationName}${resourceName}FunctionHandler handler) {
        return handler;
    }
}