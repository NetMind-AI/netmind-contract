// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IRewardContract {
    event OwnershipTransferred( address indexed previousOwner,address indexed newOwner ) ;
    event WithdrawToken( address indexed _userAddr,address _tokenAddr,uint256 _nonce,uint256 _amount ) ;
    function CONTRACT_DOMAIN(  ) external view returns (bytes32 ) ;
    function DOMAIN_SEPARATOR(  ) external view returns (bytes32 ) ;
    function addBlacklist( address guy ) external   ;
    function blacker(  ) external view returns (address ) ;
    function blacklist( address  ) external view returns (bool ) ;
    function close(  ) external   ;
    function conf(  ) external view returns (address ) ;
    function exector(  ) external view returns (address ) ;
    function init( address _conf ) external   ;
    function isOwner(  ) external view returns (bool ) ;
    function nonce( address  ) external view returns (uint256 ) ;
    function owner(  ) external view returns (address ) ;
    function pause(  ) external view returns (bool ) ;
    function removeBlacklist( address guy ) external   ;
    function renounceOwnership(  ) external   ;
    function setBlacker( address guy ) external   ;
    function signNum(  ) external view returns (uint256 ) ;
    function threshold(  ) external view returns (uint256 ) ;
    function transferOwnership( address newOwner ) external   ;
    function updateExector( address _exector ) external   ;
    function updatePause( bool _sta ) external   ;
    function updateSignNum( uint256 _signNum ) external   ;
    function updateThreshold( uint256 _threshold ) external   ;
    function withdrawData( address ,uint256  ) external view returns (address tokenAddr, uint256 amount) ;
    function withdrawLimit( uint256  ) external view returns (uint256 ) ;
    function withdrawToken( address[2] memory addrs,uint256[2] memory uints,uint8[] memory vs,bytes32[] memory rssMetadata ) external   ;
}


