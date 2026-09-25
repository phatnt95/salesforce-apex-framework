/**
 * @description       : Selector class for the Contact SObject.
 *                      All queries are built via SOQLBuilder (through SObjectSelector.newQueryBuilder()).
 * @author            : PHAT NGUYEN
 * @group             : Selectors
 * @last modified on  : 09-25-2026
 * @last modified by  : PHAT NGUYEN
**/
public with sharing class ContactSelector extends SObjectSelector {

    // ─────────────────────────────────────────────────────────────────────────
    // ISObjectSelector — required overrides
    // ─────────────────────────────────────────────────────────────────────────

    public override Schema.SObjectType getSObjectType() {
        return Contact.SObjectType;
    }

    public override List<String> getDefaultFields() {
        return new List<String>{
            'Id',
            'FirstName',
            'LastName',
            'Name',
            'AccountId',
            'Account.Name',
            'Email',
            'Phone',
            'Title',
            'Department',
            'OwnerId',
            'CreatedDate',
            'LastModifiedDate'
        };
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Custom query methods
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Returns Contacts belonging to the given Account.
     * @param accountId The parent Account Id.
     * @return List<Contact>
     */
    public List<Contact> selectByAccountId(Id accountId) {
        return (List<Contact>) newQueryBuilder()
            .whereCondition('AccountId = \'' + accountId + '\'')
            .orderBy('LastName ASC, FirstName ASC')
            .execute();
    }

    /**
     * Returns Contacts belonging to a set of Account Ids.
     * @param accountIds Set of parent Account Ids.
     * @return List<Contact>
     */
    public List<Contact> selectByAccountIds(Set<Id> accountIds) {
        if (accountIds == null || accountIds.isEmpty()) {
            return new List<Contact>();
        }
        return (List<Contact>) newQueryBuilder()
            .whereCondition('AccountId IN :accountIds')
            .orderBy('LastName ASC, FirstName ASC')
            .execute();
    }

    /**
     * Returns Contacts whose Email matches (case-insensitive exact match).
     * @param email The email address to search.
     * @return List<Contact>
     */
    public List<Contact> selectByEmail(String email) {
        return (List<Contact>) newQueryBuilder()
            .whereCondition('Email = \'' + SOQLBuilder.sanitize(email) + '\'')
            .execute();
    }

    /**
     * Returns Contacts filtered by Department.
     * @param department The Department value to filter on.
     * @return List<Contact>
     */
    public List<Contact> selectByDepartment(String department) {
        return (List<Contact>) newQueryBuilder()
            .whereCondition('Department = \'' + SOQLBuilder.sanitize(department) + '\'')
            .orderBy('LastName ASC')
            .execute();
    }
}
