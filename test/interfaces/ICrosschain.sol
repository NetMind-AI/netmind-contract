// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ICrosschain {
    event AddNodeAddr( address[] nodeAddrs ) ;
    event DeleteNodeAddr( address[] nodeAddrs ) ;
    event OwnershipTransferred( address indexed previousOwner,address indexed newOwner ) ;
    event StakeToken( address indexed _tokenAddr,address indexed _userAddr,string receiveAddr,uint256 amount,uint256 fee,string chain ) ;
    event TransferToken( address indexed _tokenAddr,address _receiveAddr,uint256 _amount,string chain,string txid ) ;
    event UpdateChainCharge( string chain,bool sta,address[] tokens,uint256[] fees ) ;
    event UpdatePause( bool sta ) ;
    event UpdateThreshold( address tokenAddr,uint256 thresholdType,uint256 threshold ) ;
    event WithdrawChargeAmount( address tokenAddr,uint256 amount ) ;
    function CONTRACT_DOMAIN(  ) external view returns (bytes32 ) ;
    function DOMAIN_SEPARATOR(  ) external view returns (bytes32 ) ;
    function addBlacklist( address[] memory guys ) external   ;
    function addNodeAddr( address[] memory _nodeAddrs ) external   ;
    function blacker(  ) external view returns (address ) ;
    function blacklist( address  ) external view returns (bool ) ;
    function bridgeToken( address[2] memory addrs,uint256[2] memory uints,string[] memory strs,uint8[] memory vs,bytes32[] memory rssMetadata ) external   ;
    function chainSta( string memory  ) external view returns (bool ) ;
    function chargeRate( string memory ,address  ) external view returns (uint256 ) ;
    function close(  ) external   ;
    function deleteNodeAddr( address[] memory _nodeAddrs ) external   ;
    function exector(  ) external view returns (address ) ;
    function init( address _management,bool _sta ) external   ;
    function isOwner(  ) external view returns (bool ) ;
    function mainChainSta(  ) external view returns (bool ) ;
    function nodeAddrSta( address  ) external view returns (bool ) ;
    function nodeIndexAddr( uint256  ) external view returns (address ) ;
    function nodeNum(  ) external view returns (uint256 ) ;
    function owner(  ) external view returns (address ) ;
    function pause(  ) external view returns (bool ) ;
    function queryCharge( address[] memory addrs ) external view returns (address[] memory , uint256[] memory ) ;
    function queryLimit( address token ) external view returns (uint256 , uint256 , uint256 , uint256 , uint256 ) ;
    function queryNode(  ) external view returns (address[] memory ) ;
    function removeBlacklist( address[] memory guys ) external   ;
    function renounceOwnership(  ) external   ;
    function setBlacker( address guy ) external   ;
    function signNum(  ) external view returns (uint256 ) ;
    function stakeMsg( uint256  ) external view returns (address tokenAddr, address userAddr, string memory receiveAddr, uint256 amount, uint256 fee, string memory chain) ;
    function stakeNum(  ) external view returns (uint256 ) ;
    function stakeThreshold( address  ) external view returns (uint256 ) ;
    function stakeToken( string memory _chain,string memory receiveAddr,address tokenAddr,uint256 _amount ) external payable  ;
    function stakingDailyUsage( address ,uint256  ) external view returns (uint256 ) ;
    function tokenSta( address  ) external view returns (uint256 ) ;
    function trader(  ) external view returns (address ) ;
    function transferDailyUsage( address ,uint256  ) external view returns (uint256 ) ;
    function transferOwnership( address newOwner ) external   ;
    function transferThreshold( address  ) external view returns (uint256 ) ;
    function updateChainCharge( string memory _chain,bool _sta,address[] memory _tokens,uint256[] memory _fees,uint256[] memory _stas ) external   ;
    function updateExector( address _exector ) external   ;
    function updatePause( bool _sta ) external   ;
    function updateSignNum( uint256 _signNum ) external   ;
    function updateThreshold( address[] memory _tokens,uint256[] memory _thresholdTypes,uint256[] memory _thresholds ) external   ;
    function updateTrader( address _trader ) external   ;
    function withdrawChargeAmount( address[] memory tokenAddrs,address receiveAddr ) external   ;
}
