// "SPDX-License-Identifier: Apache 2.0"
pragma solidity >0.7.0 <=0.9.0; 

import "../interface/IBank.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";


contract Bank is IBank { 
    
    mapping(uint256=>Transaction) transactionByTransactionReference; 
    mapping(string=>bool) initatorRefKnownStatusByinitiatorReference;
    mapping(uint256=>bool) transactionRefKnownStatusByTransactionReference; 
    
    uint256 bankBalance; 
    
    address administrator; 
    address erc20Contract; 
    IERC20 erc20; 
    bool native; 
    
    struct Transaction { 
        string  _type; 
        string  _initiatorRef; 
        uint256 _date; 
        uint256 _amount; 
        address _initiator; 
        address _reciepient; 
        uint256 _txnRef; 
    }
    
    Transaction [] txnLog; 
    
    constructor(
                address _administrator, 
                address _erc20Contract // this can only be set once 
                ) {
        administrator = _administrator; 
        if(_erc20Contract == address(0)) {
            native = true;
        }
        else {
            erc20Contract = _erc20Contract; 
            erc20 = IERC20(erc20Contract);
        }
    }
    
    /**
     * this will deposit the given amount into the bank and issue a deposit reference 
     */ 
    function deposit(uint256 _amount, string memory _depositReference) override payable external returns (uint256 _bankBalance, uint256 _depositTime, uint256 _txnRef){
        applyBasicSecurity();
        require(!initatorRefKnownStatusByinitiatorReference[_depositReference]," d00 - duplicate deposit reference");
        require(_amount > 0, "d01 - malicious deposit amount ");
        if(!native) { // not ETH
            erc20.transferFrom(msg.sender, address(this), _amount);
        }
        else {
            // nothing to do 
        }
        bankBalance+=_amount; // add to balance
        uint256 txnRef = generateTxnRef(); 
        Transaction memory transaction = Transaction({  _type : "deposit", 
                                                            _initiatorRef : _depositReference, 
                                                            _date : block.timestamp, 
                                                            _amount : _amount, 
                                                            _initiator : msg.sender, 
                                                            _reciepient : address(this), 
                                                            _txnRef : txnRef
                                                        });
        txnLog.push(transaction)                                                        ;
        transactionByTransactionReference[txnRef] = transaction; 
        return (bankBalance, block.timestamp, txnRef);
    }
    
    /** 
     * this will withdraw the given amount from the bank and issue a withdrawal reference 
     */ 
    function withdraw(uint256 _amount, string memory _withdrawalReference,  address payable _payoutAddress) override external returns (uint256 _bankBalance, uint256 _withdrawalTime, uint256 _txnRef){
        applyBasicSecurity();
        require(!initatorRefKnownStatusByinitiatorReference[_withdrawalReference], "w00 - duplicate withdrawal reference"); 
        require(_amount > 0, "w01 - malicious withdrawal amount ");
        require(bankBalance > 0 && bankBalance >= _amount, "w02 insufficient funds ");
        bankBalance-=_amount; // deduct from the balance first 
        if(!native) { // not ETH
            erc20.transfer(_payoutAddress, _amount);
        }
        else {
           _payoutAddress.transfer(_amount);
        }
        uint256 txnRef = generateTxnRef(); 
        Transaction memory transaction = Transaction({  _type : "withdrawal", 
                                                    _initiatorRef : _withdrawalReference, 
                                                    _date : block.timestamp, 
                                                    _amount : _amount, 
                                                    _initiator : msg.sender, 
                                                    _reciepient : _payoutAddress, 
                                                    _txnRef : txnRef
                                                });
        txnLog.push(transaction)                                                        ;
        transactionByTransactionReference[txnRef] = transaction; 
        return (bankBalance, block.timestamp, txnRef);
    }
    
    /**
     * this will return the ERC20 currency that this bank supports. It will return address(0) for ETH 
     */ 
    function getCurrencyContract() override external view returns (address _currencyContract){
        applyBasicSecurity();
        return erc20Contract;
    }

    function findTransaction(uint256 txnRef) override external view returns (string memory _type, string memory _initiatorRef, uint256 _date, uint256 _amount, address _initiator, address _reciepient, uint256 _txnRef) {
        applyBasicSecurity();
        require(transactionRefKnownStatusByTransactionReference[txnRef], "ft00 - unkown transaction reference");
        Transaction memory transaction = transactionByTransactionReference[txnRef];
        return (transaction._type,transaction._initiatorRef, transaction._date, transaction._amount, transaction._initiator, transaction._reciepient, transaction._txnRef );
    }
    
    /**
     * this will return the balance of the bank at the given point in time. NOTE: this is not the same as the balance of the contract 
     */
    function getBankBalance() override external view returns (uint256 _balance, uint256 _date){
        applyBasicSecurity();
        return (bankBalance, block.timestamp); 
    }

    function getStatement(uint256 _startDate, uint256 _endDate) override external view returns (string [] memory _type, 
                                                                                                string [] memory _initiatorRef, 
                                                                                                uint256 [] memory _date,
                                                                                                uint256 [] memory  _amount, 
                                                                                                address [] memory  _initiator, 
                                                                                                address [] memory  _receipient, 
                                                                                                uint256 [] memory  _txnRef) {
        applyBasicSecurity();
        
        uint256 length = txnLog.length; 
        Transaction [] memory results = new Transaction[](length);
        
        // find the right transactions
        uint256 inRangeIndex = 0; 
        uint256 x = 0;
        for(x ; x < length; x++ ){
            Transaction memory transaction = txnLog[x];
            if(transaction._date >= _startDate && transaction._date <=_endDate){
                results[inRangeIndex] = transaction;
                inRangeIndex++;
            }
        }
            
        _type = new string[](inRangeIndex); 
        _initiatorRef = new string[](inRangeIndex);
        _date = new uint256[](inRangeIndex); 
        _amount = new uint256[](inRangeIndex);
        _initiator = new address[](inRangeIndex); 
        _receipient = new address[](inRangeIndex); 
        _txnRef = new uint256[](inRangeIndex);
        
        // reset x
        uint256 y = 0;
        
        // reset length
        
        for(y ; y < inRangeIndex; y++) {
            Transaction memory result = results[y];
            _type[y] =  result._type;  
            _initiatorRef[y] =  result._initiatorRef; 
            _date[y] =  result._date; 
            _amount[y] =  result._amount; 
            _initiator[y] =  result._initiator; 
            _receipient[y] =  result._reciepient;
            _txnRef[y] =  result._txnRef; 
        }
        
        return (_type, _initiatorRef, _date, _amount, _initiator, _receipient, _txnRef); 
    }

    function generateTxnRef() internal returns (uint256 _ref){
        uint256 txnRef = block.timestamp;
        transactionRefKnownStatusByTransactionReference[txnRef] = true; 
        return txnRef;
    }

    function applyBasicSecurity() internal view returns (bool _isAllowed){
        require(msg.sender == administrator, " abs 00 - bank administrator only ");
        return true; 
    }

}