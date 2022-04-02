// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


interface IOpenBankSafety { 

     function getBalanceDescrepancies() view external returns (address[] memory _erc20Addresses, uint256 [] memory _expectedNonDenominatedBalance, uint256 [] memory _actualNonDenominatedBalance);

     function pumpDescrepanciesToSafety() external returns (address [] memory _erc20Address, uint256 [] memory _nonDenominatedDecrepantAmount);

     function exitToSafety() external returns (address [] memory _erc20Address, uint256 [] memory _exitedNonDenominatedBalances, address _safetyAddress);
     
}