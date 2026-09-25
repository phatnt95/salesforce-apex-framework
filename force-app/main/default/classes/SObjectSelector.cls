/**
 * @description       : Abstract base class for all SObject Selector classes.
 *                      All queries MUST be constructed via SOQLBuilder.
 *                      Extend this class and implement getSObjectType() and getDefaultFields()
 *                      to create a concrete selector for a specific SObject.
 *
 *                      Usage example:
 *                        public class AccountSelector extends SObjectSelector {
 *                            public override Schema.SObjectType getSObjectType() {
 *                                return Account.SObjectType;
 *                            }
 *                            public override List<String> getDefaultFields() {
 *                                return new List<String>{ 'Id', 'Name', 'Industry', 'AnnualRevenue' };
 *                            }
 *                            public List<Account> selectByIndustry(String industry) {
 *                                return (List<Account>) newQueryBuilder()
 *                                    .whereCondition('Industry = \'' + SOQLBuilder.sanitize(industry) + '\'')
 *                                    .execute();
 *                            }
 *                        }
 *
 * @author            : PHAT NGUYEN
 * @group             : 
 * @last modified on  : 09-25-2026
 * @last modified by  : PHAT NGUYEN
**/
public abstract class SObjectSelector implements ISObjectSelector {

    public class SelectorException extends Exception {}

    // ─────────────────────────────────────────────────────────────────────────
    // Abstract methods — must be implemented by subclasses
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Returns the SObjectType this selector is responsible for.
     * Example: return Account.SObjectType;
     */
    public abstract Schema.SObjectType getSObjectType();

    /**
     * Returns the default fields to include in every query.
     * Must always include 'Id' at minimum.
     * Example: return new List<String>{ 'Id', 'Name' };
     */
    public abstract List<String> getDefaultFields();

    // ─────────────────────────────────────────────────────────────────────────
    // ISObjectSelector — concrete implementations
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Selects all records of the SObject type using the default fields.
     * @return List<SObject>
     */
    public List<SObject> selectAll() {
        return newQueryBuilder().execute();
    }

    /**
     * Selects records matching the given set of Ids using the default fields.
     * @param ids Set of record Ids to query.
     * @return List<SObject>
     */
    public List<SObject> selectById(Set<Id> ids) {
        if (ids == null || ids.isEmpty()) {
            return new List<SObject>();
        }
        return newQueryBuilder()
            .whereCondition('Id IN :ids')
            .execute();
    }

    /**
     * Creates a new SOQLBuilder pre-loaded with the SObject name and default fields.
     * Subclasses should use this as the entry point for all custom query methods.
     * @return SOQLBuilder
     */
    public SOQLBuilder newQueryBuilder() {
        validateDefaultFields();
        SOQLBuilder builder = new SOQLBuilder(getSObjectType())
            .selectFields(getDefaultFields());
        return builder;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Private helpers
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Validates that the subclass returns a non-empty default fields list
     * that contains at least the 'Id' field.
     */
    private void validateDefaultFields() {
        List<String> fields = getDefaultFields();
        if (fields == null || fields.isEmpty()) {
            throw new SelectorException(
                getSObjectType().getDescribe().getName() + ': getDefaultFields() must return at least one field.'
            );
        }
        Boolean hasId = false;
        for (String f : fields) {
            if (f.equalsIgnoreCase('Id')) {
                hasId = true;
                break;
            }
        }
        if (!hasId) {
            throw new SelectorException(
                getSObjectType().getDescribe().getName() + ': getDefaultFields() must include the Id field.'
            );
        }
    }
}
