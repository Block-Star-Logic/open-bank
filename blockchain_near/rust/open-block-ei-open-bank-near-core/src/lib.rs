#![allow(dead_code)]
#![allow(unused_imports)]
/// SPDX-License-Identifier: APACHE 2.0
///
/// # Open Bank  - obei_ob_near_core
///
/// <br/> @author : Block Star Logic 
/// <br/> @coder : T Ushewokunze 
/// <br/> @license :  Apache 2.0 
///
/// <br/> The [**OpenBankContract**] has been built to provide onchain banking/fund management access to dApps on the NEAR blockchain
/// <br/> It extracts actions such as 'pay in', and 'pay out', allowing a dApp to focus on core business delivery. 
/// <br/> It comes with externalised role governance which enables you to delegate authority for certain functions to different groups or apps whilst also enabling you to retain your access control scheme between deployments i.e. 
/// <br/> you can upgrade 'OpenBank' without having to rebuild your access control lists. 
/// <br/> 
/// <br/> **Features :** 
/// <br/> - 'pay in' - this feature provides the ability for third parties to pay in funds in a controlled way 
/// <br/> - 'pay out' - this feature provides the ability to pay third parties in a controlled way 
/// <br/> - 'pay out multi' - this feature provides the ability to pay multiple third parties varying amounts in a controlled way  
/// <br/> - 'request debit' - this feature provides the ability for third parties to draw down fixed funds at set intervals for a given period to a named 'account id' 
/// <br/> - 'deposit' - this feature provides the ability for internal payments in a controlled way 
/// <br/> - 'withdraw' - this feature provides the ability for controlled withdrawal to the 'nominee account id' associated with this bank 
/// <br/> 
/// <br/> # Integration 
/// <br/> To integrate OpenBank into your NEAR dApp you use either/both of the traits [ob_traits::TOpenBank] and/or [ob_traits::TOpenBankAdmin]
/// <br/> 

mod ob_io;
mod tests; 

use std::collections::{HashMap, HashSet};

use near_sdk::borsh::{self, BorshDeserialize, BorshSerialize};
use near_sdk::{env, near_bindgen,  ext_contract, json_types, PromiseResult, Promise, PromiseOrValue,};
use near_sdk::json_types::{U64, I64, U128};
use ob_io::{RequestDebit, Payment, MultiPaymentRequest};

near_sdk::setup_alloc!();

const NO_DEPOSIT: near_sdk::Balance = 0;
const BASE_GAS: near_sdk::Gas = 5_000_000_000_000;

#[ext_contract(ext_open_roles)]
pub trait TOpenRoles {

    /// Checks whether the given on chain **'user_account_id'**  is allowed to access the stated operation (function)
    fn is_allowed(&self, contract_account_id : String, contract_name : String, operation : String, user_account_id : String) -> PromiseOrValue<i32>;
    
    /// Checks whether the given on chain **'user_account_id'**  is barred from access the stated operation (function)
    fn is_barred(&self, contract_account_id : String, contract_name :String, operation : String, user_account_id : String) -> PromiseOrValue<i32>; 
}

#[near_bindgen]
#[derive(Default, Eq, PartialEq, serde::Serialize, BorshDeserialize, BorshSerialize)]
struct OpenBank {

	bank_balance                : u128, ///  this is the current balance of the bank based on Payments made
    bank_name                   : String, /// this is the name of the bank 
    bank_deployed_account_id    : String, /// this is the account to which the bank has been deployed

    denomination                : String, /// this is the currency denomination of the bank 
    owner                       : String, /// this is the owner of the bank 
    nominee_account_id          : String, /// this is the account to which all withdrawals regardless who calls them are sent

    request_debit_by_reference  : HashMap<u64, ob_io::RequestDebit>, /// this is a log of all the request debits made at this bank searchable by reference 
    request_debits_by_status    : HashMap<String, HashSet<ob_io::RequestDebit>>,

    payments                    : HashSet<ob_io::Payment>,
    payments_by_reference       : HashMap<u64, ob_io::Payment>,

    access_security             : near_sdk::AccountId, 
    nonce_register              : HashMap<String, HashSet<u64>>,
    test_mode                   : bool,
    affirmative_code            : i32, 
    negative_code               : i32, 
}

#[near_bindgen]
impl OpenBank { 

