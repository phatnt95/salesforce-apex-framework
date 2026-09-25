/**
 * @description       : Test class for AccountSelector.
 *                      All test data is created via TestDataFactory.
 * @author            : PHAT NGUYEN
 * @group             : Selectors
 * @last modified on  : 09-25-2026
 * @last modified by  : PHAT NGUYEN
**/
@isTest
private class AccountSelectorTest {

    @isTest
    static void testSelectAll() {
        TestDataFactory.createAccounts(3, true);

        Test.startTest();
        List<Account> result = new AccountSelector().selectAll();
        Test.stopTest();

        System.assert(!result.isEmpty(), 'selectAll should return records.');
        System.assert(result.size() >= 3, 'Should return at least the 3 inserted accounts.');
    }

    @isTest
    static void testSelectById() {
        List<Account> accounts = TestDataFactory.createAccounts(3, true);
        Set<Id> ids = new Map<Id, Account>(accounts).keySet();

        Test.startTest();
        List<Account> result = new AccountSelector().selectById(ids);
        Test.stopTest();

        System.assertEquals(3, result.size(), 'Should return exactly 3 accounts matching the given Ids.');
        System.assertNotEquals(null, result[0].Id,   'Id field should be populated.');
        System.assertNotEquals(null, result[0].Name, 'Name field should be populated.');
    }

    @isTest
    static void testSelectById_emptySet() {
        Test.startTest();
        List<Account> result = new AccountSelector().selectById(new Set<Id>());
        Test.stopTest();

        System.assertEquals(0, result.size(), 'Should return empty list for empty Id set.');
    }

    @isTest
    static void testSelectByIndustry() {
        TestDataFactory.createAccounts(2, true); // Industry = 'Technology'

        Test.startTest();
        List<Account> result = new AccountSelector().selectByIndustry('Technology');
        Test.stopTest();

        System.assert(!result.isEmpty(), 'Should return accounts with Industry = Technology.');
        for (Account acc : result) {
            System.assertEquals('Technology', acc.Industry, 'All returned accounts should have Industry = Technology.');
        }
    }

    @isTest
    static void testSelectByType() {
        TestDataFactory.createAccounts(2, true); // Type = 'Customer'

        Test.startTest();
        List<Account> result = new AccountSelector().selectByType('Customer');
        Test.stopTest();

        System.assert(!result.isEmpty(), 'Should return accounts with Type = Customer.');
        for (Account acc : result) {
            System.assertEquals('Customer', acc.Type, 'All returned accounts should have Type = Customer.');
        }
    }

    @isTest
    static void testSelectByNameLike() {
        TestDataFactory.createAccounts(2, true); // Names: 'Test Account 0', 'Test Account 1'

        Test.startTest();
        List<Account> result = new AccountSelector().selectByNameLike('Test Account');
        Test.stopTest();

        System.assert(!result.isEmpty(), 'Should find accounts matching name pattern.');
    }

    @isTest
    static void testNewQueryBuilder_withLimit() {
        TestDataFactory.createAccounts(3, true);

        Test.startTest();
        List<Account> result = (List<Account>) new AccountSelector()
            .newQueryBuilder()
            .setLimit(2)
            .execute();
        Test.stopTest();

        System.assertEquals(2, result.size(), 'newQueryBuilder with LIMIT 2 should return exactly 2 records.');
    }

    @isTest
    static void testGetSObjectType() {
        Test.startTest();
        Schema.SObjectType result = new AccountSelector().getSObjectType();
        Test.stopTest();

        System.assertEquals(Account.SObjectType, result, 'getSObjectType should return Account.SObjectType.');
    }

    @isTest
    static void testGetDefaultFields_containsId() {
        List<String> fields = new AccountSelector().getDefaultFields();

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
