// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ITrainingTask {
    event EndJob( string userId,string jobId,uint256 usageAmount,uint256 surplusAmount,uint256 state,uint256 jobType ) ;
    event ExecJob( string userId,string jobId,uint256 freezeAmount,uint256 state,uint256 jobType ) ;
    event ExecJobDebit( string userId,string jobId,uint256 freezeAmount,uint256 usageAmount,uint256 jobType,string orderId ) ;
    event OwnershipTransferred( address indexed previousOwner,address indexed newOwner ) ;
    event UpdateJob( string userId,string jobId,uint256 freezeAmount,uint256 state,uint256 jobType,string orderId ) ;
    function accountManage(  ) external view returns (address ) ;
    function conf(  ) external view returns (address ) ;
    function endJob( string memory userId,string memory jobId,uint256 usageAmount,uint256 state ) external   ;
    function execJob( string memory userId,string memory jobId,uint256 freezeAmount,uint256 jobType ) external   ;
    function execJobDebit( string memory userId,string memory jobId,uint256 usageAmount,string memory orderId ) external   ;
    function execOrderIdSta( string memory  ) external view returns (bool ) ;
    function init( address _conf,address _accountManage ) external   ;
    function isOwner(  ) external view returns (bool ) ;
    function jobMsg( uint256  ) external view returns (string memory userId, uint256 freezeAmount, uint256 usageAmount, uint256 surplusAmount, uint256 state, uint256 jobType) ;
    function num(  ) external view returns (uint256 ) ;
    function owner(  ) external view returns (address ) ;
    function queryJobMsg( string memory jobId ) external view returns (uint256 , uint256 , uint256 , uint256 , uint256 ) ;
    function renounceOwnership(  ) external   ;
    function transferOwnership( address newOwner ) external   ;
    function upateOrderIdSta( string memory  ) external view returns (bool ) ;
    function updateJob( string memory userId,string memory jobId,uint256 freezeAmount,string memory orderId ) external   ;
    function userJobMsg( string memory  ) external view returns (uint256 ) ;
}


