# Open Bank NEAR Blockchain Administrators Guide

**For further support join our <a href="https://rebrand.ly/obei_or_git">Discord</a> on the #admin-support channel** 

This guide has been prepared for administrators working with Open Bank on the NEAR Blockchain. It describes how to typically deploy and configure Open Bank on the NEAR Blockchain. This guide has been prepared for "no-code" administration of Open Bank. The guide uses the NEAR CLI to interface with the NEAR Blockhain. Installation instructions for NEAR CLI can be found here: https://docs.near.org/docs/tools/near-cli

An administration wallet will be needed for the deployment of open bankand instructions of how to create this can be found here:
https://docs.near.org/docs/tools/near-wallet

A deployed instance of the Open Roles project will be required to support variable role access to your Open Bank instance. Instructions on the deployment of Open Roles can be found here: https://github.com/Block-Star-Logic/open-roles/blob/main/blockchain_near/ADMIN.md

All administration transactions can be monitored using the NEAR Blockchain block explorer which can be found here:
https://docs.near.org/docs/tools/near-explorer

It is recommended that a test deployment of Open Bank is conducted on the NEAR testnet to ensure your instance and role access are behaving as expected. If you are integrating Open Bank into your dApps this integration should also be tested on the testnet. 

This guide assumes the following: 
* There is a separate dev team responsible for coding your dApps 
* Your instance of Open Roles has been separately deployed and configured. 

## NEAR Blockchain Deployment
To utilise the Open Bank Project on the NEAR Blockchain follow the proceedure below. The difference in proceedure in deploying onto different networks i.e. mainnet /testnet is that the NEAR CLI has to be re-configured to point to the correct network on your OS. 

NOTE: 
* The NEAR Blockchain accounts that you use must have funds available to execute ANY admin operation. 
* For all commandline arguments in JSON you must escape with '\' to ensure your "" quotes are preserved. 

## Instructions 
1. Download the latest / recommended release from github here: https://github.com/Block-Star-Logic/open-bank
2. Opne a command prompt or terminal window 
3. Log in to your NEAR account using:<br/>
``` > near login ```
4. Deploy your selected release using the following command: <br/>
```> near deploy openbank4.blockstarlogictest.testnet --wasmFile ${path to file}/open_block_ei_open_bank_near_core.wasm --initFunction new --initArgs {"bank_name":"${bank name}","bank_deployed_account_id":"${bank deployed account id}","denomination":"${bank currency denomination}","owner":"${owner account id}",												  "nominee_account_id":"${nominee account id}","open_roles_account_id":"${open roles account id}","affirmative_code":${affirmative code},"negative_code":${in secure code},"test_mode":${true/false} --initGas 5000000000000 --initDeposit 0 ```<br/>
The key parameters are as follows:<br/>
  **a.** ```${path to file}``` - replace with the path do your downloaded ```.wasm``` release<br/>
  **b.** ```${bank name}``` - replace with the name of the instance - necessary once you go over more than one instance in your organisation<br/>
  **c.** ```${bank deployed account id}``` - name of the account to which your instance is being deployed<br/>
  **d.** ```${bank currency denomination}``` - currency in which this OPEN BANK instance is denominated<br/>
  **e.** ```${owner account id}``` - account of the owner of this OPEN BANK instance<br/>
  **f.** ```${nominee account id}``` - account of the nominee that will either conduct deposits into the bank or make withdrawals from the OPEN BANK<br/> 
  **g.** ```${open roles account id}``` - account of the OPEN ROLES instance that manages the Role Matrix associated with this OPEN BANK<br/>
  **h.** ```${affirmative code}``` - code transmitted by OPEN ROLES to indicate ALLOWED/NOT BARRED provided by OPEN ROLES Admin<br/> 
  **i.** ```${negative code}``` - code transmitted by OPEN ROLES to indicate NOT ALLOWED/BARRED provided by OPEN ROLES Admin<br/>
  **j.** ```${true/false}``` - whether test mode is active or inactive for this instance of Open Bank<br/>
