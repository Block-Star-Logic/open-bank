// "SPDX-License-Identifier: Apache 2.0"
pragma solidity >0.7.0 <=0.9.0;

/** 
 * The IBank interface provides a way for a dApp / blockchain business to manage it's funds on chain without sending the funds 
 * to a wallet or keeping them in the operational contract. This interface is for single currency support. 
 * NOTE: currency contract is set once
 */ 
interface IBank { 
    
    /**
     * @dev This operation will depost the given amount with the given user specified payment reference  
     * @param _amount amount that is being deposited 
     * @param _paymentReference caller specified deposit reference
     * @return _bankBalance balance of this IBank instance (not necessarily the balance of the contract)
     * @return _depositTime block time at which this deposit was made
     * @return _txnRef transaction reference for this deposit
     */ 
    function deposit(uint256 _amount, string memory _paymentReference) payable external returns (uint256 _bankBalance, uint256 _depositTime, uint256 _txnRef);
    
    /** 
     * @dev this will withdraw the given amount from the bank and issue a withdrawal reference 
     * @param _amount amount that is being withdrawn 
     * @param _withdrawalReference caller specified withdrawal reference 
     * @param _payoutAddress address to which the amount withdrawn should be sent
     * @return _bankBalance remaining balance of this Bank
     * @return _withdrawalTime block time at which this withdrawal was made
     * @return _txnRef transaction ref for this withdrawal 
     */ 
    function withdraw(uint256 _amount, string memory _withdrawalReference,  address payable _payoutAddress) external returns (uint256 _bankBalance, uint256 _withdrawalTime, uint256 _txnRef);
    
    /**
     * @dev this will return the ERC20 currency that this bank supports. It will return address(0) for ETH 
     * @return _currencyContract
     */ 
    function getCurrencyContract() external view returns (address _currencyContract);

    /**
     * @dev This will return the details of the transaction listed by the given transaction reference 
     * @param _txRef reference of transaction that is sought
     * @return _txnType type of this transaction i.e. 'withdrawal' or 'deposit'
     * @return _txnInitiatorRef caller reference for the transaction i.e. 'deposit reference' or 'withdrawal reference'
     * @return _txnDate date of the transaction 
     * @return _txnAmount amount transacted in the transation 
     * @return _txnInitiator caller address 
     * @return _txnReciepient recipient of funds in the transaction 
     * @return _txnRef transaction reference for this transaction should be the same as '_txRef'
     */ 
    function findTransaction(uint256 _txRef) external view returns (string memory _txnType, string memory _txnInitiatorRef, uint256 _txnDate, uint256 _txnAmount, address _txnInitiator, address _txnReciepient, uint256 _txnRef);
    
    /**
     * @dev this will return the balance of the bank at the given point in time 
     * @return _balance balance of this IBank instance (not necessarily the balance of the contract)
     * @return _date the date on which this balance statement was issued
     */
    function getBankBalance() external returns (uint256 _balance, uint256 _date);
    
    /**
     * @dev this will return a statement of transactions between the given dates
     * @param _startDate of the period required for the statement
     * @param _endDate  of the period required for the period 
     * @return _txnType array - type of this transaction i.e. 'withdrawal' or 'deposit'
     * @return _txnInitiatorRef array
     * @return _txnDate array - date of the transaction 
     * @return _txnAmount array - amount transacted in the transation
     * @return _txnInitiator array - caller address
     * @return _txnReciepient array - recipient of funds in the transaction
     * @return _txnRef array - transaction reference for this transaction
     */ 
    function getStatement(uint256 _startDate, uint256 _endDate) external view returns (string [] memory _txnType, string [] memory _txnInitiatorRef, uint256 [] memory _txnDate, uint256 [] memory  _txnAmount, address [] memory  _txnInitiator, address [] memory  _txnReciepient, uint256 [] memory  _txnRef); 
    
}