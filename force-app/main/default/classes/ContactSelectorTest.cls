/**
 * @description       : Test class for ContactSelector.
 *                      All test data is created via TestDataFactory.
 * @author            : PHAT NGUYEN
 * @group             : Selectors
 * @last modified on  : 09-25-2026
 * @last modified by  : PHAT NGUYEN
**/
@isTest
private class ContactSelectorTest {

    @isTest
    static void testSelectAll() {
        Account acc = TestDataFactory.createAccount(true);
        TestDataFactory.createContacts(3, acc.Id, true);

        Test.startTest();
        List<Contact> result = new ContactSelector().selectAll();
        Test.stopTest();

        System.assert(!result.isEmpty(), 'selectAll should return contacts.');
        System.assert(result.size() >= 3, 'Should return at least 3 inserted contacts.');
    }

    @isTest
    static void testSelectById() {
        Account acc = TestDataFactory.createAccount(true);
        List<Contact> contacts = TestDataFactory.createContacts(2, acc.Id, true);
        Set<Id> ids = new Map<Id, Contact>(contacts).keySet();

        Test.startTest();
        List<Contact> result = new ContactSelector().selectById(ids);
        Test.stopTest();

        System.assertEquals(2, result.size(), 'Should return exactly 2 contacts matching the given Ids.');
    }

    @isTest
    static void testSelectById_emptySet() {
        Test.startTest();
        List<Contact> result = new ContactSelector().selectById(new Set<Id>());
        Test.stopTest();

        System.assertEquals(0, result.size(), 'Should return empty list for empty Id set.');
    }

    @isTest
    static void testSelectByAccountId() {
        Account acc = TestDataFactory.createAccount(true);
        TestDataFactory.createContacts(3, acc.Id, true);

        Test.startTest();
        List<Contact> result = new ContactSelector().selectByAccountId(acc.Id);
        Test.stopTest();

        System.assertEquals(3, result.size(), 'Should return 3 contacts for the given Account.');
        for (Contact c : result) {
            System.assertEquals(acc.Id, c.AccountId, 'Each contact should belong to the correct Account.');
        }
    }

    @isTest
    static void testSelectByAccountIds() {
        Account acc1 = TestDataFactory.createAccount(true);
        Account acc2 = TestDataFactory.createAccount(true);
        TestDataFactory.createContacts(2, acc1.Id, true);
        TestDataFactory.createContacts(2, acc2.Id, true);
        Set<Id> accountIds = new Set<Id>{ acc1.Id, acc2.Id };

        Test.startTest();
        List<Contact> result = new ContactSelector().selectByAccountIds(accountIds);
        Test.stopTest();

        System.assertEquals(4, result.size(), 'Should return 4 contacts across both accounts.');
    }

    @isTest
    static void testSelectByAccountIds_emptySet() {
        Test.startTest();
        List<Contact> result = new ContactSelector().selectByAccountIds(new Set<Id>());
        Test.stopTest();

        System.assertEquals(0, result.size(), 'Should return empty list for empty account Id set.');
    }

    @isTest
    static void testSelectByEmail() {
        Account acc = TestDataFactory.createAccount(true);
        TestDataFactory.createContacts(1, acc.Id, true); // Email = 'testcontact0@example.com'

        Test.startTest();
        List<Contact> result = new ContactSelector().selectByEmail('testcontact0@example.com');
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Should find exactly 1 contact with matching email.');
        System.assertEquals('testcontact0@example.com', result[0].Email, 'Email should match.');
    }

    @isTest
    static void testSelectByDepartment() {
        Account acc = TestDataFactory.createAccount(true);
        Contact con = TestDataFactory.createContact(acc.Id, false);
        con.Department = 'Engineering';
        insert con;

        Test.startTest();
        List<Contact> result = new ContactSelector().selectByDepartment('Engineering');
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Should find exactly 1 contact in the Engineering department.');
        System.assertEquals('Engineering', result[0].Department, 'Department should match.');
    }

    @isTest
    static void testGetSObjectType() {
        Test.startTest();
        Schema.SObjectType result = new ContactSelector().getSObjectType();
        Test.stopTest();

        System.assertEquals(Contact.SObjectType, result, 'getSObjectType should return Contact.SObjectType.');
    }

    @isTest
    static void testGetDefaultFields_containsId() {
        List<String> fields = new ContactSelector().getDefaultFields();

        Boolean hasId = false;
        for (String f : fields) {
            if (f.equalsIgnoreCase('Id')) {
                hasId = true;
                break;
            }
        }
        System.assert(hasId, 'getDefaultFields must include the Id field.');
    }
}
