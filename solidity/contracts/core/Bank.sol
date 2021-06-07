pragma solidity >0.7.0 <=0.9.0; 

import "../contracts/bank/IBank.sol";


contract Bank is IBank { 
    
    
    mapping(string=>uint256) depositsByPaymentReference;
    mapping(string=>uint256) withdrawalsByPaymentReference; 
    
    mapping(string=>bool) paymentReferenceStatusByPaymentReference;
    mapping(string=>bool) widthdrawalReferenceStatusByWidthdrawalReference; 

    address erc20Contract; 
    
    /**
     * this will deposit the given amount into the bank and issue a deposit reference 
     */ 
    function deposit(uint256 _amount, string memory _paymentReference) payable external returns (uint256 _bankBalance, uint256 _depositTime){
        require(!paymentReferenceStatusByPaymentReference[_paymentReference]," duplicate payment reference");
    }
    
    /** 
     * this will withdraw the given amount from the bank and issue a withdrawal reference 
     */ 
    function withdraw(uint256 _amount, string memory _withdrawalReference,  address _payoutAddress) external returns (uint256 _withdrawalTxnReference){
        require(!widthdrawalReferenceStatusByWidthdrawalReference[_withdrawalReference]); 
    }
    
    /**
     * this will return the ERC20 currency that this bank supports. It will return address(0) for ETH 
     */ 
    function getCurrencyContract() external view returns (address _currencyContract){
        return erc20Contract;
    }

    /**
     * this will find the deposit linked to the given deposit reference 
     */ 
    function findDeposit(uint256 _depositReference) external returns (address _payer, uint256 _date, uint256 _amount){
        
    }

    /**
     * this will find the withdrawal linked to the given withdrawal reference 
     */ 
    function findWithDrawal(uint256 _withdrawalReference) external returns (address _withdrawer, uint256 _date, uint256 _amount, address _payoutAddress ){
        
    }
    
    /**
     * this will return the balance of the bank at the given point in time 
     */
    function getBankBalance() external view  returns (uint256 _balance, uint256 _date){
        
    }

    function generateStatement() external view returns (uint256 _) {
        
    }

    function generateTxnRef() internal returns (uint256 _ref){
        uint256 txnRef = block.timestamp;
        txnTimeByReference[_paymentReference] = txnRef; 
        return txnRef;
    }

}