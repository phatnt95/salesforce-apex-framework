/**
 * @description       : Test class for CaseSelector.
 *                      All test data is created via TestDataFactory.
 * @author            : PHAT NGUYEN
 * @group             : Selectors
 * @last modified on  : 09-25-2026
 * @last modified by  : PHAT NGUYEN
**/
@isTest
private class CaseSelectorTest {

    @isTest
    static void testSelectAll() {
        Account acc = TestDataFactory.createAccount(true);
        TestDataFactory.createCases(3, acc.Id, true);

        Test.startTest();
        List<Case> result = new CaseSelector().selectAll();
        Test.stopTest();

        System.assert(!result.isEmpty(), 'selectAll should return cases.');
        System.assert(result.size() >= 3, 'Should return at least 3 inserted cases.');
    }

    @isTest
    static void testSelectById() {
        Account acc = TestDataFactory.createAccount(true);
        List<Case> cases = TestDataFactory.createCases(2, acc.Id, true);
        Set<Id> ids = new Map<Id, Case>(cases).keySet();

        Test.startTest();
        List<Case> result = new CaseSelector().selectById(ids);
        Test.stopTest();

        System.assertEquals(2, result.size(), 'Should return exactly 2 cases matching the given Ids.');
    }

    @isTest
    static void testSelectById_emptySet() {
        Test.startTest();
        List<Case> result = new CaseSelector().selectById(new Set<Id>());
        Test.stopTest();

        System.assertEquals(0, result.size(), 'Should return empty list for empty Id set.');
    }

    @isTest
    static void testSelectByAccountId() {
        Account acc = TestDataFactory.createAccount(true);
        TestDataFactory.createCases(3, acc.Id, true);

        Test.startTest();
        List<Case> result = new CaseSelector().selectByAccountId(acc.Id);
        Test.stopTest();

        System.assertEquals(3, result.size(), 'Should return 3 cases for the given Account.');
        for (Case c : result) {
            System.assertEquals(acc.Id, c.AccountId, 'Each case should belong to the correct Account.');
        }
    }

    @isTest
    static void testSelectByStatus() {
        Account acc = TestDataFactory.createAccount(true);
        TestDataFactory.createCases(2, acc.Id, true); // Status = 'New'

        Test.startTest();
        List<Case> result = new CaseSelector().selectByStatus('New');
        Test.stopTest();

        System.assert(!result.isEmpty(), 'Should find cases with Status = New.');
        for (Case c : result) {
            System.assertEquals('New', c.Status, 'Each case should have Status = New.');
        }
    }

    @isTest
    static void testSelectByPriority() {
        Account acc = TestDataFactory.createAccount(true);
        TestDataFactory.createCases(2, acc.Id, true); // Priority = 'Medium'

        Test.startTest();
        List<Case> result = new CaseSelector().selectByPriority('Medium');
        Test.stopTest();

        System.assert(!result.isEmpty(), 'Should find cases with Priority = Medium.');
        for (Case c : result) {
            System.assertEquals('Medium', c.Priority, 'Each case should have Priority = Medium.');
        }
    }

    @isTest
    static void testSelectOpenCases() {
        Account acc = TestDataFactory.createAccount(true);
        TestDataFactory.createCases(3, acc.Id, true); // IsClosed = false (Status = 'New')

        Test.startTest();
        List<Case> result = new CaseSelector().selectOpenCases();
        Test.stopTest();

        System.assert(!result.isEmpty(), 'Should return open cases.');
        for (Case c : result) {
            System.assertEquals(false, c.IsClosed, 'Each returned case should be open (IsClosed = false).');
        }
    }

    @isTest
    static void testSelectByContactId() {
        Account acc = TestDataFactory.createAccount(true);
        Contact con = TestDataFactory.createContact(acc.Id, true);
        Case c = TestDataFactory.createCase(acc.Id, false);
        c.ContactId = con.Id;
        insert c;

        Test.startTest();
        List<Case> result = new CaseSelector().selectByContactId(con.Id);
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Should return 1 case linked to the given Contact.');
        System.assertEquals(con.Id, result[0].ContactId, 'ContactId should match.');
    }

    @isTest
    static void testGetSObjectType() {
        Test.startTest();
        Schema.SObjectType result = new CaseSelector().getSObjectType();
        Test.stopTest();

        System.assertEquals(Case.SObjectType, result, 'getSObjectType should return Case.SObjectType.');
    }

    @isTest
    static void testGetDefaultFields_containsId() {
        List<String> fields = new CaseSelector().getDefaultFields();

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
