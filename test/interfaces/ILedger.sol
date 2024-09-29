// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ILedgerInterface {
    event UpdateLedger( address userAddr,uint256 nonce,address token,uint256 amount,string txHash ) ;
    event UpdateLedgerFail( address userAddr,uint256 nonce,address token,uint256 amount,string txHash ) ;
    function conf(  ) external view returns (address ) ;
    function init( address _conf ) external   ;
    function queryVotes( address userAddr,uint256 nonce ) external view returns (bool , uint256 , address[] memory , address , uint256 , string memory , uint256 ) ;
    function updateLedger( address[] memory _userAddrs,uint256[] memory _nonces,address[] memory _tokenAddrs,uint256[] memory _amounts,string[] memory _txHashs ) external   ;
}
