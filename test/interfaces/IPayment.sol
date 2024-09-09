// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IPayment {
    event AgentPay( string id,string paycode,uint256 worth ) ;
    event Distribute( string id,address reciver,uint256 amount,uint256 burn ) ;
    event OwnershipTransferred( address indexed previousOwner,address indexed newOwner ) ;
    event Pay( string id,address payer,uint256 amount,uint256 worth ) ;
    event Refund( string id,address payer,uint256 amount ) ;
    function CONTRACT_DOMAIN(  ) external view returns (bytes32 ) ;
    function DOMAIN_SEPARATOR(  ) external view returns (bytes32 ) ;
    function SigNum(  ) external view returns (uint256 ) ;
    function agent(  ) external view returns (address ) ;
    function agentDistribute( string memory paymentId,address gpu_provider,uint256 gpu_fee,uint256 gpu_nmt,uint256 platform_fee,uint256 platform_nmt,uint256 expir,uint8[] memory vs,bytes32[] memory rs ) external   ;
    function agentPayment( string memory paymentId,string memory paycode,uint256 worth ) external   ;
    function agentRecipts( string memory  ) external view returns (string memory paycode, uint256 worth, uint256 timestamp, uint256 distributed) ;
    function burnProfit(  ) external view returns (bool ) ;
    function cleaner(  ) external view returns (address ) ;
    function conf(  ) external view returns (address ) ;
    function digestSta( bytes32  ) external view returns (bool ) ;
    function distribute( string memory paymentId,address gpu_provider,uint256 gpu_fee,uint256 platform_fee,uint256 expir,uint8[] memory vs,bytes32[] memory rs ) external   ;
    function feeTo(  ) external view returns (address ) ;
    function getWhiteList(  ) external view returns (address[] memory ) ;
    function init( address _conf,uint256 _signum ) external   ;
    function isOwner(  ) external view returns (bool ) ;
    function owner(  ) external view returns (address ) ;
    function payment( string memory paymentId,uint256 amt,uint256 worth ) external payable  ;
    function recipts( string memory  ) external view returns (address payer, uint256 amount, uint256 worth, uint256 refund, uint256 timestamp, uint256 distributed) ;
    function refund( string memory paymentId,uint256 amt,uint256 expir,uint8[] memory vs,bytes32[] memory rs ) external   ;
    function renounceOwnership(  ) external   ;
    function setAgent( address _agent ) external   ;
    function setCleaner( address _cleaner ) external   ;
    function setFeeTo( address _feeTo ) external   ;
    function setWhiteList( address[] memory uers ) external   ;
    function transferOwnership( address newOwner ) external   ;
}
