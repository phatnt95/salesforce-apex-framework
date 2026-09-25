/**
 * @description       : 
 * @author            : PHAT NGUYEN
 * @group             : 
 * @last modified on  : 07-03-2026
 * @last modified by  : PHAT NGUYEN
**/
@isTest
private class SObjectUnitOfWorkTest {
    @isTest
    static void testNewRecordsWithRelationships() {
        // Define SObjectTypes in order of execution
        List<Schema.SObjectType> types = new List<Schema.SObjectType>{
            Account.SObjectType,
            Contact.SObjectType
        };
        SObjectUnitOfWork uow = new SObjectUnitOfWork(types);
        // 1. Create records
        Account parentAcc = TestDataFactory.createAccount('UoW Parent Account', false);
        Contact childCon1 = TestDataFactory.createContact(null, 'UoW', 'Child 1', false);
        Contact childCon2 = TestDataFactory.createContact(null, 'UoW', 'Child 2', false);
        // 2. Register
        uow.registerNew(parentAcc);
        
        // Register new with relationship link
        uow.registerNew(childCon1, Contact.AccountId, parentAcc);
        
        // Or register separately and link relationship
        uow.registerNew(childCon2);
        uow.registerRelationship(childCon2, Contact.AccountId, parentAcc);
        // 3. Commit Work
        Test.startTest();
        uow.commitWork();
        Test.stopTest();
        // 4. Verify database state
        List<Account> accounts = [SELECT Id, Name FROM Account WHERE Name = 'UoW Parent Account'];
        System.assertEquals(1, accounts.size(), 'Account should be inserted');
        
        List<Contact> contacts = [SELECT Id, FirstName, LastName, AccountId FROM Contact WHERE AccountId = :accounts[0].Id];
        System.assertEquals(2, contacts.size(), 'Two contacts should be inserted and linked to parent Account');
    }
    @isTest
    static void testDirtyRecords() {
        // Create initial data
        Account acc = TestDataFactory.createAccount('Original Name', true);
        List<Schema.SObjectType> types = new List<Schema.SObjectType>{ Account.SObjectType };
        SObjectUnitOfWork uow = new SObjectUnitOfWork(types);
        // Modify and register dirty
        acc.Name = 'Updated Name';
        uow.registerDirty(acc);
        Test.startTest();
        uow.commitWork();
        Test.stopTest();
        // Verify update
        Account updatedAcc = [SELECT Id, Name FROM Account WHERE Id = :acc.Id];
        System.assertEquals('Updated Name', updatedAcc.Name, 'Account name should be updated');
    }
    @isTest
    static void testDeleteRecords() {
        // Create initial data
        Account acc = TestDataFactory.createAccount('To Delete', true);
        List<Schema.SObjectType> types = new List<Schema.SObjectType>{ Account.SObjectType };
        SObjectUnitOfWork uow = new SObjectUnitOfWork(types);
        // Register for deletion
        uow.registerDelete(acc);
        Test.startTest();
        uow.commitWork();
        Test.stopTest();
        // Verify deletion
        List<Account> accounts = [SELECT Id FROM Account WHERE Id = :acc.Id];
        System.assertEquals(0, accounts.size(), 'Account should be deleted');
    }
    @isTest
    static void testTransactionRollbackOnFailure() {
        List<Schema.SObjectType> types = new List<Schema.SObjectType>{
            Account.SObjectType,
            Contact.SObjectType
        };
        SObjectUnitOfWork uow = new SObjectUnitOfWork(types);
        // Register valid Account
        Account acc = TestDataFactory.createAccount('Rollback Account', false);
        uow.registerNew(acc);
        // Register invalid Contact (LastName is a required field on Contact)
        Contact invalidCon = TestDataFactory.createContact(null, 'Invalid', null, false);
        uow.registerNew(invalidCon, Contact.AccountId, acc);
        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            uow.commitWork();
        } catch (DmlException e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        System.assert(exceptionThrown, 'A DMLException should have been thrown');
        // Verify that the entire transaction was rolled back and no Account was created
        List<Account> accounts = [SELECT Id FROM Account WHERE Name = 'Rollback Account'];
        System.assertEquals(0, accounts.size(), 'Account creation should be rolled back');
    }
    @isTest
    static void testUnregisteredSObjectTypeException() {
        // Initialize with only Account
        List<Schema.SObjectType> types = new List<Schema.SObjectType>{ Account.SObjectType };
        SObjectUnitOfWork uow = new SObjectUnitOfWork(types);
        // Try registering a Contact, which is unregistered
        Contact con = TestDataFactory.createContact(null, null, 'Test', false);
        
        Boolean exceptionThrown = false;
        try {
            uow.registerNew(con);
        } catch (SObjectUnitOfWork.UnitOfWorkException e) {
            exceptionThrown = true;
            System.assert(e.getMessage().contains('Contact is not registered'), 'Exception message should mention the unregistered object');
        }
        System.assert(exceptionThrown, 'UnitOfWorkException should have been thrown');
    }
    @isTest
    static void testMissingIdOnDirtyRegister() {
        List<Schema.SObjectType> types = new List<Schema.SObjectType>{ Account.SObjectType };
        SObjectUnitOfWork uow = new SObjectUnitOfWork(types);
        // Account record without an Id
        Account acc = TestDataFactory.createAccount('No Id', false);
        Boolean exceptionThrown = false;
        try {
            uow.registerDirty(acc);
        } catch (SObjectUnitOfWork.UnitOfWorkException e) {
            exceptionThrown = true;
            System.assert(e.getMessage().contains('Cannot register a dirty record without an ID'), 'Exception message should warn about missing ID');
        }
        System.assert(exceptionThrown, 'UnitOfWorkException should have been thrown');
    }
}