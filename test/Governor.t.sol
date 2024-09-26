// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Governor} from "../contracts/Governor.sol";
import {GovernorProxy} from "../contracts/proxy/Governor_proxy.sol";
import {IGovernor} from "./interfaces/IGovernor.sol";



contract GovernorTest is Test {
    IGovernor public governor;
    address public owner = 0x2cD77303737430D78F5a5FbCf8B8f8064d2a92a9;
    address public proposer = 0xA82d72F648037c075554882Bd4FBF0C80E950644;
    address public voter1 = 0xab3eE52D0C7d0f946ebc808d3F166938DC4a5F28;
    address public voter2 = 0x80A2bC738D283773519804F2F3Abc811E1A3FEf2;
    address public voter3 = 0xeACB50a28630a4C44a884158eE85cBc10d2B3F10;

    function setUp() public {
        vm.startPrank(owner);
        governor = IGovernor(address(new GovernorProxy(address(new Governor()))));
        governor.init(1e23, 1e24, 7 days);
        vm.stopPrank();
        deal(proposer, 1e25);
        deal(voter1, 1e25);
        deal(voter2, 1e25);
        deal(voter3, 1e25);
    }

    function testOwner() public {
        assertEq(governor.owner(), owner);
    }

    function testPropose() public {
        vm.prank(proposer);
        governor.propose{value: 1e23}("test propose");
        (address proposerAddr, uint256 launchTime, uint256 expire, uint256 status, uint256 forVotes, uint256 againstVotes, string memory proposalContent) = governor.proposalMsg(governor.proposalCount());
        assertEq(address(governor).balance, 1e23); 
        assertEq(proposerAddr, proposer); 
        assertEq(launchTime, block.timestamp); 
        assertEq(expire, block.timestamp + 7 days); 
        assertEq(proposalContent, "test propose"); 
    }

    function testVote() public {
        vm.prank(proposer);
        governor.propose{value: 1e23}("test propose");
        uint256 proposalCount =  governor.proposalCount();
        vm.warp(100);
        vm.prank(voter1);
        governor.vote{value: 5e23}(proposalCount, 0);
        vm.prank(voter3);
        governor.vote{value: 2e23}(proposalCount, 1);
        vm.prank(voter2);
        governor.vote{value: 6e23}(proposalCount, 0);
        (address proposerAddr, uint256 launchTime, uint256 expire, uint256 status, uint256 forVotes, uint256 againstVotes, string memory proposalContent) = governor.proposalMsg(proposalCount);
        
        assertEq(address(governor).balance, 1e23 + 5e23 + 6e23 + 2e23); 
        assertEq(proposerAddr, proposer); 
        assertEq(status, 1); 
        assertEq(forVotes, 1e23 + 5e23 + 6e23); 
        assertEq(againstVotes, 2e23); 
    }

    function testWithdrawStake() public {
        vm.prank(proposer);
        governor.propose{value: 1e23}("test propose");
        uint256 proposalCount =  governor.proposalCount();
        vm.warp(100);
        vm.prank(voter1);
        governor.vote{value: 5e23}(proposalCount, 0);
        vm.prank(voter3);
        governor.vote{value: 2e23}(proposalCount, 1);
        vm.prank(voter2);
        governor.vote{value: 6e23}(proposalCount, 0);
        (address proposerAddr, uint256 launchTime, uint256 expire, uint256 status, uint256 forVotes, uint256 againstVotes, string memory proposalContent) = governor.proposalMsg(proposalCount);
        vm.warp(block.timestamp + 7 days);

        uint256[] memory proposals = new uint256[](1);
        proposals[0] = 1;
        vm.prank(proposer);
        governor.withdrawStake(proposals);
        vm.prank(voter1);
        governor.withdrawStake(proposals);
        vm.prank(voter2);
        governor.withdrawStake(proposals);
        vm.prank(voter3);
        governor.withdrawStake(proposals);
        assertEq(address(governor).balance, 0); 
        assertEq(address(voter1).balance, 1e25); 
        assertEq(address(voter2).balance, 1e25); 
        assertEq(address(voter3).balance, 1e25); 
    }







}