5.Test your release is deployed with the following command:<br/>
```> near call ${bank deployed account id} get_version --accountId ${any account id}```<br/>
This should return the version number of the release you have just deployed <br/>
6. The following checks are optional:<br/>
  **a.** Check whether test mode is enabled:<br/>
  ```> near call ${bank deployed account id} is_test_mode --accountId ${any account id} ```<br/>
  This should return whether this instance is in test mode or not<br/>
  **b.** Check secure codes:<br/>
  ```> near call ${bank deployed account id} check_secure_codes --accountId ${authorised account id}```<br/>
  This should return the configured secure codes ```[affirmative code, negative code]```<br/>
  **c.** Check nominee account<br/> 
  ```> near call ${bank deployed account id} view_nominee_account_id --accountId ${any account id}```<br/> 
  This should return the configured nominee account id<br/>
  
  That should complete the deployment of your OPEN BANK instance. 
  
## Authorisation Requiring Operations 
Authorisation requiring operations are operations that require users to be configured in the Open Bank Role Matrix (OBRM) which is managed by Open Roles. This section will provide a summary description of how each operation operates.

### View Balance
This enables the user to view the balance of this OPEN BANK. <br/>
```> near call ${bank deployed account id} view_balance --accountId ${authorised account id}``` <br/>
**CONSOLE RETURN:** Numeric value for the bank balance<br/>
**NOTE:** Balance of the OPEN BANK is not necessarily balance of the account hosting the OPEN BANK

### Check Secure Codes
This returns the secure codes that are used by the Role Matrix managing user access to this OPEN BANK <br/>
```> near call ${bank deployed account id} check_secure_codes --accountId ${authorised account id}```<br/>
**CONSOLE RETURN:** Numeric array with values of the secure codes 

### Pay out
This operation triggers a payout to the stated acount id from this OPEN BANK. The OPEN BANK balance should decrease by the stated amount <br/>
```> near call ${bank deployed account id} pay_out {"description":"${decription of payment}","amount":${amount to be paid}, "account_id":"${account to pay to}","nonce":${nonce}) --accountId ${authorised account id}``` <br/>
**CONSOLE RETURN:** Payment object describing the pay out 

### Approve Request Debit
This operation triggers the approval of a Request Debit registration. <br/>
```> near call ${bank deployed account id} approve_request_debit {"request_debit_ref":${request debit ref},"nonce":${nonce}} --accountId ${authorised account id}``` <br/>
**CONSOLE RETURN:** Reference of the approved Request Debit

### Cancel Request Debit
This operation triggers the cancellation of a Request Debit registration. <br/>
```> near call ${bank deployed account id} cancel_request_debit ("request_debit_ref":${request debit ref},"nonce":${nonce}} --accountId ${authorised account id}```<br/>
**CONSOLE RETURN:** Reference of the cancelled Request Debit

### Deposit
This operation deposits the given amount into this OPEN BANK. The balance of this OPEN BANK should increase by the deposited amount<br/>
```> near call ${bank deployed account id} deposit {"description":"${deposit description}","amount":${deposit amount},"nonce":${nonce}} ${deposit amount currency}--accountId ${nominee_account_id / authorised account id}```<br/>
**CONSOLE RETURN:** Payment object describing this deposit

### Withdraw
This operation withdraws the given amount from this OPEN BANK. The balance of this OPEN BANK should decrease by the deposited amount<br/>
```> near call ${bank deployed account id} withdraw {"description":"${withdrawal description}","amount":${withdrawal amount},"nonce":${nonce}} --accountId ${nominee_account_id / authorised account id} ```<br/>
**CONSOLE RETURN:** Payment object describing this withdrawal 

### Set Open Bank Name
This operation sets the name of this OPEN BANK <br/>
```> near call ${bank deployed account id} set_open_bank_name {"bank_name":"${new bank name}"} --accountId ${authorised account id}``` <br/>
**CONSOLE RETURN:** 'true' if the bank name set

### Set Open Bank Nominee Account
This operation sets the nominee account of this OPEN BANK <br/>
```> near call ${bank deployed account id} set_open_bank_nominee_account {"nominee_account_id":"${nominee account id"}} --accountId ${authorised account id}``` <br/>
**CONSOLE RETURN:** 'true' if the nominee account is set 
 
 
 
## Permissive Operations 
Permissive operations are operations that operate on a **BARRING** principle i.e. anyone is allowed unless they are **BARRED**. 

### Pay In 
This operation enables communities, users, dapps to make 'pay in's to this OPEN BANK <br/>
```> near send ${bank deployed account id} pay_in {"payment_description":"${payment-description}", "payment_amount":${payment-amount}, "nonce":${nonce}} ${pay in amount} --accountId ${any account id} ``` <br/>
**CONSOLE RETURN:** Payment object describing this 'pay in'

