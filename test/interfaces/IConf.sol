// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IConf {
    function Award(  ) external view returns (address ) ;
    function Credit(  ) external view returns (address ) ;
    function Inference(  ) external view returns (address ) ;
    function N(  ) external view returns (uint256 ) ;
    function Price(  ) external view returns (address ) ;
    function Staking(  ) external view returns (address ) ;
    function Training(  ) external view returns (address ) ;
    function WNMT(  ) external view returns (address ) ;
    function accountManageExecutor(  ) external view returns (address ) ;
    function accountUsdExecutor(  ) external view returns (address ) ;
    function acts( address  ) external view returns (bool ) ;
    function awardDetals(  ) external view returns (uint256 miner, uint256 node, uint256 lp, uint256 staking) ;
    function deny( address guy ) external   ;
    function execDeductionExecutor(  ) external view returns (address ) ;
    function file( bytes32 what,uint256 data ) external   ;
    function file( address act,bool flag ) external   ;
    function file( bytes32 what,address dst ) external   ;
    function fmr_awd(  ) external view returns (uint256 ) ;
    function getAwradMSG(  ) external view returns (uint256 miner_award, uint256 node_award, uint256 liquidity_award, uint256 staking_award, uint256 staking_gini_, uint256 award_N, uint256 fmr_awd_, uint256 non_vc_awd_, uint256 vc_awd_) ;
    function initialize(  ) external   ;
    function non_vc_awd(  ) external view returns (uint256 ) ;
    function p_settlement(  ) external view returns (uint256 ) ;
    function priceServiceExecutor(  ) external view returns (address ) ;
    function rely( address guy ) external   ;
    function trainingTaskExecutor(  ) external view returns (address ) ;
    function v_settlement(  ) external view returns (uint256 ) ;
    function vc_awd(  ) external view returns (uint256 ) ;
    function wards( address  ) external view returns (uint256 ) ;
}