	/// Returns the code version of this OpenBank instance 
    /// [**ungoverned**], [**non-payable**] 
	/// # Return Value 
	/// **String** with version code 
	pub fn get_version(&self) -> String {
		"0.1.0".to_string()
	}

    /// Returns the bank name for this OpenBank instance 
    /// [**ungoverned**], [**non-payable**] 
    /// # Return Value 
    /// **String** with the name of this bank instance 
    pub fn get_bank_name(&self) -> String {
        self.bank_name.clone()
    }

    /// Returns the currency denomination for this OpenBank instance
    /// [**ungoverned**], [**non-payable**] 
    /// # Return Value 
    /// **String** with the currency denomination of this bank instance 
    pub fn get_denomination(&self) -> String {
        self.denomination.clone()
    }

    /// this operation will return the nominee account for this bank 
    /// [**ungoverned**], [**non-payable**] 
    /// # Return Value
    pub fn view_nominee_account_id (&self) -> String{
        self.nominee_account_id.clone()
    }

    /// this operation will return the total balance of this bank in the denomination of the bank 
    /// [**governed**], [**non-payable**]
    /// # Return Value 
    pub fn view_balance(&mut self) -> U128 {
        if self.is_secure( "view_balance".to_string(), "ALLOWED".to_string()) {
            return U128::from(self.bank_balance);
        }     
        panic!("BALANCE VIEW NOT ALLOWED - IN SECURE ACCOUNT {} ",env::signer_account_id());
    }
    /// this operation will return the role security codes for this bank
    /// [**governed**], [**non-payable**] 
    /// # Return Value 
    /// *secure_code* - code used to determine if a user is secure 
    /// *in_secure_code* - code used to determine if a user is in secure
    pub fn check_secure_codes(&mut self) ->(i32, i32) {
        if self.is_secure( "check_secure_codes".to_string(), "ALLOWED".to_string()) {
            return (self.affirmative_code.clone(), self.negative_code.clone())
        }
        panic!("SECURE CODE VIEW NOT ALLOWED - IN SECURE ACCOUNT {} ",env::signer_account_id());
    }

    /// this operation will return whether testing has been left on 
    /// use **disable_testing()** to deactivate;
    /// [**ungoverned**], [**non-payable**]  
    /// # Return Value 
    /// *true* if and only if this bank is in in test mode
    pub fn is_test_mode(&self) -> bool {
        self.test_mode
    }

	/// this operation will find the given RequestDebit according to the given reference    
    /// [**ungoverned**], [**non-payable**] 
    /// # Return Value
    /// Request Debit struct matching the provided reference 
    /// @panic if unknown reference provided 
    pub fn find_request_debit(&self, u_request_debit_reference : U64)-> ob_io::RequestDebit  {
        let request_debit_reference = u64::from(u_request_debit_reference);
        if !self.request_debit_by_reference.contains_key(&request_debit_reference) {
            panic!("UNKNOWN REQUEST DEBIT REFERENCE {} ", request_debit_reference);
        }
        self.request_debit_by_reference.get(&request_debit_reference).unwrap().clone()
    }

    /// this operation will find a set of RequestDebits that have the given status 
    /// [**ungoverned**], [**non-payable**] 
    /// # Return Value 
    /// **HashSet** of **RequestDebit** structs with the status provided 
    /// @panic if unknown request debit status provided 
    pub fn find_request_debits_by_status(&self, status : String) -> HashSet<ob_io::RequestDebit> {
        if !self.request_debits_by_status.contains_key(&status) {
            panic!("UNKNOWN REQUEST DEBIT STATUS {} ", status);
        }
        self.request_debits_by_status.get(&status).unwrap().clone()
    }
   
    /// this operation will find the given Payment with the given reference 
    /// [**ungoverned**], [**non-payable**]     
    /// # Return Value
    /// **Payment** struct matching payment reference 
    /// @panic if unknown payment reference provided
    pub fn find_payment(&self, u_payment_ref :U64) -> ob_io::Payment {
        let payment_ref = u64::from(u_payment_ref);
        if !self.payments_by_reference.contains_key(&payment_ref)  {
            panic!("UNKNOWN PAYMENT REFERENCE {} ", payment_ref);
        }
        self.payments_by_reference.get(&payment_ref).unwrap().clone()
    }
    /// this operation will return whether the given payment reference is valid 
    /// [**ungoverned**], [**non-payable**] 
    /// # Return Value 
    /// **true** if and only if the payment reference is valid 
    pub fn is_valid_payment_ref(&self, u_payment_ref :U64) -> bool {
        let payment_ref = u64::from(u_payment_ref);
        self.payments_by_reference.contains_key(&payment_ref)
    } 

