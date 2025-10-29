package ${packageName}.service;

<#if hasProcessManager>
import io.DoorSync.core.application.process.ProcessManager;
</#if>
<#if hasDtoImports>
import ${packageName}.dto.${dtoPackage}.*;
</#if>
<#if hasMapper>
import ${packageName}.mapper.${mapperName};
</#if>
import ${packageName}.model.${aggregateName};
import ${packageName}.service.${aggregateName}Service;
<#if additionalImports??>
<#list additionalImports as import>
import ${import};
</#list>
</#if>
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import lombok.extern.slf4j.Slf4j;

/**
 * Optional application service for ${aggregateName} orchestration.
 * Prefer handlers; introduce services only when reusing orchestration across handlers/edges.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class ${serviceName} {
	private final ${aggregateName}Service domainService;
	<#if hasMapper>
	private final ${mapperName} mapper;
	</#if>
<#if hasProcessManager>
    // Prefer a factory to create per-execution process managers; do not inject a singleton
    // private final ProcessManagerFactory processManagerFactory;
    </#if>
	<#if additionalDependencies??>
	<#list additionalDependencies as dependency>
	private final ${dependency.type} ${dependency.name};
	</#list>
	</#if>

	<#if methods??>
	<#list methods as method>
	public ${method.returnType} ${method.name}(<#list method.parameters as param>${param.type} ${param.name}<#if param_has_next>, </#if></#list>) {
		<#if method.implementation?has_content>
		${method.implementation}
		<#else>
		return null;
		</#if>
	}
	</#list>
	</#if>
} 