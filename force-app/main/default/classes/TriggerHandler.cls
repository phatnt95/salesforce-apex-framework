/**
 * @description Reusable, production-oriented Apex Trigger Framework base class.
 * Enforces a one-trigger-per-object architecture, centralizes trigger context dispatching,
 * controls recursion/infinite loops, and supports bypassing handlers for migrations or batch operations.
 *
 * Based on the standard pattern described in:
 * "Xây dựng Apex Trigger Framework chuẩn: Handler, Context và kiểm soát Recursion"
 *
 * @author PHAT NGUYEN
 * @group Trigger Framework
 */
public virtual class TriggerHandler {
    /**
     * @description Strongly defined trigger execution contexts.
     */
    public enum TriggerContext {
        BEFORE_INSERT,
        BEFORE_UPDATE,
        BEFORE_DELETE,
        AFTER_INSERT,
        AFTER_UPDATE,
        AFTER_DELETE,
        AFTER_UNDELETE
    }

    /**
     * @description Dedicated exception thrown when framework rules (such as loop limits) are violated.
     */
    public class TriggerHandlerException extends Exception {
    }

    /**
     * @description Internal helper tracking recursion loop counts per handler and context.
     */
    @TestVisible
    public class LoopCount {
        private Integer max;
        private Integer count;

        public LoopCount() {
            this(DEFAULT_MAX_LOOP_COUNT);
        }

        public LoopCount(Integer maxCount) {
            this.max = maxCount;
            this.count = 0;
        }

        public Integer getMax() {
            return this.max;
        }

        public Integer getCount() {
            return this.count;
        }

        public void setMax(Integer max) {
            this.max = max;
        }

        public void increment() {
            this.count++;
        }

        public Boolean exceeded() {
            return this.count > this.max;
        }
    }

    // Default maximum recursion executions permitted before throwing an exception
    private static final Integer DEFAULT_MAX_LOOP_COUNT = 5;

    // Transaction-scoped static state
    @TestVisible
    private static Map<String, LoopCount> loopCountMap = new Map<String, LoopCount>();
    @TestVisible
    private static Set<String> bypassedHandlers = new Set<String>();

    // Instance-scoped state
    @TestVisible
    private TriggerContext context;
    @TestVisible
    private Boolean isTriggerExecuting;
    private Integer maxLoopCount;
    private String customHandlerName;

    protected List<SObject> newList;
    protected List<SObject> oldList;
    protected Map<Id, SObject> newMap;
    protected Map<Id, SObject> oldMap;

    /**
     * @description Default constructor. Automatically inspects and resolves the current trigger context.
     */
    public TriggerHandler() {
        this.setTriggerContext();
    }

    /**
     * @description Constructor with an explicit handler name.
     * @param name Explicit identifier for this handler.
     */
    protected TriggerHandler(String name) {
        this.customHandlerName = name;
        this.setTriggerContext();
        this.newList = Trigger.new;
        this.oldList = Trigger.old;
        this.newMap = Trigger.newMap;
        this.oldMap = Trigger.oldMap;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Public Entry Point
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @description Main entry point invoked by triggers. Validates trigger context,
     * checks bypass registry, increments and validates loop counters, and dispatches
     * to the corresponding context method.
     */
    public void run() {
        if (!validateRun()) {
            return;
        }

        addToLoopCount();

        switch on this.context {
            when BEFORE_INSERT {
                this.beforeInsert();
            }
            when BEFORE_UPDATE {
                this.beforeUpdate();
            }
            when BEFORE_DELETE {
                this.beforeDelete();
            }
            when AFTER_INSERT {
                this.afterInsert();
            }
            when AFTER_UPDATE {
                this.afterUpdate();
            }
            when AFTER_DELETE {
                this.afterDelete();
            }
            when AFTER_UNDELETE {
                this.afterUndelete();
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Loop Count / Recursion Control
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @description Configures the maximum loop count allowed for this handler.
     * Must be greater than or equal to 0.
     * @param max Maximum execution count allowed.
     * @throws TriggerHandlerException if max is null or negative.
     */
    public void setMaxLoopCount(Integer max) {
        if (max == null || max < 0) {
            throw new TriggerHandlerException(
                'Max loop count must be greater than or equal to zero.'
            );
        }
        this.maxLoopCount = max;
        String key = getLoopCountKey();
        if (loopCountMap.containsKey(key)) {
            loopCountMap.get(key).setMax(max);
        }
    }

    /**
     * @description Clears all transaction-scoped loop counters.
     */
    public static void clearAllLoopCounts() {
        loopCountMap.clear();
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Bypass Mechanism
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @description Bypasses a specific handler class for the remainder of the transaction.
     * @param handlerName The name of the handler class to bypass.
     */
    public static void bypass(String handlerName) {
        if (String.isNotBlank(handlerName)) {
            bypassedHandlers.add(handlerName);
        }
    }

    /**
     * @description Clears the bypass on a specific handler class. Safe to call if not bypassed.
     * @param handlerName The name of the handler class to reinstate.
     */
    public static void clearBypass(String handlerName) {
        if (String.isNotBlank(handlerName)) {
            bypassedHandlers.remove(handlerName);
        }
    }

    /**
     * @description Checks if a specific handler class is currently bypassed.
     * @param handlerName The name of the handler class to check.
     * @return Boolean True if bypassed, false otherwise.
     */
    public static Boolean isBypassed(String handlerName) {
        if (String.isBlank(handlerName)) {
            return false;
        }
        return bypassedHandlers.contains(handlerName);
    }

    /**
     * @description Clears all bypassed handlers in the transaction.
     */
    public static void clearAllBypasses() {
        bypassedHandlers.clear();
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Virtual Context Dispatch Methods (No-Op Defaults)
    // ─────────────────────────────────────────────────────────────────────────

    protected virtual void beforeInsert() {
    }
    protected virtual void beforeUpdate() {
    }
    protected virtual void beforeDelete() {
    }
    protected virtual void afterInsert() {
    }
    protected virtual void afterUpdate() {
    }
    protected virtual void afterDelete() {
    }
    protected virtual void afterUndelete() {
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Context Detection & Validation
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @description Validates whether execution should proceed. Safely returns false
     * if not in a trigger context or if the handler is bypassed.
     * @return Boolean True if execution is valid and should proceed.
     */
    @TestVisible
    protected virtual Boolean validateRun() {
        if (!this.isTriggerExecuting || this.context == null) {
            return false;
        }
        if (isBypassed(getHandlerName())) {
            return false;
        }
        return true;
    }

    /**
     * @description Resolves the current trigger context based on standard Trigger boolean flags.
     */
    @TestVisible
    private void setTriggerContext() {
        this.setTriggerContext(null, false);
    }

    /**
     * @description Internal/TestVisible method to establish or mock trigger context.
     * @param ctx The trigger context to set (when in test mode).
     * @param testMode True to allow setting context outside of actual trigger execution.
     */
    @TestVisible
    private void setTriggerContext(TriggerContext ctx, Boolean testMode) {
        if (!Trigger.isExecuting && !testMode) {
            this.isTriggerExecuting = false;
            return;
        } else {
            this.isTriggerExecuting = true;
        }

        if (testMode && ctx != null) {
            this.context = ctx;
            return;
        }

        if (Trigger.isExecuting) {
            if (Trigger.isBefore) {
                if (Trigger.isInsert) {
                    this.context = TriggerContext.BEFORE_INSERT;
                } else if (Trigger.isUpdate) {
                    this.context = TriggerContext.BEFORE_UPDATE;
                } else if (Trigger.isDelete) {
                    this.context = TriggerContext.BEFORE_DELETE;
                }
            } else if (Trigger.isAfter) {
                if (Trigger.isInsert) {
                    this.context = TriggerContext.AFTER_INSERT;
                } else if (Trigger.isUpdate) {
                    this.context = TriggerContext.AFTER_UPDATE;
                } else if (Trigger.isDelete) {
                    this.context = TriggerContext.AFTER_DELETE;
                } else if (Trigger.isUndelete) {
                    this.context = TriggerContext.AFTER_UNDELETE;
                }
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Handler Name & Loop Key Helpers
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @description Resolves the identifier for the current handler instance.
     * Subclasses can override if an explicit name is needed.
     * @return String The handler class name.
     */
    @TestVisible
    protected virtual String getHandlerName() {
        if (String.isNotBlank(this.customHandlerName)) {
            return this.customHandlerName;
        }
        String str = String.valueOf(this);
        Integer colonIndex = str.indexOf(':');
        return colonIndex == -1 ? str : str.substring(0, colonIndex);
    }

    /**
     * @description Generates the key used for loop counter tracking (<HandlerName>:<Context>).
     * @return String Unique key for this handler and context.
     */
    @TestVisible
    protected virtual String getLoopCountKey() {
        String handler = getHandlerName();
        String ctx = this.context != null ? this.context.name() : 'UNKNOWN';
        return handler + ':' + ctx;
    }

    /**
     * @description Increments loop count for the current handler and context.
     * Throws TriggerHandlerException if the configured max limit is exceeded.
     */
    @TestVisible
    private void addToLoopCount() {
        String handlerName = getHandlerName();
        String key = getLoopCountKey();
        Integer configuredMax = (this.maxLoopCount != null)
            ? this.maxLoopCount
            : DEFAULT_MAX_LOOP_COUNT;

        if (!loopCountMap.containsKey(key)) {
            loopCountMap.put(key, new LoopCount(configuredMax));
        }

        LoopCount lc = loopCountMap.get(key);
        lc.increment();
        if (lc.exceeded()) {
            throw new TriggerHandlerException(
                'Trigger handler loop limit exceeded: handler=' +
                    handlerName +
                    ', context=' +
                    (this.context != null ? this.context.name() : 'UNKNOWN') +
                    ', max=' +
                    lc.getMax()
            );
        }
    }
}
