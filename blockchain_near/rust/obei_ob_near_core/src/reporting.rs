pub struct BankStatement {
    month : u8,
    year : u8,
    payments : Payment[], 
}

pub struct RequestDebitAuthorisation {
    authoriser_account_id : String,
    payee : String, 
    value : u64,
    denomination : String, 
    request_debit_ref : u64,
}