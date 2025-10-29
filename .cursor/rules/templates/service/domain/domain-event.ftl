package ${packageName}.event;

import io.DoorSync.core.domain.event.AbstractDomainEvent;

import java.time.Instant;
<#if includeJacksonAnnotationsForEvents?? && includeJacksonAnnotationsForEvents>
import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonProperty;
</#if>

/**
 * Domain event: ${aggregateName} ${eventName} Event.
 * Carries only domain facts (aggregateId, occurredAt) and optional attributes.
 */
public final class ${aggregateName}${eventName}Event extends AbstractDomainEvent {

<#list attributes as attr>
    private final ${attr.type} ${attr.name};
</#list>

    <#if includeJacksonAnnotationsForEvents?? && includeJacksonAnnotationsForEvents>
    @JsonCreator
    public ${aggregateName}${eventName}Event(@JsonProperty("aggregateId") String aggregateId,
                                             @JsonProperty("occurredAt") Instant occurredAt<#if attributes?has_content>, </#if><#list attributes as attr>@JsonProperty("${attr.name}") ${attr.type} ${attr.name}<#if attr?has_next>, </#if></#list>) {
    <#else>
    public ${aggregateName}${eventName}Event(String aggregateId, Instant occurredAt<#if attributes?has_content>, </#if><#list attributes as attr>${attr.type} ${attr.name}<#if attr?has_next>, </#if></#list>) {
    </#if>
        super(aggregateId, occurredAt);
<#list attributes as attr>
        this.${attr.name} = ${attr.name};
</#list>
    }

<#list attributes as attr>
    public ${attr.type} get${attr.name?cap_first}() { return ${attr.name}; }
</#list>
}