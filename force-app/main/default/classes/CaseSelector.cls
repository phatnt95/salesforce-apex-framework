/**
 * @description       : Selector class for the Case SObject.
 *                      All queries are built via SOQLBuilder (through SObjectSelector.newQueryBuilder()).
 * @author            : PHAT NGUYEN
 * @group             : Selectors
 * @last modified on  : 09-25-2026
 * @last modified by  : PHAT NGUYEN
**/
public with sharing class CaseSelector extends SObjectSelector {

    // ─────────────────────────────────────────────────────────────────────────
    // ISObjectSelector — required overrides
    // ─────────────────────────────────────────────────────────────────────────

    public override Schema.SObjectType getSObjectType() {
        return Case.SObjectType;
    }

    public override List<String> getDefaultFields() {
        return new List<String>{
            'Id',
            'CaseNumber',
            'Subject',
            'Description',
            'Status',
            'Priority',
            'Origin',
            'AccountId',
            'Account.Name',
            'ContactId',
            'Contact.Name',
            'OwnerId',
            'IsClosed',
            'CreatedDate',
            'LastModifiedDate'
        };
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Custom query methods
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Returns Cases belonging to the given Account.
     * @param accountId The parent Account Id.
     * @return List<Case>
     */
    public List<Case> selectByAccountId(Id accountId) {
        return (List<Case>) newQueryBuilder()
            .whereCondition('AccountId = \'' + accountId + '\'')
            .orderBy('CreatedDate DESC')
            .execute();
    }

    /**
     * Returns Cases filtered by Status.
     * @param status The Case Status picklist value (e.g. 'New', 'Working', 'Closed').
     * @return List<Case>
     */
    public List<Case> selectByStatus(String status) {
        return (List<Case>) newQueryBuilder()
            .whereCondition('Status = \'' + SOQLBuilder.sanitize(status) + '\'')
            .orderBy('CreatedDate DESC')
            .execute();
    }

    /**
     * Returns Cases filtered by Priority.
     * @param priority The Case Priority picklist value (e.g. 'High', 'Medium', 'Low').
     * @return List<Case>
     */
    public List<Case> selectByPriority(String priority) {
        return (List<Case>) newQueryBuilder()
            .whereCondition('Priority = \'' + SOQLBuilder.sanitize(priority) + '\'')
            .orderBy('CreatedDate DESC')
            .execute();
    }

    /**
     * Returns all open (non-closed) Cases.
     * @return List<Case>
     */
    public List<Case> selectOpenCases() {
        return (List<Case>) newQueryBuilder()
            .whereCondition('IsClosed = false')
            .orderBy('Priority ASC, CreatedDate DESC')
            .execute();
    }

    /**
     * Returns Cases belonging to the given Contact.
     * @param contactId The related Contact Id.
     * @return List<Case>
     */
    public List<Case> selectByContactId(Id contactId) {
        return (List<Case>) newQueryBuilder()
            .whereCondition('ContactId = \'' + contactId + '\'')
            .orderBy('CreatedDate DESC')
            .execute();
    }
}