    /// this operation will *'pay in'* the attached funds to the bank and increment the bank balance accordingly
    /// [**governed**], [**payable**]
    /// # Return Value
    /// **Payment** struct containing  details of the "pay in" made
    #[payable]
    pub fn pay_in(&mut self, payment_description :  String ,  pay_in_amount : U128, nonce : U64)->  ob_io::Payment {
        // check nonce
        self.check_nonce(u64::from(nonce));

        let signer_account_id = env::signer_account_id();
        
        // do security
        let security_response = self.is_secure("pay_in".to_string(), "BARRED".to_string());
        self.require(security_response, format!("PAY IN NOT ALLOWED. ACCOUNT {} BARRED", signer_account_id));

        let stated_amount = u128::from(pay_in_amount);

        // check amounts
        let attached_amount = env::attached_deposit();
        self.check_attachment_vs_stated_amount(attached_amount, stated_amount);

        // increment the bank balance
        self.increment_bank_balance(stated_amount);

        self.create_and_register_payment(  
                                            self.bank_deployed_account_id.clone(), 
                                            signer_account_id, 
                                            env::signer_account_id(), 
                                            stated_amount, 
                                            payment_description,
                                            "COMPLETED".to_string(),
                                            "PAY_IN".to_string())
                                      
    } 

    /// This operation will *'pay out'* funds to the given account ID and decrement the balance of this bank accordingly 
    /// [**governed**], [**non-payable**]
    /// # Return Value 
    /// **Payment** object with details of the pay out made 
    pub fn pay_out(&mut self, description : String, payout_amount : U128, account_id : String, nonce : U64) -> ob_io::Payment {
        // check nonce 
        self.check_nonce(u64::from(nonce));
        
        let signer_account_id = env::signer_account_id();

        let security_response = self.is_secure("payout".to_string(), "ALLOWED".to_string());
        self.require(security_response, format!("PAY OUT CANCELLED. ACCOUNT {} NOT ALLOWED", signer_account_id));

        let amount = u128::from(payout_amount);

        // check bank balance 
        self.check_bank_balance(amount);

        // decrement the bank balance
        self.decrement_bank_balance(amount);

        // pay to the given account 
        self.pay_to(  account_id, 
                            signer_account_id, 
               amount, 
           description, 
                "PAY_OUT".to_string())
    }
    
    /// This operation will 'pay out' to multiple 'payee's as described by the *'multi_payment_requests'* and decrement the balance of this bank accordingly
    /// [**governed**], [**non-payable**] 
    /// #Return Value 
    /// **HashSet** of **Payment** structs conaining information on the payments made     
    pub fn pay_out_multi(&mut self, multi_payment_requests : HashSet<MultiPaymentRequest>, nonce : U64) -> HashSet<Payment> {
        // check nonce 
        self.check_nonce(u64::from(nonce));

        let signer_account_id = env::signer_account_id();
        
        let security_response = self.is_secure("pay_out_multi".to_string(), "ALLOWED".to_string());
        self.require(security_response, format!("MULTI PAY OUT CANCELLED. ACCOUNT {} NOT ALLOWED", signer_account_id));
        
        // sum the amounts 
        let total = OpenBank::get_total(multi_payment_requests.clone());

        // check the bank balance 
        self.check_bank_balance(total);

        // set up the payments basket
        let mut payments :  HashSet<Payment> = HashSet::new();

        // iterate 
        for mpr in multi_payment_requests {
                let amount = mpr.payout_amount;
                // decrement the bank balance
                self.decrement_bank_balance(amount);
                
                // pay to the payee
               let payment =  self.pay_to(    
                                                    mpr.payee_account_id, 
                                                    signer_account_id.clone(), 
                                        amount, 
                                 mpr.description,
                                       "PAY_OUT_MULTI".to_string());

                // add payment to vector
                payments.insert(payment);
        }
        // return the payments
        payments
    
    }

