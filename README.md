# Salesforce Apex Framework

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![API Version](https://img.shields.io/badge/API%20Version-67.0-brightgreen.svg)](https://developer.salesforce.com/)
[![Apex Tests](https://img.shields.io/badge/Tests-100%25%20Passing-success.svg)](#testing)

A lightweight, enterprise-ready Apex framework for building scalable and maintainable Salesforce applications. It establishes a consistent architecture for data retrieval, dynamic SOQL construction, transaction management, and automated test data generation.

---

## Table of Contents

- [Overview](#overview)
- [Quick Deploy](#quick-deploy)
- [Architecture](#architecture)
- [Core Components](#core-components)
  - [SOQLBuilder](#soqlbuilder)
  - [SObjectSelector](#sobjectselector)
  - [SObjectUnitOfWork](#sobjectunitofwork)
  - [TestDataFactory](#testdatafactory)
- [Ready-to-Use Selectors](#ready-to-use-selectors)
- [Project Structure](#project-structure)
- [Design Principles](#design-principles)
- [Testing](#testing)
- [Salesforce CLI Commands](#salesforce-cli-commands)
- [AI Coding Agent Integration](#ai-coding-agent-integration)
- [License](#license)

---

## Overview

The framework provides foundational building blocks designed to enforce separation of concerns in enterprise Apex codebases:

* **`SOQLBuilder`**: Fluent, type-safe dynamic SOQL query builder supporting security enforcement, user mode, subqueries, bind variables, and automated ID list formatting.
* **`SObjectSelector`**: Abstract base selector class enforcing consistent field selection, default queries (`selectAll`, `selectById`), and default-field validation.
* **`SObjectUnitOfWork`**: Transaction manager coordinating ordered DML operations (inserts, updates, deletes), parent-child relationship resolution, and automatic rollback on failure.
* **`TestDataFactory`**: Centralized test data generator with sensible defaults, unique sequence tracking, and duplicate rule bypass.
* **Reference Implementations**: Production-grade selectors for `Account`, `Contact`, `Case`, and `Lead`.

---

## Quick Deploy

Deploy the framework directly to your Salesforce environment with one click:

| Environment | 1-Click Deployment |
| :--- | :--- |
| **Production / Developer Org** | [![Deploy to Salesforce](https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/button/button.png)](https://githubsfdeploy.herokuapp.com/?owner=phatnt95&repo=salesforce-apex-framework&ref=main) |
| **Sandbox Org** | [![Deploy to Salesforce Sandbox](https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/button/button.png)](https://githubsfdeploy.herokuapp.com/?owner=phatnt95&repo=salesforce-apex-framework&ref=main&target=sandbox) |

---

## Architecture

The framework decouples data reads and writes from business logic across triggers, handlers, services, and controllers:

```text
               ┌──────────────────────────────────────────────┐
               │    Trigger / Controller / Invocable Flow     │
               └──────────────────────┬───────────────────────┘
                                      │
                                      ▼
               ┌──────────────────────────────────────────────┐
               │             Service / Domain Layer           │
               └──────────────┬───────────────────────────────┘
                              │
            ┌─────────────────┴─────────────────┐
            │ READ                              │ WRITE
            ▼                                   ▼
┌───────────────────────┐           ┌───────────────────────┐
│    SObjectSelector    │           │   SObjectUnitOfWork   │
└───────────┬───────────┘           └───────────┬───────────┘
            │                                   │
            ▼                                   ▼
┌───────────────────────┐           ┌───────────────────────┐
│      SOQLBuilder      │           │    Database DML       │
└───────────┬───────────┘           │  (Ordered & Atomic)   │
            │                       └───────────────────────┘
            ▼
┌───────────────────────┐
│     SOQL Database     │
│   (System/User Mode)  │
└───────────────────────┘
```

### Core Architecture Rules

1. **Reads go through a Selector**: Never place inline SOQL queries directly in service classes, triggers, or UI controllers. Always query through the dedicated `SObjectSelector`.
2. **Selectors compose via `SOQLBuilder`**: Selector query methods start with `newQueryBuilder()` and fluently construct queries, ensuring centralized security and field consistency.
3. **Writes go through `SObjectUnitOfWork`**: Coordinate inserts, updates, and deletes through Unit of Work. Call `commitWork()` at the transaction boundary rather than running scattered DML statements.

---

## Core Components

### SOQLBuilder

`SOQLBuilder` offers a fluent, chainable API for building dynamic SOQL queries with compile-time safety and runtime security:

```apex
// 1. Fluent Query Construction
String query = new SOQLBuilder(Account.SObjectType)
    .selectFields(new List<String>{ 'Id', 'Name', 'Industry', 'AnnualRevenue' })
    .whereCondition('Industry = \'Technology\'')
    .orderBy('AnnualRevenue DESC NULLS LAST')
    .setLimit(50)
    .withUserMode()
    .build();

// 2. Direct Execution with Bind Variables
List<SObject> accounts = new SOQLBuilder(Account.SObjectType)
    .selectFields('Id, Name, Industry')
    .whereCondition('Industry = :targetIndustry')
    .bind('targetIndustry', 'Technology')
    .withUserMode()
    .execute();
```

#### Key Capabilities

* **Field Selection**: Single field (`selectField`), comma-separated strings (`selectFields('Id, Name')`), `List<String>`, `Set<String>`, and Field Sets (`Schema.FieldSet`).
* **Subqueries**: Add child relationship queries using `selectSubQuery(SOQLBuilder childBuilder)`.
* **Where Clauses**: Chainable `whereCondition(String condition)` joined automatically by `AND`.
* **Order & Pagination**: `orderBy(String)`, `setLimit(Integer)`, and `setOffset(Integer)`.
* **Security & Access**: `withSecurityEnforced()` for `WITH SECURITY_ENFORCED`, or `withUserMode()` for `AccessLevel.USER_MODE`.
* **Bind Variables**: `bind(String key, Object value)` and `bind(Map<String, Object>)` executed with `Database.queryWithBinds`.
* **ID Formatting Helper**: `SOQLBuilder.formatIds(Set<Id> ids)` safely formats ID collections into valid SOQL expressions (`'('001...', '001...')'`).
* **Input Sanitization**: `SOQLBuilder.sanitize(String input)` escapes single quotes to safeguard against SOQL injection.

---

### SObjectSelector

`SObjectSelector` is the abstract base class for all object-specific query selectors. Subclasses declare their target SObject type and default fields, while inheriting standard query capabilities.

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
            'OwnerId',
            'CreatedDate'
        };
    }

    // Custom domain-specific queries
    public List<Account> selectByIndustry(String industry) {
        return (List<Account>) newQueryBuilder()
            .whereCondition('Industry = \'' + SOQLBuilder.sanitize(industry) + '\'')
            .orderBy('Name ASC')
            .execute();
    }
}
```

#### Inherited Methods

* **`selectAll()`**: Queries all records using the default fields.
* **`selectById(Set<Id> ids)`**: Queries records matching the provided set of IDs.
* **`newQueryBuilder()`**: Instantiates a pre-configured `SOQLBuilder` loaded with default fields and SObject name.
* **Default Field Validation**: Automatically verifies on invocation that `getDefaultFields()` contains at least one field and includes `'Id'`.

---

### SObjectUnitOfWork

`SObjectUnitOfWork` implements the Unit of Work design pattern to manage database transactions. It enforces proper execution order, automatically resolves parent-child relationships, and handles transaction rollbacks:

```apex
// Define execution dependency order: Parent first, then Child
SObjectUnitOfWork uow = new SObjectUnitOfWork(new List<Schema.SObjectType>{
    Account.SObjectType,
    Contact.SObjectType
});

// Create records
Account acc = new Account(Name = 'Acme Corp');
Contact con = new Contact(LastName = 'Smith');

// Register new parent
uow.registerNew(acc);

// Register child and link to parent before insert
uow.registerNew(con, Contact.AccountId, acc);

// Commit all work in a single transaction
uow.commitWork();
```

#### Transaction Flow

1. **Dependency Order Execution**: Inserts and updates proceed strictly in the order specified in the constructor (e.g. `Account` then `Contact`).
2. **Relationship Resolution**: Automatically assigns parent record IDs to child lookup fields before child records are inserted.
3. **Reverse-Order Deletions**: Deletions execute in reverse dependency order (child before parent) to prevent foreign key errors.
4. **Atomic Rollback**: If any DML statement fails, `commitWork()` rolls back to the initial `Savepoint` and re-throws the exception.

---

### TestDataFactory

`TestDataFactory` provides centralized, consistent test data generation with built-in protections against duplicate rules and picklist validation issues:

```apex
// Insert 1 Account
Account acc = TestDataFactory.createAccount(true);

// Build 3 Contacts linked to the Account (in memory)
List<Contact> contacts = TestDataFactory.createContacts(3, acc.Id, false);

// Create Cases and Leads
Case singleCase = TestDataFactory.createCase(acc.Id, true);
List<Lead> leads = TestDataFactory.createLeads(5, true);
```

#### Factory Highlights

* **Safe Insertion**: Uses `Database.DMLOptions` with `duplicateRuleHeader.allowSave = true` to prevent test failures caused by active duplicate rules.
* **Sequence Generators**: Employs static sequence counters (`accountSequence`, `contactSequence`, etc.) so multiple factory calls within the same transaction generate unique names and emails.
* **Clean Standards**: Avoids hardcoding strict picklist fields (such as State & Country codes) that could fail in customized orgs.

---

## Ready-to-Use Selectors

The repository includes battle-tested selectors and test suites for standard Salesforce objects:

| Selector | SObject | Key Query Methods |
| :--- | :--- | :--- |
| [`AccountSelector`](file:///d:/DEV/salesforce-apex-framework/force-app/main/default/classes/AccountSelector.cls) | `Account` | `selectByIndustry`, `selectByType`, `selectByOwnerId`, `selectByNameLike` |
| [`ContactSelector`](file:///d:/DEV/salesforce-apex-framework/force-app/main/default/classes/ContactSelector.cls) | `Contact` | `selectByAccountId`, `selectByAccountIds`, `selectByEmail`, `selectByDepartment` |
| [`CaseSelector`](file:///d:/DEV/salesforce-apex-framework/force-app/main/default/classes/CaseSelector.cls) | `Case` | `selectByAccountId`, `selectByStatus`, `selectByPriority`, `selectOpenCases`, `selectByContactId` |
| [`LeadSelector`](file:///d:/DEV/salesforce-apex-framework/force-app/main/default/classes/LeadSelector.cls) | `Lead` | `selectByStatus`, `selectByLeadSource`, `selectUnconvertedLeads`, `selectByIndustry`, `selectByEmail` |

---

## Project Structure

```text
salesforce-apex-framework/
├── force-app/
│   └── main/default/classes/
│       ├── Interfaces
│       │   ├── ISObjectSelector.cls
│       │   └── ISObjectUnitOfWork.cls
│       │
│       ├── Core Framework
│       │   ├── SOQLBuilder.cls
│       │   ├── SOQLBuilderTest.cls
│       │   ├── SObjectSelector.cls
│       │   ├── SObjectSelectorTest.cls
│       │   ├── SObjectUnitOfWork.cls
│       │   └── SObjectUnitOfWorkTest.cls
│       │
│       ├── Domain Selectors
│       │   ├── AccountSelector.cls
│       │   ├── AccountSelectorTest.cls
│       │   ├── ContactSelector.cls
│       │   ├── ContactSelectorTest.cls
│       │   ├── CaseSelector.cls
│       │   ├── CaseSelectorTest.cls
│       │   ├── LeadSelector.cls
│       │   └── LeadSelectorTest.cls
│       │
│       └── Test Utilities
│           └── TestDataFactory.cls
│
├── manifest/
│   └── package.xml
├── config/
│   └── project-scratch-def.json
├── sfdx-project.json
├── package.json
└── README.md
```

---

## Design Principles

### 1. Separation of Concerns
* **Business Rules** reside in Services and Domain classes.
* **Data Retrieval** belongs exclusively to `SObjectSelector`.
* **SOQL String Construction** is delegated to `SOQLBuilder`.
* **DML Persistence & Transactions** belong to `SObjectUnitOfWork`.

### 2. Consistency & Reusability
Every SObject has one canonical selector class. This eliminates duplicate query logic, avoids missing fields, and simplifies query maintenance across the application.

### 3. Enterprise Security
`SOQLBuilder` simplifies compliance with Salesforce security review standards by natively supporting:
* `withSecurityEnforced()` for field- and object-level read permissions.
* `withUserMode()` for `AccessLevel.USER_MODE` query enforcement.
* Strict sanitization to eliminate dynamic SOQL injection vulnerabilities.

---

## Testing

The framework achieves **100% test pass rate** with thorough assertions and edge case validation:

* Query construction, field concatenation, sanitization, and bind parameter execution.
* Base selector validation (null checks, missing `Id` field detection, empty ID sets).
* Unit of Work transactional rollback, dirty-state validation, and relationship linking.
* Duplicate-safe test record creation via `TestDataFactory`.

### Run All Tests via CLI

```bash
sf apex run test \
    --tests AccountSelectorTest \
    --tests ContactSelectorTest \
    --tests CaseSelectorTest \
    --tests LeadSelectorTest \
    --tests SObjectUnitOfWorkTest \
    --tests SOQLBuilderTest \
    --tests SObjectSelectorTest \
    --wait 10 \
    --result-format human
```

---

## Salesforce CLI Commands

### 1. Authenticate with your Org

```bash
sf org login web --alias my-org
```

### 2. Deploy Using Manifest

```bash
sf project deploy start \
    --manifest manifest/package.xml \
    --target-org my-org
```

### 3. Deploy and Run Local Tests

```bash
sf project deploy start \
    --manifest manifest/package.xml \
    --target-org my-org \
    --test-level RunLocalTests
```

### 4. Deploy Entire Source

```bash
sf project deploy start \
    --source-dir force-app \
    --target-org my-org
```

---

## AI Coding Agent Integration

This framework is built to integrate with AI-assisted development tools and Autonomous Coding Agents. 

Agents adhering to the framework will consistently generate compliant code:

* **Query Generation**: Agents are instructed to extend `SObjectSelector` and use `SOQLBuilder` rather than writing inline SOQL queries.
* **DML Operations**: Agents register mutations with `SObjectUnitOfWork` rather than calling standalone `insert` or `update` statements.
* **Test Creation**: Agents leverage `TestDataFactory` for clean, reliable mock data without triggering validation rule or duplicate rule errors.

---

## License

This project is licensed under the [MIT License](LICENSE).
