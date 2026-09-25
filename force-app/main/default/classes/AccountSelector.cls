/**
 * @description       : Selector class for the Account SObject.
 *                      All queries are built via SOQLBuilder (through SObjectSelector.newQueryBuilder()).
 * @author            : PHAT NGUYEN
 * @group             : Selectors
 * @last modified on  : 09-25-2026
 * @last modified by  : PHAT NGUYEN
**/
public with sharing class AccountSelector extends SObjectSelector {

    // ─────────────────────────────────────────────────────────────────────────
    // ISObjectSelector — required overrides
    // ─────────────────────────────────────────────────────────────────────────

    public override Schema.SObjectType getSObjectType() {
        return Account.SObjectType;
    }

    public override List<String> getDefaultFields() {
        return new List<String>{
            'Id',
            'Name',
            'Industry',
            'Type',
            'BillingCity',
            'BillingState',
            'BillingCountry',
            'Phone',
            'Website',
            'OwnerId',
            'CreatedDate',
            'LastModifiedDate'
        };
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Custom query methods
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Returns Accounts filtered by Industry.
     * @param industry The Industry picklist value to filter on.
     * @return List<Account>
     */
    public List<Account> selectByIndustry(String industry) {
        return (List<Account>) newQueryBuilder()
            .whereCondition('Industry = \'' + SOQLBuilder.sanitize(industry) + '\'')
            .orderBy('Name ASC')
            .execute();
    }

    /**
     * Returns Accounts filtered by Type.
     * @param accountType The Type picklist value to filter on.
     * @return List<Account>
     */
    public List<Account> selectByType(String accountType) {
        return (List<Account>) newQueryBuilder()
            .whereCondition('Type = \'' + SOQLBuilder.sanitize(accountType) + '\'')
            .orderBy('Name ASC')
            .execute();
    }

    /**
     * Returns Accounts owned by the given user.
     * @param ownerId The Id of the owning User.
     * @return List<Account>
     */
    public List<Account> selectByOwnerId(Id ownerId) {
        return (List<Account>) newQueryBuilder()
            .whereCondition('OwnerId = \'' + ownerId + '\'')
            .orderBy('Name ASC')
            .execute();
    }

    /**
     * Returns Accounts whose Name contains the given search term (case-insensitive LIKE).
     * @param searchTerm Partial or full Account name.
     * @return List<Account>
     */
    public List<Account> selectByNameLike(String searchTerm) {
        return (List<Account>) newQueryBuilder()
            .whereCondition('Name LIKE \'%' + SOQLBuilder.sanitize(searchTerm) + '%\'')
            .orderBy('Name ASC')
            .execute();
    }
}