    /// This operation will trigger the payment of the RequestDebit associated wqith the 'request_debit_ref'. Funds will be sent to the account id attached to the RequestDebit *not* the caller
    /// [**governed**] - [BARRING], [**non-payable**]
    /// # Return Value 
    /// **Payment** struct with details of the payment to the Request Debit 
    pub fn request_debit(&mut self, request_debit_ref : U64, nonce : U64) -> ob_io::Payment {
        
        // check nonce
        self.check_nonce(u64::from(nonce));

        let signer_account_id = env::signer_account_id();

        let security_response = self.is_secure("request_debit".to_string(), "BARRED".to_string());
        self.require(security_response, format!("REQUEST DEBIT PAY OUT CANCELLED. ACCOUNT {} REQUEST DEBIT CLAIM NOT ALLOWED", signer_account_id));

        let request_debit  = self.find_request_debit(request_debit_ref); 

        // check request debit status 
        self.check_request_debit_status(request_debit.status.clone(), "APPROVED".to_string());

        let rd = self.find_request_debit(request_debit_ref); 

        // check last paid vs interval 
        self.check_request_debit_interval( rd); 

        let rda = self.find_request_debit(request_debit_ref); 

        // check bank balance 
        self.check_bank_balance(rda.amount);

        // decrement the bank balance
        self.decrement_bank_balance(rda.amount);

        let mut rdp = self.find_request_debit(request_debit_ref); 
        // update the request_debit last paid date to now 
        rdp.last_paid = env::block_timestamp() as i64;

        let rdc = self.find_request_debit(request_debit_ref); 
        // pay to the payee
        self.pay_to(    rdc.payee, 
                        signer_account_id, 
                            rdc.amount, 
       rdc.description,
            "REQUEST_DEBIT".to_string())      
    }

    /// This operation will register a 'new' *'Request Debit'* with this bank. The RequestDebit will need to be approved before it can be 'debited' 
    /// This operation is [**governed**] - [BARRING], [**non-payable**]
    /// #Return Value
    pub fn register_request_debit(&mut self, 
                                    payee           : String,
                                    description     : String, 
                                    amount          : U128, 
                                    payout_interval : I64, 
                                    start_date      : I64, 
                                    end_date        : I64, 
                                    nonce : U64)-> U64 {
        self.check_nonce(u64::from(nonce));

        let signer_account_id = env::signer_account_id();

        let security_response = self.is_secure("register_request_debit".to_string(), "BARRED".to_string());
        self.require(security_response, format!("REQUEST DEBIT REGISTRATION CANCELLED. ACCOUNT {} NOT ALLOWED", signer_account_id));
        
        let debit_amount = u128::from(amount);

        let request_debit = ob_io::RequestDebit::create_request_debit(payee, debit_amount, description, i64::from(payout_interval), i64::from(start_date), i64::from(end_date), signer_account_id);
        let rd_clone = request_debit.clone();
        let rd_reference = request_debit.reference.clone();

        self.request_debit_by_reference.insert(request_debit.reference, request_debit);
        
        if !self.request_debits_by_status.contains_key( &rd_clone.status) {
            let mut debit_list = HashSet::<RequestDebit>::new(); 
            let status = rd_clone.status.clone();
            debit_list.insert(rd_clone);
            self.request_debits_by_status.insert(status,debit_list);
        }
        else {
            self.request_debits_by_status.get_mut(&rd_clone.status).unwrap().insert(rd_clone);
        }
        U64(rd_reference)
    }

    /// This operation will 'approve' the 'RequestDebit' associated with the given 'request_debit_ref'. Once approved the 'RequestDebit can be drawn down after the start date 
    /// This operation is [**governed**], [**non-payable**] 
    /// # Return Value
    pub fn approve_request_debit(&mut self, request_debit_ref : U64, nonce: U64) -> U64 {
        
        self.check_nonce(u64::from(nonce));

        // do security
        let signer_account_id = env::signer_account_id();
        let security_response = self.is_secure("approve_request_debit".to_string(), "ALLOWED".to_string());
        self.require(security_response, format!("REQUEST DEBIT APPROVAL STOPPED. ACCOUNT {} NOT ALLOWED", signer_account_id));

        self.check_is_valid_request_debit_reference(u64::from(request_debit_ref));
        
        let mut request_debit = self.find_request_debit(request_debit_ref);
        
        let evacuating_status = request_debit.status.clone(); 

        self.check_request_debit_status(evacuating_status.clone(), "PENDING".to_string());

        request_debit.status = "APPROVED".to_string();

        let rd_reference = request_debit.reference.clone();
        
        println!(" request debit status {} reference {} ", request_debit.status, request_debit.reference );

        // overwrite 
        self.request_debit_by_reference.insert(rd_reference.clone(), request_debit);

        let rd = self.find_request_debit(U64(rd_reference.clone()));

        println!(" request debit status {} reference {} ", rd.status.clone(), rd.reference.clone() );

        self.move_request_debit_by_status(evacuating_status, rd.status.clone(), rd);

        U64(rd_reference)
    }
    
