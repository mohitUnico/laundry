package ${packageName}.handler.command;

import io.DoorSync.core.application.command.BaseCommandHandler;
import io.DoorSync.core.application.observability.AppLogger;
import io.DoorSync.core.application.observability.AppMetrics;
import io.DoorSync.core.interfaces.lambda.RequestContext;
import lombok.extern.slf4j.Slf4j;
import ${packageName}.dto.command.${commandName};
<#if hasResponse>
import ${packageName}.dto.response.${responseName};
</#if>
<#if hasMapper>
import ${packageName}.mapper.${mapperName};
</#if>
import ${packageName}.model.${aggregateName};
import ${packageName}.model.${aggregateName}Id;
import ${packageName}.service.${aggregateName}Service;
import jakarta.validation.Validator;
import org.springframework.stereotype.Component;
import java.time.Instant;
import io.DoorSync.core.application.exception.NotFoundException;

/**
 * Command handler for ${commandName}.
 */
@Slf4j
@Component
public class ${className} extends BaseCommandHandler<${commandName}, <#if hasResponse>${responseName}<#else>Void</#if>> {

    private final ${aggregateName}Service domainService;
    <#if hasMapper>
    private final ${mapperName} mapper;
    </#if>
    <#if additionalDependencies??>
    <#list additionalDependencies as dependency>
    private final ${dependency.type} ${dependency.name};
    </#list>
    </#if>

    public ${className}(
            Validator validator,
            AppLogger appLogger,
            AppMetrics appMetrics,
            ${aggregateName}Service domainService<#if hasMapper>,
            ${mapperName} mapper</#if><#if additionalDependencies??><#list additionalDependencies as dependency>,
            ${dependency.type} ${dependency.name}</#list></#if>) {
        super(validator, appLogger, appMetrics);
        this.domainService = domainService;
        <#if hasMapper>
        this.mapper = mapper;
        </#if>
        <#if additionalDependencies??>
        <#list additionalDependencies as dependency>
        this.${dependency.name} = ${dependency.name};
        </#list>
        </#if>
    }

    @Override
    protected <#if hasResponse>${responseName}<#else>Void</#if> executeCommand(${commandName} command, RequestContext requestContext) {
        log.debug("Handling ${commandName}: {}", command);

        <#if hasImplementation?? && hasImplementation>
        ${implementationCode}
        <#else>
        <#if isCreateCommand?? && isCreateCommand>
        // Create aggregate
        ${aggregateName} ${aggregateInstance} = <#if useAggregateFactory?? && useAggregateFactory>
            ${aggregateName}.create(
                <#if factoryParams??>
                <#list factoryParams as param>
                ${param}<#if param_has_next>,</#if>
                </#list>
                </#if>
            )
        <#else>
            <#if hasMapper>mapper.toDomain(command)<#else>/* map command to domain */ null</#if>
        </#if>;
        ${aggregateName} saved = domainService.create(${aggregateInstance}, Instant.now());
        log.info("Created new ${aggregateName} with ID: {}", saved.id());
        <#if hasResponse>
        <#-- Support configurable create return type -->
        <#if createReturnType?? && createReturnType == 'CreatedResponse'>
        return <#if hasMapper>mapper.toCreatedResponse(saved)<#else>${responseName}.builder().build()</#if>;
        <#elseif createReturnType?? && createReturnType == 'Void'>
        return null;
        <#else>
        return <#if hasMapper>mapper.toResponse(saved)<#else>${responseName}.builder().build()</#if>;
        </#if>
        <#else>
        return null;
        </#if>
        <#elseif isUpdateCommand?? && isUpdateCommand>
        // Load, apply updates, and persist via domain service
        ${aggregateName}Id id = ${aggregateName}Id.fromString(<#if idAccessorExpr??>${idAccessorExpr}<#else>command.getId()</#if>);
        ${aggregateName} existing = domainService.get(id)
            .orElseThrow(() -> new NotFoundException("${aggregateName} not found with ID: " + command.getId()));
        <#if useAggregateUpdateMethod?? && useAggregateUpdateMethod>
        existing.update(
            <#if updateParams??>
            <#list updateParams as param>
            ${param}<#if param_has_next>,</#if>
            </#list>
            </#if>
        );
        <#elseif hasMapper>
        mapper.updateFromCommand(command, existing);
        </#if>
        ${aggregateName} saved = domainService.update(existing);
        <#if hasResponse>
        return <#if hasMapper>mapper.toResponse(saved)<#else>${responseName}.builder().build()</#if>;
        <#else>
        return null;
        </#if>
        <#elseif isDeleteCommand?? && isDeleteCommand>
        // Delete via domain service
        ${aggregateName}Id id = ${aggregateName}Id.fromString(<#if idAccessorExpr??>${idAccessorExpr}<#else>command.getId()</#if>);
        domainService.delete(id);
        return null;
        <#else>
        log.debug("No-op path for ${commandName} (non-CRUD). Returning without side effects.");
        return null;
        </#if>
        </#if>
    }

    <#if hasCustomValidation?? && hasCustomValidation>
    @Override
    protected void performCustomValidation(${commandName} command) {
        ${validationCode}
    }
    </#if>
}