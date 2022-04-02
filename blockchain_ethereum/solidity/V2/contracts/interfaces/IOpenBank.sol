// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


interface IOpenBank { 


  struct Txn { 
        address initiator; 
        uint256 amount; 
        address currency;
        string ref;  
        uint256 date;
        address recipient; 
        bool treasured;
        uint256 auditKey; 
        uint256 txnRef;
        uint256 denominatedAccountedBalance; 
        uint256 denominatedUnAccountedBalance; 
        address denomination; 
        string txType;    
    }

    function getTxnRefs() view external returns (uint256 [] memory _txnRefs);

    function getAuditKeys() view external returns(uint256 [] memory _auditKeys);

    function getTxnByTxnRef(uint256 _txnRef) view external returns (Txn memory _txn);

    function getTxnByAuditKey(uint256 _auditKey) view external returns(Txn memory _txn);

    function getDenomination() view external returns (address _erc20);

    function getBalances() external returns (uint256 _currentAccountedDenominatedBankBalance, uint256 _currentUnAccountedDenominatedBankBalance, uint256 _currentAccountedDenominatedTreasuryBalance, uint256 _currentUnAccountedDenominatedTreasuryBalance, uint256 _snapshotTime );    

    function getCurrenciesWithNonDenominatedBalances() view external returns (address [] memory _erc20Addresses, uint256 [] memory _currentUnAccountedNonDenominatedBalances); 

    function deposit(uint256 _amount, address _erc20Address, string memory _reference) payable external returns (uint256 _txRef);

    function withdraw(uint256 _amount, address _erc20, string memory _withdrawalReference, uint256 _nonce, address payable _payoutAddress) external returns (uint256 _bankBalancew, uint256 _withdrawalTime, uint256 _txnRef);

}