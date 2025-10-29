package ${basePackage}.dto.command;

import io.DoorSync.core.application.dto.command.AbstractCommandDTO;
import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.validation.constraints.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.ToString;
import lombok.experimental.SuperBuilder;

/**
 * Command Request DTO for ${operationName} ${resourceName} operation.
 * Context fields (tenantId, userId, correlationId) are injected via RequestContext.
 */
@Getter
@SuperBuilder
@NoArgsConstructor
@ToString(callSuper = true)
public class ${operationName}${resourceName}RequestDTO extends AbstractCommandDTO {
    
    <#list fields as field>
    /**
     * ${field.description}
     */
    <#if field.required>
    @NotNull(message = "${field.name} is required")
    </#if>
    <#if field.type == "String">
    <#if field.notBlank?? && field.notBlank>
    @NotBlank(message = "${field.name} cannot be blank")
    </#if>
    <#if field.minLength??>
    @Size(min = ${field.minLength}, message = "${field.name} must be at least ${field.minLength} characters")
    </#if>
    <#if field.maxLength??>
    @Size(max = ${field.maxLength}, message = "${field.name} must be at most ${field.maxLength} characters")
    </#if>
    <#if field.pattern??>
    @Pattern(regexp = "${field.pattern}", message = "${field.name} must match pattern ${field.pattern}")
    </#if>
    <#if field.email?? && field.email>
    @Email(message = "${field.name} must be a valid email address")
    </#if>
    </#if>
    <#if field.type == "Integer" || field.type == "Long" || field.type == "Double" || field.type == "Float" || field.type == "BigDecimal">
    <#if field.min??>
    @Min(value = ${field.min}, message = "${field.name} must be at least ${field.min}")
    </#if>
    <#if field.max??>
    @Max(value = ${field.max}, message = "${field.name} must be at most ${field.max}")
    </#if>
    </#if>
    @JsonProperty("${field.name}")
    private ${field.type} ${field.name};
    
    </#list>
}