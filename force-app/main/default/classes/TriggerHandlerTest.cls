/**
 * @description Comprehensive unit tests for the TriggerHandler framework and AccountTrigger implementation.
 * Validates context dispatching, recursion control, bypass handling, bulk safety, and safe execution outside trigger.
 *
 * @author PHAT NGUYEN
 * @group Tests
 */
@IsTest
private class TriggerHandlerTest {
    @TestSetup
    static void setup() {
        TriggerHandler.clearAllBypasses();
        TriggerHandler.clearAllLoopCounts();
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Test Handlers for Unit Testing
    // ─────────────────────────────────────────────────────────────────────────

    private class TestHandler extends TriggerHandler {
        public String lastMethodCalled;
        public Integer executionCount = 0;

        public TestHandler() {
            super();
        }

        public TestHandler(String name) {
            super(name);
        }

        protected override void beforeInsert() {
            this.lastMethodCalled = 'beforeInsert';
            this.executionCount++;
        }

        protected override void beforeUpdate() {
            this.lastMethodCalled = 'beforeUpdate';
            this.executionCount++;
        }

        protected override void beforeDelete() {
            this.lastMethodCalled = 'beforeDelete';
            this.executionCount++;
        }

        protected override void afterInsert() {
            this.lastMethodCalled = 'afterInsert';
            this.executionCount++;
        }

        protected override void afterUpdate() {
            this.lastMethodCalled = 'afterUpdate';
            this.executionCount++;
        }

        protected override void afterDelete() {
            this.lastMethodCalled = 'afterDelete';
            this.executionCount++;
        }

        protected override void afterUndelete() {
            this.lastMethodCalled = 'afterUndelete';
            this.executionCount++;
        }
    }

    private class OtherHandler extends TriggerHandler {
        public Integer executionCount = 0;

        protected override void afterUpdate() {
            this.executionCount++;
        }
    }

    // Default handler that does not override virtual methods (tests base no-op implementations)
    private class DefaultNoOpHandler extends TriggerHandler {
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 13.1 Context Dispatch Tests
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void testBeforeInsertDispatch() {
        TestHandler handler = new TestHandler();
        handler.setTriggerContext(
            TriggerHandler.TriggerContext.BEFORE_INSERT,
            true
        );
        handler.run();

        Assert.areEqual(
            'beforeInsert',
            handler.lastMethodCalled,
            'beforeInsert must be dispatched'
        );
        Assert.areEqual(
            1,
            handler.executionCount,
            'Execution count should be 1'
        );
    }

    @IsTest
    static void testBeforeUpdateDispatch() {
        TestHandler handler = new TestHandler();
        handler.setTriggerContext(
            TriggerHandler.TriggerContext.BEFORE_UPDATE,
            true
        );
        handler.run();

        Assert.areEqual(
            'beforeUpdate',
            handler.lastMethodCalled,
            'beforeUpdate must be dispatched'
        );
        Assert.areEqual(
            1,
            handler.executionCount,
            'Execution count should be 1'
        );
    }

    @IsTest
    static void testBeforeDeleteDispatch() {
        TestHandler handler = new TestHandler();
        handler.setTriggerContext(
            TriggerHandler.TriggerContext.BEFORE_DELETE,
            true
        );
        handler.run();

        Assert.areEqual(
            'beforeDelete',
            handler.lastMethodCalled,
            'beforeDelete must be dispatched'
        );
        Assert.areEqual(
            1,
            handler.executionCount,
            'Execution count should be 1'
        );
    }

    @IsTest
    static void testAfterInsertDispatch() {
        TestHandler handler = new TestHandler();
        handler.setTriggerContext(
            TriggerHandler.TriggerContext.AFTER_INSERT,
            true
        );
        handler.run();

        Assert.areEqual(
            'afterInsert',
            handler.lastMethodCalled,
            'afterInsert must be dispatched'
        );
        Assert.areEqual(
            1,
            handler.executionCount,
            'Execution count should be 1'
        );
    }

    @IsTest
    static void testAfterUpdateDispatch() {
        TestHandler handler = new TestHandler();
        handler.setTriggerContext(
            TriggerHandler.TriggerContext.AFTER_UPDATE,
            true
        );
        handler.run();

        Assert.areEqual(
            'afterUpdate',
            handler.lastMethodCalled,
            'afterUpdate must be dispatched'
        );
        Assert.areEqual(
            1,
            handler.executionCount,
            'Execution count should be 1'
        );
    }

    @IsTest
    static void testAfterDeleteDispatch() {
        TestHandler handler = new TestHandler();
        handler.setTriggerContext(
            TriggerHandler.TriggerContext.AFTER_DELETE,
            true
        );
        handler.run();

        Assert.areEqual(
            'afterDelete',
            handler.lastMethodCalled,
            'afterDelete must be dispatched'
        );
        Assert.areEqual(
            1,
            handler.executionCount,
            'Execution count should be 1'
        );
    }

    @IsTest
    static void testAfterUndeleteDispatch() {
        TestHandler handler = new TestHandler();
        handler.setTriggerContext(
            TriggerHandler.TriggerContext.AFTER_UNDELETE,
            true
        );
        handler.run();

        Assert.areEqual(
            'afterUndelete',
            handler.lastMethodCalled,
            'afterUndelete must be dispatched'
        );
        Assert.areEqual(
            1,
            handler.executionCount,
            'Execution count should be 1'
        );
    }

    @IsTest
    static void testDefaultBaseNoOpMethods() {
        DefaultNoOpHandler handler = new DefaultNoOpHandler();
        for (
            TriggerHandler.TriggerContext ctx : TriggerHandler.TriggerContext.values()
        ) {
            handler.setTriggerContext(ctx, true);
            handler.run(); // Should cleanly execute default virtual no-op methods
        }
        Assert.isTrue(true, 'Default no-op methods executed without error');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 13.2 Trigger Context Validation Tests
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void testRunOutsideTriggerContextSafelyExits() {
        TestHandler handler = new TestHandler();
        // Trigger.isExecuting is false in test method without setTriggerContext testMode
        handler.run();

        Assert.isNull(
            handler.lastMethodCalled,
            'Handler logic must not run outside a trigger context'
        );
        Assert.areEqual(
            0,
            handler.executionCount,
            'Execution count must remain 0 outside a trigger context'
        );
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 13.3 Recursion / Loop Control Tests
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void testDefaultRecursionLimitExceededThrowsException() {
        TriggerHandler.clearAllLoopCounts();
        TestHandler handler = new TestHandler();
        handler.setTriggerContext(
            TriggerHandler.TriggerContext.AFTER_UPDATE,
            true
        );

        // Run up to default limit of 5
        for (Integer i = 0; i < 5; i++) {
            handler.run();
        }
        Assert.areEqual(
            5,
            handler.executionCount,
            'Should successfully run 5 times'
        );

        // 6th execution should exceed limit and throw TriggerHandlerException
        Boolean exceptionThrown = false;
        try {
            handler.run();
        } catch (TriggerHandler.TriggerHandlerException ex) {
            exceptionThrown = true;
            Assert.isTrue(
                ex.getMessage().contains('TestHandler'),
                'Exception must include handler name'
            );
            Assert.isTrue(
                ex.getMessage().contains('AFTER_UPDATE'),
                'Exception must include context'
            );
            Assert.isTrue(
                ex.getMessage().contains('max=5'),
                'Exception must include max limit'
            );
        }

        Assert.isTrue(
            exceptionThrown,
            'TriggerHandlerException should have been thrown on 6th run'
        );
    }

    @IsTest
    static void testCustomRecursionLimit() {
        TriggerHandler.clearAllLoopCounts();
        TestHandler handler = new TestHandler();
        handler.setTriggerContext(
            TriggerHandler.TriggerContext.BEFORE_UPDATE,
            true
        );
        handler.setMaxLoopCount(2);

        handler.run();
        handler.run();
        Assert.areEqual(
            2,
            handler.executionCount,
            'Should successfully run 2 times'
        );

        Boolean exceptionThrown = false;
        try {
            handler.run();
        } catch (TriggerHandler.TriggerHandlerException ex) {
            exceptionThrown = true;
            Assert.isTrue(
                ex.getMessage().contains('max=2'),
                'Exception must include configured max'
            );
        }

        Assert.isTrue(
            exceptionThrown,
            'Exception must be thrown on 3rd execution'
        );
    }

    @IsTest
    static void testUpdateMaxLoopCountWhenKeyAlreadyExists() {
        TriggerHandler.clearAllLoopCounts();
        TestHandler handler = new TestHandler();
        handler.setTriggerContext(
            TriggerHandler.TriggerContext.BEFORE_INSERT,
            true
        );
        handler.run(); // Initializes loop counter with default 5

        // Now dynamically reconfigure to a higher limit
        handler.setMaxLoopCount(10);
        for (Integer i = 0; i < 9; i++) {
            handler.run();
        }
        Assert.areEqual(
            10,
            handler.executionCount,
            'Should successfully run 10 times total'
        );

        Boolean exceptionThrown = false;
        try {
            handler.run(); // 11th run exceeds 10
        } catch (TriggerHandler.TriggerHandlerException ex) {
            exceptionThrown = true;
            Assert.isTrue(
                ex.getMessage().contains('max=10'),
                'Exception must reflect new configured max'
            );
        }
        Assert.isTrue(exceptionThrown);
    }

    @IsTest
    static void testSetMaxLoopCountValidation() {
        TestHandler handler = new TestHandler();

        Boolean negativeExThrown = false;
        try {
            handler.setMaxLoopCount(-1);
        } catch (TriggerHandler.TriggerHandlerException ex) {
            negativeExThrown = true;
        }
        Assert.isTrue(
            negativeExThrown,
            'Negative loop count must throw TriggerHandlerException'
        );

        Boolean nullExThrown = false;
        try {
            handler.setMaxLoopCount(null);
        } catch (TriggerHandler.TriggerHandlerException ex) {
            nullExThrown = true;
        }
        Assert.isTrue(
            nullExThrown,
            'Null loop count must throw TriggerHandlerException'
        );
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 13.4 Bypass Tests
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void testBypassMechanism() {
        TriggerHandler.clearAllBypasses();
        Assert.isFalse(
            TriggerHandler.isBypassed('TestHandler'),
            'Handler should not be bypassed initially'
        );

        TriggerHandler.bypass('TestHandler');
        Assert.isTrue(
            TriggerHandler.isBypassed('TestHandler'),
            'Handler should be bypassed'
        );

        TestHandler handler = new TestHandler();
        handler.setTriggerContext(
            TriggerHandler.TriggerContext.BEFORE_INSERT,
            true
        );
        handler.run();

        Assert.isNull(
            handler.lastMethodCalled,
            'Logic must not execute when handler is bypassed'
        );
        Assert.areEqual(
            0,
            handler.executionCount,
            'Execution count should remain 0 when bypassed'
        );

        TriggerHandler.clearBypass('TestHandler');
        Assert.isFalse(
            TriggerHandler.isBypassed('TestHandler'),
            'Handler bypass should be cleared'
        );

        handler.run();
        Assert.areEqual(
            'beforeInsert',
            handler.lastMethodCalled,
            'Logic should execute after clearing bypass'
        );
        Assert.areEqual(
            1,
            handler.executionCount,
            'Execution count should increment after bypass cleared'
        );
    }

    @IsTest
    static void testClearAllBypasses() {
        TriggerHandler.bypass('TestHandler');
        TriggerHandler.bypass('OtherHandler');
        Assert.isTrue(TriggerHandler.isBypassed('TestHandler'));
        Assert.isTrue(TriggerHandler.isBypassed('OtherHandler'));

        TriggerHandler.clearAllBypasses();
        Assert.isFalse(TriggerHandler.isBypassed('TestHandler'));
        Assert.isFalse(TriggerHandler.isBypassed('OtherHandler'));
    }

    @IsTest
    static void testBypassSafetyWithNullAndBlank() {
        TriggerHandler.bypass(null);
        TriggerHandler.bypass('');
        Assert.isFalse(TriggerHandler.isBypassed(null));
        Assert.isFalse(TriggerHandler.isBypassed(''));

        // Calling clearBypass on non-bypassed handler is a safe no-op
        TriggerHandler.clearBypass('NonExistentHandler');
        Assert.isFalse(TriggerHandler.isBypassed('NonExistentHandler'));
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 13.5 Bypass Isolation Tests
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void testBypassIsolationBetweenHandlers() {
        TriggerHandler.clearAllBypasses();
        TriggerHandler.bypass('TestHandler');

        Assert.isTrue(
            TriggerHandler.isBypassed('TestHandler'),
            'TestHandler should be bypassed'
        );
        Assert.isFalse(
            TriggerHandler.isBypassed('OtherHandler'),
            'OtherHandler should NOT be bypassed'
        );

        TestHandler testH = new TestHandler();
        testH.setTriggerContext(
            TriggerHandler.TriggerContext.AFTER_UPDATE,
            true
        );
        testH.run();

        OtherHandler otherH = new OtherHandler();
        otherH.setTriggerContext(
            TriggerHandler.TriggerContext.AFTER_UPDATE,
            true
        );
        otherH.run();

        Assert.areEqual(
            0,
            testH.executionCount,
            'Bypassed TestHandler must not execute'
        );
        Assert.areEqual(
            1,
            otherH.executionCount,
            'Non-bypassed OtherHandler must execute'
        );
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 13.6 Loop Isolation Tests
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void testLoopCountIsolationBetweenHandlersAndContexts() {
        TriggerHandler.clearAllLoopCounts();

        // 1. Consume 3 loops on TestHandler:AFTER_UPDATE
        TestHandler testH = new TestHandler();
        testH.setTriggerContext(
            TriggerHandler.TriggerContext.AFTER_UPDATE,
            true
        );
        testH.run();
        testH.run();
        testH.run();
        Assert.areEqual(3, testH.executionCount);

        // 2. OtherHandler:AFTER_UPDATE should start at 0 and run without issue
        OtherHandler otherH = new OtherHandler();
        otherH.setTriggerContext(
            TriggerHandler.TriggerContext.AFTER_UPDATE,
            true
        );
        otherH.run();
        Assert.areEqual(1, otherH.executionCount);

        // 3. TestHandler:BEFORE_UPDATE should also have its own independent loop counter
        TestHandler testBeforeH = new TestHandler();
        testBeforeH.setTriggerContext(
            TriggerHandler.TriggerContext.BEFORE_UPDATE,
            true
        );
        testBeforeH.run();
        Assert.areEqual(1, testBeforeH.executionCount);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Custom Handler Name and LoopCount Helper Unit Tests
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void testCustomHandlerNameConstructor() {
        TestHandler customHandler = new TestHandler('CustomAliasHandler');
        Assert.areEqual(
            'CustomAliasHandler',
            customHandler.getHandlerName(),
            'Should return explicitly assigned name'
        );
    }

    @IsTest
    static void testLoopCountClassMethods() {
        TriggerHandler.LoopCount lc = new TriggerHandler.LoopCount();
        Assert.areEqual(5, lc.getMax(), 'Default max should be 5');
        Assert.areEqual(0, lc.getCount(), 'Initial count should be 0');
        Assert.isFalse(lc.exceeded(), 'Should not be exceeded initially');

        lc.increment();
        Assert.areEqual(1, lc.getCount());

        lc.setMax(1);
        Assert.isFalse(lc.exceeded(), '1 is not > 1');

        lc.increment();
        Assert.areEqual(2, lc.getCount());
        Assert.isTrue(lc.exceeded(), '2 > 1 should be exceeded');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 13.7 Bulk Operations & End-to-End Trigger Tests
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void testAccountTriggerBulkInsertAndUpdate() {
        TriggerHandler.clearAllBypasses();
        TriggerHandler.clearAllLoopCounts();

        List<Account> accounts = TestDataFactory.createAccounts(200, false);
        for (Account acc : accounts) {
            acc.Description = null; // Clear description to verify beforeInsert logic
        }

        Test.startTest();
        insert accounts;
        Test.stopTest();

        List<Account> insertedAccounts = [
            SELECT Id, Description, Industry
            FROM Account
            WHERE Id IN :accounts
        ];
        Assert.areEqual(
            200,
            insertedAccounts.size(),
            'All 200 accounts should be inserted'
        );
        for (Account acc : insertedAccounts) {
            Assert.areEqual(
                'Default description set by AccountTriggerHandler',
                acc.Description,
                'Default description should be set'
            );
        }

        // Test Bulk Update
        for (Account acc : insertedAccounts) {
            acc.Industry = 'Finance';
        }
        update insertedAccounts;

        List<Account> updatedAccounts = [
            SELECT Id, Description, Industry
            FROM Account
            WHERE Id IN :insertedAccounts
        ];
        for (Account acc : updatedAccounts) {
            Assert.areEqual(
                'Industry updated from Technology to Finance',
                acc.Description,
                'Industry change description should be set'
            );
        }
    }

    @IsTest
    static void testAccountTriggerBypassInRealDml() {
        TriggerHandler.clearAllLoopCounts();
        TriggerHandler.bypass('AccountTriggerHandler');

        Account acc = new Account(
            Name = 'Bypass Test Account',
            Industry = 'Consulting',
            Description = null
        );

        Test.startTest();
        insert acc;
        Test.stopTest();

        Account refreshed = [
            SELECT Id, Description
            FROM Account
            WHERE Id = :acc.Id
        ];
        Assert.isNull(
            refreshed.Description,
            'Handler should have been bypassed; Description should remain null'
        );

        TriggerHandler.clearBypass('AccountTriggerHandler');

        refreshed.Industry = 'Banking';
        update refreshed;

        Account updated = [
            SELECT Id, Description
            FROM Account
            WHERE Id = :acc.Id
        ];
        Assert.areEqual(
            'Industry updated from Consulting to Banking',
            updated.Description,
            'Handler should execute once bypass is cleared'
        );
    }

    @IsTest
    static void testAccountTriggerDeleteAndUndelete() {
        Account acc = new Account(
            Name = 'Delete Test Account',
            Industry = 'Technology'
        );
        insert acc;

        Test.startTest();
        delete acc;
        undelete acc;
        Test.stopTest();

        Account restored = [
            SELECT Id, IsDeleted
            FROM Account
            WHERE Id = :acc.Id
            ALL ROWS
        ];
        Assert.isFalse(
            restored.IsDeleted,
            'Account should be successfully restored'
        );
    }
}
