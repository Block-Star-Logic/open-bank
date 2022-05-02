// SPDX-License-Identifier: APACHE 2.0
pragma solidity >=0.7.0 <0.9.0;


import "https://github.com/Block-Star-Logic/open-libraries/blob/703b21257790c56a61cd0f3d9de3187a9012e2b3/blockchain_ethereum/solidity/V1/libraries/LOpenUtilities.sol";

import "./IOpenBank.sol";
import "./IOpenBankAccount.sol";

abstract contract OpenBank is IOpenBank { 

    using LOpenUtilities for address; 
    using LOpenUtilities for address[];

    address constant NATIVE = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;    

    uint256 version             = 1;     
    address SAFE_HARBOUR;     
    address self; 

    uint256 [] txnRefs;
    mapping(uint256=>address) accountByTxRef;
    mapping(address=>bool) knownAccountByAddress; 

    address [] viewableAccounts; 
    address [] hiddenAccounts; 
    address [] allAccounts; 

    mapping(address=>address) accountByErc20; 
    mapping(address=>bool) hasAccountByErc20; 
    

    constructor(address _safeHarbour) {
        SAFE_HARBOUR = _safeHarbour; 
        self = address(this);
    }

    function getTxnRefs() view external returns (uint256 [] memory _txnRefs){
        return txnRefs; 
    }

    function getTxnByTxnRef(uint256 _txnRef) view external returns (Txn memory _txn){
        return IOpenBankAccount(accountByTxRef[_txnRef]).getTxn(_txnRef);
    }

    function getBalances() view external returns (string [] memory _currency, uint256 [] memory _registeredBalance, uint256  [] memory _unregisteredBalance, uint256 [] memory _discrepancy){
        _currency = new string[](viewableAccounts.length);
        _registeredBalance = new uint256[](viewableAccounts.length);
        _unregisteredBalance = new uint256[](viewableAccounts.length);
        _discrepancy = new uint256[](viewableAccounts.length);
        for(uint256 x = 0; x < viewableAccounts.length; x++) {
            IOpenBankAccount ioba = IOpenBankAccount(viewableAccounts[x]);

            address _erc20; 
            (_erc20, _currency[x]) = ioba.getDenomination(); 
            (_registeredBalance[x], _unregisteredBalance[x], _discrepancy[x]) = ioba.getBalances(); 
        }
    }
    

    function registerTxnRef(uint256 _txnRef) external returns (bool _registered){
        require(knownAccountByAddress[msg.sender], " unknown account "); 
        txnRefs.push(_txnRef);
        accountByTxRef[_txnRef] = msg.sender; 
        return true; 
    }

    function getRegisteredAccounts() view external returns (address [] memory _registeredAccounts){
        return viewableAccounts;
    }

    function getRegisteredAccountForDenomination(address _erc20) view external returns (address _account){
        return accountByErc20[_erc20];
    }

    function hasAccount(address _erc20) view external returns (bool _hasAccount){
        return hasAccountByErc20[_erc20];
    }

    function hideCurrencyAccount(address _account) external returns (bool _hidden){
        viewableAccounts = _account.remove(viewableAccounts);
        hiddenAccounts.push(_account);
        return true; 
    }

    function unhideCurrencyAccount(address _account) external returns (bool _unhidden){
       return unhideInternal(_account);
    }

    function unhideAllCurrencyAccounts() external returns (bool _unhidden){
        for(uint256 x = 0; x < hiddenAccounts.length; x++) {
            unhideInternal(hiddenAccounts[x]);
        }
        return true; 
    }


// ========================================== INTERNAL =======================================================

    function addAccountInternal(address _account, address _erc20) internal returns (bool) {
        if(!knownAccountByAddress[_account]){
            viewableAccounts.push(_account);
            allAccounts.push(_account);
            knownAccountByAddress[_account] = true; 
             accountByErc20[_erc20] = _account;
            hasAccountByErc20[_erc20] = true; 
            knownAccountByAddress[_account] = true; 
            return true; 
        }        
        return false; 
    }


    function unhideInternal(address _account) internal returns (bool) { 
        hiddenAccounts = _account.remove(hiddenAccounts);
        viewableAccounts.push(_account);
        return true; 
    }


}