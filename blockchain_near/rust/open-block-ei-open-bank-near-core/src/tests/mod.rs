#![allow(dead_code)]

use near_sdk::{env,};
use chrono::Utc;
use near_sdk::{testing_env, VMContext};
use near_sdk::MockedBlockchain;
use near_sdk::json_types::{U64, I64, U128};

#[cfg(test)]
fn get_context(input: Vec<u8>, is_view: bool) -> VMContext {
    get_context_with_deposit(input, is_view, 10)
}

fn get_context_with_deposit(input: Vec<u8>, is_view: bool, attached_deposit : u128) -> VMContext {
    VMContext {
        current_account_id: "alice.testnet".to_string(),
        signer_account_id: "robert.testnet".to_string(),
        signer_account_pk: vec![0, 1, 2],
        predecessor_account_id: "jane.testnet".to_string(),
        input,
        block_index: Utc::now().timestamp_millis() as u64,
        block_timestamp: Utc::now().timestamp_millis() as u64,
        account_balance: 0,
        account_locked_balance: 0,
        storage_usage: 0,
        attached_deposit,
        prepaid_gas: 10u64.pow(18),
        random_seed: vec![0, 1, 2],
        is_view,
        output_data_receivers: vec![],
        epoch_height: 19,
    }
}

fn get_default_ob() -> super::OpenBank {

    let start_date = I64(Utc::now().timestamp_millis());
    let end_date= I64(i64::from(start_date) + (24*60*60*1000));
    let interval  = I64(60);
    let nonce = U64(env::block_timestamp());
    let pay_in_amount = U128(10); 
    let request_debit_amount = U128(1); 
    let mock_or_account = "mock_or_account";

    let mut ob =  super::OpenBank::new(
        "test bank".to_string(),
        "test_deployed_account.testnet".to_string(),
        "NEAR".to_string(),
        "testowner.testnet".to_string(),
        "testnominee.testnet".to_string(),
        "testopenroles.testnet".to_string(),
        20,
        10,
        true,
    ); 

    ob.set_obei_open_roles(mock_or_account.to_string());
    ob.set_open_bank_name("test_bank".to_string());

    ob.pay_in("test_payment".to_string(), pay_in_amount, nonce);
    let new_nonce = U64(env::block_timestamp()+11);
    ob.register_request_debit("testaccount.testnet".to_string(), "test request debit".to_string(), request_debit_amount, interval, start_date, end_date, new_nonce);
           
    ob
}

#[test] // done
fn test_view_nominee_account_id (){
    let context = get_context(vec![], false);

    testing_env!(context);
    let ob = get_default_ob();
    assert!("testnominee.testnet".as_bytes() == ob.view_nominee_account_id().as_bytes())    
}

#[test]// done
fn test_view_balance () {

    let context = get_context(vec![], false);        
    testing_env!(context);    
    let mut ob = get_default_ob();
    assert_eq!(20, u128::from(ob.view_balance()) )
}

#[test]// done
fn test_find_request_debit () {

    let context = get_context(vec![], false);
    testing_env!(context);
    let mut ob = get_default_ob(); 

    let start_date = I64(Utc::now().timestamp_millis());
    let end_date =  I64(i64::from(start_date) + (24*60*60*1000));
    let interval  = I64(60);
    let nonce = U64((Utc::now().timestamp_millis()+16) as u64);
    let request_debit_amount = U128(1); 

    let request_debit_reference = ob.register_request_debit("testaccount.testnet".to_string(), "test request debit".to_string(), request_debit_amount, interval, start_date, end_date, nonce);

    let request_debit = ob.find_request_debit(request_debit_reference);
    assert_eq!("testaccount.testnet", request_debit.payee)
}

#[test] // done
fn test_find_request_debits () {

    let context = get_context(vec![], false);
    testing_env!(context);
    let ob = get_default_ob(); 

    let request_debit_list = ob.find_request_debits_by_status("PENDING".to_string()); 

    assert_eq!(request_debit_list.len(),1);
}

#[test] // done
fn test_find_payment () {

    let context = get_context(vec![], false);
    testing_env!(context);
    let mut ob = get_default_ob(); 

    let nonce = U64((Utc::now().timestamp_millis()+12) as u64);
    let pay_in_amount = U128(10); 
    let payment_ref = U64(ob.pay_in("test_payment".to_string(), pay_in_amount, nonce).reference); 
    let payment = ob.find_payment(payment_ref);
    
    assert_eq!(10, payment.amount)
}

#[test] // done
fn test_is_valid_payment_ref () {

    let context = get_context(vec![], false);
    testing_env!(context);
   
    let mut ob = get_default_ob(); 
    let nonce = U64((Utc::now().timestamp_millis()+13) as u64);
    let pay_in_amount = U128(10);
    let payment_ref = U64(ob.pay_in("test_payment".to_string(), pay_in_amount, nonce).reference); 

    assert!(ob.is_valid_payment_ref(payment_ref))
}