    /// This operation will 'cancel' the 'RequestDebit' associated with the given 'request_debit_ref'. Cancellation can happen at any point in the 'RequestDebit' lifecycle 
    /// This operation is [**governed**], [**non-payable**]
    /// # Return Value
    /// Reference of the cancelled Request Debit
    pub fn cancel_request_debit(&mut self, request_debit_ref : U64, nonce : U64) -> U64 {
        
        self.check_nonce(u64::from(nonce));

        let signer_account_id = env::signer_account_id();

        // do security 
        let security_response = self.is_secure("request_debit".to_string(), "ALLOWED".to_string());
        self.require(security_response, format!("REQUEST DEBIT CANCELLATION STOPPED. ACCOUNT {} NOT ALLOWED", signer_account_id));

        self.check_is_valid_request_debit_reference(u64::from(request_debit_ref));
        
        let mut request_debit = self.find_request_debit(request_debit_ref);

        let evacuating_status = request_debit.status.clone(); 
        
        request_debit.status = "CANCELLED".to_string();
        
        let rd_reference = U64(request_debit.reference.clone());
        
        // overwrite 
        self.request_debit_by_reference.insert(u64::from(rd_reference.clone()), request_debit);

        let rd = self.find_request_debit(rd_reference);

        self.move_request_debit_by_status( evacuating_status, rd.status.clone(), rd);

        rd_reference
    } 

    /// This operation will 'deposit' the attached funds into this bank and increment the balance of this bank.
    /// This operation is oriented towards internal business payments into the bank as opposed to external 'pay in' 
    /// The governance of this operation allows the 'nominee_account_id' to make deposits at any time 
    /// [**governed**], [**payable**]
    /// # Return Value
    #[payable]
    pub fn deposit(&mut self, description : String, amount : U128, nonce : U64) -> ob_io::Payment {
        
        // check nonce 
        self.check_nonce(u64::from(nonce));

        let signer_account_id = env::signer_account_id();
        
        let security_response = self.is_secure("deposit".to_string(), "ALLOWED".to_string());

        self.require(signer_account_id.as_bytes() == self.nominee_account_id.as_bytes() || security_response, format!("DEPOSIT CANCELLED. ACCOUNT {} NOT ALLOWED", signer_account_id));

        // check transfer amount
        let attached_deposit = near_sdk::env::attached_deposit();

        let stated_deposit = u128::from(amount);

        self.check_attachment_vs_stated_amount(attached_deposit, stated_deposit);

        // increase the bank balance
        self.increment_bank_balance(stated_deposit);

        // log the payment
        let current_account_id = env::current_account_id();
        self.create_and_register_payment( self.bank_deployed_account_id.clone(), 
                                          current_account_id, 
                                                signer_account_id, 
                                                stated_deposit, 
                                                description, 
                                   "COMPLETED".to_string(),
                                     "DEPOSIT".to_string())
    }
   
    /// This operation will 'withdraw' the given amout to the 'nominee_account_id' 
    /// This operation can be called by the 'nominee_account_id' at any time 
    /// This operation is [**governed**], [**non-payable**] 
    /// # Return Value
    pub fn withdraw(&mut self, description : String, amount : U128, nonce : U64) -> ob_io::Payment {
        // check nonce 
        self.check_nonce(u64::from(nonce));

        let signer_account_id = env::signer_account_id();

        // do security
        let security_response = self.is_secure("withdraw".to_string(), "ALLOWED".to_string());
        self.require(signer_account_id.as_bytes() == self.nominee_account_id.as_bytes() || security_response, format!("Account {} not allowed ", signer_account_id));               
     
        let withdrawal_amount = u128::from(amount) ;
        
        // check balance can afford it 
        self.check_bank_balance(withdrawal_amount);

        self.decrement_bank_balance(withdrawal_amount);

        // pay to the nominee account
        self.pay_to( self.nominee_account_id.clone(), 
                            signer_account_id, 
                            withdrawal_amount, 
                            description, 
                            "WITHDRAWAL".to_string())
    }

