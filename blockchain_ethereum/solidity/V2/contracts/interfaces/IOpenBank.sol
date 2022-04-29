// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


struct Txn { 
  address payer; 
  address payee; 
  string txnType;    
  string ref;  
  address account;
  string currencySymbol; 
  uint256 amount;                
  uint256 createDate;       
  uint256 txnRef;
  uint256 accountRegisteredBalance; 
  uint256 accountUnregisteredBalance;         
}

interface IOpenBank { 

    function getTxnRefs() view external returns (uint256 [] memory _txnRefs);

    function getTxnByTxnRef(uint256 _txnRef) view external returns (Txn memory _txn);

    function registerTxnRef(uint256 _txnRef) external returns (bool _registered);

    // ============================= ACCOUNTS =======================================    

    function getBalances() view external returns (string [] memory _currency, uint256 [] memory _registeredBalance, uint256  [] memory _unregisteredBalance, uint256 [] memory _discrepancy);
    
    function getRegisteredAccounts() view external returns (address [] memory _registeredAccounts);

    function hasAccount(address _erc20) view external returns (bool _hasAccount);

    function registerCurrencyAcccount(address _erc20) external returns (address _account);

    function hideCurrencyAccount(address _account) external returns (bool _hidden);

    function unhideCurrencyAccount(address _account) external returns (bool _unhidden);

    function unhideAllCurrencyAccounts() external returns (bool _unhidden);

}