#[test] // @done
fn test_pay_in () {

    let context = get_context_with_deposit(vec![], false, 10);
    testing_env!(context);

    let mut ob = get_default_ob();     

    ob.pay_in("next_test_payment".to_string(), U128(10) ,U64((Utc::now().timestamp_millis()+14) as u64));

    assert_eq!(30,u128::from(ob.view_balance()));
}


#[test] // @done
fn test_register_request_debit (){

    let context = get_context(vec![], false);
    testing_env!(context);
    let mut ob = get_default_ob();     
    
    let request_debit_amount = U128(1); 
    let start_date  = I64(Utc::now().timestamp_millis()); 
    let end_date= I64(i64::from(start_date) + (24*60*60*1000));
    let interval  = I64(60);
    let nonce = U64((Utc::now().timestamp_millis()+15) as u64);

    let rd_ref  = ob.register_request_debit("test_account_2.testnet".to_string(), "test request debit".to_string(), request_debit_amount, interval, start_date, end_date, nonce);

    let rd = ob.find_request_debit(rd_ref);

    assert_eq!(rd.payee, "test_account_2.testnet");

    assert_eq!(rd.status, "PENDING");
}

#[test] // @done
fn test_approve_request_debit (){

    let context = get_context(vec![], false);
    testing_env!(context);
    let mut ob = get_default_ob();  
    
    let request_debit_amount = U128(1);
    let start_date = I64(Utc::now().timestamp_millis()); 
    let end_date = I64(i64::from(start_date) + (24*60*60*1000));
    let interval  = I64(60);
    let nonce = U64(Utc::now().timestamp_millis() as u64);
    
    let rd_ref = ob.register_request_debit("test_account_2.testnet".to_string(), "test request debit".to_string(), request_debit_amount, interval, start_date, end_date, nonce);

    let rd = ob.find_request_debit(rd_ref);

    assert_eq!(rd.status, "PENDING");

    ob.approve_request_debit(rd_ref.clone(), U64(Utc::now().timestamp_millis() as u64));

    let rd1 = ob.find_request_debit(rd_ref);
    
    assert_eq!(rd1.status, "APPROVED");
}

#[test]//@done
fn test_cancel_request_debit () { 

    let context = get_context(vec![], false);        
    testing_env!(context);
    let mut ob = get_default_ob(); 

    let request_debit_amount = U128(1);
    let start_date = I64(Utc::now().timestamp_millis()); 
    let end_date = I64(i64::from(start_date) + (24*60*60*1000));
    let interval  = I64(60);
    let nonce = U64(Utc::now().timestamp_millis() as u64);

    let rd_ref = ob.register_request_debit("test_account_2.testnet".to_string(), "test request debit".to_string(), request_debit_amount, interval, start_date, end_date, nonce);

    let rd = ob.find_request_debit(rd_ref);

    assert_ne!(rd.status, "CANCELLED");

    ob.cancel_request_debit(rd_ref, U64(Utc::now().timestamp_millis() as u64));
    
    println!(" rd ref {} ", u64::from(rd_ref));

    let rd2 = ob.find_request_debit(rd_ref);

    let cancelled =  ob.find_request_debits_by_status("CANCELLED".to_string());

    for rd3 in cancelled {
        println!(" rd : {} status {} rd2 status {} ", rd3.reference , rd3.status, rd2.status);
    }
    
    assert_eq!(rd2.status, "CANCELLED");
}

#[test] // @done
fn test_deposit () {

    let context = get_context(vec![], false);
    testing_env!(context);
    let mut ob = get_default_ob(); 

    let bal = ob.view_balance();
    
    let amount = U128(10);

    let payment = ob.deposit("test deposit".to_string(),amount, U64((Utc::now().timestamp_millis()+17) as u64));

    let test_payment = ob.find_payment(U64(payment.reference));

    let test_bal = ob.view_balance(); 

    assert_eq!(payment, test_payment);

    let total = u128::from(bal)+u128::from(amount);

    assert_eq!(total, u128::from(test_bal))

}

#[test] // @cross account
fn test_withdraw () {

    let context = get_context(vec![], false);
    testing_env!(context);
    let ob = get_default_ob();     


}

#[test] // @ done
fn test_set_open_bank_nominee_account () {

    let context = get_context(vec![], false);
    testing_env!(context);
    let mut ob = get_default_ob();  
    
    let nominee = "test_nominee.testnet".to_string(); 

    ob.set_open_bank_nominee_account(nominee.clone());

    assert_eq!(ob.view_nominee_account_id(), nominee);
}

#[test]//
fn test_set_obei_open_roles () {

    let context = get_context(vec![], false);
    testing_env!(context);
    let ob = get_default_ob();   

}

#[test] //@internal 
fn test_pay_to () {

    let context = get_context(vec![], false);
    testing_env!(context);
    let ob = get_default_ob();     
}

#[test] //@internal @done
fn test_create_and_register_payment () {

    let context = get_context(vec![], false);
    testing_env!(context);
    let mut ob = get_default_ob();    
    let payee = "test_payee.testnet".to_string(); 
    let payer = "test_payer.testnet".to_string();  
    let signer = "test_signer.testnet".to_string();
    let amount = 1;
    let description= "test payment".to_string(); 
    let payment_status = "TEST".to_string();
    let payment_type = "TEST".to_ascii_lowercase();
    let payment = ob.create_and_register_payment(payee, payer, signer, amount, description, payment_status, payment_type); 

    let test_payment = ob.find_payment(U64(payment.reference));

    assert_eq!(test_payment, payment);

}
    

