use std::collections::{HashMap, HashSet};
use chrono::{Utc};

use near_sdk::borsh::{self, BorshDeserialize, BorshSerialize};
use near_sdk::{env, near_bindgen, json_types, ext_contract, Promise, PromiseOrValue,};

use crate::io::{Payment, RequestDebit, MultiPaymentRequest};

near_sdk::setup_alloc!();

mod io; 

#[ext_contract(ext_open_roles)]
trait TOpenRoles {
    
    fn is_allowed(&self, contract_account_id : String, contract_name : String, operation : String, user_account_id : String) -> PromiseOrValue<bool>;
    
    fn is_barred(&self, contract_account_id : String, contract_name :String, operation : String, user_account_id : String) -> PromiseOrValue<bool>; 
}

const NO_DEPOSIT: near_sdk::Balance = 0;
const BASE_GAS: near_sdk::Gas = 5_000_000_000_000;

#[near_bindgen]
#[derive(Default, Eq, PartialEq, BorshDeserialize, BorshSerialize)]
struct OpenBank {

	bank_balance                : u128,
    bank_name                   : String,
    bank_deployed_account_id    : String,

    denomination                : String, 
    owner                       : String, 
    nominee_account_id          : String, // this is the account to which all withdrawals regardless who calls them are sent

    request_debit_by_reference  : HashMap<u64, io::RequestDebit>, 
    request_debits_by_status    : HashMap<String, HashSet<io::RequestDebit>>,

    payments                    : HashSet<io::Payment>,
    payments_by_reference       : HashMap<u64, io::Payment>,

    access_security             : near_sdk::AccountId, 
    nonce_register              : HashMap<String, HashSet<u64>>,
}

#[near_bindgen]
impl OpenBank { 
    
    pub fn view_nominee_account_id (&self) -> String{
        self.nominee_account_id.clone()
    }

    pub fn view_balance(&mut self) -> u128 {
        OpenBank::do_security(self, "view_balance".to_string(), "ALLOWED".to_string());
        self.bank_balance
    }
		
    pub fn find_request_debit(&self, request_debit_reference : u64)-> io::RequestDebit  {
        self.request_debit_by_reference.get(&request_debit_reference).unwrap().clone()
    }

    pub fn find_request_debits(&self, status : String) -> HashSet<io::RequestDebit> {
        self.request_debits_by_status.get(&status).unwrap().clone()
    }
   
    pub fn find_payment(&self, payment_ref :u64) -> io::Payment {
        self.payments_by_reference.get(&payment_ref).unwrap().clone()
    }
   
    pub fn is_valid_payment_ref(&self, payment_ref : u64) -> bool {
        self.payments_by_reference.contains_key(&payment_ref)
    } 

    #[payable]
    pub fn pay_in(&mut self, payment_description :  String ,  payment_amount : u128, nonce : u64)->  io::Payment {
        // check nonce
        self.check_nonce(nonce);

        let signer_account_id = env::signer_account_id();
        
        // do security 
        OpenBank::require(self.do_security("pay_in".to_string(), "ALLOWED".to_string()), format!("account {} not allowed ", signer_account_id));

        // increment the bank balance
        self.increment_bank_balance(payment_amount);

        let current_account_id = env::current_account_id(); 

        OpenBank::create_and_register_payment( self, 
                                            self.bank_deployed_account_id.clone(), 
                                            current_account_id, 
                                            signer_account_id.clone(), 
                                            payment_amount, 
                                            payment_description,
                                        "COMPLETED".to_string(),
                                     "PAY_IN".to_string())
                                      
    } 

