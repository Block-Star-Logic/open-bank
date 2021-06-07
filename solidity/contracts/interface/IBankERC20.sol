pragma solidity >0.7.0 <=0.9.0;
/** 
 * The IBankERC20 interface provides a way for a dApp / blockchain business to manage it's funds on chain without sending the funds 
 * to a wallet or keeping them in the operational contract. This interface supports multi-currency ERC20 interaction 
 */ 

interface IBankERC20 { 
    
 /**
     * this will deposit the given amount into the bank and issue a deposit reference 
     */ 
    function deposit(uint256 _amount, address _erc20ContractAddress) payable external returns (uint256 _depositReference);
    
    /** 
     * this will withdraw the given amount from the bank and issue a withdrawal reference 
     */ 
    function withdraw(uint256 _amount, address _erc20ContractAddress, address _payoutAddress) external returns (uint256 _withdrawalReference);
    
    /**
     * this will return the ERC20 currency that this bank supports. It will return address(0) for ETH 
     */ 
    function getSupportedCurrencyContracts() external view returns (address [] memory _erc20CurrencyContracts);

    /**
     * this will find the deposit linked to the given deposit reference 
     */ 
    function findDeposit(uint256 _depositReference) external returns (address _payer, uint256 _date, uint256 _amount, address _erc20CurrencyContract); 

    /**
     * this will find the withdrawal linked to the given withdrawal reference 
     */ 
    function findWithDrawal(uint256 _withdrawalReference) external returns (address _withdrawer, uint256 _date, uint256 _amount, address _erc20CurrencyContract, address _payoutAddress );

    /**
     * this will get the bank balance on the given ERC20 contract 
     */ 
    function getBankBalance(address _erc20CurrencyContract) external returns(uint256 _balance, uint256 _date);
    
    /**
     * this will get the total bank balance across all supported erc20 currency contracts converted into the provided 
     * erc20CurrencyContract. NOTE: this is an expensive operation 
     */ 
    function getTotalBankBalance(address _erc20CurrencyContract) external returns (uint256 _balance, uint256 _date);
    
}
