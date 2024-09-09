// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IRewardPool {
    event Burn( uint256 indexed day,uint256 timestamp,address op,uint256 amt ) ;
    event Move( uint256 indexed day,uint256 timestamp,address op,uint256 amt ) ;
    event OwnershipTransferred( address indexed previousOwner,address indexed newOwner ) ;
    function BurnNonce(  ) external view returns (uint256 ) ;
    function CONTRACT_DOMAIN(  ) external view returns (bytes32 ) ;
    function DOMAIN_SEPARATOR(  ) external view returns (bytes32 ) ;
    function DailyMaxMove(  ) external view returns (uint256 ) ;
    function DailyMoved( uint256  ) external view returns (uint256 ) ;
    function MoveNonce(  ) external view returns (uint256 ) ;
    function Moveable(  ) external view returns (uint256 ) ;
    function Rewardcontract(  ) external view returns (address ) ;
    function SigNum(  ) external view returns (uint256 ) ;
    function burn( uint256 nonce,uint256 amt,uint256 expir,uint8[] memory vs,bytes32[] memory rs ) external   ;
    function conf(  ) external view returns (address ) ;
    function init( address _conf,address _reward,uint256 _dailymaxmove,uint256 _signum,uint256 _moveable ) external   ;
    function isOwner(  ) external view returns (bool ) ;
    function move( uint256 nonce,uint256 amt,uint256 expir,uint8[] memory vs,bytes32[] memory rs ) external   ;
    function owner(  ) external view returns (address ) ;
    function renounceOwnership(  ) external   ;
    function setDailyMaxMove( uint256 amt ) external   ;
    function setMoveable( uint256 amt ) external   ;
    function setSigNum( uint256 num ) external   ;
    function transferOwnership( address newOwner ) external   ;
}
