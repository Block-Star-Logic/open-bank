//! SPDX-License-Identifier: APACHE 2.0 
//!
//! # OpenRoles::ob_traits 
//!
//! <br/> @author : Block Star Logic 
//! <br/> @coder : T Ushewokunze 
//! <br/> @license :  Apache 2.0 
//!
//! These trait are implmented by the calling contracts 
//! - [TOpenBank] is implemented for front facing contracts e.g. dApps 
//! - [TOpenBankAdmin] is implemented by back-end admin dApps and dashboards
//! 
use near_sdk::borsh::{BorshDeserialize, BorshSerialize};
use near_sdk::{env, near_bindgen, json_types, ext_contract, PromiseResult, Promise, PromiseOrValue,};

mod io; 

#[ext_contract(ext_open_bank)]
pub trait TOpenBank {
    
    fn find_request_debit(&self, 
        request_debit_reference : u64) -> PromiseOrValue<RequestDebit>;

    fn find_request_debits(&self, 
        status : String) -> PromiseOrValue<HashSet<RequestDebit>>;

    fn find_payment(&self, 
        payment_ref :u64) -> PromiseOrValue<Payment>;

    fn is_valid_payment_ref(&self, 
        payment_ref : u64) -> PromiseOrValue<bool>;

    fn pay_in(&mut self, 
        payment_description :  String ,  
        payment_amount : u128, 
        nonce : u64)->  PromiseOrValue<Payment>;

    fn request_debit(&mut self, 
        request_debit_ref : u64, 
        nonce : u64) -> PromiseOrValue<Payment>;

    fn register_request_debit(&mut self, 
        payee           : String,
        description     : String, 
        amount          : u128, 
        payout_interval : i64, 
        start_date      : i64, 
        end_date        : i64, 
        nonce : u64)-> PromiseOrValue<u64>;

    fn cancel_request_debit(mut self, 
        request_debit_ref : u64, 
        nonce : u64) -> PromiseOrValue<u64>;
}

#[ext_contract(ext_open_bank_admin)]
pub trait TOpenBankAdmin { 
    fn view_nominee_account_id (&self) -> PromiseOrValue<String>;

    fn view_balance(&mut self) -> PromiseOrValue<u128>;

    fn find_request_debit(&self, 
        request_debit_reference : u64) -> PromiseOrValue<RequestDebit>;

    fn find_request_debits(&self, 
        status : String) -> PromiseOrValue<HashSet<RequestDebit>>;

    fn find_payment(&self, 
        payment_ref :u64) -> PromiseOrValue<Payment>;

    fn is_valid_payment_ref(&self, 
        payment_ref : u64) -> PromiseOrValue<bool>;

    fn register_request_debit(&mut self, 
        payee           : String,
        description     : String, 
        amount          : u128, 
        payout_interval : i64, 
        start_date      : i64, 
        end_date        : i64, 
        nonce : u64)-> PromiseOrValue<u64>;

    fn cancel_request_debit(mut self, 
        request_debit_ref : u64, 
        nonce : u64) -> PromiseOrValue<u64>;

    fn pay_out(&mut self, description : String, amount :u128, account_id : String, nonce : u64) -> PromiseOrValue<Payment>;

    fn pay_out_multi(&mut self, multi_payment_requests : HashSet<MultiPaymentRequest>, nonce : u64) -> PromiseOrValue<HashSet<Payment>>;

    fn approve_request_debit(mut self, request_debit_ref : u64, nonce: u64) -> PromiseOrValue<u64>;

    fn deposit(&mut self, description : String, amount : u128, nonce : u64) -> PromiseOrValue<Payment>;

    fn withdraw(&mut self, description : String, amount : u128, nonce : u64) -> PromiseOrValue<Payment>;

    fn set_open_bank_nominee_account(&mut self, nominee_account_id : String) -> PromiseOrValue<bool>;

    fn set_obei_open_roles(&mut self, open_roles_account_id : String) -> PromiseOrValue<bool>;
}