    /// This operation will set the 'bank_name' for this bank 
    /// This operation is [**'governed'**], [**non-payable**]
    /// # Return Value
    /// 
    pub fn set_open_bank_name(&mut self, bank_name : String) -> bool {
        let signer_account_id = env::signer_account_id();

        // do security
        let security_response = self.is_secure("set_open_bank_name".to_string(), "ALLOWED".to_string());
        self.require(security_response, format!("OPERATION CANCELLED. ACCOUNT {} NOT ALLOWED", signer_account_id));
        
        // run assignment
        self.bank_name = bank_name; 
        true
    }

    /// This operation will set the 'nominee_account_id' for this bank 
    /// This operation is [**'governed'**], [**non-payable**] 
    /// # Return Value
    /// 
    pub fn set_open_bank_nominee_account(&mut self, nominee_account_id : String) -> bool {
        let signer_account_id = env::signer_account_id();

         // do security
        let security_response = self.is_secure("set_obei_nominee_acccount".to_string(), "ALLOWED".to_string()); 
        self.require(security_response, format!("OPERATION CANCELLED. ACCOUNT {} NOT ALLOWED", signer_account_id));
        
        // run assignment
        self.nominee_account_id = nominee_account_id; 
        true
    }

    /// This operation will set the **'obei_or_near_core'** (Open Roles) 'account_id'. All governance calls will be made to this 'account_id'
    /// This operation is [**'governed'**], [**non-payable**]
    /// # Return Value
    /// 
    pub fn set_obei_open_roles(&mut self, open_roles_account_id : String) -> bool {
        let signer_account_id = env::signer_account_id();

        // do security
        let security_response = self.is_secure("set_obei_open_roles".to_string(), "ALLOWED".to_string());
        self.require(security_response, format!("OPERATION CANCELLED. ACCOUNT {} NOT ALLOWED", signer_account_id));

        // run assignment
        self.access_security = open_roles_account_id.to_string(); 
        
        true
    }

    /// This operation will set the affirmative security code for role management 
    /// # Return Value 
    /// **Numeric** representing new security code
    pub fn set_affirmative_secure_code(&mut self, affirmative_secure_code : i32) -> i32 {
        let signer_account_id = env::signer_account_id();
        let security_response = self.is_secure("set_affirmative_secure_code".to_string(), "ALLOWED".to_string());
        self.require(security_response, format!("OPERATION CANCELLED. ACCOUNT {} NOT ALLOWED", signer_account_id));
        self.affirmative_code = affirmative_secure_code; 
        self.affirmative_code.clone()
    }

    /// This operation will set the negative security code for role management 
    /// # Return value 
    /// **Numeric** representing new security code
    pub fn set_negative_secure_code(&mut self, negative_secure_code : i32) -> i32 {
        let signer_account_id = env::signer_account_id();
        let security_response = self.is_secure("set_negative_secure_code".to_string(), "ALLOWED".to_string());
        self.require(security_response, format!("OPERATION CANCELLED. ACCOUNT {} NOT ALLOWED", signer_account_id));
        self.negative_code = negative_secure_code; 
        self.negative_code.clone()
    }


    /// This operaion will deactivate test mode on this bank. Once deactivated this cannot be reactivated 
    /// # Return Value 
    /// **true** if and only if test mode has been deactivated
    pub fn deactivate_test_mode(&mut self)-> bool {
        self.test_mode = false; 
        self.test_mode
    }

    fn pay_to( &mut self, 
                payee : String, 
                signer : String, 
                payment_amount : u128, 
                payment_description : String,
                payment_type : String ) -> ob_io::Payment { 
                
                // transfer funds to payee                
                Promise::new(payee.clone()).transfer(payment_amount);
                
                self.require(env::promise_results_count() == 1, "pay_to:01 PROMISE FAILURE ".to_string());
                let res  = match env::promise_result(0) {
                                       PromiseResult::Successful(x) => x,
                                        _ => Vec::<u8>::new(),
                                    };
                let transfer_code = res[0];

                let payment_status : String = transfer_code.to_string();

                // log the payment
                self.create_and_register_payment( payee, 
                                            self.bank_deployed_account_id.clone(),
                                            signer, 
                                            payment_amount, 
                                            payment_description,
                                            payment_status,
                                            payment_type)
                                    
    }

