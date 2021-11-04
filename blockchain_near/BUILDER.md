# Open Bank on NEAR - Builders Guide

This guide has been prepared for the Builders on the NEAR blockchain 

This implmentation of Open Bank is built using the RUST programming language. It utilises the NEAR RUST SDK. For more information on RUST see <a href="https://www.rust-lang.org/">here</a>. For more information on how to install and set up the NEAR RUST SDK see <a href="https://docs.near.org/docs/develop/contracts/rust/intro">here</a>

## Design
Open Bank has been built using a "plugin" design pattern that allows for easy extension and migration. The key features of Open Bank are the following:
* Pay in - basic pay in 
* Pay out - basic pay out
* Pay out Multi  - multi party pay out
* Nominee Deposit  - nominee deposit
* Nominee Withdrawal - nominee withdrawal
* Request Debit - timed payments 

### Pay in 
The pay in functionality has been designed to create a Payment object that describes the 'pay in' that has just been made. It has been created with dApp and user communities in mind. When routing in bound payments to Open Bank the **pay in** operation should be used. 
This operation has been designed to be permissive hence implements a 'Barring' list in the Open Roles Role Matrix. 

### Pay out 
The **pay out** fundionality has been designed to create a Payment object that describes the 'pay out' that has just been made. It has been created with dApp and user communities in mind. When routing out bound payments to Open Bank the **pay out** operation should be used. 
This operation has been designed to be fully governed by the Open Roles Role Matrix and implements an 'Allow' list. 

### Pay Out Multi
The **pay out multi** has been designed with dApps and bulk payments in mind. It returns a list of Payment objects describing the individual payments that have been made in the same transaction. When routing multiple payments from your dApp the **pay out multi** operation should be used. 
This operation has been designed to be fully governed by the Open Roles Role Matrix and implements an 'Allow' list. 

### Nominee Deposit 
The **deposit** functionality has been designed with the concept of a "Nominee" in mind. The nominee is the primary business financial center, this can be a wallet or another dApp, however large transactions from Open Bank such as fiat **on** ramp should be carried out using the "Nominee" account. 
This operation has been designed to be fully governed by the Open Roles Role Matrix and implements an 'Allow' list. This operation can always be called by the "Nominee" account by passing the Role Matrix. 

### Nominee Withdrawal 
The **withdrawal** functionality has been designed with the concept of "Nominee" in mind. The nominee is the primary business financial center, this can be a wallet or another dApp, however large transactions from Open Bank such as fiat **off** ramp should be carried out using the "Nominee" account.
This operation has been designed to be fully governed by the Open Roles Role Matrix and implements an 'Allow' list. This operation can always be called by the "Nominee" account by passing the Role Matrix. 

### Request Debit
The **Request Debit** represents a timed payment claim against the Open Bank, it has been designed with service/supplier payments in mind. Request debits work by enabling any other account to register a Request Debit against the Open Bank. This Request Debit then has to be approved by an **authorised user** of the Open Bank as described by the Role Matrix. Once the **Request Debit** has been approved, it can then be claimed against by any account, however it will only **pay out** to the amount requested and to the account stated on the Request Debit, when the time of the Request Debit has been reached or exceeded. 

## How to implement 
The RUST API documentation for this impolementat can be found on Docs.rs <a href="https://docs.rs">here</a> 
The RUST distribution can be downloaded from Crates.io <a href="https://crates.io">here</a>


**For further support join our <a href="https://rebrand.ly/obei_or_git">Discord</a> on the #dev-support channel **
