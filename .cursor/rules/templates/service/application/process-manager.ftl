package ${packageName}.process;

import io.DoorSync.core.application.process.ProcessManager;
import io.DoorSync.core.application.observability.AppLogger;
import io.DoorSync.core.application.observability.AppMetrics;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

<#if dependencies??>
<#list dependencies as dependency>
import ${dependency.importPath};
</#list>
</#if>

/**
 * Process manager for ${processDescription}.
 */
@Slf4j
public class ${className} extends ProcessManager {

    <#if dependencies??>
    <#list dependencies as dependency>
    private final ${dependency.type} ${dependency.name};
    </#list>
    </#if>

    private ${className}(String correlationId, AppLogger appLogger, AppMetrics appMetrics<#if dependencies??><#list dependencies as dependency>,
            ${dependency.type} ${dependency.name}</#list></#if>) {
        super(correlationId, appLogger, appMetrics);
        <#if dependencies??>
        <#list dependencies as dependency>
        this.${dependency.name} = ${dependency.name};
        </#list>
        </#if>
    }

    public static ${className} create(String correlationId, AppLogger appLogger, AppMetrics appMetrics<#if dependencies??><#list dependencies as dependency>, ${dependency.type} ${dependency.name}</#list></#if>) {
        return new ${className}(correlationId, appLogger, appMetrics<#if dependencies??><#list dependencies as dependency>, ${dependency.name}</#list></#if>);
    }

    @Override
    protected void execute() throws Exception {
        log.info("Executing ${processDescription} process with correlation ID: {}", getCorrelationId());

        <#if processSteps??>
        <#list processSteps as step>
        // Step ${step_index + 1}: ${step.description}
        ${step.methodName}();
        </#list>
        </#if>

        log.info("${processDescription} process completed successfully");
    }

    <#if processSteps??>
    <#list processSteps as step>
    private void ${step.methodName}() throws Exception {
        log.debug("Executing step: ${step.description}");
        <#if step.implementation??>
        ${step.implementation}
        <#else>
        // No-op: step has no implementation defined
        </#if>
    }

    </#list>
    </#if>
}