/**
 * @description Handler class for AccountTrigger demonstrating the one-trigger-per-object pattern.
 * Coordinates before and after trigger events and delegates to service layer if necessary.
 *
 * @author PHAT NGUYEN
 * @group Handlers
 */
public with sharing class AccountTriggerHandler extends TriggerHandler {
    /**
     * @description Orchestrates before insert logic for Account records.
     * Populates a default description if none is provided.
     */
    protected override void beforeInsert() {
        for (Account acc : (List<Account>) newList) {
            if (String.isBlank(acc.Description)) {
                acc.Description = 'Default description set by AccountTriggerHandler';
            }
        }
    }

    /**
     * @description Orchestrates before update logic for Account records.
     * Updates description when Industry is modified.
     */
    protected override void beforeUpdate() {
        for (Account acc : (List<Account>) newList) {
            Account oldAcc = (Account) oldMap.get(acc.Id);
            if (acc.Industry != oldAcc.Industry) {
                acc.Description =
                    'Industry updated from ' +
                    oldAcc.Industry +
                    ' to ' +
                    acc.Industry;
            }
        }
    }

    /**
     * @description Orchestrates after insert logic for Account records.
     */
    protected override void afterInsert() {
        // Business logic or service delegation can be added here
    }

    /**
     * @description Orchestrates after update logic for Account records.
     */
    protected override void afterUpdate() {
        // Business logic or service delegation can be added here
    }
}