    fn create_and_register_payment(&mut self,   
                                payee : String, 
                                payer : String, 
                                signer : String, 
                                amount : u128, 
                                description : String,
                                payment_status : String,
                                payment_type : String) -> ob_io::Payment {
        
        let payment = ob_io::Payment::create_payment ( payee,
                                                            payer,
                                                            signer, 
                                                            amount,
                                                            description,
                                                            payment_type,
                                                            payment_status); 
                                                            
        self.payments.insert(payment.clone());
        self.payments_by_reference.insert(payment.reference, payment.clone());

        payment
    }

    fn require(&mut self, condition : bool, message : String) -> bool {
        if !condition {
            panic!("{}", message);
        }
        true
    }

    fn is_secure(&mut self, operation : String, mode : String) -> bool {
        
        if self.test_mode {
           return self.test_mode;
        }

        let security_response = false; 

        let signer_account_id = env::signer_account_id(); 

        if  mode.as_bytes() == "ALLOWED".to_string().as_bytes() {
           
            ext_open_roles::is_allowed(self.access_security.clone(), 
                                        self.bank_deployed_account_id.clone(), 
                                        self.bank_name.clone(), 
                                        operation.clone(), 
                                        &signer_account_id, 
                                        NO_DEPOSIT, 
                                        BASE_GAS); 
                                        let role_response : i32;
                                        match env::promise_result(0) {
                                           near_sdk::PromiseResult::Successful(x) => role_response = num::ToPrimitive::to_i32(x.get(0).unwrap()).unwrap(),
                                            _ => panic!("is_secure::01 :- PROMISE FAILURE FOR SECURITY REQUEST :: OR LOCATION {} - CONTRACT ACCOUNT {} - CONTRACT {} - OPERATION {} - USER ACCOUNT {}",self.access_security.clone(),self.bank_deployed_account_id.clone(), self.bank_name.clone(), operation.clone(), &signer_account_id),
                                        };
                                        
                                        if role_response == self.affirmative_code {
                                            return true; 
                                        }
            return security_response; 
        }
        else {

            ext_open_roles::is_barred(self.access_security.clone(), 
                                        self.bank_deployed_account_id.clone(), 
                                        self.bank_name.clone(), 
                                        operation.clone(), 
                                        &signer_account_id, 
                                        NO_DEPOSIT, 
                                        BASE_GAS); 
                                        let role_response : i32;
                                        match env::promise_result(0) {
                                           near_sdk::PromiseResult::Successful(x) => role_response = num::ToPrimitive::to_i32(x.get(0).unwrap()).unwrap(),
                                            _ => panic!("is_secure::02 :- PROMISE FAILURE FOR SECURITY REQUEST :: OR LOCATION {} - CONTRACT ACCOUNT {} - CONTRACT {} - OPERATION {} - USER ACCOUNT {}",self.access_security.clone(),self.bank_deployed_account_id.clone(), self.bank_name.clone(), operation.clone(), &signer_account_id),
                                        };
                                        
                                        if role_response == self.negative_code {
                                            return true; 
                                        }
            return security_response; 
        }
    }

    fn check_nonce( &mut self, nonce : u64) {
        let signer_account_id = env::signer_account_id().to_string();
        
        if self.nonce_register.contains_key(&signer_account_id) {
            let nonce_history = self.nonce_register.get(&signer_account_id).unwrap();
            
            if nonce_history.contains(&nonce) {
                panic!("REPEAT NONCE DETECTED. NONCE: {} ", nonce);
            }
        }
        else {
            let mut nonce_history = HashSet::<u64>::new();
            nonce_history.insert(nonce);
            self.nonce_register.insert(signer_account_id, nonce_history);
        }
    }

    fn check_bank_balance(&mut self, amount_required : u128) {
        
        let pseudo_balance = self.bank_balance.clone(); 
        if amount_required < pseudo_balance {
            let answer = pseudo_balance - amount_required;

            if answer == 0 || answer > self.bank_balance {
                panic!("INSUFFICIENT FUNDS AVAILABLE. REQUIRED AMOUNT: {} AVAILABLE AMOUNT: {}", amount_required, self.bank_balance);
            }
            return;

        }
        else {
            panic!("INSUFFICIENT FUNDS AVAILABLE. REQUIRED AMOUNT: {} AVAILABLE AMOUNT: {}", amount_required, self.bank_balance);
        }

    }

