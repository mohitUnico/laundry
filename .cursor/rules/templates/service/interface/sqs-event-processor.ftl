package ${basePackage}.handler;

import com.fasterxml.jackson.databind.ObjectMapper;
import io.micrometer.core.instrument.MeterRegistry;
import io.DoorSync.core.interfaces.lambda.AbstractEventProcessor;
import io.DoorSync.core.interfaces.lambda.EventProcessingContext;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

/**
 * SQS Event Processor for ${resourceName} integration events.
 *
 * Registers event handlers and processes messages using DoorSync-core base classes.
 */
@Slf4j
@Component
public final class ${resourceName}EventProcessor extends AbstractEventProcessor {

    public ${resourceName}EventProcessor(ObjectMapper mapper, MeterRegistry registry) {
        super(mapper, registry);
    }

    @Override
    protected void registerEventHandlers() {
        // Example registration:
        // registerEventHandler("${resourceName}CreatedEvent", ${resourceName}CreatedEvent.class, this::on${resourceName}Created);
    }

    // Example handler method
    // private void on${resourceName}Created(${resourceName}CreatedEvent event, EventProcessingContext ctx) {
    //     // delegate to application service
    // }
}


