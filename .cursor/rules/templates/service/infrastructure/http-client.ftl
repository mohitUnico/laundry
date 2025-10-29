package ${packageName}.client;

import io.DoorSync.core.infrastructure.exception.InfrastructureException;
import io.DoorSync.core.infrastructure.exception.ExternalServiceException;
import io.DoorSync.core.interfaces.lambda.RequestContext;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.reactive.function.client.WebClientResponseException;
import reactor.core.publisher.Mono;
import reactor.util.retry.Retry;
import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.Timer;

import java.time.Duration;
import java.util.concurrent.TimeoutException;

/**
 * HTTP client for interacting with the ${externalServiceName} external service.
 * Uses standard WebClient patterns with proper error handling, retries, and metrics.
 */
@Slf4j
@Component
public class ${className} {

    private final WebClient webClient;
    private final MeterRegistry meterRegistry;
    
    <#if hasEndpoints??>
    <#list endpoints as endpoint>
    private static final String ${endpoint.name?upper_case}_PATH = "${endpoint.path}";
    </#list>
    <#else>
    // TODO: Define API endpoint paths here
    // private static final String EXAMPLE_PATH = "/api/v1/example";
    </#if>

    /**
     * Constructor that initializes the WebClient with the service base URL.
     * 
     * @param baseUrl The base URL for the ${externalServiceName} service
     * @param meterRegistry The meter registry for metrics collection
     */
    public ${className}(
            @Value("${${externalServiceName?lower_case}.api.url}") String baseUrl,
            MeterRegistry meterRegistry) {
        this.meterRegistry = meterRegistry;
        this.webClient = WebClient.builder()
                .baseUrl(baseUrl)
                .defaultHeader("Content-Type", "application/json")
                .defaultHeader("Accept", "application/json")
                <#if hasDefaultHeaders??>
                <#list defaultHeaders as header>
                .defaultHeader("${header.name}", "${header.value}")
                </#list>
                </#if>
                .build();
        
        log.info("Initialized ${className} with base URL: {}", baseUrl);
    }