    fn check_is_valid_request_debit_reference(&mut self, request_debit_ref: u64 ) {
        if !self.request_debit_by_reference.contains_key(&request_debit_ref) {
            panic!("REQUEST DEBIT REFERENCE NOT FOUND. REFERENCE PRESENTED: {}", request_debit_ref);    
        }
    }

    fn check_request_debit_status(&mut self, currenct_status : String, required_status : String){
        if currenct_status.as_bytes() != required_status.as_bytes() { 
            panic!("INVALID STATUS FOR ACTION. REQUIRED STATUS : {}, ACTUAL STATUS : {} ", required_status, currenct_status);
        }
    }

    fn check_attachment_vs_stated_amount(&mut self, attached_amount : u128, stated_amount : u128){
        if attached_amount != stated_amount{
            panic!("DEPOSIT MIS-MATCH. STATED AMOUNT: {} ATTACHED AMOUNT: {}.", stated_amount, attached_amount);
        }
    }

    fn check_request_debit_interval(&mut self, request_debit : ob_io::RequestDebit){
        let time_now = env::block_timestamp() as i64;
        if request_debit.start_date > time_now {            
            panic!("REQUEST DEBIT CLAIM PERIOD NOT STARTED. TIME NOW {}, CLAIM PERIOD START DATE {}.",time_now, request_debit.start_date);
        }

        if request_debit.end_date < time_now {
            panic!("REQUEST DEBIT CLAIM PERIOD EXPIRED. TIME NOW {}, CLAIM PERIOD END DATE {}.",time_now, request_debit.end_date);
        }

        let next_payment;
        if request_debit.last_paid > 0 {
            next_payment = request_debit.last_paid + request_debit.payout_interval;
        }
        else{
            next_payment = request_debit.start_date + request_debit.payout_interval;
        }
    
        if  next_payment > time_now {
            panic!("PAY OUT INTERVAL NOT REACHED. TIME NOW {}, LAST PAID {}, INTERVAL REQUIRED {}.",time_now, request_debit.last_paid, request_debit.payout_interval);
        }
    }

    fn decrement_bank_balance(&mut self, amount : u128) {
        self.bank_balance -= amount;
    }

    fn increment_bank_balance(&mut self, amount : u128) {
        self.bank_balance += amount;
    }

    fn get_total( mprs : HashSet<ob_io::MultiPaymentRequest>) -> u128 {
        let mut total :u128 = 0;
        for mpr in mprs {
            total += mpr.payout_amount;
        }
        total
    }

    fn move_request_debit_by_status(&mut self, old_status : String, new_status : String, mut request_debit : ob_io::RequestDebit) {
        self.request_debits_by_status.get_mut(&old_status).unwrap().remove(&request_debit);
        request_debit.status = new_status.clone(); 
        if !self.request_debits_by_status.contains_key(&new_status) {
            let mut debit_list = HashSet::<RequestDebit>::new(); 
            debit_list.insert(request_debit);
            self.request_debits_by_status.insert(new_status, debit_list);
        }
        else {
            self.request_debits_by_status.get_mut(&new_status).unwrap().insert(request_debit);
        }
    }

    #[init]
    pub fn new( bank_name : String, 
                bank_deployed_account_id : String, 
                denomination : String, 
                owner : String, 
                nominee_account_id : String, 
                open_roles_account_id : String, 
                affirmative_code : i32, 
                negative_code : i32, 
                test_mode : bool ) -> Self {
        Self {
            bank_name                   ,
            bank_balance                : env::account_balance(),
            bank_deployed_account_id    , 
            denomination                , 
            owner                       ,
            nominee_account_id          ,
            request_debit_by_reference  : HashMap::<u64, ob_io::RequestDebit>::new(),
            request_debits_by_status    : HashMap::<String, HashSet<ob_io::RequestDebit>>::new(),
            payments                    : HashSet::<ob_io::Payment>::new(),
            payments_by_reference       : HashMap::<u64, ob_io::Payment>::new(),
            access_security             : open_roles_account_id, 
            nonce_register              : HashMap::<String, HashSet<u64>>::new(),
            test_mode                   ,
            affirmative_code                 ,
            negative_code              ,
        }
    }

    pub fn default() -> Self { 
        panic!("OPEN BANK REQUIRES INITIALISATION ON DEPLOYMENT")
    }

}