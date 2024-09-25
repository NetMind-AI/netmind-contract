// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IPurchase {
    event OwnershipTransferred( address indexed previousOwner,address indexed newOwner ) ;
    event SwapToken( uint256 _usdcAmount,uint256 _nmtAmount,string _orderId ) ;
    function calculateAmountOutMin( uint256 amountIn ) external view returns (uint256 ) ;
    function crosschain(  ) external view returns (address ) ;
    function exector(  ) external view returns (address ) ;
    function init( address _router,address _usdc,address _nmtToken,address _exector,address _crosschain,string memory _receiver ) external   ;
    function isOwner(  ) external view returns (bool ) ;
    function nmtToken(  ) external view returns (address ) ;
    function orderId( string memory  ) external view returns (bool ) ;
    function owner(  ) external view returns (address ) ;
    function receiver(  ) external view returns (string memory ) ;
    function renounceOwnership(  ) external   ;
    function router(  ) external view returns (address ) ;
    function swapToken( uint256 _amount,uint256 _minOut,string memory _orderId ) external   ;
    function transferOwnership( address newOwner ) external   ;
    function updateExector( address _exector ) external   ;
    function updateReceiver( string memory _receiver ) external   ;
    function usdc(  ) external view returns (address ) ;
    function withdraw( address to ) external   ;
}

