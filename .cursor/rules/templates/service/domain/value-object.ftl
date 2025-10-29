package ${packageName}.model;

import io.DoorSync.core.domain.BaseValueObject;
import io.DoorSync.core.domain.validation.ValidationResult;
import lombok.Getter;
import lombok.ToString;

import java.util.Objects;

/**
 * Value object representing ${voName} in the domain.
 * <p>
 * Value objects are immutable, have no identity, and are defined by their attributes.
 * This value object extends BaseValueObject from DoorSync-core which provides
 * proper value object semantics and equality behavior.
 */
@Getter
@ToString
public final class ${voName} extends BaseValueObject<${voName}> {

<#list attributes as attr>
    private final ${attr.type} ${attr.name};
</#list>

    /**
     * Constructor for ${voName}.
     * 
<#list attributes as attr>
     * @param ${attr.name} The ${attr.name} of this value object
</#list>
     */
    public ${voName}(<#list attributes as attr>${attr.type} ${attr.name}<#if attr?has_next>, </#if></#list>) {
<#list attributes as attr>
        this.${attr.name} = Objects.requireNonNull(${attr.name}, "${attr.name} cannot be null");
</#list>
        
        // Validate the value object using ValidationResult
        ValidationResult validation = validate();
        validation.throwIfInvalid();
    }

    /**
     * Validate the value object invariants using ValidationResult.
     * 
     * @return ValidationResult containing any validation errors
     */
    private ValidationResult validate() {
        ValidationResult result = new ValidationResult("${voName} validation failed");
        
        // Add validation rules here
<#list attributes as attr>
<#if attr.validations??>
<#list attr.validations as validation>
        ${validation}
</#list>
</#if>
</#list>
        
        return result;
    }

    /**
     * Check equality between this value object and another instance.
     * Implementation of the abstract method from BaseValueObject.
     *
     * @param other the other value object to compare with
     * @return true if all attributes are equal, false otherwise
     */
    @Override
    protected boolean isEqualTo(${voName} other) {
<#list attributes as attr>
        if (!Objects.equals(this.${attr.name}, other.${attr.name})) {
            return false;
        }
</#list>
        return true;
    }

    /**
     * Compute a hash code from all attributes.
     *
     * @return the hash code
     */
    @Override
    public int hashCode() {
        return Objects.hash(<#list attributes as attr>${attr.name}<#if attr?has_next>, </#if></#list>);
    }

<#if factoryMethods??>
<#list factoryMethods as factory>
    /**
     * ${factory.description}
     *
<#list factory.params as param>
     * @param ${param.name} ${param.description}
</#list>
     * @return A new ${voName} instance
     * @throws io.DoorSync.core.domain.exception.DomainValidationException if validation fails
     */
    public static ${voName} ${factory.name}(<#list factory.params as param>${param.type} ${param.name}<#if param?has_next>, </#if></#list>) {
        ${factory.code}
    }

</#list>
</#if>
<#if methods??>
<#list methods as method>
    /**
     * ${method.description}
     *
<#list method.params as param>
     * @param ${param.name} ${param.description}
</#list>
     * @return ${method.returnDescription}
     */
    public ${method.returnType} ${method.name}(<#list method.params as param>${param.type} ${param.name}<#if param?has_next>, </#if></#list>) {
        ${method.code}
    }

</#list>
</#if>
} 