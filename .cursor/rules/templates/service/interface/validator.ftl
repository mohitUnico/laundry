package ${basePackage}.validator;

<#if serviceType == "command">
import ${basePackage}.dto.command.${operationName}${resourceName}RequestDTO;
<#else>
import ${basePackage}.dto.query.${operationName}${resourceName}RequestDTO;
</#if>
import jakarta.validation.ConstraintValidator;
import jakarta.validation.ConstraintValidatorContext;
import org.springframework.stereotype.Component;

/**
 * Custom validator for ${resourceName} request DTOs.
 */
@Component
<#if serviceType == "command">
public class ${resourceName}Validator implements ConstraintValidator<Valid${resourceName}, ${operationName}${resourceName}RequestDTO> {
<#else>
public class ${resourceName}Validator implements ConstraintValidator<Valid${resourceName}, ${operationName}${resourceName}RequestDTO> {
</#if> {

    @Override
    public void initialize(Valid${resourceName} constraintAnnotation) {
    }

    @Override
<#if serviceType == "command">
    public boolean isValid(${operationName}${resourceName}RequestDTO value, ConstraintValidatorContext context) {
<#else>
    public boolean isValid(${operationName}${resourceName}RequestDTO value, ConstraintValidatorContext context) {
</#if> {
        if (value == null) {
            return true;
        }
        
        context.disableDefaultConstraintViolation();
        
        boolean isValid = true;
        
        <#list validationRules as rule>
        if (${rule.condition}) {
            context.buildConstraintViolationWithTemplate("${rule.message}")
                   .addPropertyNode("${rule.field}")
                   .addConstraintViolation();
            isValid = false;
        }
        
        </#list>
        
        return isValid;
    }
} 