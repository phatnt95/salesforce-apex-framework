/**
 * Centralized factory for creating test data with sensible defaults.
 * All methods accept a doInsert flag for flexibility.
 */
@isTest
public class TestDataFactory {

    private static Integer accountSequence = 0;
    private static Integer contactSequence = 0;
    private static Integer caseSequence = 0;
    private static Integer leadSequence = 0;

    // ─── Accounts ─────────────────────────────────────────────────────────

    public static List<Account> createAccounts(Integer count, Boolean doInsert) {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < count; i++) {
            Integer seq = accountSequence++;
            accounts.add(new Account(
                Name        = 'Test Account ' + seq,
                Industry    = 'Technology',
                Type        = 'Customer'
            ));
        }
        if (doInsert) {
            Database.DMLOptions dml = new Database.DMLOptions();
            dml.duplicateRuleHeader.allowSave = true;
            dml.optAllOrNone = true;
            Database.insert(accounts, dml);
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
            Integer seq = contactSequence++;
            contacts.add(new Contact(
                FirstName   = 'Test',
                LastName    = 'Contact ' + seq,
                AccountId   = accountId,
                Email       = 'testcontact' + seq + '@example.com',
                Phone       = '555-000-' + String.valueOf(seq).leftPad(4, '0'),
                Title       = 'QA Engineer'
            ));
        }
        if (doInsert) {
            Database.DMLOptions dml = new Database.DMLOptions();
            dml.duplicateRuleHeader.allowSave = true;
            dml.optAllOrNone = true;
            Database.insert(contacts, dml);
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
            Integer seq = caseSequence++;
            cases.add(new Case(
                Subject     = 'Test Case ' + seq,
                AccountId   = accountId,
                Status      = 'New',
                Priority    = 'Medium',
                Origin      = 'Web'
            ));
        }
        if (doInsert) {
            Database.DMLOptions dml = new Database.DMLOptions();
            dml.duplicateRuleHeader.allowSave = true;
            dml.optAllOrNone = true;
            Database.insert(cases, dml);
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
            Integer seq = leadSequence++;
            leads.add(new Lead(
                FirstName   = 'Test',
                LastName    = 'Lead ' + seq,
                Company     = 'Test Company ' + seq,
                Email       = 'testlead' + seq + '@example.com',
                Status      = 'Open - Not Contacted',
                LeadSource  = 'Web',
                Industry    = 'Technology'
            ));
        }
        if (doInsert) {
            Database.DMLOptions dml = new Database.DMLOptions();
            dml.duplicateRuleHeader.allowSave = true;
            dml.optAllOrNone = true;
            Database.insert(leads, dml);
        }
        return leads;
    }

    public static Lead createLead(Boolean doInsert) {
        return createLeads(1, doInsert)[0];
    }
}