package ${basePackage}.dto.response;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;
import java.util.UUID;

/** Response DTO envelope. */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@JsonInclude(JsonInclude.Include.NON_NULL)
public class ${responseClassName} {

    /** The response data object or collection. */
    @JsonProperty("data")
    private ${dataType} data;
    
    /** Metadata about the response. */
    @JsonProperty("metadata")
    private ResponseMetadata metadata;

    <#list fields as field>
    /** ${field.description!""} */
    @JsonProperty("${field.name}")
    private ${field.type} ${field.name};
    </#list>
    
    <#if isPaginatedResponse>
    <#if paginationStyle?? && paginationStyle == "cursor">
    /** Opaque cursor for fetching the next page of results. */
    @JsonProperty("nextCursor")
    private String nextCursor;
    <#else>
    /** Total number of results available for the query. */
    @JsonProperty("totalCount")
    private Long totalCount;

    /** The current offset used for the query. */
    @JsonProperty("offset")
    private Integer offset;

    /** The limit (page size) used for the query. */
    @JsonProperty("limit")
    private Integer limit;
    </#if>
    </#if>
    
    /** Metadata about the response. */
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ResponseMetadata {
        /** The ID of the request that generated this response. */
        @JsonProperty("requestId")
        private UUID requestId;
        /** The timestamp when the response was created. */
        @JsonProperty("timestamp")
        private Instant timestamp;
        /** The correlation ID for request tracing. */
        @JsonProperty("correlationId")
        private String correlationId;
    }
} 