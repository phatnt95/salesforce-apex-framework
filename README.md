# Salesforce Apex Framework

A lightweight, source-driven Apex framework for building maintainable Salesforce applications with a consistent data-access and transaction architecture.

The framework provides reusable building blocks for:

* **`SOQLBuilder`** — build dynamic SOQL using a fluent Builder pattern.
* **`SObjectSelector`** — centralize SObject queries and enforce a Selector layer.
* **`SObjectUnitOfWork`** — coordinate inserts, updates, deletes, relationships, rollback, and transaction ordering.
* **`Selector interfaces`** — define contracts for selector implementations.
* **`TestDataFactory`** — reusable test data helpers for common standard SObjects.
* **`Ready-to-use selector examples`** — Account, Contact, Case, and Lead.
* 
# Deployment

<a href="https://githubsfdeploy.herokuapp.com?owner=phatnt95&repo=salesforce-apex-framework&ref=main">
  <img alt="Deploy to Salesforce"
       src="https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/deploy.png">
</a>

Deploy the framework directly to your Salesforce org without cloning the repository.

## Architecture

```text
Trigger
   │
   ▼
Trigger Handler
   │
   ▼
Service / Domain
   │
   ├────────────── READ ──────────────┐
   │                                 │
   ▼                                 │
SObjectSelector                      │
   │                                 │
   ▼                                 │
SOQLBuilder                           │
   │                                 │
   ▼                                 │
 SOQL                                │
   │                                 │
   └─────────────── WRITE ────────────┘
                     │
                     ▼
              SObjectUnitOfWork
                     │
                     ▼
                    DML
```

### Core Rules

**Reads go through a Selector.**

Do not place application SOQL directly in services, domains, handlers, or controllers. Create or reuse the selector for the SObject being queried.

**Selector queries use `SOQLBuilder`.**

Concrete selector methods should start from `newQueryBuilder()` and compose the query through `SOQLBuilder`.

**Writes go through `SObjectUnitOfWork`.**

Application code should register records with the Unit of Work and call `commitWork()` at the transaction boundary instead of performing scattered DML operations.

---

## Components

### SOQLBuilder

`SOQLBuilder` provides a fluent API for constructing dynamic SOQL:

```apex
String query = new SOQLBuilder(Account.SObjectType)
    .selectFields(new List<String>{
        'Id',
        'Name',
        'Industry'
    })
    .whereCondition('Industry = \'Technology\'')
    .orderBy('Name ASC')
    .setLimit(100)
    .build();
```

Supported features:

* Single field selection
* Multiple field selection
* `List<String>` and `Set<String>` fields
* Field Sets
* Child subqueries
* WHERE conditions
* ORDER BY
* LIMIT
* OFFSET
* `WITH SECURITY_ENFORCED`
* User Mode execution
* Input sanitization
* Direct query execution

Example:

```apex
List<SObject> accounts = new SOQLBuilder(Account.SObjectType)
    .selectFields(new List<String>{
        'Id',
        'Name',
        'Industry'
    })
    .whereCondition('Industry = \'Technology\'')
    .withUserMode()
    .execute();
```

---

### SObjectSelector

All concrete selectors extend `SObjectSelector`.

Example:

```apex
public with sharing class AccountSelector extends SObjectSelector {

    public override Schema.SObjectType getSObjectType() {
        return Account.SObjectType;
    }

    public override List<String> getDefaultFields() {
        return new List<String>{
            'Id',
            'Name',
            'Industry',
            'Type',
            'OwnerId'
        };
    }

    public List<Account> selectByIndustry(String industry) {
        return (List<Account>) newQueryBuilder()
            .whereCondition(
                'Industry = \'' +
                SOQLBuilder.sanitize(industry) +
                '\''
            )
            .orderBy('Name ASC')
            .execute();
    }
}
```

The base selector provides:

* `getSObjectType()`
* `getDefaultFields()`
* `selectAll()`
* `selectById(Set<Id>)`
* `newQueryBuilder()`
* Default-field validation

Every selector should represent **one SObject** and expose business-readable query methods.

Examples:

```text
AccountSelector
├── selectByIndustry()
├── selectByType()
├── selectByOwnerId()
└── selectByNameLike()

ContactSelector
├── selectByAccountId()
├── selectByAccountIds()
├── selectByEmail()
└── selectByDepartment()
```

---

### SObjectUnitOfWork

`SObjectUnitOfWork` centralizes persistence operations.

```apex
SObjectUnitOfWork uow = new SObjectUnitOfWork(
    new List<Schema.SObjectType>{
        Account.SObjectType,
        Contact.SObjectType
    }
);

Account account = new Account(
    Name = 'Acme'
);

Contact contact = new Contact(
    LastName = 'Developer'
);

uow.registerNew(account);

uow.registerNew(
    contact,
    Contact.AccountId,
    account
);

uow.commitWork();
```

Supported operations:

* `registerNew()`
* `registerDirty()`
* `registerDelete()`
* `registerRelationship()`
* Ordered DML by SObject type
* Child-to-parent delete ordering
* Automatic transaction rollback on failure

### Transaction Ordering

The constructor accepts SObject types in dependency order:

```apex
new List<Schema.SObjectType>{
    Account.SObjectType,
    Contact.SObjectType
}
```

This allows the Unit of Work to:

1. Insert parent records first.
2. Resolve child lookup relationships.
3. Insert child records.
4. Process updates.
5. Process deletes in reverse dependency order.
6. Roll back the transaction if any DML operation fails.

---

## Included Selectors

The repository currently includes:

| Selector          | SObject |
| ----------------- | ------- |
| `AccountSelector` | Account |
| `ContactSelector` | Contact |
| `CaseSelector`    | Case    |
| `LeadSelector`    | Lead    |

Each selector demonstrates the intended Selector + `SOQLBuilder` pattern and includes corresponding unit tests.

---

# Quick Deploy

You can deploy the framework directly to a Salesforce org without cloning the repository.

## Production / Developer Org

[![Deploy to Salesforce](https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/button/button.png)](https://githubsfdeploy.herokuapp.com/?owner=phatnt95&repo=salesforce-apex-framework&ref=main)

## Sandbox

[![Deploy to Salesforce Sandbox](https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/button/button.png)](https://githubsfdeploy.herokuapp.com/?owner=phatnt95&repo=salesforce-apex-framework&ref=main&target=sandbox)

The deployment uses the repository's Salesforce metadata and `manifest/package.xml`.

> **Note:** Review the metadata and tests before deploying to a production org. This project is intended as a reusable Apex framework and reference implementation.

---

# Salesforce CLI

## Authenticate

```bash
sf org login web --alias my-org
```

## Deploy Using the Manifest

```bash
sf project deploy start \
    --manifest manifest/package.xml \
    --target-org my-org
```

## Deploy and Run Local Tests

```bash
sf project deploy start \
    --manifest manifest/package.xml \
    --target-org my-org \
    --test-level RunLocalTests
```

## Deploy the Entire Source Directory

```bash
sf project deploy start \
    --source-dir force-app \
    --target-org my-org
```

## Run Apex Tests

```bash
sf apex run test \
    --target-org my-org \
    --test-level RunLocalTests \
    --wait 30
```

---



# Project Structure

```text
salesforce-apex-framework/
│
├── force-app/
│   └── main/default/classes/
│       │
│       ├── ISObjectSelector.cls
│       ├── ISObjectUnitOfWork.cls
│       │
│       ├── SObjectSelector.cls
│       ├── SObjectSelectorTest.cls
│       │
│       ├── SObjectUnitOfWork.cls
│       ├── SObjectUnitOfWorkTest.cls
│       │
│       ├── SOQLBuilder.cls
│       ├── SOQLBuilderTest.cls
│       │
│       ├── AccountSelector.cls
│       ├── AccountSelectorTest.cls
│       │
│       ├── ContactSelector.cls
│       ├── ContactSelectorTest.cls
│       │
│       ├── CaseSelector.cls
│       ├── CaseSelectorTest.cls
│       │
│       ├── LeadSelector.cls
│       ├── LeadSelectorTest.cls
│       │
│       └── TestDataFactory.cls
│
├── manifest/
│   └── package.xml
│
├── config/
├── scripts/
├── sfdx-project.json
└── package.json
```

---

# Design Principles

## 1. One Selector per SObject

SObject-specific read logic belongs to its corresponding selector.

```text
Account  → AccountSelector
Contact  → ContactSelector
Case     → CaseSelector
Lead     → LeadSelector
```

Avoid putting queries directly into business services.

---

## 2. One Query Builder Path

Selector queries should use the existing `SOQLBuilder` implementation.

```text
Service / Domain
       │
       ▼
SObjectSelector
       │
       ▼
SOQLBuilder
       │
       ▼
SOQL
```

This keeps query construction consistent and gives the framework one place to evolve dynamic SOQL behavior.

---

## 3. One Transaction Boundary

Use `SObjectUnitOfWork` to collect changes and commit them together.

```text
Business Logic
      │
      ├── registerNew()
      ├── registerDirty()
      ├── registerDelete()
      │
      ▼
commitWork()
      │
      ▼
DML Transaction
```

---

## 4. Keep Business Logic Out of Data Access

Responsibilities should remain separated:

```text
Service / Domain
    → business rules

Selector
    → data retrieval

SOQLBuilder
    → query construction

UnitOfWork
    → persistence coordination
```

---

# Testing

The framework includes unit tests for:

* `SOQLBuilder`
* `SObjectSelector`
* `SObjectUnitOfWork`
* Account Selector
* Contact Selector
* Case Selector
* Lead Selector

`TestDataFactory` provides reusable test data helpers:

```apex
Account account = TestDataFactory.createAccount(false);
```

The Unit of Work tests cover scenarios including:

* New records
* Parent/child relationships
* Updates
* Deletes
* Transaction rollback
* Invalid SObject types
* Missing record IDs

---

# API Version

The project currently targets Salesforce API version **67.0**, as configured in:

```text
sfdx-project.json
manifest/package.xml
```

---

# AI Coding Agent Integration

This framework is designed to work together with the companion Salesforce Apex AI Rules & Skills project.

```text
salesforce-apex-agent
        │
        │ understands / enforces
        ▼
salesforce-apex-framework
        │
        ├── SObjectUnitOfWork
        ├── SObjectSelector
        ├── SOQLBuilder
        └── TestDataFactory
```

The AI rules can enforce the following architecture:

```text
READ
Service / Domain
      ↓
SObjectSelector
      ↓
SOQLBuilder
      ↓
SOQL
```

```text
WRITE
Service / Domain
      ↓
SObjectUnitOfWork
      ↓
DML
```

For trigger-based implementations, the companion AI rules can additionally enforce:

```text
SObjectTrigger
      ↓
<SObject>TriggerHandler
      ↓
BaseTriggerHandler
      ↓
Service / Domain
```

This ensures AI-generated Apex reuses the existing framework rather than creating parallel abstractions.

---

# License

MIT
