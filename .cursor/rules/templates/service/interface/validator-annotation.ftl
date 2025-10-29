package ${basePackage}.validator;

import jakarta.validation.Constraint;
import jakarta.validation.Payload;

import java.lang.annotation.*;

/**
 * Custom validation constraint for ${resourceName} requests.
 * <p>
 * This annotation is used to apply complex validation rules that cannot be expressed
 * using standard validation annotations.
 */
@Documented
@Constraint(validatedBy = ${resourceName}Validator.class)
@Target({ElementType.TYPE, ElementType.ANNOTATION_TYPE})
@Retention(RetentionPolicy.RUNTIME)
public @interface Valid${resourceName} {

    /**
     * Error message to be displayed when validation fails.
     */
    String message() default "Invalid ${resourceName} request";

    /**
     * Groups that this constraint belongs to.
     * Default is an empty array.
     */
    Class<?>[] groups() default {};

    /**
     * Payload with additional validation metadata.
     * Default is an empty array.
     */
    Class<? extends Payload>[] payload() default {};
} 