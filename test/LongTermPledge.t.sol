// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Pledge} from "../contracts/Pledge.sol";
import {PledgeProxy} from "../contracts/proxy/Pledge_proxy.sol";
import {IPledge} from "./interfaces/IPledge.sol";
import {LongTermPledge} from "../contracts/LongTermPledge.sol";
import {LongTermPledgeProxy} from "../contracts/proxy/LongTermPledge_proxy.sol";
import {ILongTermPledge} from "./interfaces/ILongTermPledge.sol";



contract LongTermPledgeTest is Test {
    IPledge public pledge;
    ILongTermPledge public longTermPledge;
    address public owner = 0x2cD77303737430D78F5a5FbCf8B8f8064d2a92a9;
    

    function setUp() public {
        vm.startPrank(owner);
        pledge = IPledge(address(new PledgeProxy(address(new Pledge()))));
        pledge.init();
        longTermPledge = ILongTermPledge(address(new LongTermPledgeProxy(address(new LongTermPledge()))));
        longTermPledge.init(address(pledge));
        address[] memory _addrs = new address[](3);
        _addrs[0] = address(1);_addrs[1] = address(2);_addrs[2] = address(3);
        pledge.addNodeAddr(_addrs);
        pledge.updateGuarder(address(longTermPledge));
        vm.stopPrank();
    }

    function testOwner() public {
        assertEq(longTermPledge.owner(), owner);
    }

    function stake(address user, bool _type) public {
        deal(user, 100 ether);
        vm.prank(user);
        longTermPledge.stake{value: 10 ether}(address(1), address(0), 10 ether, _type);
    }

    function testStake() public {
        address user = 0xA82d72F648037c075554882Bd4FBF0C80E950644;
        stake(user, true);
        (address userAddr, address nodeAddr, uint256 start, uint256 lockTime, uint256 end, uint256 tokenAmount, address tokenAddr) = longTermPledge.stakeTokenMsg(longTermPledge.stakeTokenNum());
        vm.assertEq(userAddr, user);
        vm.assertEq(nodeAddr, address(1));
        vm.assertEq(end, 0);
        vm.assertEq(tokenAmount, 10 ether);
        vm.assertEq(tokenAddr, address(0));
    }

    function testMigrateStake() public {
        address user = 0xA82d72F648037c075554882Bd4FBF0C80E950644;
        deal(address(pledge), 100 ether);
        vm.prank(address(pledge));
        longTermPledge.migrateStake{value: 10 ether}(user, address(1), true);
        (address userAddr, address nodeAddr, uint256 start, uint256 lockTime, uint256 end, uint256 tokenAmount, address tokenAddr) = longTermPledge.stakeTokenMsg(longTermPledge.stakeTokenNum());
        vm.assertEq(userAddr, user);
        vm.assertEq(nodeAddr, address(1));
        vm.assertEq(end, 0);
        vm.assertEq(tokenAmount, 10 ether);
        vm.assertEq(tokenAddr, address(0));
        vm.assertEq(address(longTermPledge).balance, 10 ether);
    }

    function testCancleStake() public {
        address user = 0xA82d72F648037c075554882Bd4FBF0C80E950644;
        stake(user, false);
        (address userAddr, address nodeAddr, uint256 start, uint256 lockTime, uint256 end, uint256 tokenAmount, address tokenAddr) = longTermPledge.stakeTokenMsg(longTermPledge.stakeTokenNum());
        vm.assertEq(userAddr, user);
        vm.assertEq(nodeAddr, address(1));
        vm.assertEq(end, 0);
        vm.assertEq(tokenAmount, 10 ether);
        vm.assertEq(tokenAddr, address(0));
        vm.warp(block.timestamp + 183 days);
        uint256[] memory indexs = new uint256[](1);
        indexs[0] = 1;
        vm.prank(user);
        longTermPledge.cancleStake(indexs);
        vm.assertEq(address(longTermPledge).balance, 0);
        vm.assertEq(address(user).balance, 100 ether);
        ( ,  , , , uint256 end2,  ,  ) = longTermPledge.stakeTokenMsg(longTermPledge.stakeTokenNum());
        vm.assertEq(end2, block.timestamp);
    }

    function testSwitchStake() public {
        vm.warp(170000000);
        address user = 0xA82d72F648037c075554882Bd4FBF0C80E950644;
        stake(user, true);
        uint num = longTermPledge.stakeTokenNum();
        (address userAddr, address nodeAddr, uint256 start, uint256 lockTime, uint256 end, uint256 tokenAmount, address tokenAddr) = longTermPledge.stakeTokenMsg(num);
        vm.assertEq(userAddr, user);
        vm.assertEq(nodeAddr, address(1));
        vm.assertEq(lockTime, 0);
        vm.assertEq(tokenAmount, 10 ether);
        vm.assertEq(tokenAddr, address(0));
        vm.prank(user);
        longTermPledge.switchStake(num, false);
        ( ,  ,  ,   uint256 lockTime2, ,  ,  ) = longTermPledge.stakeTokenMsg(num);
        vm.assertEq(lockTime2, block.timestamp +182 days);
        vm.prank(user);
        longTermPledge.switchStake(num, true);
        ( ,  ,  , uint256 lockTime3, ,  ,  ) = longTermPledge.stakeTokenMsg(num);
        vm.assertEq(lockTime3, 0);
    }

    function testUpdateStake(bool yp) public {
        vm.warp(170000000);
        address user = 0xA82d72F648037c075554882Bd4FBF0C80E950644;
        stake(user, false);
        uint num = longTermPledge.stakeTokenNum();
        (address userAddr, address nodeAddr, uint256 start, uint256 lockTime, uint256 end, uint256 tokenAmount, address tokenAddr) = longTermPledge.stakeTokenMsg(num);
        vm.assertEq(userAddr, user);
        vm.assertEq(nodeAddr, address(1));
        vm.assertEq(lockTime, block.timestamp +182 days);
        vm.assertEq(tokenAmount, 10 ether);
        vm.assertEq(tokenAddr, address(0));
        vm.warp(block.timestamp + 183 days);
        vm.prank(user);
        longTermPledge.updateStake(num, yp);
        ( ,  ,  ,   uint256 lockTime2, ,  ,  ) = longTermPledge.stakeTokenMsg(num);
        if(yp){
            vm.assertEq(lockTime2, 0);
        }else{
            vm.assertEq(lockTime2, block.timestamp +182 days);
        }
        
    }








}