#[test] //@internal @done  
#[should_panic (expected = "failed condition")]
fn test_require () {

    let context = get_context(vec![], false);
    testing_env!(context);
    let mut ob = get_default_ob();
    
    assert!(ob.require(false, "failed condition".to_string() ))
}

#[test] // @internal @cross contract
fn test_is_secure () {

    let context = get_context(vec![], false);
    testing_env!(context);
    let mut ob = get_default_ob(); 
    
    assert!(ob.is_secure("view_balance".to_string(), "ALLOWED".to_string()));
    
    assert!(ob.is_secure("request_debit".to_string(), "BARRED".to_string()));    
}

#[test] // @internal @done
#[should_panic (expected = "REPEAT NONCE DETECTED")]
fn test_check_nonce () {

    let context = get_context(vec![], false);
    testing_env!(context);
    let mut ob = get_default_ob(); 
    
    let nonce = env::block_timestamp();

    ob.check_nonce(nonce);

    ob.check_nonce(nonce)
}

#[test] // @internal @done 
#[should_panic (expected = "INSUFFICIENT FUNDS AVAILABLE")]
fn test_check_bank_balance (){
    
    let context = get_context(vec![], false);
    testing_env!(context);
    let mut ob = get_default_ob();   
    
    ob.check_bank_balance(100);

}

#[test] // @internal @done
#[should_panic (expected = "REQUEST DEBIT REFERENCE NOT FOUND")]
fn test_check_is_valid_request_debit_reference () {

    let context = get_context(vec![], false);
    testing_env!(context);
    let mut ob = get_default_ob();
    
    ob.check_is_valid_request_debit_reference(0);
    
}

#[test] // @internal @done
#[should_panic (expected = "INVALID STATUS FOR ACTION")]
fn test_check_request_debit_status () {

    let context = get_context(vec![], false);
    testing_env!(context);
    let mut ob = get_default_ob();  
    
    ob.check_request_debit_status("CANCELLED".to_string(), "PENDING".to_string());
}

#[test] // @internal @done
#[should_panic (expected = "DEPOSIT MIS-MATCH")]
fn test_check_attachment_vs_stated_amount () {

    let context = get_context_with_deposit(vec![], false, 10);
    testing_env!(context);
    let mut ob = get_default_ob();     

    ob.check_attachment_vs_stated_amount(10, 9)

}

#[test] // @internal @done
#[should_panic (expected = "PAY OUT INTERVAL NOT REACHED")]
fn test_check_request_debit_interval () { 

    let context = get_context(vec![], false);
    testing_env!(context);
    let mut ob = get_default_ob();   
    
    let request_debit_amount = U128(1);
    let start_date = I64(Utc::now().timestamp_millis()-600000); 
    let end_date = I64(i64::from(start_date) + (24*60*60*1000));
    let interval  = I64(30000000000);
    let nonce = U64(Utc::now().timestamp_millis() as u64);
    
    let rd_ref = ob.register_request_debit("test_account_2.testnet".to_string(), "test request debit".to_string(), request_debit_amount, interval, start_date, end_date, nonce);

    let request_debit = ob.find_request_debit(rd_ref); 

    ob.check_request_debit_interval(request_debit);
    
}

#[test] // @internal @done
fn test_decrement_bank_balance () {

    let context = get_context(vec![], false);
    testing_env!(context);
    let mut ob = get_default_ob();  
    
    let bal = ob.view_balance(); 

    ob.decrement_bank_balance(1);

    let total =U128(u128::from(bal) - 1); 

    assert_eq!(total, ob.view_balance());
    
}

#[test] // @internal @done
fn test_increment_bank_balance () {

    let context = get_context(vec![], false);
    testing_env!(context);
    let mut ob = get_default_ob(); 
    
    let bal = ob.view_balance(); 

    ob.increment_bank_balance(1);

    let total = U128(u128::from(bal) + 1);

    assert_eq!(total, ob.view_balance());
}


#[test] // @internal @ done
fn test_move_request_debit_by_status () {

    let context = get_context(vec![], false);
    testing_env!(context);
    let mut ob = get_default_ob();  
    
    let request_debit_amount = U128(1);
    let start_date = I64(Utc::now().timestamp_millis()); 
    let end_date = I64(i64::from(start_date) + (24*60*60*1000));
    let interval  = I64(60);
    let nonce = U64(Utc::now().timestamp_millis() as u64);
    let new_nonce = U64((Utc::now().timestamp_millis()+10) as u64);
    let rd_ref = ob.register_request_debit("test_account_2.testnet".to_string(), "test request debit".to_string(), request_debit_amount, interval, start_date, end_date, new_nonce);

    let rd = ob.find_request_debit(rd_ref);     

    let t = &mut ob;

    ob.move_request_debit_by_status("PENDING".to_string(), "APPROVED".to_string(), rd);
}
