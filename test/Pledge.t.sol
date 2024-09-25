// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Pledge} from "../contracts/Pledge.sol";
import {PledgeProxy} from "../contracts/proxy/Pledge_proxy.sol";
import {IPledge} from "./interfaces/IPledge.sol";
import {LongTermPledge} from "../contracts/LongTermPledge.sol";
import {LongTermPledgeProxy} from "../contracts/proxy/LongTermPledge_proxy.sol";
import {ILongTermPledge} from "./interfaces/ILongTermPledge.sol";


contract PledgeTest is Test {
    IPledge public pledge;
    ILongTermPledge public longTermPledge;
    address public owner = 0x2cD77303737430D78F5a5FbCf8B8f8064d2a92a9;
    

    function setUp() public {
        vm.startPrank(owner);
        pledge = IPledge(address(new PledgeProxy(address(new Pledge()))));
        pledge.init();
        longTermPledge = ILongTermPledge(address(new LongTermPledgeProxy(address(new LongTermPledge()))));
        longTermPledge.init(address(pledge));
        vm.stopPrank();
    }

    function testOwner() public {
        assertEq(pledge.owner(), owner);
    }

    function testNodeAddr() public {
        address[] memory _addrs = new address[](3);
        _addrs[0] = address(1);_addrs[1] = address(2);_addrs[2] = address(3);
        vm.assertFalse(pledge.nodeAddrSta(_addrs[0]));
        vm.assertFalse(pledge.nodeAddrSta(_addrs[1]));
        vm.assertFalse(pledge.nodeAddrSta(_addrs[2]));
        vm.prank(owner);
        pledge.addNodeAddr(_addrs);
        vm.assertTrue(pledge.nodeAddrSta(_addrs[0]));
        vm.assertTrue(pledge.nodeAddrSta(_addrs[1]));
        vm.assertTrue(pledge.nodeAddrSta(_addrs[2]));
        vm.assertEq(pledge.nodeNum(), _addrs.length);
        vm.prank(owner);
        pledge.deleteNodeAddr(_addrs);
        vm.assertFalse(pledge.nodeAddrSta(_addrs[0]));
        vm.assertFalse(pledge.nodeAddrSta(_addrs[1]));
        vm.assertFalse(pledge.nodeAddrSta(_addrs[2]));
        vm.assertEq(pledge.nodeNum(), 0);
    }

    function addrNodeAddr() public {
        address[] memory _addrs = new address[](3);
        _addrs[0] = address(1);_addrs[1] = address(2);_addrs[2] = address(3);
        vm.prank(owner);
        pledge.addNodeAddr(_addrs);
    }

    function testUpdateMapping() public {
        address[] memory _addrs = new address[](2);
        _addrs[0] = address(1);_addrs[1] = address(2);
        address[] memory _newAddrs = new address[](2);
        _newAddrs[0] = address(11);_newAddrs[1] = address(12); 
        address[] memory _walAddrs = new address[](2);
        _walAddrs[0] = address(21);_walAddrs[1] = address(22); 
        addrNodeAddr();
        vm.assertEq(pledge.getNodeWalById(address(1)), address(1));
        vm.assertEq(pledge.getNodeAddrById(address(1)), address(1));
        vm.assertEq(pledge.getNodeWalById(address(2)), address(2));
        vm.assertEq(pledge.getNodeAddrById(address(2)), address(2));
        vm.prank(owner);
        pledge.updateMapping(_addrs, _newAddrs, _walAddrs);
        vm.assertEq(pledge.getNodeAddrById(address(1)), address(11));
        vm.assertEq(pledge.getNodeWalById(address(1)), address(21));
        vm.assertEq(pledge.getNodeAddrById(address(2)), address(12));
        vm.assertEq(pledge.getNodeWalById(address(2)), address(22));
    }

    function stake(address user) public {
        addrNodeAddr();
        deal(user, 100 ether);
        vm.prank(owner);
        pledge.updateTokenSta(address(0), true);
        vm.prank(user);
        pledge.stake{value: 10 ether}(address(1), address(0), 10 ether);
    }

    function testStake() public {
        address user = 0xA82d72F648037c075554882Bd4FBF0C80E950644;
        stake(user);
        (address userAddr, address nodeAddr, uint256 start, uint256 end, uint256 tokenAmount, address tokenAddr) = pledge.stakeTokenMsg(pledge.stakeTokenNum());
        vm.assertEq(userAddr, user);
        vm.assertEq(nodeAddr, address(1));
        vm.assertEq(tokenAmount, 10 ether);
        vm.assertEq(tokenAddr, address(0));
    }

    function testCancleStake() public {
        address user = 0xA82d72F648037c075554882Bd4FBF0C80E950644;
        stake(user);
        (address userAddr, address nodeAddr, uint256 start,  , uint256 tokenAmount, address tokenAddr) = pledge.stakeTokenMsg(pledge.stakeTokenNum());
        vm.assertEq(userAddr, user);
        vm.assertEq(nodeAddr, address(1));
        vm.assertEq(tokenAmount, 10 ether);
        vm.assertEq(tokenAddr, address(0));
        vm.assertEq(address(pledge).balance, 10 ether);
        vm.warp(10000);
        uint256[] memory indexs = new uint256[](1);
        indexs[0] = 1;
        vm.prank(user);
        pledge.cancleStake(indexs);
        vm.assertEq(address(pledge).balance, 0);
        vm.assertEq(address(user).balance, 100 ether);
        ( ,  ,  , uint256 end,  ,  ) = pledge.stakeTokenMsg(pledge.stakeTokenNum());
        vm.assertEq(end, 10000);
    }

    function testMigrateStake() public {
        address user = 0xA82d72F648037c075554882Bd4FBF0C80E950644;
        stake(user);
        vm.startPrank(owner);
        pledge.updateLongTermPledge(address(longTermPledge));
        pledge.updateGuarder(address(longTermPledge));
        vm.stopPrank();
        vm.warp(10000);

        uint256[] memory indexs = new uint256[](1);
        indexs[0] = 1;
        vm.prank(user);
        pledge.migrateStake(indexs, true);
        vm.assertEq(address(pledge).balance, 0);
        vm.assertEq(address(longTermPledge).balance, 10 ether);
        ( ,  ,  , uint256 end,  ,  ) = pledge.stakeTokenMsg(pledge.stakeTokenNum());
        vm.assertEq(end, 10000);
        (address userAddr, address nodeAddr, uint256 start, uint256 lockTime, , uint256 tokenAmount, address tokenAddr) = longTermPledge.stakeTokenMsg(1);
        vm.assertEq(userAddr, user);
        vm.assertEq(nodeAddr, address(1));
        vm.assertEq(tokenAmount, 10 ether);
        vm.assertEq(tokenAddr, address(0));
        vm.assertEq(start, 10000);
        vm.assertEq(address(longTermPledge).balance, 10 ether);
    }

    function testUpadeNodesStake() public {
        address user = 0xA82d72F648037c075554882Bd4FBF0C80E950644;
        stake(user);
        vm.prank(owner);
        pledge.updateGuarder(address(90));
        address[] memory _addrs = new address[](3);
        _addrs[0] = address(1);_addrs[1] = address(2);_addrs[2] = address(3);
        uint256[] memory indexs = new uint256[](3);
        indexs[0] = 1e20; indexs[1] = 2e20;indexs[2] = 3e20;
        vm.prank(address(90));
        pledge.upadeNodesStake(_addrs, indexs, block.timestamp + 100 , "test");
        vm.assertEq(pledge.nodeChainAmount("test", address(1)), 1e20);
        vm.assertEq(pledge.nodeChainAmount("test", address(2)), 2e20);
        vm.assertEq(pledge.nodeChainAmount("test", address(3)), 3e20);
        vm.prank(address(90));
        pledge.deleteChain( "test");
        vm.assertEq(pledge.nodeChainAmount("test", address(1)), 0);
        vm.assertEq(pledge.nodeChainAmount("test", address(2)), 0);
        vm.assertEq(pledge.nodeChainAmount("test", address(3)), 0);
    }






}
