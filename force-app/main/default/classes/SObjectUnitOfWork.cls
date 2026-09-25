/**
 * @description       : 
 * @author            : PHAT NGUYEN
 * @group             : 
 * @last modified on  : 07-03-2026
 * @last modified by  : PHAT NGUYEN
**/
public class SObjectUnitOfWork implements ISObjectUnitOfWork {
    
    public class UnitOfWorkException extends Exception {}
    private List<Schema.SObjectType> sObjectTypes;
    private Map<Schema.SObjectType, List<SObject>> newRecordsListMap;
    private Map<Schema.SObjectType, Map<Id, SObject>> dirtyRecordsMapMap;
    private Map<Schema.SObjectType, Map<Id, SObject>> deletedRecordsMapMap;
    private Map<Schema.SObjectType, List<Relationship>> relationshipsMap;
    /**
     * Constructor to initialize the Unit of Work with a list of SObjectTypes in execution dependency order.
     * For example: new List<SObjectType>{ Account.SObjectType, Contact.SObjectType, Opportunity.SObjectType }
     *
     * @param sObjectTypes List of SObjectTypes in the order they should be inserted.
     */
    public SObjectUnitOfWork(List<Schema.SObjectType> sObjectTypes) {
        if (sObjectTypes == null || sObjectTypes.isEmpty()) {
            throw new UnitOfWorkException('SObjectTypes list cannot be null or empty.');
        }
        
        this.sObjectTypes = sObjectTypes;
        this.newRecordsListMap = new Map<Schema.SObjectType, List<SObject>>();
        this.dirtyRecordsMapMap = new Map<Schema.SObjectType, Map<Id, SObject>>();
        this.deletedRecordsMapMap = new Map<Schema.SObjectType, Map<Id, SObject>>();
        this.relationshipsMap = new Map<Schema.SObjectType, List<Relationship>>();
        for (Schema.SObjectType sObjectType : sObjectTypes) {
            this.newRecordsListMap.put(sObjectType, new List<SObject>());
            this.dirtyRecordsMapMap.put(sObjectType, new Map<Id, SObject>());
            this.deletedRecordsMapMap.put(sObjectType, new Map<Id, SObject>());
            this.relationshipsMap.put(sObjectType, new List<Relationship>());
        }
    }
    /**
     * Registers a new record to be inserted.
     */
    public void registerNew(SObject record) {
        if (record == null) {
            return;
        }
        Schema.SObjectType sObjectType = record.getSObjectType();
        validateSObjectType(sObjectType);
        this.newRecordsListMap.get(sObjectType).add(record);
    }
    /**
     * Registers a new record to be inserted and links its parent lookup relationship.
     */
    public void registerNew(SObject record, Schema.SObjectField relatedToField, SObject relatedTo) {
        registerNew(record);
        registerRelationship(record, relatedToField, relatedTo);
    }
    /**
     * Registers an existing record to be updated.
     */
    public void registerDirty(SObject record) {
        if (record == null) {
            return;
        }
        Schema.SObjectType sObjectType = record.getSObjectType();
        validateSObjectType(sObjectType);
        if (record.Id == null) {
            throw new UnitOfWorkException('Cannot register a dirty record without an ID.');
        }
        this.dirtyRecordsMapMap.get(sObjectType).put(record.Id, record);
    }
    /**
     * Registers a list of existing records to be updated.
     */
    public void registerDirty(List<SObject> records) {
        if (records == null) {
            return;
        }
        for (SObject record : records) {
            registerDirty(record);
        }
    }
    /**
     * Registers an existing record to be deleted.
     */
    public void registerDelete(SObject record) {
        if (record == null) {
            return;
        }
        Schema.SObjectType sObjectType = record.getSObjectType();
        validateSObjectType(sObjectType);
        if (record.Id == null) {
            throw new UnitOfWorkException('Cannot register a record for deletion without an ID.');
        }
        this.deletedRecordsMapMap.get(sObjectType).put(record.Id, record);
    }
    /**
     * Registers a list of existing records to be deleted.
     */
    public void registerDelete(List<SObject> records) {
        if (records == null) {
            return;
        }
        for (SObject record : records) {
            registerDelete(record);
        }
    }
    /**
     * Registers a relationship lookup relationship between two records.
     */
    public void registerRelationship(SObject record, Schema.SObjectField relatedToField, SObject relatedTo) {
        if (record == null || relatedTo == null) {
            return;
        }
        Schema.SObjectType childType = record.getSObjectType();
        validateSObjectType(childType);
        Schema.SObjectType parentType = relatedTo.getSObjectType();
        validateSObjectType(parentType);
        
        this.relationshipsMap.get(childType).add(new Relationship(record, relatedToField, relatedTo));
    }
    /**
     * Clears all registered records and relationships.
     */
    public void clear() {
        for (Schema.SObjectType sObjectType : sObjectTypes) {
            this.newRecordsListMap.get(sObjectType).clear();
            this.dirtyRecordsMapMap.get(sObjectType).clear();
            this.deletedRecordsMapMap.get(sObjectType).clear();
            this.relationshipsMap.get(sObjectType).clear();
        }
    }
    /**
     * Commits all registered changes (inserts, updates, deletes) in order of SObjectTypes in a transaction.
     */
    public void commitWork() {
        Savepoint sp = Database.setSavepoint();
        try {
            // 1. Process inserts and updates in defined order
            for (Schema.SObjectType sObjectType : sObjectTypes) {
                // Resolve relationships for child records of this SObjectType
                for (Relationship rel : this.relationshipsMap.get(sObjectType)) {
                    rel.resolve();
                }
                
                // Perform inserts
                List<SObject> inserts = this.newRecordsListMap.get(sObjectType);
                if (!inserts.isEmpty()) {
                    insert inserts;
                }
                
                // Perform updates
                List<SObject> updates = this.dirtyRecordsMapMap.get(sObjectType).values();
                if (!updates.isEmpty()) {
                    update updates;
                }
            }
            // 2. Process deletes in reverse order (child-to-parent)
            for (Integer i = sObjectTypes.size() - 1; i >= 0; i--) {
                Schema.SObjectType sObjectType = sObjectTypes.get(i);
                List<SObject> deletes = this.deletedRecordsMapMap.get(sObjectType).values();
                if (!deletes.isEmpty()) {
                    delete deletes;
                }
            }
        } catch (Exception e) {
            Database.rollback(sp);
            throw e;
        }
    }
    private void validateSObjectType(Schema.SObjectType sObjectType) {
        if (!this.newRecordsListMap.containsKey(sObjectType)) {
            throw new UnitOfWorkException(
                'SObjectType ' + sObjectType.getDescribe().getName() + ' is not registered in this Unit of Work. ' +
                'Please pass it into the constructor to define its execution order.'
            );
        }
    }
    /**
     * Class to hold relationship linkages to be resolved during commitWork.
     */
    private class Relationship {
        public SObject record;
        public Schema.SObjectField relatedToField;
        public SObject relatedTo;
        public Relationship(SObject record, Schema.SObjectField relatedToField, SObject relatedTo) {
            this.record = record;
            this.relatedToField = relatedToField;
            this.relatedTo = relatedTo;
        }
        public void resolve() {
            if (this.relatedTo.Id == null) {
                throw new UnitOfWorkException(
                    'Parent record does not have an ID. Ensure the parent SObjectType is registered before the child SObjectType in the Unit of Work constructor.'
                );
            }
            this.record.put(this.relatedToField, this.relatedTo.Id);
        }
    }
}