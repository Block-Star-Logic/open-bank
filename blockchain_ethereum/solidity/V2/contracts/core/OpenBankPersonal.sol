// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/fcf35e5722847f5eadaaee052968a8a54d03622a/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "https://github.com/Block-Star-Logic/open-version/blob/e161e8a2133fbeae14c45f1c3985c0a60f9a0e54/blockchain_ethereum/solidity/V1/interfaces/IOpenVersion.sol";

import "../interfaces/IOpenBankPersonal.sol";
import "../interfaces/IOpenBankSafety.sol";

import "./OpenBankPersonalAccount.sol";
import "./OpenBank.sol";

contract OpenBankPersonal is OpenBank, IOpenBankPersonal, IOpenVersion { 

    using LOpenUtilities for address; 

    address private owner; 
    string name = "OPEN BANK PERSONAL"; 
    address [] users; 
    address [] suspendedUsers; 

    constructor(address _owner, address _safeHarbour) OpenBank(_safeHarbour) { 
        owner = _owner; 
        version = 1; // override parent version
    }

    function getName() view external returns (string memory _name) {
        return name; 
    }

    function getVersion() view external returns (uint256 _version) {
        return version; 
    }

    function registerCurrencyAcccount(address _erc20) external returns (address _account){
        ownerOnly();
        require(!hasAccountByErc20[_erc20], "account already registered");           
        OpenBankPersonalAccount account_ = new OpenBankPersonalAccount(self, _erc20);
        address accountAddress_ = address(account_);
        accountByErc20[_erc20] = accountAddress_;
        hasAccountByErc20[_erc20] = true; 
        knownAccountByAddress[accountAddress_] = true; 
        return accountAddress_; 
    }

    function isUser(address _user) view external returns (bool _isUser) {
        isRegisteredAccount(); 
        return (_user.isContained(users));
    }

    function getUsers() view external returns (address [] memory _users, address [] memory _suspendedUsers){
        return (users, suspendedUsers); 
    }

    function addUser(address _user) external returns (bool _added){
        ownerOnly();
        return addUserInternal(_user);
    }

    function removeUser(address _user) external returns (bool _removed){
        ownerOnly();
        return removeUserInternal(_user);
    }

    function suspendUser(address _user) external returns (bool _suspended){
        ownerOnly();
        removeUserInternal(_user);
        suspendedUsers.push(_user);
        return true; 
    }

    function unsuspendUser(address _user) external returns (bool _unsuspended){
        ownerOnly();
        suspendedUsers = _user.remove(suspendedUsers);
        addUserInternal(_user);
        return true; 
    }

    function updateSafety(address _newSafety) external returns (address _safety) {
        ownerOnly();      
        SAFE_HARBOUR = _newSafety; 
        return SAFE_HARBOUR; 
    }   

    function getSafety() view external returns (address _safeHarbour){
        return SAFE_HARBOUR; 
    }

    function pumpDescrepanciesToSafety(uint256 _batchSize) external returns (address [] memory _erc20Address, uint256 [] memory _nonDenominatedDecrepantAmount){
        ownerOnly();
        _erc20Address = new address[](_batchSize);
        _nonDenominatedDecrepantAmount = new uint256[](_batchSize);
        uint256 y = 0; 
        for(uint256 x = 0; x < allAccounts.length ; x++){
            IOpenBankAccount account_ = IOpenBankAccount(allAccounts[x]);
            (address denominationAddress_, string memory symbol_) = account_.getDenomination(); 
            _erc20Address[y] = denominationAddress_; 
                       
            _nonDenominatedDecrepantAmount[x] = account_.getBalanceDescrepancy(); 

            if(_nonDenominatedDecrepantAmount[x] > 0) {
                safeHarbourTransfer(denominationAddress_,  _nonDenominatedDecrepantAmount[x]);
                y++;
                if(y >= _batchSize){
                    break; 
                }
            }
        }  
        return (_erc20Address, _nonDenominatedDecrepantAmount);
    }

    function exitToSafety(uint256 _batchSize) external returns (address [] memory _erc20Address, uint256 [] memory _exitedNonDenominatedBalances, address _safetyAddress){
        ownerOnly();
        
        _erc20Address = new address[](_batchSize);
        _exitedNonDenominatedBalances = new uint256[](_batchSize);
        uint256 y = 0; 
        for(uint256 x = 0; x < allAccounts.length ; x++){
            IOpenBankAccount account_ = IOpenBankAccount(allAccounts[x]);
            (address denominationAddress_, string memory symbol_) = account_.getDenomination(); 
            _erc20Address[y] = denominationAddress_; 
            
            IERC20 erc20_ = IERC20(denominationAddress_);
           
            _exitedNonDenominatedBalances[x] = erc20_.balanceOf(self);

            if(_exitedNonDenominatedBalances[x] > 0) {
                safeHarbourTransfer(denominationAddress_,  _exitedNonDenominatedBalances[x]);
                y++;
                if(y >= _batchSize){
                    break; 
                }
            }
        }  
        return (_erc20Address, _exitedNonDenominatedBalances, SAFE_HARBOUR );
    }
    

    function getOwner() view external returns (address _owner){
        return owner; 
    }

    function changeOwner(address _newOwner) external returns (address _owner){
        ownerOnly();
        owner =  _newOwner; 
        return _owner; 
    }



    // ============================== INTERNAL =====================================


    function safeHarbourTransfer(address _erc20, uint256 _amount) internal returns (uint256 _transferedBalance ) {
        IERC20 erc20_ = IERC20(_erc20);
        
        if(_amount > 0){
            erc20_.transferFrom(self, SAFE_HARBOUR, _amount);
            return _amount; 
        }
        return 0; 
    }


    function isRegisteredAccount() view internal returns (bool) {
        require(msg.sender.isContained(allAccounts), " bank accounts only");
        return true; 
    }

    function ownerOnly() view internal returns (bool) {
        require(msg.sender == owner, "owner only");
        return true; 
    }

    function addUserInternal(address _user) internal returns (bool) {
        users.push(_user);
        return true; 
    }

    function removeUserInternal(address _user) internal returns (bool) {
         users = _user.remove(users);
        return true; 
    }
}