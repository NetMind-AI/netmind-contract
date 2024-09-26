// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {CommunityFund} from "../contracts/CommunityFund.sol";
import {CommunityFundProxy} from "../contracts/proxy/CommunityFund_proxy.sol";
import {ICommunityFund} from "./interfaces/ICommunityFund.sol";

contract CommunityFundTest is Test {
    ICommunityFund public communityFund;

    address public owner = address(1);
    address public node1 = address(2);
    address public node2 = address(3);
    address public node3 = address(4);
    address public node4 = address(5);

          
    address public nonNode = address(6);
    address[] public initialNodes;

    function setUp() public {
        initialNodes = [node1, node2, node3, node4];

        vm.startPrank(owner);  // Simulate the behavior of the owner

        communityFund = ICommunityFund(address(new CommunityFundProxy(address(new CommunityFund()))));
        communityFund.init(initialNodes, block.timestamp);

        vm.stopPrank();
    }

    // 1. Test contract initialization
    function testInitialization() view public {
        assertEq(communityFund.owner(), owner, "Owner should be correct");
        assertEq(communityFund.nodeNum(), 4, "Initial node count should be correct");
        assertTrue(communityFund.nodeAddrSta(node1), "Node 1 should be initialized");
        assertTrue(communityFund.nodeAddrSta(node2), "Node 2 should be initialized");
        assertTrue(communityFund.nodeAddrSta(node3), "Node 3 should be initialized");
        assertTrue(communityFund.nodeAddrSta(node4), "Node 4 should be initialized");
    }

    // 2. Test adding a node
    function testAddNode() public {
        address[] memory newNodes = new address[](1);

        newNodes[0] = address(7);

        vm.prank(owner);
        communityFund.addNodeAddr(newNodes);

        assertEq(communityFund.nodeNum(), 5, "Node count should be 5 after adding a node");
        assertTrue(communityFund.nodeAddrSta(address(7)), "New node should be added");
    }

    // 3. Test removing a node
    function testDeleteNode() public {
        vm.prank(owner);
        address[] memory deleNodes = new address[](1);
        deleNodes[0] = node1;
        communityFund.deleteNodeAddr(deleNodes);

        assertEq(communityFund.nodeNum(), 3, "Node count should be 3 after deleting a node");
        assertFalse(communityFund.nodeAddrSta(node1), "Node 1 should be deleted");
    }

    // 4. Test proposing
    function testPropose() public {
        vm.warp(block.timestamp + 10000000000); 
        uint256 amount = 1 ether;
        assertLe(amount, communityFund.calcRelease(block.timestamp), "No more relaxed amount");

        vm.prank(node1);
        communityFund.propose(node2, amount, "Test Proposal");

        (address proposer, string memory content, address targetAddr,,,) = communityFund.proposalMsg(1);
        assertEq(proposer, node1, "Proposer should be node1");
        assertEq(content, "Test Proposal", "Proposal content should be correct");
        assertEq(targetAddr, node2, "Target address should be node2");
    }

    // 5. Test voting and executing proposal
    function testVote() public {
        vm.warp(block.timestamp + 100000000000); 
        uint256 amount = 1 ether;
        assertLe(amount, communityFund.calcRelease(block.timestamp), "No more relaxed amount");

        vm.deal(address(communityFund), 10 ether);
        vm.prank(node1);
        communityFund.propose(node2, amount, "Test Proposal");
        
        vm.prank(node2);
        communityFund.vote(1);

        vm.prank(node3);
        communityFund.vote(1);

        (, , , , bool proposalSta,) = communityFund.proposalMsg(1);
        assertTrue(proposalSta, "Proposal should be executed after voting");
    }

    // 6. Test preventing double voting
    function testCannotVoteTwice() public {
        vm.warp(block.timestamp + 100000000000); 
        uint256 amount = 1 ether;
        assertLe(amount, communityFund.calcRelease(block.timestamp), "No more relaxed amount");

        vm.deal(address(communityFund), 10 ether);
        vm.prank(node1);
        communityFund.propose(node2, 1 ether, "Test Proposal");

        vm.prank(node2);
        communityFund.vote(1);

        vm.expectRevert("The proposer has already voted");
        vm.prank(node2);
        communityFund.vote(1);
    }

    // 7. Test proposal expiration
    function testCannotVoteAfterExpiration() public {
        vm.warp(block.timestamp + 100000000000); 
        uint256 amount = 1 ether;
        assertLe(amount, communityFund.calcRelease(block.timestamp), "No more relaxed amount");

        vm.prank(node1);
        communityFund.propose(node2, 1 ether, "Test Proposal");

        // Simulate the passage of time to exceed the voting period
        vm.warp(block.timestamp + 3 days);  // The voting period is 2 days, exceed it

        vm.expectRevert("The vote on the proposal has expired");
        vm.prank(node2);
        communityFund.vote(1);
    }

    // 8. Test non-node cannot propose
    function testNonNodeCannotPropose() public {
        vm.warp(block.timestamp + 100000000000); 
        uint256 amount = 1 ether;
        assertLe(amount, communityFund.calcRelease(block.timestamp), "No more relaxed amount");

        vm.expectRevert("The caller is not the nodeAddr");
        vm.prank(nonNode);
        communityFund.propose(node2, 1 ether, "Non-node Proposal");
    }

    // 9. Test non-node cannot vote
    function testNonNodeCannotVote() public {
        vm.warp(block.timestamp + 100000000000); 
        uint256 amount = 1 ether;
        assertLe(amount, communityFund.calcRelease(block.timestamp), "No more relaxed amount");

        vm.prank(node1);
        communityFund.propose(node2, 1 ether, "Test Proposal");

        vm.expectRevert("The caller is not the nodeAddr");
        vm.prank(nonNode);
        communityFund.vote(1);
    }

    // 10. Test updating the voting period
    function testUpdateVotingPeriod() public {
        vm.prank(owner);
        communityFund.updateVotingPeriod(10 days);

        assertEq(communityFund.votingPeriod(), 10 days, "Voting period should be updated");
    }

    // 11. Test token withdrawal
    function testWithdrawToken() public {
        // Ensure the contract has a balance
        deal(address(communityFund), 1650 * 1e22 + 1 ether);
        assertEq(communityFund.withdraw(), 0, "withdrew should be 0");

        //deal(owner, 1 ether);
        vm.prank(owner);
        communityFund.withdrawToken(address(0x8A239732871AdC8829EA2f47e94087C5FBad47b6));

        assertEq(address(0x8A239732871AdC8829EA2f47e94087C5FBad47b6).balance, 1 ether, "Owner should withdraw correct amount");
        assertEq(address(communityFund).balance, 1650 * 1e22, "CommunityFund need be 1650*1e22");
    }
}