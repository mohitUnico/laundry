package ${packageName}.infrastructure.mapper;

import ${packageName}.domain.${entityName};
import ${packageName}.infrastructure.model.${entityName}Model;
import io.DoorSync.core.infrastructure.persistence.ModelMapper;
import org.springframework.stereotype.Component;

/**
 * Mapper implementing the core ModelMapper interface.
 */
@Component
public class ${className} implements ModelMapper<${entityName}Model, ${entityName}> {

    @Override
    public ${entityName} toAggregate(${entityName}Model model) {
        // TODO: map model -> aggregate using domain factory methods
        throw new UnsupportedOperationException("Implement ${entityName}Model -> ${entityName} mapping");
    }

    @Override
    public ${entityName}Model toModel(${entityName} aggregate) {
        // TODO: map aggregate -> model; ensure model.setEntityType("${entityName}")
        throw new UnsupportedOperationException("Implement ${entityName} -> ${entityName}Model mapping");
    }
}