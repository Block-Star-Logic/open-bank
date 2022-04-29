// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./IOpenBank.sol";
import "./IOpenBankSafety.sol";

interface IOpenBankPersonal is IOpenBank, IOpenBankSafety  { 

    // ============================= USERS =======================================

    function isUser(address _user) view external returns (bool _isUser);

    function getUsers() view external returns (address [] memory _users, address [] memory _suspendedUsers);

    function addUser(address _user) external returns (bool _added);

    function removeUser(address _user) external returns (bool _removed);

    function suspendUser(address _user) external returns (bool _suspended);

    function unsuspendUser(address _user) external returns (bool _unsuspended);

    // ============================= OWNER =======================================

    function getOwner() view external returns (address _owner); 

    function changeOwner(address _newOwner) external returns (address _owner);

}