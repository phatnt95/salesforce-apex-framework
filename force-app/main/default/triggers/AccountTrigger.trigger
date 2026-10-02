/**
 * @description One-trigger-per-object implementation for Account SObject.
 * Contains no business logic; delegates execution immediately to AccountTriggerHandler.
 *
 * @author PHAT NGUYEN
 */
trigger AccountTrigger on Account(
    before insert,
    before update,
    before delete,
    after insert,
    after update,
    after delete,
    after undelete
) {
    new AccountTriggerHandler().run();
}
