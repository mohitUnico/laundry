package ${packageName}.validator;

import jakarta.validation.ConstraintValidator;
import jakarta.validation.ConstraintValidatorContext;
import jakarta.validation.Payload;
import jakarta.validation.Constraint;
import java.lang.annotation.Documented;
import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * Validation annotation to validate ${validationTarget}.
 */
@Documented
@Constraint(validatedBy = ${className}.Validator.class)
@Target({ ElementType.FIELD, ElementType.PARAMETER })
@Retention(RetentionPolicy.RUNTIME)
public @interface ${className} {
    
    /**
     * Error message to be displayed when validation fails.
     */
    String message() default "Invalid ${validationTarget}";
    
    /**
     * Validation groups this constraint belongs to.
     */
    Class<?>[] groups() default {};
    
    /**
     * Payload data for this constraint.
     */
    Class<? extends Payload>[] payload() default {};

    /**
     * Validator implementation for ${className} annotation.
     */
    class Validator implements ConstraintValidator<${className}, ${validatedType}> {
        
        @Override
        public void initialize(${className} constraintAnnotation) {}
        
        @Override
        public boolean isValid(${validatedType} value, ConstraintValidatorContext context) {
            if (value == null) {
                return true;
            }
            
            <#if validationLogic??>
            ${validationLogic}
            <#else>
            return true;
            </#if>
        }
    }
} 