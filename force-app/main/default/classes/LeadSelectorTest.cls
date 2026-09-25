/**
 * @description       : Test class for LeadSelector.
 *                      All test data is created via TestDataFactory.
 * @author            : PHAT NGUYEN
 * @group             : Selectors
 * @last modified on  : 09-25-2026
 * @last modified by  : PHAT NGUYEN
**/
@isTest
private class LeadSelectorTest {

    @isTest
    static void testSelectAll() {
        TestDataFactory.createLeads(3, true);

        Test.startTest();
        List<Lead> result = new LeadSelector().selectAll();
        Test.stopTest();

        System.assert(!result.isEmpty(), 'selectAll should return leads.');
        System.assert(result.size() >= 3, 'Should return at least 3 inserted leads.');
    }

    @isTest
    static void testSelectById() {
        List<Lead> leads = TestDataFactory.createLeads(2, true);
        Set<Id> ids = new Map<Id, Lead>(leads).keySet();

        Test.startTest();
        List<Lead> result = new LeadSelector().selectById(ids);
        Test.stopTest();

        System.assertEquals(2, result.size(), 'Should return exactly 2 leads matching the given Ids.');
    }

    @isTest
    static void testSelectById_emptySet() {
        Test.startTest();
        List<Lead> result = new LeadSelector().selectById(new Set<Id>());
        Test.stopTest();

        System.assertEquals(0, result.size(), 'Should return empty list for empty Id set.');
    }

    @isTest
    static void testSelectByStatus() {
        TestDataFactory.createLeads(2, true); // Status = 'Open - Not Contacted'

        Test.startTest();
        List<Lead> result = new LeadSelector().selectByStatus('Open - Not Contacted');
        Test.stopTest();

        System.assert(!result.isEmpty(), 'Should find leads with the given status.');
        for (Lead l : result) {
            System.assertEquals('Open - Not Contacted', l.Status, 'Each lead should have the correct status.');
        }
    }

    @isTest
    static void testSelectByLeadSource() {
        TestDataFactory.createLeads(2, true); // LeadSource = 'Web'

        Test.startTest();
        List<Lead> result = new LeadSelector().selectByLeadSource('Web');
        Test.stopTest();

        System.assert(!result.isEmpty(), 'Should find leads with LeadSource = Web.');
        for (Lead l : result) {
            System.assertEquals('Web', l.LeadSource, 'Each lead should have LeadSource = Web.');
        }
    }

    @isTest
    static void testSelectUnconvertedLeads() {
        TestDataFactory.createLeads(3, true); // IsConverted = false by default

        Test.startTest();
        List<Lead> result = new LeadSelector().selectUnconvertedLeads();
        Test.stopTest();

        System.assert(!result.isEmpty(), 'Should return unconverted leads.');
        for (Lead l : result) {
            System.assertEquals(false, l.IsConverted, 'Each returned lead should not be converted.');
        }
    }

    @isTest
    static void testSelectByIndustry() {
        TestDataFactory.createLeads(2, true); // Industry = 'Technology'

        Test.startTest();
        List<Lead> result = new LeadSelector().selectByIndustry('Technology');
        Test.stopTest();

        System.assert(!result.isEmpty(), 'Should find leads with Industry = Technology.');
        for (Lead l : result) {
            System.assertEquals('Technology', l.Industry, 'Each lead should have Industry = Technology.');
        }
    }

    @isTest
    static void testSelectByEmail() {
        TestDataFactory.createLeads(1, true); // Email = 'testlead0@example.com'

        Test.startTest();
        List<Lead> result = new LeadSelector().selectByEmail('testlead0@example.com');
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Should find exactly 1 lead with matching email.');
        System.assertEquals('testlead0@example.com', result[0].Email, 'Email should match.');
    }

    @isTest
    static void testGetSObjectType() {
        Test.startTest();
        Schema.SObjectType result = new LeadSelector().getSObjectType();
        Test.stopTest();

        System.assertEquals(Lead.SObjectType, result, 'getSObjectType should return Lead.SObjectType.');
    }

    @isTest
    static void testGetDefaultFields_containsId() {
        List<String> fields = new LeadSelector().getDefaultFields();

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