### Request Debit 
This operation enables partners, suppliers, communities, users, dapps to claim payment against an existing and approved Request Debit. <br/> 
```> near call ${bank deployed account id} request_debit {"request_debit_ref":${request debit reference},"nonce":${nonce}} --accountId ${any account id}``` <br/>
**CONSOLE RETURN:** Payment object describing the payment made against this Request Debit<br/>
**NOTE:** Payment against a Request Debit will **only** go to the account id listed on the Request Debit Registration 

### Register Request Debit 
This operation enables partners, suppliers, communities, users, dapps to register new Request Debits against this OPEN BANK <br/>
```> near call ${bank deployed account id} register_request_debit {"payee":"${payee account id}","description":"${debit description}","amount":${amount},"payout_interval":${payout interval},"start_date":${start date},"end_date":${end date},"nonce":${nonce}} --accountId ${any account id}```<br/>
**CONSOLE RETURN:** Reference to the Request Debit

## Open Operations 
Open operations are currently completely ungoverned i.e. they can be called by any account id.

### Get Version
This operation returns the current 'hard' version of this OPEN BANK.<br/>
```> near call ${bank deployed account id} get_version --accountId ${any account id}```<br/>
**CONSOLE RETURN:** Version of OPEN BANK deployed 

### Get Bank Name
This operation returns the name of this OPEN BANK<br/>
```> near call ${bank deployed account id} get_bank_name --accountId ${any account id}```<br/>
**CONSOLE RETURN:** Name of this OPEN BANK

### Get Denomination
This operation returns the cryptocurency denomination of this OPEN BANK<br/>
```> near call ${bank deployed account id} get_denomination --accountId ${any account id}```<br/>
**CONSOLE RETURN:** Crypto denomination of this OPEN BANK

### View Nominee Account Id
This operation returns the current nominee of this OPEN BANK<br/>
```> near call ${bank deployed account id} view_nominee_account_id --accountId ${any account id}```<br/>
**CONSOLE RETURN:** Nominee account id  of this OPEN BANK

### Is Test Mode
This operation returns whether this OPEN BANK is in TEST MODE<br/>
```> near call ${bank deployed account id} is_test_mode --accountId ${any account id}```<br/>
**CONSOLE RETURN:** 'true' if OPEN BANK is in TEST MODE<br/>
**NOTE:** TEST MODE should be immediately disabled for production / mainnet environments

### Find Request Debit
This operation return the Request Debit associated with the given Request Debit Reference<br/>
```> near cal ${bank deployed account id} find_request_debit '{"request_debit_reference":${request-debit-reference}}' --accountId ${any account id}```<br/>
**CONSOLE RETURN:** Object describing Request Debit 

### Find Request Debits By Status
This operation returns the Request Debits with the selected status<br/> 
```> near call ${bank deployed account id} find_request_debits_by_status {"status":"${PENDING / ACTIVE / CANCELLED}"} --accountId ${any account id}```<br/>
**CONSOLE RETURN:** list of Request Debit Objects with the given status 

### Find Payment
This operation returns the Payment with the given reference <br/>
```> near call ${bank deployed account id} find_payment {"payment_ref":${payment-reference}} --accountId ${any account id}```<br/>
**CONSOLE RETURN:** Payment Object associated with the presented reference

### Is Valid Payment
This operation returns whether the given payment reference is valid <br/>
```> near call ${bank deployed account id} is_valid_payment_ref {"payment_ref":${payment-reference}} --accountId ${any account id}```<br/>
**CONSOLE RETURN:** 'true' if and only if the payment reference is valid

### Deactivate Test Mode 
This operation deactivates TEST MODE whenever called <br/>
```> near call ${bank deployed account id} deactivate_test_mode --accountId ${any account id}```<br/>
**CONSOLE RETURN:** 'false' current status of TEST MODE

## Migrate Open Bank 
To migrate Open Bank requires the following steps to be carried out as part of your business processes:
* Assignment of current Open Roles to new OPEN BANK instance
* Transfer of Balances from old OPEN BANK instance to new OPEN BANK instance 

**For further support join our <a href="https://rebrand.ly/obei_or_git">Discord</a> on the #admin-support channel**


