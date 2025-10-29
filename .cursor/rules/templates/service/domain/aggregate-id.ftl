package ${packageName}.model;

import io.DoorSync.core.domain.BaseValueObject;

import java.util.Objects;

/**
 * Strongly-typed identifier for the ${aggregateName} aggregate.
 */
public final class ${aggregateName}Id extends BaseValueObject<${aggregateName}Id> {

    private final String value;

    private ${aggregateName}Id(String value) {
        this.value = Objects.requireNonNull(value, "id value required");
        if (this.value.isBlank()) {
            throw new IllegalArgumentException("id value must not be blank");
        }
    }

    public static ${aggregateName}Id fromString(String value) {
        return new ${aggregateName}Id(value);
    }

    public String value() {
        return value;
    }

    @Override
    protected boolean isEqualTo(${aggregateName}Id other) {
        return value.equals(other.value);
    }

    @Override
    public int hashCode() {
        return value.hashCode();
    }

    @Override
    public String toString() {
        return value;
    }
}

