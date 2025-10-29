package ${basePackage}.dto.query;

import io.DoorSync.core.application.dto.query.AbstractQueryDTO;
import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.validation.constraints.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.ToString;
import lombok.experimental.SuperBuilder;

import java.util.Map;

/**
 * Query Request DTO for ${operationName} ${resourceName}.
 * Context fields are injected from RequestContext by the edge.
 */
@Getter
@SuperBuilder
@NoArgsConstructor
@ToString(callSuper = true)
public class ${operationName}${resourceName}RequestDTO extends AbstractQueryDTO {
    
    <#if supportsFiltering?? && supportsFiltering>
    /**
     * Flexible filter criteria for the query.
     */
    @JsonProperty("filters")
    private Map<String, Object> filters;
    </#if>
    
    <#list fields as field>
    /** ${field.description} */
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

    <#if supportsPagination?? && supportsPagination>
    <#if paginationStyle?? && paginationStyle == "cursor">
    /** Opaque cursor for pagination. */
    @JsonProperty("cursor")
    private String cursor;

    /** Page size limit. */
    @Min(value = 1, message = "limit must be at least 1")
    @Max(value = 200, message = "limit must be at most 200")
    @JsonProperty("limit")
    private Integer limit;
    <#else>
    /** Offset-based pagination: number of records to skip. */
    @Min(value = 0, message = "offset must be non-negative")
    @JsonProperty("offset")
    private Integer offset;

    /** Offset-based pagination: max records to return. */
    @Min(value = 1, message = "limit must be at least 1")
    @Max(value = 200, message = "limit must be at most 200")
    @JsonProperty("limit")
    private Integer limit;
    </#if>
    </#if>
} 