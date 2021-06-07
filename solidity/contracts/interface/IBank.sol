// "SPDX-License-Identifier: Apache 2.0"
pragma solidity >0.7.0 <=0.9.0;

/** 
 * The IBank interface provides a way for a dApp / blockchain business to manage it's funds on chain without sending the funds 
 * to a wallet or keeping them in the operational contract. This interface is for single currency support. 
 * NOTE: currency contract is set once
 */ 
interface IBank { 
    
    /**
     * this will deposit the given amount into the bank and issue a deposit reference 
     */ 
    function deposit(uint256 _amount, string memory paymentReference) payable external returns (uint256 _bankBalance, uint256 _depositTime, uint256 _txnRef);
    
    /** 
     * this will withdraw the given amount from the bank and issue a withdrawal reference 
     */ 
    function withdraw(uint256 _amount, string memory withdrawalReference,  address payable _payoutAddress) external returns (uint256 _bankBalance, uint256 _withdrawalTime, uint256 _txnRef);
    
    /**
     * this will return the ERC20 currency that this bank supports. It will return address(0) for ETH 
     */ 
    function getCurrencyContract() external view returns (address _currencyContract);

    /**
     * This will return the details of the transaction listed by the given transaction reference 
     */ 
    function findTransaction(uint256 txnRef) external view returns (string memory _type, string memory _initiatorRef, uint256 _date, uint256 _amount, address _initiator, address _reciepient, uint256 _txnRef);
    
    /**
     * this will return the balance of the bank at the given point in time 
     */
    function getBankBalance() external returns (uint256 _balance, uint256 _date);
    
    /**
     * this will return a statement of transactions between the given dates
     */ 
    function getStatement(uint256 _startDate, uint256 _endDate) external view returns (string [] memory _type, string [] memory _initiatorRef, uint256 [] memory _date, uint256 [] memory  _amount, address [] memory  _initiator, address [] memory  _reciepient, uint256 [] memory  _txnRef); 
    
}