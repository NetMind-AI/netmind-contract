// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IFiatoSettle {
    event Distribute( address receiver,uint256 amount,uint256 burn ) ;
    event OwnershipTransferred( address indexed previousOwner,address indexed newOwner ) ;
    function accountManage(  ) external view returns (address ) ;
    function burnAddr(  ) external view returns (address ) ;
    function distribute( address receiver,uint256 amount,uint256 burn ) external  returns (bool ) ;
    function init( address _payment ) external   ;
    function isOwner(  ) external view returns (bool ) ;
    function owner(  ) external view returns (address ) ;
    function payment(  ) external view returns (address ) ;
    function renounceOwnership(  ) external   ;
    function setAccountManage( address _accountManage ) external   ;
    function setBurnAddr( address _burnAddr ) external   ;
    function transferOwnership( address newOwner ) external   ;
}
