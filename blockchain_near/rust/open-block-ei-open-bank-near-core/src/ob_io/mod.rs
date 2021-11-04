/// SPDX-License-Identifier: APACHE 2.0
/// <br/> 
/// <br/> # Open Bank 'io' mod for NEAR blockchain 
/// <br/> 
/// <br/> @author Block Star Logic 
/// <br/> @coder T Ushewokunze 
/// <br/> @license Apache 2.0 
/// <br/>
/// <br/> This module contains the structs that are exchanged between Open Bank and the dependent user be that dApp or UI
//use near_sdk::serde::{Serialize, Deserialize};
use near_sdk::{near_bindgen};
use near_sdk::borsh::{self, BorshDeserialize, BorshSerialize };

use std::collections::hash_map::DefaultHasher;
use std::hash::{Hash, Hasher};
use chrono::{Utc};

// #Payment 
// The Payment struct represents the payments that are conducted by Open Bank. Transaction that has funds attached regardless of whether it is inbound or outbound from 
// Open Bank is regarded as a payment. 
// Payments are typically returned at the end of a transaction along with the necessary references. 
#[near_bindgen]
#[derive(Default, Eq, PartialEq, Debug, Clone, PartialOrd, serde::Serialize,  BorshDeserialize, BorshSerialize, Hash)]
pub struct Payment {
                pub payee           : String,
                pub payer           : String, 
                pub signer          : String, 
                pub amount          : u128,
                pub description     : String, 
                pub payment_type    : String,
                pub status          : String, 
                pub payment_time    : i64,
                pub  reference       : u64,
}

impl Payment {
    // This function is used to create a payment 
    // 'payee' - entity to which the payment was directed. This will ususally be Open Bank for 'pay in' and 'deposit' functions. 
    // 'payer' - entity which is paying the funds. This will usually be Open Bank for outbound operations such as 'pay out' 
    // 'signer' - entity which signed the transaction 
    // 'amount' - amount of the payment 
    // 'description' - description of the payment 
    // 'payment_type' - type of the payment e.g. 'pay in', 'pay out', 'request debit' etc
    // 'status' - status of the payment 
    pub fn create_payment ( payee          : String, 
                            payer          : String,
                            signer         : String,  
                            amount         : u128,
                            description    : String, 
                            payment_type   : String,
                            status : String) -> Self {
                                let payment_time = Utc::now().timestamp_millis();

                                let mut s = Self {
                                    payee, 
                                    payer, 
                                    signer,
                                    amount, 
                                    description, 
                                    payment_type,
                                    status, 
                                    payment_time,
                                    reference : 0,
                                };
                                s.reference = Payment::calculate_hash(&s);
                                s
    }
    
    // This is an internal method to determine a hash to identify this 'Payment'
    fn calculate_hash<T: Hash>(t: &T) -> u64 {
        let mut s = DefaultHasher::new();
        t.hash(&mut s);
        s.finish()
    }
}
    
#[derive(Default, Eq, PartialEq, Hash, serde::Serialize, PartialOrd, Clone, BorshDeserialize, BorshSerialize)]
// # RequestDebit 
// The 'RequestDebit' struct represents a payment draw down authorisation. This is useful in cases where the 'client' dApp or user requires funds to be paid out at given intervals.
// The bank will enable the client to request a payment on presentation of a 'RequestDebitReference'. The payout will be made to the client listed on the reference and 'not' to the 
// caller. 
// All request debits are created with 'PENDING' status and must be approved before they can be collected. 
pub struct RequestDebit {
    pub payee           : String,
    pub amount          : u128,
    pub description      : String, 
    pub payout_interval : i64,
    pub creation_date   : i64,
    pub last_paid       : i64, 
    pub start_date      : i64,
    pub end_date        : i64,
    pub creator         : String,
    pub status          : String, 
    pub approved_by     : String,
    pub reference       : u64,
}

impl RequestDebit {
    /// This function is used to internally create a representation of the RequestDebit 
    /// 'payee' - entity to which the debited funds will be directed. 
    /// 'amount' - amount of the debit 
    /// 'description' - description of the debit
    /// 'payout_interval' - interval between debits in millis 
    /// 'start_date' - date from which debits will start
    /// 'end_date' - date on which debits will end 
    /// 'creator' - entity that created the RequestDebit
    pub fn create_request_debit (
                                payee           : String,
                                amount          : u128,
                                description      : String, 
                                payout_interval : i64,                                
                                start_date      : i64,
                                end_date        : i64,
                                creator         : String) -> Self {

                                let mut rd = Self {
                                        payee,
                                        amount,
                                        description, 
                                        payout_interval,
                                        creation_date   : Utc::now().timestamp_millis(),
                                        last_paid       : 0, 
                                        start_date,
                                        end_date,
                                        creator,
                                        status          : "PENDING".to_string(), 
                                        approved_by     : "".to_string(),
                                        reference       : 0
                                };
                                rd.reference = RequestDebit::calculate_hash(&rd);
                                rd
    }

    // This is an internal method to determine a hash to identify this 'RequestDebit'
    fn calculate_hash<T: Hash>(t: &T) -> u64 {
        let mut s = DefaultHasher::new();
        t.hash(&mut s);
        s.finish()
    }
}

/// # MultiPaymentRequest
/// The MultiPaymentRequest represents an individual request for payment as part of a simultaneous payment to multiple parties
#[derive(Default, Eq, PartialEq, Clone, PartialOrd, serde::Serialize, serde::Deserialize, BorshDeserialize, BorshSerialize, Hash)]
pub struct MultiPaymentRequest {
    pub payee_account_id : String, 
    pub payout_amount : u128,
    pub description : String,
}
