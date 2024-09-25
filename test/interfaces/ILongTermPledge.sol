// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ILongTermPledge {
    event CancleStakeToken( uint256 indexed _stakeIndex,address indexed _userAddr,address _nodeAddr,uint256 _time ) ;
    event OwnershipTransferred( address indexed previousOwner,address indexed newOwner ) ;
    event StakeToken( uint256 indexed _stakeIndex,address _userAddr,address _nodeAddr,uint256 _amount,uint256 _time,uint256 _lockTime,address _token ) ;
    event UpdateLockPeriod( uint256 time ) ;
    event UpdateStake( uint256 indexed _stakeIndex,uint256 _lockTime ) ;
    function cancleStake( uint256[] memory _indexs ) external   ;
    function getStakeList( address addr ) external view returns (uint256[] memory ) ;
    function getStakeLockTime( uint256 _index ) external view returns (uint256 ) ;
    function init( address _pledgeContract ) external   ;
    function isOwner(  ) external view returns (bool ) ;
    function lockPeriod(  ) external view returns (uint256 ) ;
    function migrateStake( address _sender,address _nodeAddr,bool _type ) external payable  ;
    function owner(  ) external view returns (address ) ;
    function pledgeContract(  ) external view returns (address ) ;
    function renounceOwnership(  ) external   ;
    function stake( address _nodeAddr,address _token,uint256 _amount,bool _type ) external payable  ;
    function stakeTokenMsg( uint256  ) external view returns (address userAddr, address nodeAddr, uint256 start, uint256 lockTime, uint256 end, uint256 tokenAmount, address tokenAddr) ;
    function stakeTokenNum(  ) external view returns (uint256 ) ;
    function switchStake( uint256 _index,bool _type ) external   ;
    function transferOwnership( address newOwner ) external   ;
    function updateLockPeriod( uint256 _lockPeriod ) external   ;
    function updateStake( uint256 _index,bool _type ) external   ;
}
