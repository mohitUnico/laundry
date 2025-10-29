package ${packageName}.infrastructure.config;

import ${packageName}.domain.*;
import ${packageName}.domain.repository.*;
import ${packageName}.infrastructure.model.*;
import ${packageName}.infrastructure.mapper.*;
import ${packageName}.infrastructure.translator.*;
import ${packageName}.infrastructure.factory.*;
import io.DoorSync.core.infrastructure.persistence.TableOperations;
import io.DoorSync.core.infrastructure.persistence.QueryOperations;
import io.DoorSync.core.infrastructure.persistence.QueryResult;
import io.DoorSync.core.infrastructure.persistence.QueryTranslator;
import io.DoorSync.core.infrastructure.persistence.factory.RepositoryRegistry;
import io.DoorSync.core.domain.event.DomainEventPublisher;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.beans.factory.InitializingBean;

@Configuration
public class ${className} {

    <#list domainEntities as entity>
    @Bean
    public QueryTranslator<${entity}, Object> ${entity?lower_case}QueryTranslator() {
        return new ${entity}QueryTranslator();
    }

    @Bean
    public ${entity}RepositoryFactory ${entity?lower_case}RepositoryFactory(
        TableOperations<${entity}Model, ${entity}Id> tableOps,
        ${entity}ModelMapper mapper,
        QueryTranslator<${entity}, Object> translator,
        QueryOperations<Object, QueryResult<${entity}>> queryOps,
        DomainEventPublisher eventPublisher
    ) {
        return new ${entity}RepositoryFactory(tableOps, mapper, translator, queryOps, eventPublisher);
    }
    </#list>

    @Bean
    public InitializingBean registerRepositoryFactories(
        RepositoryRegistry registry,
        <#list domainEntities as entity>
        ${entity}RepositoryFactory ${entity?lower_case}Factory<#if entity?has_next>,</#if>
        </#list>
    ) {
        return () -> {
            <#list domainEntities as entity>
            registry.registerRepositoryFactory(${entity}Repository.class, ${entity?lower_case}Factory);
            </#list>
        };
    }
}