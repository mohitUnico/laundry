package ${packageName}.mapper;

<#if useMapstruct?? && useMapstruct>
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.MappingTarget;
import org.mapstruct.NullValuePropertyMappingStrategy;
import org.mapstruct.factory.Mappers;
</#if>
import ${packageName}.model.${aggregateName};
import ${packageName}.dto.command.*;
import ${packageName}.dto.query.*;
import ${packageName}.dto.response.*;
import io.DoorSync.core.domain.Page;
import java.util.List;

/**
 * Mapper for converting between ${aggregateName} domain model and DTOs.
 */
<#if useMapstruct?? && useMapstruct>
@Mapper(
    componentModel = "spring",
    nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE
)
public interface ${className} {
<#else>
import org.springframework.stereotype.Component;

@Component
public class ${className} {
</#if>

<#if useMapstruct?? && useMapstruct>
    ${responseName} toResponse(${aggregateName} ${aggregateInstanceLower});
    List<${responseName}> toResponseList(List<${aggregateName}> ${aggregateInstancePluralLower});
    default Page<${responseName}> toPage(Page<${aggregateName}> page) {
        return new Page<>(
            toResponseList(page.items()),
            page.nextToken()
        );
    }
    </#if>

    <#if hasCreateCommand>
    <#if useMapstruct?? && useMapstruct>
    @Mapping(target = "id", ignore = true)
    ${aggregateName} toDomain(Create${aggregateName}Command command);
    </#if>
    </#if>

    <#if hasUpdateCommand>
    <#if useMapstruct?? && useMapstruct>
    @Mapping(target = "id", ignore = true)
    ${aggregateName} updateFromCommand(Update${aggregateName}Command command, @MappingTarget ${aggregateName} ${aggregateInstanceLower});
    </#if>
    </#if>

    <#if hasCreatedResponse>
    <#if useMapstruct?? && useMapstruct>
    ${aggregateName}CreatedResponse toCreatedResponse(${aggregateName} ${aggregateInstanceLower});
    </#if>
    </#if>
}