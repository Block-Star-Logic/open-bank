// SPDX-License-Identifier: APACHE 2.0
pragma solidity >=0.7.0 <0.9.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/fcf35e5722847f5eadaaee052968a8a54d03622a/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "https://github.com/Block-Star-Logic/open-version/blob/e161e8a2133fbeae14c45f1c3985c0a60f9a0e54/blockchain_ethereum/solidity/V1/interfaces/IOpenVersion.sol";

import "https://github.com/Block-Star-Logic/open-bank/blob/main/blockchain_ethereum/solidity/V2/contracts/interfaces/IOpenBankAccount.sol";

abstract contract OpenBankAccount is IOpenBankAccount, IOpenVersion { 
    
    uint256 version = 2; 
    string name = "OPEN_BANK_ACCOUNT";
    address constant NATIVE = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;    
    address denomination; 
    IERC20Metadata erc20; 
    string symbol; 
    uint256 registeredBalance; 
    address self; 
    

    bool isNative; 
    
    uint256 [] txnRefs; 
    mapping(uint256=>Txn) txnByTxnRef; 

    constructor(address _erc20) {
        if(NATIVE == _erc20){ 
            isNative = true;             
        }
        else {
            erc20 = IERC20Metadata(_erc20);            
            symbol = erc20.symbol();
        }
        denomination = _erc20; 
        self = address(this);        
    }

    function getName() virtual view external returns (string memory _name) {
        return name; 
    }

    function getVersion() virtual view external returns (uint256 _version) {
        return version; 
    }

    function getDenomination() view external returns (address _erc20, string memory _sybmol){    
        return (denomination, symbol); 
    }

    function getTxnRefs() view external returns (uint256 [] memory _txnRefs){
        return txnRefs; 
    }

    function getTxn(uint256 _txnRef) view external returns (Txn memory _txn){
        return txnByTxnRef[_txnRef];
    }

    function getBalances() view external returns (uint256 _registeredBalance, uint256 _unregisteredBalance, uint256 _descripancy){
        return (registeredBalance, getUnregisteredBalanceInternal(), getDiscrepancyInternal());
    }

    function getRegisteredBalance() view external returns (uint256 _registeredBalance){
        return registeredBalance; 
    }

    function getUnregisteredBalance() view external returns (uint256 _unregisteredBalance){
        return getUnregisteredBalanceInternal(); 
    }

    function getBalanceDescrepancy() view external returns (uint256 _discrepancy){
        return getDiscrepancyInternal();
    }

    //================================ INTERNAL ===========================================

    function getDiscrepancyInternal() view internal returns (uint256 _discrepancy) {
        return getUnregisteredBalanceInternal() - registeredBalance;
    }

    function getUnregisteredBalanceInternal() view internal returns (uint256 _unregisteredBalance) {
        if(isNative) {
            return self.balance; 
        }
        return erc20.balanceOf(self);
    }

    function mergeDiscrepancyInternal(uint256 _amount) internal returns (uint256 _txRef) {
        uint256 discrepancy_ = getDiscrepancyInternal();
        if( discrepancy_ > _amount){
            // merge only the amount
            _txRef = incrementRegisteredBalance(_amount);
        }
        else { 
            // merge the entire discrepancy
            _txRef = incrementRegisteredBalance(discrepancy_);
        }
        return _txRef; 
    }

    function credit(uint256 _amount, address _from, address _to) internal returns (uint256 _txnRef) {
        if(isNative) {
            // do nothing 
        }
        else { 
            uint256 balance_ = erc20.balanceOf(_from);
            require(balance_ >= _amount, " insufficient balance ");
            uint256 allowance_ = erc20.allowance(_from, _to);
            require(allowance_ >= _amount, " insufficient approval provided ");
            erc20.transferFrom(_from, _to, _amount);
        }
        _txnRef = incrementRegisteredBalance(_amount);
        return _txnRef; 
    }

    function debit(uint256 _amount, address payable _to) internal returns (uint256 _txnRef) {
        _txnRef = decrementRegisteredBalance(_amount);
        if(isNative) {
            require(self.balance >= _amount);
            _to.transfer(_amount);
        }
        else { 
            uint256 balance_ = erc20.balanceOf(self);
            require(balance_ >= _amount, " insufficient balance ");
            erc20.transfer(_to, _amount);
        }        
        return _txnRef; 
    }

    function incrementRegisteredBalance(uint256 _amount) internal returns (uint256 _txId) {
        registeredBalance += _amount; 
        return generateTxnRef();
    }

    function decrementRegisteredBalance(uint256 _amount) internal returns (uint256 _txId) {
        require(registeredBalance >= _amount, "insufficient balance ");
        registeredBalance -= _amount; 
        return generateTxnRef();
    }

    function getTxn(  address _payer, 
                        address   _payee,
                        string  memory  _txnType,    
                        string   memory _ref,  
                        address   _account,
                        string  memory  _currencySymbol, 
                        uint256   _amount,                
                        uint256   _createDate,       
                        uint256   _txnRef,
                        uint256   _accountRegisteredBalance,
                        uint256   _accountUnregisteredBalance) internal pure returns (Txn memory) {
                            Txn memory txn_ = Txn({
                            payer                       : _payer,
                            payee                       : _payee, 
                            txnType                     : _txnType,
                            ref                         : _ref,
                            account                     : _account, 
                            currencySymbol              : _currencySymbol,
                            amount                      : _amount,              
                            createDate                  : _createDate,      
                            txnRef                      : _txnRef,
                            accountRegisteredBalance    : _accountRegisteredBalance, 
                            accountUnregisteredBalance  : _accountUnregisteredBalance
                            });       
        return txn_; 
    }

    function generateTxnRef() view internal returns (uint256 _txRef) {
        _txRef = block.timestamp; 
        return _txRef;  
    }
}