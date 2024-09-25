// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ILiquidityFundsManage {
    event OwnershipTransferred( address indexed previousOwner,address indexed newOwner ) ;
    function DexRouter(  ) external view returns (address ) ;
    function Expire(  ) external view returns (uint256 ) ;
    function GetProposalMSG( uint256 id ) external view returns (ProposalMsg memory , string memory ) ;
    function NMT(  ) external view returns (address ) ;
    function Pair(  ) external view returns (address ) ;
    function Tolerance(  ) external view returns (uint256 ) ;
    function USDC(  ) external view returns (address ) ;
    function USDC_Price(  ) external view returns (uint256 ) ;
    function addLiquidity_P( uint256 usdc ) external  returns (uint256 ) ;
    function addManager( address user ) external   ;
    function buy_P( uint256 usdc,uint256 slippage ) external  returns (uint256 ) ;
    function calculateAmountMin( uint256 desired ) external view returns (uint256 ) ;
    function calculateAmountOutMin( address tokenIn,address tokenOut,uint256 amountIn,uint256 slippage ) external view returns (uint256 ) ;
    function calculateDesired( uint256 fixedValueUSDC ) external view returns (uint256 ) ;
    function getCurrentPrice(  ) external view returns (uint256 ) ;
    function init( address _nmt,address _usdc,address _router,address _pair,uint256 _usdc_decamals ) external   ;
    function isOwner(  ) external view returns (bool ) ;
    function managersList(  ) external view returns (address[] memory ) ;
    function owner(  ) external view returns (address ) ;
    function pid(  ) external view returns (uint256 ) ;
    function removeLiquidity_P( uint256 liquidityPropotion ) external  returns (uint256 ) ;
    function removeManager( address user ) external   ;
    function renounceOwnership(  ) external   ;
    function sell_P( uint256 nmt,uint256 slippage ) external  returns (uint256 ) ;
    function setExpire( uint256 t ) external   ;
    function setTolerance( uint256 t ) external   ;
    function threshold(  ) external view returns (uint256 ) ;
    function transferOwnership( address newOwner ) external   ;
    function transfer_P( address to,uint256 usdc,uint256 nmt ) external  returns (uint256 ) ;
    function vote( uint256 id ) external   ;
    function voteRecord( uint256 ,address  ) external view returns (bool ) ;
    struct ProposalMsg {
        address proposer;
        address receiver;
        bool isPass;
        uint8 opType;
        uint256 expire;
        uint256 usdc;
        uint256 nmt;
        uint256 liquidity;
        address[] assentors;
    }
    enum OP_TYPE{
            BUY,
            SELL,
            ADDLIQUIDITY,
            REMOVELIQUIDITY,
            TRANSFER
    }
}


