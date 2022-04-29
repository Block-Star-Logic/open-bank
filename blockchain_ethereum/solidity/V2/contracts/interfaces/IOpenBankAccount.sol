// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import {Txn} from "./IOpenBank.sol";

interface IOpenBankAccount {

    enum Operation{PAY_IN, PAY_OUT, REQUEST_DEBIT_APPROvE, REQUEST_DEBIT_DECLINE, ALL}

    function getDenomination() view external returns (address _erc20, string memory _symbol);

    function getTxnRefs() view external returns (uint256 [] memory _txnRefs);

    function getTxn(uint256 _txnRef) view external returns (Txn memory _txn);

    function getBalances() view external returns (uint256 _registeredBalance, uint256 _unregisteredBalance, uint256 _descripancy);  

    function getRegisteredBalance() view external returns (uint256 _registeredBalance);

    function getUnregisteredBalance() view external returns (uint256 _unregisteredBalance);

    function getBalanceDescrepancy() view external returns (uint256 _discrepancy);

    function payIn(uint256 _amount, string memory _reference) payable external returns (uint256 _txRef); 

    function payOut(address payable _to, uint256 _amount, string memory _reference) external returns (uint256 _txRef);

    function deposit(uint256 _amount, string memory _reference) payable external returns (uint256 _txnRef);

    function withdraw(uint256 _amount, string memory _reference) external returns (uint256 _txRef);

    function setLimit(address _user, uint256 _amount, Operation _operation) external returns (bool _set);

    function exitDiscrepancy() external returns (bool _exited);

}
