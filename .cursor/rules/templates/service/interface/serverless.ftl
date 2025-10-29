service: ${serviceName}

frameworkVersion: '3'

provider:
  name: aws
  runtime: java17
  region: ${region}
  stage: ${stage}
  logRetentionInDays: 14
  environment:
    DOORSYNC_LOG_LEVEL: ${logLevel}
    DOORSYNC_METRICS_NAMESPACE: ${metricsNamespace}
    DOORSYNC_TRACING_ENABLED: ${tracingEnabled}
    DOORSYNC_TENANT_CLAIM: ${tenantClaim}
    DOORSYNC_TENANT_REQUIRE_CLAIM: ${tenantRequireClaim!true}
    DOORSYNC_TENANT_ALLOW_HEADER_OVERRIDE: ${tenantAllowHeaderOverride!false}
    DOORSYNC_CURSOR_TTL_HOURS: ${cursorTtlHours}
    DOORSYNC_CURSOR_HMAC_KID: ${cursorHmacKid}
    DOORSYNC_CURSOR_HMAC_SECRET: ${cursorHmacSecret}
    DOORSYNC_TENANT_SUSPEND_LIST: ${tenantSuspendList!""}
    DOORSYNC_LOG_JSON_ENABLED: ${logJsonEnabled!true}
    DOORSYNC_OBSERVABILITY_REDACTION: ${observabilityRedaction!"standard"}
    DOORSYNC_OBSERVABILITY_DIM_TENANT_ENABLED: ${observabilityDimTenantEnabled!true}

package:
  artifact: target/${serviceName}-interfaces-0.0.1-SNAPSHOT-aws.jar

functions:
<#list functions as function>
  ${function.name}:
    handler: org.springframework.cloud.function.adapter.aws.FunctionInvoker::handleRequest
    memorySize: ${function.memory}
    timeout: ${function.timeout}
    events:
      - http:
          path: ${function.path}
          method: ${function.method}
          cors: true
          authorizer: ${function.authorizer!"none"}
    environment:
      SPRING_CLOUD_FUNCTION_DEFINITION: ${function.beanName}
      SPRING_CLOUD_FUNCTION_SCAN_PACKAGES: ${basePackage}
      SPRING_MAIN_WEB_APPLICATION_TYPE: none
      <#list function.env as env>
      ${env.key}: ${env.value}
      </#list>
    tags:
      Service: ${serviceName}
      Function: ${function.name}
      Stage: ${stage}

</#list>