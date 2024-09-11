// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {ConfInit} from "./ConfInit.sol";


contract ConfTest is ConfInit {



    function setUp() public {
        ConfInit.init();

    }

    function test_file(address dst) public {
        vm.assume(dst != address(0));
        conf.file(accountManageExecutor, dst);
        assertEq(conf.accountManageExecutor(), dst);
    }

    function test_file(uint256 data) public {
        vm.assume(data > 0);
        conf.file(N, data);
        assertEq(conf.N(), data);
    }

    function test_file(address act, bool flag) public {
        if(flag){
            conf.file(act, true);
            assertEq(conf.acts(act), true);
            conf.file(act, false);
            assertEq(conf.acts(act), false);
        }
    }

   function test_wards(address act) public {
        vm.assume(act != address(0));
        conf.rely(act);
        assertEq(conf.wards(act), 1);
        conf.deny(act);
        assertEq(conf.wards(act), 0);
   }

   function test_awardDetals(uint256 times) public {
        vm.assume(times >= 1713268800);
        vm.assume(times < 2038801600);
        vm.warp(times); 
        (uint256 miner, uint256 node, uint256 lp, uint256 staking) = conf.awardDetals();
        uint256 phase_1 = 1713268800;             
        uint256 phase_2 = phase_1 + 2 * 365 days;
        uint256 phase_3 = phase_2 + 2 * 365 days;
        uint256 phase_4 = phase_3 + 2 * 365 days;
        uint256 phase_5 = phase_4 + 2 * 365 days;
        if(times < phase_1 || times > phase_5 + 2*365 days){
            assertEq(miner, 0);
            assertEq(node, 0);
            assertEq(lp, 0);
            assertEq(staking, 0);
        }else if(times < phase_2){
            assertEq(miner, 27397_260270e12);
            assertEq(node, 5479_452055e12/10);
            assertEq(lp, 5479_452055e12 *4/10);
            assertEq(staking, 5479_452055e12/2);
        }else if(times < phase_3){
            assertEq(miner, 20547_945210e12);
            assertEq(node, 4794_520548e12/10);
            assertEq(lp, 4794_520548e12 *4/10);
            assertEq(staking, 4794_520548e12/2);
           
        }else if(times < phase_4){
            assertEq(miner, 13698_630140e12);
            assertEq(node, 4109_589041e12/10);
            assertEq(lp, 4109_589041e12 *4/10);
            assertEq(staking, 4109_589041e12/2);
           
        }else if(times < phase_5){
            assertEq(miner, 10273_972600e12);
            assertEq(node, 4109_589041e12/10);
            assertEq(lp, 4109_589041e12 *4/10);
            assertEq(staking, 4109_589041e12/2);
           
        }else{
            assertEq(miner, 6849_315068e12);
            assertEq(node, 4109_589041e12/10);
            assertEq(lp, 4109_589041e12 *4/10);
            assertEq(staking, 4109_589041e12/2);
           
        }
   }



}
