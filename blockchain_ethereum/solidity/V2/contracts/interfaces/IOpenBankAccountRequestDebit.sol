// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./IOpenBankAccount.sol";

interface IOpenBankAccountRequestDebit is IOpenBankAccount { 

    struct RequestDebit  { 
        address requestor;
        address payee; 
        uint256 amount; 
        uint256 createDate; 
        uint256 latestRequestDate;         
        uint256 requestInterval;         
        uint256 [] requestTxnIds; 
    }

    function registerRequestDebit(address _owner, uint256 _amount, uint256 _interval) external returns (uint256 _requestDebitRef);

    function getRequestDebits() view external returns (RequestDebit [] memory _requestDebits);

    function getRequestDebitStatus(uint256 _requestDebitRef) view external returns (string memory _requestDebitStatus);

    function approveRequestDebit(uint256 _requestDebitRef) external returns (bool _approved);

    function declineRequestDebit(uint256 _requestDebitRef) external returns (bool _declined);
    
    function cancelRequestDebit(uint256 _requestDebitRef) external returns (bool _cancel);

}