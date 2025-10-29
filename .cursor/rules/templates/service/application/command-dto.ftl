package ${packageName}.dto.command;

import io.DoorSync.core.application.dto.command.AbstractCommandDTO;
<#if hasCustomValidation?? && hasCustomValidation>
import io.DoorSync.core.application.validation.Validateable;
import io.DoorSync.core.application.exception.ValidationException;
</#if>
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.ToString;
import lombok.experimental.SuperBuilder;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
<#if additionalImports??>
<#list additionalImports as import>
import ${import};
</#list>
</#if>

/**
 * ${commandDescription}
 */
<#-- Only add @Getter when properties exist -->
<#if properties?? && (properties?size > 0)>
@Getter
<#else>
<#-- No fields; skip @Getter to match minimal DTOs -->
</#if>
@SuperBuilder
@NoArgsConstructor
@ToString(callSuper = true)
public class ${className} extends AbstractCommandDTO<#if hasCustomValidation?? && hasCustomValidation> implements Validateable</#if> {

    <#if properties??>
    <#list properties as property>
    /**
     * ${property.description}
     */
    <#if property.validation??>
    <#list property.validation as validation>
    ${validation}
    </#list>
    </#if>
    private ${property.type} ${property.name};
    
    </#list>
    </#if>

<#if hasCustomValidation?? && hasCustomValidation>
    @Override
    public void validate() throws ValidationException {
        <#if customValidationRules??>
        <#list customValidationRules as rule>
        if (${rule.condition}) {
            throw new ValidationException("${rule.errorMessage}", "${rule.errorCode}");
        }
        </#list>
        <#else>
        // no-op: no additional business rules
        </#if>
    }
</#if>
} 