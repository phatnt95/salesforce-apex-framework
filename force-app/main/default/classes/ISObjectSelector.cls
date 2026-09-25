/**
 * @description       : Interface for SObjectSelector. Defines the contract for all Selector classes
 *                      that query SObject records using SOQLBuilder.
 * @author            : PHAT NGUYEN
 * @group             : 
 * @last modified on  : 09-25-2026
 * @last modified by  : PHAT NGUYEN
**/
public interface ISObjectSelector {
    /**
     * Returns the SObjectType that this selector is responsible for querying.
     * @return Schema.SObjectType
     */
    Schema.SObjectType getSObjectType();

    /**
     * Returns the default list of fields to SELECT in all queries.
     * Implementations must always include at minimum the Id field.
     * @return List<String>
     */
    List<String> getDefaultFields();

    /**
     * Selects all records of the SObject type using the default fields.
     * @return List<SObject>
     */
    List<SObject> selectAll();

    /**
     * Selects records by a set of Ids using the default fields.
     * @param ids Set of record Ids to query.
     * @return List<SObject>
     */
    List<SObject> selectById(Set<Id> ids);

    /**
     * Builds a SOQLBuilder pre-configured with the default fields and SObject type,
     * ready to have additional conditions, ordering, or limits applied before execution.
     * @return SOQLBuilder
     */
    SOQLBuilder newQueryBuilder();
}
