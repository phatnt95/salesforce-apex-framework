/**
 * @description       : Selector class for the Lead SObject.
 *                      All queries are built via SOQLBuilder (through SObjectSelector.newQueryBuilder()).
 * @author            : PHAT NGUYEN
 * @group             : Selectors
 * @last modified on  : 09-25-2026
 * @last modified by  : PHAT NGUYEN
**/
public with sharing class LeadSelector extends SObjectSelector {

    // ─────────────────────────────────────────────────────────────────────────
    // ISObjectSelector — required overrides
    // ─────────────────────────────────────────────────────────────────────────

    public override Schema.SObjectType getSObjectType() {
        return Lead.SObjectType;
    }

    public override List<String> getDefaultFields() {
        return new List<String>{
            'Id',
            'FirstName',
            'LastName',
            'Name',
            'Company',
            'Email',
            'Phone',
            'Status',
            'LeadSource',
            'Industry',
            'IsConverted',
            'ConvertedAccountId',
            'ConvertedContactId',
            'OwnerId',
            'CreatedDate',
            'LastModifiedDate'
        };
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Custom query methods
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Returns Leads filtered by Status.
     * @param status The Lead Status picklist value (e.g. 'Open - Not Contacted', 'Working - Contacted').
     * @return List<Lead>
     */
    public List<Lead> selectByStatus(String status) {
        return (List<Lead>) newQueryBuilder()
            .whereCondition('Status = \'' + SOQLBuilder.sanitize(status) + '\'')
            .orderBy('CreatedDate DESC')
            .execute();
    }

    /**
     * Returns Leads filtered by LeadSource.
     * @param leadSource The Lead Source picklist value (e.g. 'Web', 'Phone Inquiry').
     * @return List<Lead>
     */
    public List<Lead> selectByLeadSource(String leadSource) {
        return (List<Lead>) newQueryBuilder()
            .whereCondition('LeadSource = \'' + SOQLBuilder.sanitize(leadSource) + '\'')
            .orderBy('CreatedDate DESC')
            .execute();
    }

    /**
     * Returns Leads that have NOT yet been converted.
     * @return List<Lead>
     */
    public List<Lead> selectUnconvertedLeads() {
        return (List<Lead>) newQueryBuilder()
            .whereCondition('IsConverted = false')
            .orderBy('CreatedDate DESC')
            .execute();
    }

    /**
     * Returns Leads filtered by Industry.
     * @param industry The Industry picklist value.
     * @return List<Lead>
     */
    public List<Lead> selectByIndustry(String industry) {
        return (List<Lead>) newQueryBuilder()
            .whereCondition('Industry = \'' + SOQLBuilder.sanitize(industry) + '\'')
            .orderBy('LastName ASC')
            .execute();
    }

    /**
     * Returns Leads whose Email matches (case-insensitive exact match).
     * @param email The email address to search.
     * @return List<Lead>
     */
    public List<Lead> selectByEmail(String email) {
        return (List<Lead>) newQueryBuilder()
            .whereCondition('Email = \'' + SOQLBuilder.sanitize(email) + '\'')
            .execute();
    }
}
