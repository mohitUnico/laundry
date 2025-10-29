package ${packageName}.model;

import java.util.Arrays;
import java.util.Optional;
import lombok.Getter;

/**
 * Enumeration representing the possible ${enumName} values in the domain.
 * <p>
 * This enum is used to represent a fixed set of valid values for ${enumDescription}.
 */
@Getter
public enum ${enumName} {
    <#list enumValues as value>
    /**
     * ${value.description}
     */
    ${value.name}("${value.code}", "${value.displayName}")<#if value?has_next>,<#else>;</#if>
    </#list>

    private final String code;
    private final String displayName;

    ${enumName}(String code, String displayName) {
        this.code = code;
        this.displayName = displayName;
    }

    /**
     * Find a ${enumName} by its code using Optional for null safety.
     *
     * @param code The code to look up
     * @return Optional containing the matching ${enumName}, or empty if not found
     */
    public static Optional<${enumName}> fromCode(String code) {
        if (code == null || code.trim().isEmpty()) {
            return Optional.empty();
        }
        
        return Arrays.stream(values())
                .filter(value -> value.getCode().equals(code))
                .findFirst();
    }

    /**
     * Find a ${enumName} by its code, throwing exception if not found.
     *
     * @param code The code to look up
     * @return The matching ${enumName}
     * @throws IllegalArgumentException if code is invalid
     */
    public static ${enumName} fromCodeRequired(String code) {
        return fromCode(code)
                .orElseThrow(() -> new IllegalArgumentException("Invalid ${enumName} code: " + code));
    }

    /**
     * Check if the provided code is a valid ${enumName} code.
     *
     * @param code The code to validate
     * @return true if the code matches a valid ${enumName}, false otherwise
     */
    public static boolean isValid(String code) {
        return fromCode(code).isPresent();
    }
} 