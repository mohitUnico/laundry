package ${packageName}.model;

import io.DoorSync.core.domain.AggregateRoot;
import io.DoorSync.core.domain.validation.ValidationResult;
import ${packageName}.event.${aggregateName}CreatedEvent;
<#if supportsSoftDelete?? && supportsSoftDelete>
import ${packageName}.event.${aggregateName}DeletedEvent;
</#if>
import ${packageName}.event.${aggregateName}UpdatedEvent;

import java.time.Instant;
import java.util.Objects;

/**
 * Aggregate root for ${aggregateName}.
 * Pure domain model: no framework imports, no tenant or transport concerns.
 */
public final class ${aggregateName} extends AggregateRoot<${aggregateName}Id> {

    private String name;
    <#if includeAuditFields?? && includeAuditFields>
    private String addedBy;
    private String updatedBy;
    private java.time.Instant addedOn;
    private java.time.Instant updatedOn;
    private boolean deleted;
    private java.time.Instant deletedOn;
    </#if>

    private ${aggregateName}(${aggregateName}Id id, String name<#if includeAuditFields?? && includeAuditFields>, String addedBy, String updatedBy, java.time.Instant addedOn, java.time.Instant updatedOn, boolean deleted, java.time.Instant deletedOn</#if>) {
        super(Objects.requireNonNull(id, "id required"));
        this.name = Objects.requireNonNull(name, "name required");
        <#if includeAuditFields?? && includeAuditFields>
        this.addedBy = addedBy;
        this.updatedBy = updatedBy;
        this.addedOn = addedOn;
        this.updatedOn = updatedOn;
        this.deleted = deleted;
        this.deletedOn = deletedOn;
        </#if>
    }

    public static ${aggregateName} create(${aggregateName}Id id, String name<#if includeAuditFields?? && includeAuditFields>, String addedBy, String updatedBy</#if>) {
        ValidationResult validation = new ValidationResult("${aggregateName} creation failed");
        if (id == null) validation.addError("id", "id required");
        if (name == null || name.isBlank()) validation.addError("name", "name required");
        validation.throwIfInvalid();
        <#if includeAuditFields?? && includeAuditFields>
        java.time.Instant now = java.time.Instant.now();
        return new ${aggregateName}(id, name, addedBy, updatedBy, now, now, false, null);
        <#else>
        return new ${aggregateName}(id, name);
        </#if>
    }

    <#if includeRehydrateFactory?? && includeRehydrateFactory>
    /**
     * Reconstructs an aggregate instance from a persisted state without validation.
     */
    public static ${aggregateName} rehydrate(${aggregateName}Id id, String name<#if includeAuditFields?? && includeAuditFields>, String addedBy, String updatedBy, java.time.Instant addedOn, java.time.Instant updatedOn, boolean deleted, java.time.Instant deletedOn</#if>) {
        return new ${aggregateName}(id, name<#if includeAuditFields?? && includeAuditFields>, addedBy, updatedBy, addedOn, updatedOn, deleted, deletedOn</#if>);
    }
    </#if>

    public void rename(String newName) {
        ValidationResult validation = new ValidationResult("${aggregateName} rename failed");
        if (newName == null || newName.isBlank()) validation.addError("name", "name required");
        validation.throwIfInvalid();
        this.name = newName;
        <#if includeAuditFields?? && includeAuditFields>
        this.updatedOn = java.time.Instant.now();
        </#if>
    }

    // Example of raising a domain event (occurredAt must be provided by the caller)
    public void recordCreatedEvent(Instant occurredAt) {
        this.recordEvent(new ${aggregateName}CreatedEvent(id().toString(), occurredAt));
    }

    /** Record an Updated event for this aggregate. */
    public void recordUpdatedEvent(Instant occurredAt) {
        this.recordEvent(new ${aggregateName}UpdatedEvent(id().toString(), occurredAt));
    }

    <#if supportsSoftDelete?? && supportsSoftDelete>
    /** Mark this aggregate as deleted and record a Deleted event. */
    public void markDeleted(Instant occurredAt, String updatedBy) {
        <#if includeAuditFields?? && includeAuditFields>
        this.deleted = true;
        this.deletedOn = occurredAt;
        this.updatedBy = updatedBy;
        this.updatedOn = occurredAt;
        </#if>
        this.recordEvent(new ${aggregateName}DeletedEvent(id().toString(), occurredAt));
    }
    </#if>

    public String name() {
        return name;
    }
    <#if includeAuditFields?? && includeAuditFields>
    public String addedBy() { return addedBy; }
    public String updatedBy() { return updatedBy; }
    public java.time.Instant addedOn() { return addedOn; }
    public java.time.Instant updatedOn() { return updatedOn; }
    public boolean deleted() { return deleted; }
    public java.time.Instant deletedOn() { return deletedOn; }
    </#if>

    @Override
    public String toString() {
        return "${aggregateName}{id=" + id() + ", name='" + name + "'}";
    }
}