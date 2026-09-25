/**
 * @description       : Test class for SObjectSelector base class validation logic.
 * @author            : PHAT NGUYEN
 * @group             : Selectors
 * @last modified on  : 09-25-2026
 * @last modified by  : PHAT NGUYEN
**/
@isTest
private class SObjectSelectorTest {

    // ─── Helper stubs ──────────────────────────────────────────────────────

    private class SelectorWithNoIdField extends SObjectSelector {
        public override Schema.SObjectType getSObjectType() { return Account.SObjectType; }
        public override List<String> getDefaultFields()     { return new List<String>{ 'Name' }; }
    }

    private class SelectorWithEmptyFields extends SObjectSelector {
        public override Schema.SObjectType getSObjectType() { return Account.SObjectType; }
        public override List<String> getDefaultFields()     { return new List<String>(); }
    }

    private class SelectorWithNullFields extends SObjectSelector {
        public override Schema.SObjectType getSObjectType() { return Account.SObjectType; }
        public override List<String> getDefaultFields()     { return null; }
    }

    // ─── Tests ─────────────────────────────────────────────────────────────

    @isTest
    static void testValidation_throwsWhenIdFieldMissing() {
        SObjectSelector.SelectorException caughtEx;

        Test.startTest();
        try {
            new SelectorWithNoIdField().selectAll();
        } catch (SObjectSelector.SelectorException ex) {
            caughtEx = ex;
        }
        Test.stopTest();

        System.assertNotEquals(null, caughtEx, 'Should throw SelectorException when Id is missing from default fields.');
        System.assert(caughtEx.getMessage().contains('Id field'), 'Exception message should mention the Id field.');
    }

    @isTest
    static void testValidation_throwsWhenFieldsListIsEmpty() {
        SObjectSelector.SelectorException caughtEx;

        Test.startTest();
        try {
            new SelectorWithEmptyFields().selectAll();
        } catch (SObjectSelector.SelectorException ex) {
            caughtEx = ex;
        }
        Test.stopTest();

        System.assertNotEquals(null, caughtEx, 'Should throw SelectorException when default fields list is empty.');
        System.assert(caughtEx.getMessage().contains('at least one field'), 'Exception message should mention at least one field.');
    }

    @isTest
    static void testValidation_throwsWhenFieldsListIsNull() {
        SObjectSelector.SelectorException caughtEx;

        Test.startTest();
        try {
            new SelectorWithNullFields().selectAll();
        } catch (SObjectSelector.SelectorException ex) {
            caughtEx = ex;
        }
        Test.stopTest();

        System.assertNotEquals(null, caughtEx, 'Should throw SelectorException when getDefaultFields returns null.');
    }

    @isTest
    static void testSelectById_nullSetReturnsEmpty() {
        Test.startTest();
        List<SObject> result = new AccountSelector().selectById(null);
        Test.stopTest();

        System.assertEquals(0, result.size(), 'Should return empty list when null Id set is passed.');
    }
}
