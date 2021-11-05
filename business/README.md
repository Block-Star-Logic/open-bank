# The Open Bank - Business Guide

The following documentation has been prepared for the Business User/Owner/Executive looking to implement the Open Bank project as part of their Web 3 Enterprise strategy. 

## Introduction 
Open Bank has been created to provide your organisation with the ability to manage your decentralized finances beyond well beyond the standard wallet and it provides your organisation with multi-role decentralized non-custodial banking access to your dApp related Enterprise finances. 
Open Bank provides you with the ability to engage in sophisticated on chain business banking interactions that can help you serve multiple communities with the same suite of dApps. 
The features provided by Open Bank as standard are:
* **Pay in** 
* **Pay out** 
* **Pay out Multi** 
* **Nominee Deposit** 
* **Nominee Withdrawal** 
* **Request Debit** 

### Feature summary 
#### Pay in 
The **Pay in** feature enables both users and dApps to make payments into Open Bank. Payments can be barred from specific entities
#### Pay out 
The  **Pay out** feature enables authorised users or dApps to trigger pay outs from Open Bank. 
#### Pay out Multi 
The **Pay out Multi** feature enables authorised dApps to trigger multiple payments to multiple payees in the same transaction from Open Bank. 
#### Nominee Deposit 
The **Nominee Deposit** feature enables a specific nominated account or an authorised user to make a deposit to Open Bank. This is typically used when performing business actions such as fiat to crypto on ramp
#### Nominee Withdrawal 
The **Nominee Withdrawal** feature enables a specific nominated account or an authorised user to make a withdrawal from Open Bank. This is typically used when performing business actions such as crypto to fiat off ramp 
#### Request Debit 
The **Request Debit** feature enables suppliers or partners to create timed debits against Open Bank. These Request Debits allow suppliers or partners to make permissionless debit claims against Open Bank at regular timed intervals. This is typically useful when paying for recurring services which incur fixed costs. 

To illustrate how to implement Open Bank in your business we will use the Web 3 Enterprise Business Example below. 

## Web 3 Enterprise Business Example

In this business example we have an Enterprise dApp called NFT Factory provided by We Are Decentralized (WAD). NFT Factory provides white label NFT minting services for NFT Projects. We Are Decentralized provides telephone and social media support for NFT projects. NFT Factory uses Open Bank as it's on chain financial core. Below are some of the business Capabilities that Open Bank provides to NFT Factory. 

### Revenue Management 
Using Open Bank **Pay In** NFT Factory is able to route payments straight through to Open Bank hence it does not hold any funds during NFT project minting runs. As Open Bank provides multi-role access, during the minting run if an NFT project or customer requires a refund, the dApp utilised by the We Are Decentralized team enables the Customer Support person to execute a controlled **Pay Out** to the affected customer in realtime. 

### Multi Party Partner Payments 
At the end of the minting run We Are Decentralized is able to quickly and easily disburse multiple payments to NFT Project team members using the Open Bank **Pay Out Multi** feature. This feature also allows We are Decentralized to pay other partners related to the project simultaneously. 

### Single Partner Payments
For one off single partner payments Open Bank provides a **Pay out** feature.

### Supplier Request Debits
Suppliers to We Are Decentralized can also register for **Request Debits** which are pre-agreed direct debits against Open Bank. Once approved. These debits can be claimed at the contractually agreed intervals and are paid to the entity listed on the Request Debit registration

### Treasury Management
Treasury managment is facilitated by the Open Bank **Nominee Deposit** and **Nominee withdrawal** feature. This enables large deposits and withdrawals to be exclusively routed to *from* and *to* Open Bank by a nominated on chain account.

## Role Matrix 
The Open Bank Role Matrix is a core part of the operation and maintenance of Open Bank. The Role Matrix provides governance for Open Bank operation. The diagram below illustrates the different roles that could be used in an Open Bank implementation.<br/>  
<img src="https://github.com/Block-Star-Logic/open-bank/blob/b34ffe216edfca10a82081b0cbd181e20f9eecbf/media/open%20bank-Open%20Bank%20Communities.drawio.png" alt="open bank deployment illustration"/>

The Open Bank Role Matrix aligns the functions of Open Bank with the user communities that need governed access. Below is an example role matrix.<br/>
<img src="https://github.com/Block-Star-Logic/open-bank/blob/27592f03dffe429cde6c454d173be05d9cb53ec0/media/open%20bank-Open%20Bank%20Role%20Matrix.drawio.png" alt="Open Bank Role Matrix Example"/>

To build an Open Bank Role Matrix the proceedure below might be taken as an initial approach:

1. Define your business hierarchy i.e. which business roles you have e.g. analyst, manager etc.
2. Map the features provided by Open Bank to the users, dApps and communities that require access
3. Identify and fix any security problems in the lists e.g. a dApp administrator having business manager functions when they shouldn't
3. Hand over the lists to the Open Bank administrator to implement on Open Roles
4. Test your Web 3 Enterprise dApp functions behave according your Open Bank Role Matrix e.g. payments from your W3E dApp are being routed to Open Bank.
5. Done. You should now have a working implmentation of Open Bank in your decentralzed business 


