use std::collections::hash_map::DefaultHasher;
use std::hash::{Hash, Hasher};
use chrono::{Utc};
use serde::{Serialize, Deserialize};

use near_sdk::borsh::{self, BorshDeserialize, BorshSerialize};
use near_sdk::{near_bindgen};

near_sdk::setup_alloc!();

#[near_bindgen]
#[derive(Default, Eq, PartialEq, Clone, PartialOrd, BorshDeserialize, BorshSerialize, Hash)]
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
#[near_bindgen]
impl Payment {
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
    
    fn calculate_hash<T: Hash>(t: &T) -> u64 {
        let mut s = DefaultHasher::new();
        t.hash(&mut s);
        s.finish()
    }
}
    
#[near_bindgen]
#[derive(Default, Eq, PartialEq, Hash, PartialOrd, Clone, BorshDeserialize, BorshSerialize)]
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

#[near_bindgen]
impl RequestDebit {
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
    
    fn calculate_hash<T: Hash>(t: &T) -> u64 {
        let mut s = DefaultHasher::new();
        t.hash(&mut s);
        s.finish()
    }
}
#[near_bindgen]
#[derive(Default, Eq, PartialEq, Clone, PartialOrd, Serialize, Deserialize, BorshDeserialize, BorshSerialize, Hash)]
pub struct MultiPaymentRequest {
    pub payee_account_id : String, 
    pub payout_amount : u128,
    pub description : String,
}
