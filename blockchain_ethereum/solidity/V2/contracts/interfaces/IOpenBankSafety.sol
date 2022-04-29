// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;


interface IOpenBankSafety { 

     function getSafety() view external returns (address _safeHarbour);

     function pumpDescrepanciesToSafety(uint256 _batchSize) external returns (address [] memory _erc20Address, uint256 [] memory _nonDenominatedDecrepantAmount);

     function exitToSafety(uint256 _batchSize) external returns (address [] memory _erc20Address, uint256 [] memory _exitedNonDenominatedBalances, address _safetyAddress);
     
}