    pub fn pay_out(&mut self, description : String, amount :u128, account_id : String, nonce : u64) -> io::Payment {
        // check nonce 
        self.check_nonce(nonce);
        
        let signer_account_id = env::signer_account_id();
        OpenBank::require(self.do_security("payout".to_string(), "ALLOWED".to_string()), format!("account {} not allowed ", signer_account_id));

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
    
    pub fn pay_out_multi(&mut self, multi_payment_requests : HashSet<MultiPaymentRequest>, nonce : u64) -> HashSet<io::Payment> {
        // check nonce 
        self.check_nonce(nonce);

        let signer_account_id = env::signer_account_id();
        
        OpenBank::require(self.do_security("pay_out_multi".to_string(), "ALLOWED".to_string()), format!("account {} not allowed ", signer_account_id));
        
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

    pub fn request_debit(&mut self, request_debit_ref : u64, nonce : u64) -> io::Payment {
        self.check_nonce(nonce);
        let signer_account_id = env::signer_account_id();
        OpenBank::require(!self.do_security("request_debit".to_string(), "BARRED".to_string()), format!("account {} not allowed ", signer_account_id));
        let request_debit  = self.find_request_debit(request_debit_ref); 
        // check nonce 
        self.check_nonce(nonce);

        // check request debit status 
        self.check_request_debit_status(request_debit, "APPROVED".to_string());

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
        rdp.last_paid = Utc::now().timestamp_millis(); 

        let rdc = self.find_request_debit(request_debit_ref); 
        // pay to the payee
        self.pay_to(    rdc.payee, 
                        signer_account_id, 
           rdc.amount, 
       rdc.description,
            "REQUEST_DEBIT".to_string())
      
    }

    pub fn register_request_debit(&mut self, 
                                    payee           : String,
                                    description     : String, 
                                    amount          : u128, 
                                    payout_interval : i64, 
                                    start_date      : i64, 
                                    end_date        : i64, 
                                    nonce : u64)-> u64 {
        self.check_nonce(nonce);

        let signer_account_id = env::signer_account_id();
        OpenBank::require(!self.do_security("register_request_debit".to_string(), "BARRED".to_string()), format!("account {} not allowed ", signer_account_id));
        
        let request_debit = RequestDebit::create_request_debit(payee, amount, description, payout_interval, start_date, end_date, signer_account_id);
        let rd_clone = request_debit.clone();
        let rd_reference = request_debit.reference.clone();

        self.request_debit_by_reference.insert(request_debit.reference, request_debit);
        

        self.request_debits_by_status.get_mut(&rd_clone.status).unwrap().insert(rd_clone);

        rd_reference
    }

    pub fn approve_request_debit(mut self, request_debit_ref : u64, nonce: u64) -> u64 {
        
        self.check_nonce(nonce);

        let signer_account_id = env::signer_account_id();
        OpenBank::require(self.do_security("approve_request_debit".to_string(), "ALLOWED".to_string()), format!("account {} not allowed ", signer_account_id));
       
        let request_debit : &mut RequestDebit = &mut self.find_request_debit(request_debit_ref);
        let rd = self.find_request_debit(request_debit_ref);
        
        
        let old_status = request_debit.status.clone(); 

        self.check_request_debit_status(rd, "PENDING".to_string());

        request_debit.status = "APPROVED".to_string();
let rdc = self.find_request_debit(request_debit_ref);
        OpenBank::move_request_debit_by_status(self, old_status, request_debit.status.clone(), rdc);

        request_debit.reference
    }
   
    pub fn cancel_request_debit(mut self, request_debit_ref : u64, nonce : u64) -> u64 {
        
        self.check_nonce(nonce);
        let signer_account_id = env::signer_account_id();
        
        OpenBank::require(self.do_security("request_debit".to_string(), "ALLOWED".to_string()), format!("account {} not allowed ", signer_account_id));
        
        let request_debit : &mut RequestDebit = &mut self.find_request_debit(request_debit_ref);
        let rd = self.find_request_debit(request_debit_ref);

        let old_status = request_debit.status.clone(); 
        
        request_debit.status = "CANCELLED".to_string();
        
        OpenBank::move_request_debit_by_status(self, old_status, request_debit.status.clone(), rd);

        request_debit.reference
    } 

    #[payable]
    pub fn deposit(&mut self, description : String, amount : u128, nonce : u64) -> io::Payment {
        
        // check nonce 
        self.check_nonce(nonce);

        let signer_account_id = env::signer_account_id();
        
        OpenBank::require(signer_account_id.as_bytes() == self.nominee_account_id.as_bytes() || self.do_security("deposit".to_string(), "ALLOWED".to_string()), format!("account {} not allowed ", signer_account_id));

        // check transfer amount
        let deposit = near_sdk::env::attached_deposit();

        self.check_attachment_vs_stated_amount(deposit, amount);

        // increase the bank balance
        self.increment_bank_balance(amount);

        // log the payment
        let current_account_id = env::current_account_id();
        self.create_and_register_payment( self.bank_deployed_account_id.clone(), 
                                          current_account_id, 
                                                signer_account_id, 
                                                amount, 
                                                description, 
                                   "COMPLETED".to_string(),
                                     "DEPOSIT".to_string())
    }
   
    pub fn withdraw(&mut self, description : String, amount : u128, nonce : u64) -> io::Payment {
        let signer_account_id = env::signer_account_id();
        OpenBank::require(signer_account_id.as_bytes() == self.nominee_account_id.as_bytes() || self.do_security("withdraw".to_string(), "ALLOWED".to_string()),format!("account {} not allowed ", signer_account_id));       
        // check nonce 
        self.check_nonce(nonce);
        
        // check balance can afford it 
        self.check_bank_balance(amount);

        self.decrement_bank_balance(amount);
        // pay to the nominee account
        self.pay_to( self.nominee_account_id.clone(), 
                     signer_account_id, 
        amount, 
    description, 
          "WITHDRAWAL".to_string())
    }

    fn pay_to( &mut self, 
                payee : String, 
                signer : String, 
                payment_amount : u128, 
                payment_description : String,
                payment_type : String ) -> io::Payment { 
                
                // transfer funds to payee

                let payment_status = "".to_string();
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
                                payment_type : String) -> io::Payment {
        
        let payment = io::Payment::create_payment ( payee,
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

    fn require( condition : bool, messaage : String) -> bool {
        if !condition {
            panic!(messaage);
        }
        true
    }

    fn do_security(&mut self, operation : String, mode : String) -> bool {
       /* let signer_account_id = env::signer_account_id();
        if mode.as_bytes() == "ALLOWED".to_string().as_bytes() {
            let p = ext_open_roles::is_allowed(self.access_security, 
                                        self.bank_deployed_account_id, 
                                        self.bank_name, operation, 
                                        &signer_account_id, NO_DEPOSIT, BASE_GAS); 
                                        format!("account {} not allowed ", signer_account_id); 
                                        return true
        }
        else { 
            let p = ext_open_roles::is_barred(self.access_security, 
                self.bank_deployed_account_id, 
                self.bank_name, operation, 
                &signer_account_id, NO_DEPOSIT, BASE_GAS); 
                format!("account {} not allowed ", signer_account_id); 
                return false
        }
        
        */
        return true
    }

    fn check_nonce( &mut self, nonce : u64) {
        let signer_account_id = env::signer_account_id();
        let nonce_history = self.nonce_register.get(&signer_account_id).unwrap();
        if nonce_history.contains(&nonce) {
            panic!(format!("repeat nonce: {} ", nonce));
        }
    }

    fn check_bank_balance(&mut self, amount : u128) {
        
        let pseudo_balance = self.bank_balance; 
        
        let answer = pseudo_balance - amount;

        if answer == 0 || answer > self.bank_balance {
            panic!(format!("insufficient funds available. requested: {} available {}", amount, self.bank_balance));
        }
    }

    fn check_request_debit_status(&mut self, request_debit : RequestDebit, required_status : String){
        if request_debit.status.as_bytes() != required_status.as_bytes() { 
            panic!(format!("Invalid status for action. Required status : {}, actual status : {} ", required_status, request_debit.status));
        }
    }

    fn check_attachment_vs_stated_amount(&mut self, attached_amount : u128, stated_amount : u128){
        if attached_amount != stated_amount{
            panic!(format!("Deposit mis-match stated {} attached {}. Check amounts and retry.", stated_amount, attached_amount));
        }
    }

    fn check_request_debit_interval(&mut self, request_debit : RequestDebit){
        let time_now = Utc::now().timestamp_millis();
        if request_debit.start_date > time_now {
            panic!(format!("Request Debit approval not started. Time now {}, approval start date {}.",time_now, request_debit.start_date));
        }

        if request_debit.end_date < time_now {
            panic!(format!("Request Debit approval expired. Time now {}, approval end date {}.",time_now, request_debit.end_date));
        }

        if time_now - request_debit.last_paid < request_debit.payout_interval{
            panic!(format!("Pay out interval not reached. Time now {}, last paid {}, interval required {}.",time_now, request_debit.last_paid, request_debit.payout_interval));
        }
    }

    fn decrement_bank_balance(&mut self, amount : u128) {
        self.bank_balance -= amount;
    }

    fn increment_bank_balance(&mut self, amount : u128) {
        self.bank_balance += amount;
    }

    fn get_total( mprs : HashSet<MultiPaymentRequest>) -> u128 {
        let mut total :u128 = 0;
        for mpr in mprs {
            total += mpr.payout_amount;
        }
        total
    }

    fn move_request_debit_by_status(mut self, old_status : String, new_status : String, request_debit : RequestDebit) {
        self.request_debits_by_status.get_mut(&old_status).unwrap().remove(&request_debit);
        self.request_debits_by_status.get_mut(&new_status).unwrap().insert(request_debit);
    }
    

    pub fn set_obei_nominee_account(&mut self, nominee_account_id : String) -> bool {
        let signer_account_id = env::signer_account_id();
        OpenBank::require(self.do_security("set_obei_nominee_acccount".to_string(), "ALLOWED".to_string()), format!("account {} not allowed ", signer_account_id));
        self.nominee_account_id = nominee_account_id; 
        true
    }

    pub fn set_obei_open_roles(&mut self, open_roles_account_id : String) -> bool {
        if self.owner.as_bytes() == env::current_account_id().as_bytes() {
            self.access_security = open_roles_account_id.to_string(); 
            return true
        }
        false
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use near_sdk::MockedBlockchain;
    use near_sdk::{testing_env, VMContext};

    fn get_context(input: Vec<u8>, is_view: bool) -> VMContext {
        VMContext {
            current_account_id: "alice.testnet".to_string(),
            signer_account_id: "robert.testnet".to_string(),
            signer_account_pk: vec![0, 1, 2],
            predecessor_account_id: "jane.testnet".to_string(),
            input,
            block_index: 0,
            block_timestamp: 0,
            account_balance: 0,
            account_locked_balance: 0,
            storage_usage: 0,
            attached_deposit: 0,
            prepaid_gas: 10u64.pow(18),
            random_seed: vec![0, 1, 2],
            is_view,
            output_data_receivers: vec![],
            epoch_height: 19,
        }
    }

    #[test]
    fn get_balance() {

        let context = get_context(vec![], false);

        testing_env!(context);

        //let contract = OpenBank { ob_balance : 100 };
	
		//let bal = u64::from(contract.get_balance());
		
        //println!("Initial open bank balance: {}", bal );

        //assert_eq!(100, bal);
    }
	
}