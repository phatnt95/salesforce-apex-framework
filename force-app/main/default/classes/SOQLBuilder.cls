/**
 * @description       : Framework to build dynamic SOQL using Builder Pattern
 * @author            : PHAT NGUYEN
 * @group             : 
 * @last modified on  : 2026-04-23
 * @last modified by  : PHAT NGUYEN
**/
public with sharing class SOQLBuilder {
    private Set<String> selectFields;
    private String sObjectName;
    private List<String> whereConditions;
    private String orderByClause;
    private Integer limitCount;
    private Integer offsetCount;
    private Boolean isSecurityEnforced;
    private Boolean isUserMode;

    public SOQLBuilder(String sObjectName) {
        this.sObjectName = sObjectName;
        this.selectFields = new Set<String>();
        this.whereConditions = new List<String>();
        this.isSecurityEnforced = false;
        this.isUserMode = false;
    }

    public SOQLBuilder(Schema.SObjectType sObjectType) {
        this(sObjectType.getDescribe().getName());
    }

    public SOQLBuilder selectField(String field) {
        if (String.isNotBlank(field)) {
            this.selectFields.add(field.trim());
        }
        return this;
    }

    public SOQLBuilder selectFields(String fields) {
        if (String.isNotBlank(fields)) {
            for (String f : fields.split(',')) {
                if (String.isNotBlank(f)) {
                    this.selectFields.add(f.trim());
                }
            }
        }
        return this;
    }

    public SOQLBuilder selectFields(List<String> fields) {
        if (fields != null) {
            for (String f : fields) {
                if (String.isNotBlank(f)) {
                    this.selectFields.add(f.trim());
                }
            }
        }
        return this;
    }

    public SOQLBuilder selectFields(Set<String> fields) {
        if (fields != null) {
            for (String f : fields) {
                if (String.isNotBlank(f)) {
                    this.selectFields.add(f.trim());
                }
            }
        }
        return this;
    }

    public SOQLBuilder selectFields(Schema.FieldSet fieldSet) {
        if (fieldSet != null) {
            for (Schema.FieldSetMember fsm : fieldSet.getFields()) {
                this.selectFields.add(fsm.getFieldPath());
            }
        }
        return this;
    }

    public SOQLBuilder selectSubQuery(SOQLBuilder subQueryBuilder) {
        if (subQueryBuilder != null) {
            this.selectFields.add('(' + subQueryBuilder.build() + ')');
        }
        return this;
    }

    public SOQLBuilder whereCondition(String condition) {
        if (String.isNotBlank(condition)) {
            this.whereConditions.add(condition.trim());
        }
        return this;
    }

    public SOQLBuilder orderBy(String orderByClause) {
        this.orderByClause = orderByClause;
        return this;
    }

    public SOQLBuilder setLimit(Integer limitCount) {
        this.limitCount = limitCount;
        return this;
    }

    public SOQLBuilder setOffset(Integer offsetCount) {
        this.offsetCount = offsetCount;
        return this;
    }

    public SOQLBuilder withSecurityEnforced() {
        this.isSecurityEnforced = true;
        return this;
    }

    public SOQLBuilder withUserMode() {
        this.isUserMode = true;
        return this;
    }

    public static String sanitize(String input) {
        return String.isBlank(input) ? input : String.escapeSingleQuotes(input);
    }

    public String build() {
        String query = 'SELECT ';
        if (this.selectFields.isEmpty()) {
            query += 'Id';
        } else {
            List<String> fieldsList = new List<String>(this.selectFields);
            query += String.join(fieldsList, ', ');
        }

        query += ' FROM ' + this.sObjectName;

        if (!this.whereConditions.isEmpty()) {
            query += ' WHERE ' + String.join(this.whereConditions, ' AND ');
        }

        if (this.isSecurityEnforced && !this.isUserMode) {
            query += ' WITH SECURITY_ENFORCED';
        }

        if (String.isNotBlank(this.orderByClause)) {
            query += ' ORDER BY ' + this.orderByClause;
        }

        if (this.limitCount != null) {
            query += ' LIMIT ' + this.limitCount;
        }

        if (this.offsetCount != null) {
            query += ' OFFSET ' + this.offsetCount;
        }

        return query;
    }

    public List<SObject> execute() {
        String query = build();
        if (this.isUserMode) {
            return Database.query(query, AccessLevel.USER_MODE);
        } else {
            return Database.query(query);
        }
    }
}