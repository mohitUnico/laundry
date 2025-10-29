package ${packageName}.dto.response;

import lombok.Builder;
import lombok.Value;
import java.time.Instant;
<#if additionalImports??>
<#list additionalImports as import>
import ${import};
</#list>
</#if>

/**
 * Response DTO for ${responsePurpose}.
 * This class is immutable and used to transfer data from the application layer to the interface layer.
 */
@Value
@Builder
public class ${className} {

    /**
     * The unique identifier for the ${resourceName}.
     */
    String id;
    
    <#if includeAuditFields>
    /**
     * Timestamp when the ${resourceName} was created.
     */
    Instant createdAt;
    
    /**
     * User who created the ${resourceName}.
     */
    String createdBy;
    
    /**
     * Timestamp when the ${resourceName} was last modified.
     */
    Instant lastModifiedAt;
    
    /**
     * User who last modified the ${resourceName}.
     */
    String lastModifiedBy;
    </#if>

    <#if properties??>
    <#list properties as property>
    /**
     * ${property.description}
     */
    ${property.type} ${property.name};
    
    </#list>
    </#if>
} 