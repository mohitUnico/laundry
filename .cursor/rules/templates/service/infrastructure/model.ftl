package ${packageName}.infrastructure.model;

import software.amazon.awssdk.enhanced.dynamodb.mapper.annotations.DynamoDbBean;
import software.amazon.awssdk.enhanced.dynamodb.mapper.annotations.DynamoDbAttribute;
import io.DoorSync.core.infrastructure.persistence.BoundedContextModel;
import lombok.Getter;
import lombok.Setter;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import lombok.experimental.SuperBuilder;
import java.io.Serializable;

/**
 * DynamoDB storage model for ${entityName}. Keys and audit fields are handled by table operations.
 */
@Getter
@Setter
@SuperBuilder
@NoArgsConstructor
@AllArgsConstructor
@DynamoDbBean
public class ${className} extends BoundedContextModel implements Serializable {

    // BoundedContextModel already provides id, tenantId, audit fields, version, active

    // Domain-specific attributes
    <#if fields??>
    <#list fields as field>
    private ${field.type} ${field.name};
    </#list>
    <#else>
    // TODO: add domain attributes (e.g., name, description, etc.)
    </#if>

    // Base getters inherited; only domain attributes below
}