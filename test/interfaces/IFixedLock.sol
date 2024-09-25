// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IFixedLock {

    event ClaimReward( uint256 indexed id,address indexed owner,uint256 amt ) ;
    event Lock( uint256 indexed id,address indexed owner,uint256 amt ) ;
    event Unlock( uint256 indexed id,address indexed owner,uint256 amt ) ;
    function checkReward( uint256 id ) external view returns (uint256 ) ;
    function claimReward( uint256 id ) external   ;
    function endTime(  ) external view returns (uint256 ) ;
    function getLockInfos( address guy ) external view returns (LockInfo[] memory ) ;
    function getLocks( address guy ) external view returns (uint256[] memory ) ;
    function init( uint256 _endTime,uint256 _rewardPropotion,uint256 _rewardDelay ) external   ;
    function isReset(  ) external view returns (bool ) ;
    function lock( uint256 amt ) external payable returns (uint256 id) ;
    function lockId(  ) external view returns (uint256 ) ;
    function lockInfo( uint256  ) external view returns (address owner, uint256 locked, uint256 lockTime, uint256 unlocked, uint256 rewardsEarned) ;
    function owner(  ) external view returns (address ) ;
    function releaseDuration(  ) external view returns (uint256 ) ;
    function releaseEnd(  ) external view returns (uint256 ) ;
    function releaseStart(  ) external view returns (uint256 ) ;
    function released( uint256 id ) external view returns (uint256 ) ;
    function rewardDelay(  ) external view returns (uint256 ) ;
    function rewardPropotion(  ) external view returns (uint256 ) ;
    function startTime(  ) external view returns (uint256 ) ;
    function totalLocked(  ) external view returns (uint256 ) ;
    function unlock( uint256 id,uint256 amt ) external   ;
    struct LockInfo {
        address owner;
        uint256 locked;
        uint256 lockTime;
        uint256 unlocked;
        uint256 rewardsEarned;
    }
}