    <#if hasEndpoints??>
    <#list endpoints as endpoint>
    /**
     * ${endpoint.description!"Calls the " + endpoint.name + " endpoint"}.
     * 
     * @param requestContext The request context for tenant and correlation information
     * @param request The request payload
     * @return The response from the ${externalServiceName} service
     * @throws ExternalServiceException if the service call fails
     */
    public <T, R> R ${endpoint.name}(RequestContext requestContext, T request, Class<R> responseType) {
        Timer.Sample timer = Timer.start(meterRegistry);
        
        try {
            log.debug("Calling ${externalServiceName} ${endpoint.name} endpoint for tenant: {}", 
                    requestContext.getTenantId());
            
            R response = webClient
                    .${endpoint.method?lower_case}()
                    .uri(${endpoint.name?upper_case}_PATH)
                    .header("X-Tenant-Id", requestContext.getTenantId())
                    .header("X-Correlation-Id", requestContext.getCorrelationId())
                    <#if endpoint.method?upper_case == "POST" || endpoint.method?upper_case == "PUT">
                    .bodyValue(request)
                    </#if>
                    .retrieve()
                    .bodyToMono(responseType)
                    .timeout(Duration.ofSeconds(30))
                    .retryWhen(Retry.backoff(3, Duration.ofMillis(500))
                            .filter(throwable -> !(throwable instanceof WebClientResponseException.BadRequest)))
                    .block();
            
            timer.stop(Timer.builder("http.client.request")
                    .tag("service", "${externalServiceName}")
                    .tag("endpoint", "${endpoint.name}")
                    .tag("status", "success")
                    .register(meterRegistry));
            
            log.debug("Successfully called ${externalServiceName} ${endpoint.name} endpoint");
            return response;
            
        } catch (WebClientResponseException e) {
            timer.stop(Timer.builder("http.client.request")
                    .tag("service", "${externalServiceName}")
                    .tag("endpoint", "${endpoint.name}")
                    .tag("status", "error")
                    .tag("error_type", "client_error")
                    .register(meterRegistry));
            
            log.error("Client error calling ${externalServiceName} ${endpoint.name}: {} - {}", 
                    e.getStatusCode(), e.getResponseBodyAsString(), e);
            throw new ExternalServiceException(
                    String.format("Client error calling ${externalServiceName} ${endpoint.name}: %s", 
                            e.getStatusCode()), e);
                            
        } catch (Exception e) {
            timer.stop(Timer.builder("http.client.request")
                    .tag("service", "${externalServiceName}")
                    .tag("endpoint", "${endpoint.name}")
                    .tag("status", "error")
                    .tag("error_type", "unexpected")
                    .register(meterRegistry));
            
            if (e.getCause() instanceof TimeoutException) {
                log.error("Timeout calling ${externalServiceName} ${endpoint.name}", e);
                throw new ExternalServiceException(
                        "Timeout calling ${externalServiceName} ${endpoint.name}", e);
            }
            
            log.error("Unexpected error calling ${externalServiceName} ${endpoint.name}", e);
            throw new InfrastructureException(
                    String.format("Failed to call ${externalServiceName} ${endpoint.name}: %s", 
                            e.getMessage()), e);
        }
    }
    </#list>
    <#else>
    /**
     * Example method for calling an external service endpoint.
     * Replace with actual service-specific methods.
     * 
     * @param requestContext The request context for tenant and correlation information
     * @param request The request payload
     * @param responseType The expected response type
     * @return The response from the external service
     * @throws ExternalServiceException if the service call fails
     */
    public <T, R> R callExternalService(RequestContext requestContext, T request, Class<R> responseType) {
        Timer.Sample timer = Timer.start(meterRegistry);
        
        try {
            log.debug("Calling ${externalServiceName} service for tenant: {}", 
                    requestContext.getTenantId());
            
            R response = webClient
                    .post()
                    .uri("/api/v1/example") // TODO: Replace with actual endpoint path
                    .header("X-Tenant-ID", requestContext.getTenantId())
                    .header("X-Correlation-ID", requestContext.getCorrelationId())
                    .bodyValue(request)
                    .retrieve()
                    .bodyToMono(responseType)
                    .timeout(Duration.ofSeconds(30))
                    .retryWhen(Retry.backoff(3, Duration.ofMillis(500))
                            .filter(throwable -> !(throwable instanceof WebClientResponseException.BadRequest)))
                    .block();
            
            timer.stop(Timer.builder("http.client.request")
                    .tag("service", "${externalServiceName}")
                    .tag("endpoint", "example")
                    .tag("status", "success")
                    .register(meterRegistry));
            
            log.debug("Successfully called ${externalServiceName} service");
            return response;
            
        } catch (WebClientResponseException e) {
            timer.stop(Timer.builder("http.client.request")
                    .tag("service", "${externalServiceName}")
                    .tag("endpoint", "example")
                    .tag("status", "error")
                    .tag("error_type", "client_error")
                    .register(meterRegistry));
            
            log.error("Client error calling ${externalServiceName}: {} - {}", 
                    e.getStatusCode(), e.getResponseBodyAsString(), e);
            throw new ExternalServiceException(
                    String.format("Client error calling ${externalServiceName}: %s", 
                            e.getStatusCode()), e);
                            
        } catch (Exception e) {
            timer.stop(Timer.builder("http.client.request")
                    .tag("service", "${externalServiceName}")
                    .tag("endpoint", "example")
                    .tag("status", "error")
                    .tag("error_type", "unexpected")
                    .register(meterRegistry));
            
            if (e.getCause() instanceof TimeoutException) {
                log.error("Timeout calling ${externalServiceName}", e);
                throw new ExternalServiceException(
                        "Timeout calling ${externalServiceName}", e);
            }
            
            log.error("Unexpected error calling ${externalServiceName}", e);
            throw new InfrastructureException(
                    String.format("Failed to call ${externalServiceName}: %s", 
                            e.getMessage()), e);
        }
    }
    </#if>
} 