/**
 * Centralized factory for creating test data with sensible defaults.
 * All methods accept a doInsert flag for flexibility.
 */
@isTest
public class TestDataFactory {

    // ─── Accounts ─────────────────────────────────────────────────────────

    public static List<Account> createAccounts(Integer count, Boolean doInsert) {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < count; i++) {
            accounts.add(new Account(
                Name        = 'Test Account ' + i,
                BillingCity    = 'San Francisco',
                BillingState   = 'CA',
                BillingCountry = 'USA',
                Industry    = 'Technology',
                Type        = 'Customer'
            ));
        }
        if (doInsert) {
            insert accounts;
        }
        return accounts;
    }

    public static Account createAccount(Boolean doInsert) {
        return createAccounts(1, doInsert)[0];
    }

    // ─── Contacts ─────────────────────────────────────────────────────────

    public static List<Contact> createContacts(Integer count, Id accountId, Boolean doInsert) {
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < count; i++) {
            contacts.add(new Contact(
                FirstName   = 'Test',
                LastName    = 'Contact ' + i,
                AccountId   = accountId,
                Email       = 'testcontact' + i + '@example.com',
                Phone       = '555-000-' + String.valueOf(i).leftPad(4, '0'),
                Title       = 'QA Engineer'
            ));
        }
        if (doInsert) {
            insert contacts;
        }
        return contacts;
    }

    public static Contact createContact(Id accountId, Boolean doInsert) {
        return createContacts(1, accountId, doInsert)[0];
    }

    // ─── Cases ────────────────────────────────────────────────────────────

    public static List<Case> createCases(Integer count, Id accountId, Boolean doInsert) {
        List<Case> cases = new List<Case>();
        for (Integer i = 0; i < count; i++) {
            cases.add(new Case(
                Subject     = 'Test Case ' + i,
                AccountId   = accountId,
                Status      = 'New',
                Priority    = 'Medium',
                Origin      = 'Web'
            ));
        }
        if (doInsert) {
            insert cases;
        }
        return cases;
    }

    public static Case createCase(Id accountId, Boolean doInsert) {
        return createCases(1, accountId, doInsert)[0];
    }

    // ─── Leads ────────────────────────────────────────────────────────────

    public static List<Lead> createLeads(Integer count, Boolean doInsert) {
        List<Lead> leads = new List<Lead>();
        for (Integer i = 0; i < count; i++) {
            leads.add(new Lead(
                FirstName   = 'Test',
                LastName    = 'Lead ' + i,
                Company     = 'Test Company ' + i,
                Email       = 'testlead' + i + '@example.com',
                Status      = 'Open - Not Contacted',
                LeadSource  = 'Web',
                Industry    = 'Technology'
            ));
        }
        if (doInsert) {
            insert leads;
        }
        return leads;
    }

    public static Lead createLead(Boolean doInsert) {
        return createLeads(1, doInsert)[0];
    }
}