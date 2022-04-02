// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";

import "https://github.com/Block-Star-Logic/open-roles/blob/e7813857f186df0043c84f0cca42478584abe09c/blockchain_ethereum/solidity/v2/contracts/core/OpenRolesSecure.sol";
import "https://github.com/Block-Star-Logic/open-roles/blob/fc410fe170ac2d608ea53e3760c8691e3c5b550e/blockchain_ethereum/solidity/v2/contracts/interfaces/IOpenRolesManaged.sol";

import "https://github.com/Block-Star-Logic/open-register/blob/85c0a12e23b69c71a0c256938f6084cfdf651c77/blockchain_ethereum/solidity/V1/interfaces/IOpenRegister.sol";

import "../interfaces/IOpenBank.sol";

import "../openblock/IOpenOracle.sol";
import "../openblock/IOpenTreasury.sol";


contract OpenBank is OpenRolesSecure, IOpenRolesManaged, IOpenBank { 

    using LOpenUtilities for address[];

    string name                 = "RESERVED_OPEN_BANK"; 
    uint256 version             = 1; 
    address NATIVE              = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    bool denominationNative; 
    address SAFE_HARBOUR;     

    string registerCA           = "RESERVED_OPEN_REGISTER";
    string roleManagerCA        = "RESERVED_OPEN_ROLES";    
    string oracleCA             = "RESERVED_OPEN_ORACLE";
    string safeHarbourCA        = "RESERVED_SAFE_HARBOUR_ADDRESS";
    string denominationCA       = "DAPP_CURRENCY_DENOMINATION_ADDRESS";

    uint256 [] txnRefs;
    Txn [] txnLog;

    mapping(uint256=>Txn) txnBytxnRef; 
    mapping(uint256=>Txn) txnByauditKey; 

    address denomination; 

    IOpenRegister registry; 
    IOpenOracle oracle; 
    IOpenTreasury treasury; 


    bool treasuryActive; 

    string openAdminRole    = "RESERVED_OPEN_ADMIN_ROLE";
    string openBankUserRole = "OPEN_BANK_USER_ROLE";
    string barredUserRole   = "BARRED_USER_ROLE";

    string [] defaultRoles = [openAdminRole, barredUserRole, openBankUserRole];

    mapping(string=>bool) hasDefaultFunctionsByRole;
    mapping(string=>string[]) defaultFunctionsByRole;

    mapping(address=>uint256[]) auditKeysByTreasuryAddress; 

    address [] knownDenominationList; 
    mapping(address=>bool) knownDenominationByAddress;

    mapping(address=>uint256) heldAccountedBalanceByAddress;
    
    uint256 [] treasuryAuditKeys; 

    uint256 denominatedDepositBalance;

    constructor(address _registryAddress) {
        registry = IOpenRegister(_registryAddress);
        
        denomination = registry.getAddress(denominationCA);
        denominationNative = NATIVE == denomination; 
        knownDenominationList.push(denomination);
        if(!denominationNative){
            knownDenominationList.push(NATIVE);
        }

        setRoleManager(registry.getAddress(roleManagerCA));
        SAFE_HARBOUR = registry.getAddress(safeHarbourCA);
        oracle = IOpenOracle(registry.getAddress(oracleCA));        


        addConfigurationItem(address(oracle));
        addConfigurationItem(address(roleManager));  
        addConfigurationItem(safeHarbourCA, SAFE_HARBOUR, 0);
        addConfigurationItem(_registryAddress);   
        
        addConfigurationItem(denominationCA, denomination, 0);
        addConfigurationItem(self);

        initDefaultRolesForFunction();
    }

    function getName() override view external returns (string memory _name) { 
        return name;         
    }

    function getVersion() override view external returns( uint256 _version) {
        return version; 
    }

    function getDefaultRoles() override view external returns (string [] memory _roles){
        return defaultRoles; 
    }
    function hasDefaultFunctions(string memory _role) override view external returns(bool _hasFunctions){
        return hasDefaultFunctionsByRole[_role];
    }

    function getDefaultFunctions(string memory _role) override view external returns (string [] memory _functions){
        return defaultFunctionsByRole[_role];
    }

    function getDenomination() override view external returns (address _erc20){
        return denomination; 
    }

    function getTxnRefs() override view external returns (uint256 [] memory _txnRefs){
        return txnRefs; 
    }

    function getAuditKeys() override view external returns(uint256 [] memory _auditKeys){
        return treasuryAuditKeys;
    }

    function getTxnByTxnRef(uint256 _txnRef) override view external returns (Txn memory _txn){
        return txnBytxnRef[_txnRef];        
    }

    function getTxnByAuditKey(uint256 _auditKey) override view external returns(Txn memory _txn){
        return txnByauditKey[_auditKey];                                                                     
    }
 

    function getTokenBalance(address _erc20Address) view external returns (uint256 _balance){
        return IERC20(_erc20Address).balanceOf(self);
    }

    function getDepositedTokens() view external returns (address [] memory _tokenList) {
        return knownDenominationList; 
    }

    function getBalances() override external returns (uint256 _currentAccountedDenominatedBankBalance, 
                                            uint256 _currentUnAccountedDenominatedBankBalance, 
                                            uint256 _currentAccountedDenominatedTreasuryBalance,             
                                            uint256 _currentUnAccountedDenominatedTreasuryBalance, uint256 _snapshotTime ){
        
        for(uint256 x = 0; x < knownDenominationList.length; x++)    {
            address erc20_ = knownDenominationList[x];
            uint256 heldAccountedBalance_ =  heldAccountedBalanceByAddress[erc20_];

            if(erc20_ == denomination){
                _currentAccountedDenominatedBankBalance += heldAccountedBalance_; 
                if(denominationNative){
                    _currentUnAccountedDenominatedBankBalance += payable(self).balance;
                }
                else {
                    _currentUnAccountedDenominatedBankBalance += IERC20(denomination).balanceOf(self);
                }                               
            }
            else {                                 
                _currentAccountedDenominatedBankBalance += convertInternal(heldAccountedBalance_, erc20_, denomination);
                if(erc20_ == NATIVE){
                    _currentUnAccountedDenominatedBankBalance += convertInternal(payable(self).balance, NATIVE, denomination);
                }
                else { 
                    IERC20 ierc20_ = IERC20(erc20_);
                    _currentUnAccountedDenominatedBankBalance += convertInternal(ierc20_.balanceOf(self), NATIVE, denomination);
                }
            } 
        }
        _snapshotTime = block.timestamp; 
        if(treasuryActive) {
            (uint256 denominatedDepositBalance_, uint256 denominatedActualBalance_, uint256 date_) = treasury. getDenominatedBalance(); 
            address treasuryDenomination_ = treasury.getDenomination(); 
            if(treasuryDenomination_ == denomination) {
                _currentAccountedDenominatedTreasuryBalance = denominatedDepositBalance_; 
                _currentUnAccountedDenominatedBankBalance = denominatedActualBalance_; 
            }
            else {
                _currentAccountedDenominatedTreasuryBalance = convertInternal(denominatedDepositBalance_, treasuryDenomination_, denomination); 
                _currentUnAccountedDenominatedBankBalance = convertInternal(denominatedActualBalance_, treasuryDenomination_, denomination); 
            }        
            _snapshotTime = date_; 
        }
        
        return (_currentAccountedDenominatedBankBalance, 
                _currentUnAccountedDenominatedBankBalance, 
                _currentAccountedDenominatedTreasuryBalance,             
                _currentUnAccountedDenominatedTreasuryBalance, 
                _snapshotTime ); 

    }

    mapping(uint256=>bool) knownNonce; 


    function withdraw(uint256 _amount, address _requestedErc20, string memory _withdrawalReference, uint256 _nonce, address payable _payoutAddress) override external returns (uint256 _denominatedAccountedBalance, uint256 _withdrawalTime, uint256 _txnRef){
        require(isSecure(openBankUserRole, "withdraw")," admin only "); 
        require(!knownNonce[_nonce], " replayed transaction ");
        require(_amount > 0, " zero amounts not allowed ");
        knownNonce[_nonce] = true;        
        return withdrawInternal(_amount, _requestedErc20, _withdrawalReference, _payoutAddress);
    }    

    function deposit(uint256 _amount, address _erc20Address, string memory _reference) override payable external returns (uint256 _txRef) {
        require(isSecureBarring(barredUserRole, "deposit")," admin only "); 
        bool native_ = _erc20Address == NATIVE; 
        bool denominated_ = _erc20Address == denomination; 
        if(native_){
            require(msg.value >= _amount, " declared value <-> transmitted value mis-match ");
        }
        require(_amount > 0, " zero amounts not allowed ");            
        return depositInternal(native_, denominated_, _amount, _erc20Address, _reference ); 
    }

    function getCurrenciesWithNonDenominatedBalances() override view external returns (address [] memory _erc20Addresses, uint256 [] memory _nonDenominatedBalances){
        require(isSecure(openBankUserRole, "getCurrenciesWithBalance")," admin only ");
        uint256 size_ = knownDenominationList.length; 
        _erc20Addresses = new address[](size_);
        _nonDenominatedBalances = new uint256[](size_);
        if(!treasuryActive) {          
            uint256 trimCount_ = 0; 
            for(uint256 x = 0; x < knownDenominationList.length; x++){
                IERC20 erc20_ = IERC20(knownDenominationList[x]);     
                uint256 balance_ = erc20_.balanceOf(self);
                if(balance_ > 0 ){
                    _nonDenominatedBalances[x] = balance_; 
                    _erc20Addresses[x] = address(erc20_);
                }
                else { 
                    trimCount_++; 
                }
            }
            _erc20Addresses = _erc20Addresses.trim(trimCount_);
        }
        else { 
            _erc20Addresses = new address[](1);
            _nonDenominatedBalances = new uint256[](1);
            _erc20Addresses[0] = treasury.getDenomination();            
            _nonDenominatedBalances[0] = treasury.getDenominatedAccountedBalance();
        }

        return (_erc20Addresses, _nonDenominatedBalances);
    }

    function getTreasury() view external returns(address _treasuryAddress) {
        require(isSecure(openBankUserRole, "getTreasury")," admin only ");
        return address(treasury);
    }

    function getSafety() view external returns (address _safetyAddress){
        require(isSecure(openBankUserRole, "getSafety")," admin only "); 
        return SAFE_HARBOUR; 
    }

    function getTreasuryAuditKeys(address _treasuryAddress) view external returns (uint256 [] memory _auditKeys){
        require(isSecure(openBankUserRole, "getTreasuryAuditKeys")," admin only "); 
        return auditKeysByTreasuryAddress[_treasuryAddress]; 
    }

    function exitToSafety() external returns (address [] memory _erc20Address, uint256 [] memory _exitedNonDenominatedBalances, address _safetyAddress){
        require(isSecure(openAdminRole, "exitToSafety")," admin only "); 
        uint256 size_ = knownDenominationList.length; 
        _erc20Address = new address[](size_);
        _exitedNonDenominatedBalances = new uint256[](size_);
        for(uint256 x = 0; x < knownDenominationList.length; x++){
            _erc20Address[x] = knownDenominationList[x]; 
            _exitedNonDenominatedBalances[x] = safeHarbourTransfer(_erc20Address[x]);
        }
        return (_erc20Address, _exitedNonDenominatedBalances, SAFE_HARBOUR);
    }

    function updateSafety(address _newSafety) external returns (address _safety) {
        require(isSecure(openAdminRole, "updateSafety")," admin only ");         
        SAFE_HARBOUR = _newSafety; 
        return SAFE_HARBOUR; 
    }   

    function setAutonomousTreasuryModule(address _treasuryAddress)  external returns (bool _treasuryAdded, uint256 _migrationCount){
        require(isSecure(openAdminRole, "addAutonomousTreasuryModule")," admin only "); 
        treasury = IOpenTreasury(_treasuryAddress);
        _migrationCount = moveFundsToTreasury(); 
        treasuryActive = true; 
        return (true, _migrationCount); 
    }

    function removeAutonomousTreasuryModule() external returns (bool _treasuryRemoved, uint256 _unlockDate, uint256 _treasuryBalance, uint256 _unlockedAmount, address _denomination, uint256 _auditKey ) {
        require(isSecure(openAdminRole, "removeAutonomousTreasuryModule")," admin only "); 
        uint256 txnRef_; 
        (_unlockDate, _treasuryBalance, _unlockedAmount, _denomination, _auditKey, txnRef_) = treasury.unlockAll();        
        if(!knownDenominationByAddress[_denomination]){
            knownDenominationByAddress[_denomination] = true;
            knownDenominationList.push(_denomination);
        }
        treasuryAuditKeys.push(_auditKey);
        treasury = IOpenTreasury(address(0));
        treasuryActive = false; 
        return(true, _unlockDate, _treasuryBalance, _unlockedAmount, _denomination, _auditKey);
    }


    function notifyChangeOfAddress() external returns (bool _recieved){
        require(isSecure(openAdminRole, "notifyChangeOfAddress")," admin only ");    
        registry                = IOpenRegister(registry.getAddress(registerCA)); // make sure this is NOT a zero address               
        roleManager             = IOpenRoles(registry.getAddress(roleManagerCA));    
        SAFE_HARBOUR            = registry.getAddress(safeHarbourCA);
        oracle                  = IOpenOracle(registry.getAddress(oracleCA));

        addConfigurationItem(safeHarbourCA, SAFE_HARBOUR, 0);
        addConfigurationItem(address(registry));   
        addConfigurationItem(address(roleManager));   
        addConfigurationItem(address(oracle));
        
        return true; 
    }

    //===================================== INTERNAL ======================================

    function withdrawInternal( uint256 _amount, address _requestedErc20, string memory _withdrawalReference,  address payable _payoutAddress)internal returns (uint256 _denominatedAccountedBalance, uint256 _withdrawalTime, uint256 _txnRef){
         bool native_ = NATIVE == _requestedErc20;       
        bool bankDenominated = _requestedErc20 == denomination; 
        uint256 auditKey_ = 0; 
        address denominationInUse_ = _requestedErc20; 
        uint256 denominatedUnAccountedBalance_; 
        if(native_){ // native i.e. chain currency e.g. ETH
            if(bankDenominated){ // bank denomination requested e.g. CELO
                if(treasuryActive){ // draw from treasury
                    (_denominatedAccountedBalance, _withdrawalTime, _txnRef, auditKey_, denominationInUse_) = withdrawNativeDenominatedFromTreasuryInternal(_amount, _withdrawalReference, _payoutAddress);
                    denominatedUnAccountedBalance_ = treasury.getDenominatedUnAccountedBalance(); 
                }
                else { // draw from bank 
                    (_denominatedAccountedBalance, _withdrawalTime, _txnRef, denominationInUse_) = withdrawNativeDenominatedFromBankInternal(_amount, _withdrawalReference,_payoutAddress);
                    denominatedUnAccountedBalance_ = getDenominatedUnAccountedBalance();
                }

            }
            else { // non bank denomination requested e.g. MATIC
                if(treasuryActive){ // draw from treasury
                    (_denominatedAccountedBalance, _withdrawalTime, _txnRef, auditKey_, denominationInUse_) = withdrawNativeNonDenominatedFromTreasuryInternal(_amount, _withdrawalReference, _requestedErc20, _payoutAddress);
                    denominatedUnAccountedBalance_ = treasury.getDenominatedUnAccountedBalance(); 
                }
                else { // draw from bank 
                    (_denominatedAccountedBalance, _withdrawalTime, _txnRef, denominationInUse_) = withdrawNativeNonDenominatedFromBankInternal(_amount, _withdrawalReference, _requestedErc20, _payoutAddress);
                    denominatedUnAccountedBalance_ = getDenominatedUnAccountedBalance();
                }
            }
        }
        else {  // i.e. non chain currency e.g. ERC20
            if(bankDenominated){ // bank denomination requested e.g. USDC
                    if(treasuryActive){ // draw from treasury
                       (_denominatedAccountedBalance, _withdrawalTime, _txnRef, auditKey_, denominationInUse_ ) = withdrawNonNativeDenominatedFromTreasuryInternal(_amount, _withdrawalReference, _payoutAddress);
                       denominatedUnAccountedBalance_ = treasury.getDenominatedUnAccountedBalance(); 
                    }
                    else { // draw from bank 
                       (_denominatedAccountedBalance, _withdrawalTime, _txnRef, denominationInUse_ ) = withdrawNonNativeDenominatedFromBankInternal(_amount, _withdrawalReference, _payoutAddress);
                       denominatedUnAccountedBalance_ = getDenominatedUnAccountedBalance();
                    }

            }
            else { // non bank denomination requested e.g. SUSHI
                    if(treasuryActive){ // draw from treasury
                       (_denominatedAccountedBalance, _withdrawalTime, _txnRef, auditKey_, denominationInUse_) = withdrawNonNativeNonDenominatedFromTreasuryInternal(_amount, _withdrawalReference, _requestedErc20, _payoutAddress);
                       denominatedUnAccountedBalance_ = treasury.getDenominatedUnAccountedBalance(); 
                    }
                    else { // draw from bank 
                       (_denominatedAccountedBalance, _withdrawalTime, _txnRef, denominationInUse_) = withdrawNonNativeNonDenominatedFromBankInternal(_amount, _withdrawalReference, _requestedErc20, _payoutAddress);
                       denominatedUnAccountedBalance_ = getDenominatedUnAccountedBalance();
                    }
            }
        }

        Txn memory txn_ = Txn({
                                initiator : msg.sender,
                                amount : _amount, 
                                currency : _requestedErc20,
                                ref : _withdrawalReference,
                                date : _withdrawalTime,
                                recipient : self, 
                                treasured : treasuryActive, 
                                auditKey : auditKey_,
                                txnRef : _txnRef,
                                denominatedAccountedBalance : _denominatedAccountedBalance, 
                                denominatedUnAccountedBalance : denominatedUnAccountedBalance_, 
                                denomination : denominationInUse_,
                                txType : "WITHDRAWAL"
                            });

        txnLog.push(txn_);
        txnBytxnRef[_txnRef] = txn_;
        
        if(auditKey_ != 0){
            txnByauditKey[auditKey_] = txn_;
        }

    }


    function withdrawNativeDenominatedFromTreasuryInternal(uint256 _amount, string memory _withdrawalReference, address payable _payoutAddress) internal returns (uint256 _denominatedAccountedBalance, uint256 _withdrawalTime, uint256 _txnRef, uint256 _auditKey, address _denominationInUse){        
        uint256 denominatedAccountedAmountUnlocked_;
        (_denominatedAccountedBalance, denominatedAccountedAmountUnlocked_, _denominationInUse, _auditKey, _txnRef) = treasury.unlock(_amount, denomination); 
        _payoutAddress.transfer(_amount);
        _withdrawalTime = block.timestamp;
        return (_denominatedAccountedBalance, _withdrawalTime, _auditKey, _txnRef, _denominationInUse);
    }

    function withdrawNativeDenominatedFromBankInternal(uint256 _amount, string memory _withdrawalReference,address payable _payoutAddress) internal returns (uint256 _denominatedAccountedBalance, uint256 _withdrawalTime, uint256 _txnRef, address _denominationInUse){
        address payable self_ = payable(self);
        require(self_.balance >= _amount, " insufficient balance ");
        heldAccountedBalanceByAddress[denomination] -= _amount; 
        _payoutAddress.transfer(_amount);
        _txnRef = generateTxnRef(); 
        _withdrawalTime = block.timestamp; 
        _denominatedAccountedBalance = getDenominatedAccountedBalance();
        _denominationInUse = denomination; 
        
        return (_denominatedAccountedBalance, _withdrawalTime, _txnRef, _denominationInUse );
    }

	function withdrawNativeNonDenominatedFromTreasuryInternal(uint256 _amount, string memory _withdrawalReference, address _requestedErc20, address payable _payoutAddress) internal returns (uint256 _denominatedAccountedBalance, uint256 _withdrawalTime, uint256 _txnRef, uint256 _auditKey, address _denominationInUse){
        uint256 denominatedAccountedAmountUnlocked_;
        (_denominatedAccountedBalance, denominatedAccountedAmountUnlocked_, _denominationInUse, _auditKey, _txnRef) = treasury.unlock(_amount, _requestedErc20); 
        _payoutAddress.transfer(_amount);
        return (_denominatedAccountedBalance, _withdrawalTime, _auditKey, _txnRef, _denominationInUse);
    }

    function withdrawNativeNonDenominatedFromBankInternal(uint256 _amount, string memory _withdrawalReference, address _requestedErc20, address payable _payoutAddress) internal returns (uint256 _denominatedAccountedBalance, uint256 _withdrawalTime, uint256 _txnRef, address _denominationInUse){
        address payable self_ = payable(self);
        require(self_.balance >= _amount, " insufficient balance ");
        heldAccountedBalanceByAddress[_requestedErc20] -= _amount; 
        _payoutAddress.transfer(_amount);
        _txnRef = generateTxnRef(); 
        _withdrawalTime = block.timestamp; 
        _denominatedAccountedBalance = getDenominatedAccountedBalance();
        _denominationInUse = denomination; 
    }

	function withdrawNonNativeDenominatedFromTreasuryInternal(uint256 _amount, string memory _withdrawalReference, address payable _payoutAddress) internal returns (uint256 _denominatedAccountedBalance, uint256 _withdrawalTime, uint256 _txnRef, uint256 _auditKey, address _denominationInUse){
        uint256 denominatedAccountedAmountUnlocked_;
        (_denominatedAccountedBalance, denominatedAccountedAmountUnlocked_, _denominationInUse, _auditKey, _txnRef) = treasury.unlock(_amount, denomination); 
        IERC20 erc20_ = IERC20(denomination);
        require(erc20_.balanceOf(self) >= _amount, " treasury failure insufficient reciepts ");
        erc20_.transferFrom(self, _payoutAddress, _amount);        
        return (_denominatedAccountedBalance, _withdrawalTime, _auditKey, _txnRef, _denominationInUse);
    }

    function withdrawNonNativeDenominatedFromBankInternal(uint256 _amount, string memory _withdrawalReference, address payable _payoutAddress) internal returns (uint256 _denominatedAccountedBalance, uint256 _withdrawalTime, uint256 _txnRef, address _denominationInUse){
        IERC20 erc20_ = IERC20(denomination);
        require(erc20_.balanceOf(self) >= _amount, " insufficient balance ");
        heldAccountedBalanceByAddress[denomination] -= _amount; 
        _payoutAddress.transfer(_amount);
        _txnRef = generateTxnRef(); 
        _withdrawalTime = block.timestamp; 
        _denominatedAccountedBalance = getDenominatedAccountedBalance();
        _denominationInUse = denomination;
        return (_denominatedAccountedBalance, _withdrawalTime, _txnRef, _denominationInUse);
    }

    function withdrawNonNativeNonDenominatedFromTreasuryInternal(uint256 _amount, string memory _withdrawalReference, address _requestedErc20, address payable _payoutAddress) internal returns (uint256 _denominatedAccountedBalance, uint256 _withdrawalTime, uint256 _txnRef, uint256 _auditKey, address _denominationInUse){
        uint256 denominatedAccountedAmountUnlocked_;
        (_denominatedAccountedBalance, denominatedAccountedAmountUnlocked_, _denominationInUse, _auditKey, _txnRef) = treasury.unlock(_amount, _requestedErc20); 
        IERC20 erc20_ = IERC20(_requestedErc20);
        require(erc20_.balanceOf(self) >= _amount, " treasury failure insufficient reciepts ");
        erc20_.transferFrom(self, _payoutAddress, _amount);        
        return (_denominatedAccountedBalance, _withdrawalTime, _auditKey, _txnRef, _denominationInUse);
    }
    function withdrawNonNativeNonDenominatedFromBankInternal(uint256 _amount, string memory _withdrawalReference, address _requestedErc20, address payable _payoutAddress) internal returns (uint256 _denominatedAccountedBalance, uint256 _withdrawalTime, uint256 _txnRef, address _denominationInUse){
        IERC20 erc20_ = IERC20(_requestedErc20);
        require(erc20_.balanceOf(self) >= _amount, " insufficient balance ");
        heldAccountedBalanceByAddress[_requestedErc20] -= _amount; 
        _payoutAddress.transfer(_amount);
        _txnRef = generateTxnRef(); 
        _withdrawalTime = block.timestamp; 
        _denominatedAccountedBalance = getDenominatedAccountedBalance();
        _denominationInUse = denomination;
        return (_denominatedAccountedBalance, _withdrawalTime, _txnRef, _denominationInUse);
    }




    function depositInternal(bool _native, bool _denominated, uint256 _amount, address _erc20Address, string memory _reference) internal returns (uint256 _txRef){
            uint256 auditKey_ = 0; 
            uint256 denominatedUnAccountedBalance_ = 0; 
            uint256 denominatedAccountedBalance_ = 0;  
            if(_native) {
            if(_denominated){
                if(treasuryActive) {
                    (auditKey_, _txRef) = depositNativeDenominatedToTreasuryInternal(_amount);
                   

                }
                else { 
                    (_txRef) = depositNativeDenominatedToBankInternal(_amount); 
                    denominatedUnAccountedBalance_ = getDenominatedUnAccountedBalance();

                }
            }
            else { 
                if(treasuryActive) {
                    (auditKey_, _txRef) = depositNativeNonDenominatedToTreasuryInternal(_amount, _erc20Address);
                    denominatedUnAccountedBalance_ = treasury.getDenominatedUnAccountedBalance(); 

                }
                else { 
                     (_txRef) = depositNativeNonDenominatedToBankInternal(_amount, _erc20Address); 
                     denominatedUnAccountedBalance_ = getDenominatedUnAccountedBalance();
                }
            }
        }
        else { 
            if(_denominated){
                if(treasuryActive) {
                    (auditKey_, _txRef) = depositNonNativeDenominatedToTreasuryInternal(_amount);
                    denominatedUnAccountedBalance_ = treasury.getDenominatedUnAccountedBalance(); 
                }
                else { 
                    (_txRef) = depositNonNativeDenominatedToBankInternal(_amount); 
                    denominatedUnAccountedBalance_ = getDenominatedUnAccountedBalance();
                }
            }
            else { 
                if(treasuryActive) {
                    (auditKey_, _txRef) = depositNonNativeNonDenominatedToTreasuryInternal(_amount, _erc20Address);
                    denominatedUnAccountedBalance_ = treasury.getDenominatedUnAccountedBalance(); 

                }
                else { 
                     (_txRef) = depositNonNativeNonDenominatedToBankInternal(_amount, _erc20Address); 
                     denominatedUnAccountedBalance_ = getDenominatedUnAccountedBalance();
                }
            }
        }
       
        if(treasuryActive) {
            denominatedUnAccountedBalance_ = treasury.getDenominatedUnAccountedBalance(); 
            denominatedAccountedBalance_ = treasury.getDenominatedAccountedBalance(); 
        }
        else { 
            denominatedUnAccountedBalance_ = getDenominatedAccountedBalance(); 
            denominatedAccountedBalance_ = getDenominatedUnAccountedBalance(); 
        }

        Txn memory txn_ = Txn({
                                initiator : msg.sender,
                                amount : _amount, 
                                currency : _erc20Address,
                                ref : _reference,
                                date : block.timestamp,
                                recipient : self, 
                                treasured : treasuryActive, 
                                auditKey : auditKey_,
                                txnRef : _txRef,
                                denominatedAccountedBalance : denominatedUnAccountedBalance_, 
                                denominatedUnAccountedBalance : denominatedAccountedBalance_, 
                                denomination : denomination,
                                txType : "DEPOSIT"
                            });
        txnLog.push(txn_);
        txnBytxnRef[_txRef] = txn_;
        
        if(auditKey_ != 0){
            txnByauditKey[auditKey_] = txn_;
        }
        return (_txRef);
    }

    function depositNativeDenominatedToTreasuryInternal(uint256 _amount) internal returns (uint256 _auditKey, uint256 _txRef){
        return treasury.lockup{value : _amount }(_amount, denomination);
    }

    function depositNativeDenominatedToBankInternal(uint256 _amount) internal returns (uint256 txRef_){
        heldAccountedBalanceByAddress[denomination] += _amount; 
        return generateTxnRef();
    }

    function depositNativeNonDenominatedToTreasuryInternal(uint256 _amount, address _erc20Address) internal returns (uint256 _auditKey, uint256 _txRef){
        if(!knownDenominationByAddress[_erc20Address]){
            knownDenominationByAddress[_erc20Address] = true;
        }
       return treasury.lockup{value : _amount }(_amount, _erc20Address);
    }

    function depositNativeNonDenominatedToBankInternal(uint256 _amount, address _erc20Address) internal returns (uint256 txRef_) {
        heldAccountedBalanceByAddress[_erc20Address] += _amount; // numerical value
        return generateTxnRef();
    }					 
    
    function depositNonNativeDenominatedToTreasuryInternal(uint256 _amount) internal returns (uint256 _auditKey, uint256 _txRef){
        IERC20 erc20_ = IERC20(denomination);
        erc20_.transferFrom(msg.sender, self, _amount);
        erc20_.approve(address(treasury), _amount);   
        return treasury.lockup(_amount, denomination); 
    }
    
    function depositNonNativeDenominatedToBankInternal(uint256 _amount) internal returns (uint256 txRef_){
        IERC20 erc20_ = IERC20(denomination);
        erc20_.transferFrom(msg.sender, self, _amount);
        heldAccountedBalanceByAddress[denomination] += _amount; // numerical value
        return generateTxnRef();
     
    } 
    function depositNonNativeNonDenominatedToTreasuryInternal(uint256 _amount, address _erc20Address) internal returns (uint256 _auditKey, uint256 _txRef) {
        IERC20 erc20_ = IERC20(_erc20Address);
        erc20_.transferFrom(msg.sender, self, _amount);
        erc20_.approve(address(treasury), _amount);   
        return treasury.lockup(_amount, _erc20Address); 
    }
    function depositNonNativeNonDenominatedToBankInternal(uint256 _amount, address _erc20Address) internal returns (uint256 txRef_){
       IERC20 erc20_ = IERC20(_erc20Address);
       erc20_.transferFrom(msg.sender, self, _amount);
       heldAccountedBalanceByAddress[_erc20Address] += _amount; // numerical value
       return generateTxnRef();     
    }
                     

    function getDenominatedAccountedBalance() internal returns(uint256 _denominatedAccountedBalance) {
          for(uint256 x = 0; x < knownDenominationList.length; x++)    {
            address erc20_ = knownDenominationList[x];
            uint256 heldAccountedBalance_ =  heldAccountedBalanceByAddress[erc20_];

            if(erc20_ == denomination){
                _denominatedAccountedBalance += heldAccountedBalance_;                           
            }
            else {                                 
                _denominatedAccountedBalance += convertInternal(heldAccountedBalance_, erc20_, denomination);               
            } 
        }
    }

    function getDenominatedUnAccountedBalance() internal returns (uint256 _denominatedUnAccountedBalance) {
        for(uint256 x = 0; x < knownDenominationList.length; x++)    {
            address erc20_ = knownDenominationList[x];
            
            if(erc20_ == denomination){
                _denominatedUnAccountedBalance += IERC20(denomination).balanceOf(self);                                               
            }
            else {                                 
                IERC20 ierc20_ = IERC20(erc20_);
                _denominatedUnAccountedBalance += convertInternal(ierc20_.balanceOf(self), NATIVE, denomination);
                
            } 
        }
        return _denominatedUnAccountedBalance; 
    }

    function safeHarbourTransfer(address _erc20) internal returns (uint256 _transferedBalance ) {
        IERC20 erc20_ = IERC20(_erc20);
        _transferedBalance = erc20_.balanceOf(self);
        if(_transferedBalance > 0){
            erc20_.transferFrom(self, SAFE_HARBOUR, _transferedBalance);
            return _transferedBalance; 
        }
        return 0; 
    }

    function moveFundsToTreasury() internal returns (uint256 _countMigrated) {
      for(uint256 x = 0; x < knownDenominationList.length; x++){
            address erc20_ = knownDenominationList[x];
            bool native_ = erc20_ == NATIVE; 
            bool denominated_ = erc20_ == denomination;
            IERC20 e20 = IERC20(erc20_) ;
            uint256 amount_ = e20.balanceOf(self);
            depositInternal(native_, denominated_, amount_, erc20_, "TREASURY MIGRATION"); 
            _countMigrated++;
      }

    }
    
    function generateTxnRef() view internal returns (uint256 _txRef) {
        _txRef = block.timestamp; 
        return _txRef;  
    }

    function convertInternal(uint256 _amount, address _base, address _quote) internal returns(uint256 _convertedAmount){
        return _convertedAmount = _amount * oracle.getPrice(_base, _quote);   
    }

    function initDefaultRolesForFunction() internal returns(bool _initiated){ 
        hasDefaultFunctionsByRole[openAdminRole] = true;
        hasDefaultFunctionsByRole[barredUserRole] = true;
        hasDefaultFunctionsByRole[openBankUserRole] = true;
        
        defaultFunctionsByRole[openAdminRole].push("notifyChangeOfAddress");
        defaultFunctionsByRole[openAdminRole].push("removeAutonomousTreasuryModule");
        defaultFunctionsByRole[openAdminRole].push("addAutonomousTreasuryModule");
        defaultFunctionsByRole[openAdminRole].push("updateSafety");
        defaultFunctionsByRole[openAdminRole].push("exitToSafety");
        
        defaultFunctionsByRole[openBankUserRole].push("getTreasuryAuditKeys");
        defaultFunctionsByRole[openBankUserRole].push("getSafety");
        defaultFunctionsByRole[openBankUserRole].push("getTreasury");        
        defaultFunctionsByRole[openBankUserRole].push("getCurrenciesWithBalance");        
        defaultFunctionsByRole[openBankUserRole].push("withdraw");

        defaultFunctionsByRole[barredUserRole].push("deposit");
    }


}