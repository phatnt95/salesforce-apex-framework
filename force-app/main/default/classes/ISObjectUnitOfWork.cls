/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 07-03-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public interface ISObjectUnitOfWork {
    /**
     * Registers a new record to be inserted during the commitWork transaction.
     * @param record The SObject record to insert.
     */
    void registerNew(SObject record);
    /**
     * Registers a new record to be inserted, setting its relationship lookup field
     * to refer to a parent record that is also being inserted/updated in this Unit of Work.
     * @param record The child SObject record.
     * @param relatedToField The lookup field on the child record.
     * @param relatedTo The parent SObject record.
     */
    void registerNew(SObject record, Schema.SObjectField relatedToField, SObject relatedTo);
    /**
     * Registers an existing record to be updated during the commitWork transaction.
     * @param record The SObject record to update.
     */
    void registerDirty(SObject record);
    /**
     * Registers a list of existing records to be updated during the commitWork transaction.
     * @param records The SObject records to update.
     */
    void registerDirty(List<SObject> records);
    /**
     * Registers an existing record to be deleted during the commitWork transaction.
     * @param record The SObject record to delete.
     */
    void registerDelete(SObject record);
    /**
     * Registers a list of existing records to be deleted during the commitWork transaction.
     * @param records The SObject records to delete.
     */
    void registerDelete(List<SObject> records);
    /**
     * Registers a relationship lookup relationship between two records.
     * This is useful when the child record needs to refer to a parent record
     * whose ID is not yet known because it will be generated during the commitWork DML execution.
     * @param record The child SObject record.
     * @param relatedToField The lookup field on the child record.
     * @param relatedTo The parent SObject record.
     */
    void registerRelationship(SObject record, Schema.SObjectField relatedToField, SObject relatedTo);
    /**
     * Commits all registered changes (inserts, updates, deletes) in order of their SObjectTypes
     * in a single transaction. Executes rollback to a Savepoint if any DML exception occurs.
     */
    void commitWork();
}