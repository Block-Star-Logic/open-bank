// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/fcf35e5722847f5eadaaee052968a8a54d03622a/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "../interfaces/IOpenBankAccount.sol";
import "../interfaces/IOpenBankPersonal.sol";


contract OpenBankPersonalAccount is IOpenBankAccount { 

    address constant NATIVE = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;    
    address denomination; 
    IERC20Metadata erc20; 
    string symbol; 
    uint256 registeredBalance; 
    address self; 
    IOpenBankPersonal bank; 
    bool isNative; 

    mapping(address=>mapping(Operation=>bool)) hasLimitByOperationByUser; 
    mapping(address=>mapping(Operation=>uint256)) limitByOperationByUser;

    uint256 [] txnRefs; 
    mapping(uint256=>Txn) txnByTxnRef; 

    constructor(address _bank, address _erc20) {
        if(NATIVE == _erc20){ 
            isNative = true;             
        }
        else {
            erc20 = IERC20Metadata(_erc20);            
            symbol = erc20.symbol();
        }
        denomination = _erc20; 
        self = address(this);
        bank = IOpenBankPersonal(_bank);
    }

    function getTxnRefs() view external returns (uint256 [] memory _txnRefs){
        return txnRefs; 
    }

    function getTxn(uint256 _txnRef) view external returns (Txn memory _txn){
        return txnByTxnRef[_txnRef];
    }

    function getDenomination() view external returns (address _erc20, string memory _sybmol){    
        return (denomination, symbol); 
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

    function payIn(uint256 _amount, string memory _reference) payable external returns (uint256 _txnRef) {
        withinLimit(Operation.PAY_IN, _amount);      
        _txnRef = credit(_amount, msg.sender, self);  
        txnRefs.push(_txnRef);
        Txn memory txn_ = Txn({
                            payer                       : msg.sender,
                            payee                       : self, 
                            txnType                     : "PAY_IN",
                            ref                         : _reference,
                            account                     : self, 
                            currencySymbol              : symbol,
                            amount                      : _amount,              
                            createDate                  : block.timestamp,      
                            txnRef                      : _txnRef,
                            accountRegisteredBalance    : registeredBalance, 
                            accountUnregisteredBalance  : getUnregisteredBalanceInternal()
                            });       
        txnByTxnRef[_txnRef] = txn_;
        bank.registerTxnRef(_txnRef);
        return _txnRef;         
    } 

    function payOut(address payable _to, uint256 _amount, string memory _reference) external returns (uint256 _txnRef){
        withinLimit(Operation.PAY_OUT, _amount);
        _txnRef = debit(_amount, _to);
        txnRefs.push(_txnRef);
        Txn memory txn_ = Txn({
                            payer                       : self,
                            payee                       : _to, 
                            txnType                     : "PAY_OUT",
                            ref                         : _reference,
                            account                     : self, 
                            currencySymbol              : symbol,
                            amount                      : _amount,              
                            createDate                  : block.timestamp,      
                            txnRef                      : _txnRef,
                            accountRegisteredBalance    : registeredBalance, 
                            accountUnregisteredBalance  : getUnregisteredBalanceInternal()
                            });       
        txnByTxnRef[_txnRef] = txn_;
        bank.registerTxnRef(_txnRef);
        return _txnRef; 
    }

    function deposit(uint256 _amount, string memory _reference) payable external returns (uint256 _txnRef){
        require(isOwner(), " owner only ");
        _txnRef = credit(_amount, msg.sender, self);
        txnRefs.push(_txnRef);

        Txn memory txn_ = Txn({
                        payer                       : msg.sender,
                        payee                       : self, 
                        txnType                     : "DEPOSIT",
                        ref                         : _reference,
                        account                     : self, 
                        currencySymbol              : symbol,
                        amount                      : _amount,              
                        createDate                  : block.timestamp,      
                        txnRef                      : _txnRef,
                        accountRegisteredBalance    : registeredBalance, 
                        accountUnregisteredBalance  : getUnregisteredBalanceInternal()
                        });       
            txnByTxnRef[_txnRef] = txn_;
            bank.registerTxnRef(_txnRef);
    }

    function withdraw(uint256 _amount, string memory _reference) external returns (uint256 _txnRef){
        require(isOwner(), " owner only ");
        _txnRef = debit(_amount, payable(msg.sender));
        txnRefs.push(_txnRef);

        Txn memory txn_ = Txn({
                    payer                       : self,
                    payee                       : msg.sender, 
                    txnType                     : "WITHDRAW",
                    ref                         : _reference,
                    account                     : self, 
                    currencySymbol              : symbol,
                    amount                      : _amount,              
                    createDate                  : block.timestamp,      
                    txnRef                      : _txnRef,
                    accountRegisteredBalance    : registeredBalance, 
                    accountUnregisteredBalance  : getUnregisteredBalanceInternal()
                    });       
        txnByTxnRef[_txnRef] = txn_;
        bank.registerTxnRef(_txnRef);
        return _txnRef;  
    }

    function setLimit(address _user, uint256 _amount, Operation _operation) external returns (bool _set){
        require(isOwner(), " owner only ");
        require(bank.isUser(_user), " Unknown user " );
        hasLimitByOperationByUser[_user][_operation] = true; 
        limitByOperationByUser[_user][_operation] = _amount; 
        return true;  
    }

    function exitDiscrepancy() external returns (bool _exited){
        require(isOwner(), " owner only ");
        erc20.transferFrom(self, bank.getSafety(), getDiscrepancyInternal());
        return true;  
    }

    //===================================================== HAS LIMIT ============================================

    function credit(uint256 _amount, address _from, address _to) internal returns (uint256 _txnRef) {
        if(isNative) {
            // do nothing 
        }
        else { 
            uint256 balance_ = erc20.balanceOf(_from);
            require(balance_ >= _amount, " insufficient balance ");
            uint256 allowance_ = erc20.allowance(_from, _to);
            require(allowance_ > _amount, " insufficient approval provided ");
            erc20.transferFrom(_from, _to, _amount);
        }
        _txnRef = incrementRegisteredBalance(_amount);
        return _txnRef; 
    }

    function debit(uint256 _amount, address payable _to) internal returns (uint256 _txnRef) {
        _txnRef = decrementRegisteredBalance(_amount);
        if(isNative) {
            require(self.balance > _amount);
            _to.transfer(_amount);
        }
        else { 
            uint256 balance_ = erc20.balanceOf(self);
            require(balance_ >= _amount, " insufficient balance ");
            erc20.transfer(_to, _amount);
        }        
        return _txnRef; 
    }

    function isUser() view internal returns (bool) {
        require(bank.isUser(msg.sender), " unknown user "); 
        return true; 
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

    function getDiscrepancyInternal() view internal returns (uint256 _discrepancy) {
        return getUnregisteredBalanceInternal() - registeredBalance;
    }

    function getUnregisteredBalanceInternal() view internal returns (uint256 _unregisteredBalance) {
        if(isNative) {
            return self.balance; 
        }
        return erc20.balanceOf(self);
    }

    function withinLimit(Operation _operation, uint256 _requestedAmount) view internal returns (bool){
        if(!isOwner()) {
            uint256 limit_ = 0; 
            if(!hasLimitByOperationByUser[msg.sender][_operation]) {
                require(hasLimitByOperationByUser[msg.sender][Operation.ALL], " no limit set by owner ");
                limit_ = limitByOperationByUser[msg.sender][Operation.ALL];
            }
            else {
                limit_ = limitByOperationByUser[msg.sender][_operation];
            }

            require(limit_ > _requestedAmount, " limits exceeded. ");            
        }
        return true; 
    }

    function isOwner() view internal returns (bool) {
        return bank.getOwner() == msg.sender; 
    }

    function generateTxnRef() view internal returns (uint256 _txRef) {
        _txRef = block.timestamp; 
        return _txRef;  
    }

}