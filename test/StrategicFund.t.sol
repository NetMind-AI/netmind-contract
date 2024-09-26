// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {StrategicFund} from "../contracts/StrategicFund.sol";
import {StrategicFundProxy} from "../contracts/proxy/StrategicFund_proxy.sol";
import {IStrategicFund} from "./interfaces/IStrategicFund.sol";

contract StrategicFundTest is Test {
    IStrategicFund public strategicFund;

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

        strategicFund = IStrategicFund(address(new StrategicFundProxy(address(new StrategicFund()))));
        strategicFund.init(initialNodes, block.timestamp);

        vm.stopPrank();
    }

    // 1. Test contract initialization
    function testInitialization() view public {
        assertEq(strategicFund.owner(), owner, "Owner should be correct");
        assertEq(strategicFund.nodeNum(), 4, "Initial node count should be correct");
        assertTrue(strategicFund.nodeAddrSta(node1), "Node 1 should be initialized");
        assertTrue(strategicFund.nodeAddrSta(node2), "Node 2 should be initialized");
        assertTrue(strategicFund.nodeAddrSta(node3), "Node 3 should be initialized");
        assertTrue(strategicFund.nodeAddrSta(node4), "Node 4 should be initialized");
    }

    // 2. Test adding a node
    function testAddNode() public {
        address[] memory newNodes = new address[](1);

        newNodes[0] = address(7);

        vm.prank(owner);
        strategicFund.addNodeAddr(newNodes);

        assertEq(strategicFund.nodeNum(), 5, "Node count should be 5 after adding a node");
        assertTrue(strategicFund.nodeAddrSta(address(7)), "New node should be added");
    }

    // 3. Test removing a node
    function testDeleteNode() public {
        vm.prank(owner);
        address[] memory deleNodes = new address[](1);
        deleNodes[0] = node1;
        strategicFund.deleteNodeAddr(deleNodes);

        assertEq(strategicFund.nodeNum(), 3, "Node count should be 3 after deleting a node");
        assertFalse(strategicFund.nodeAddrSta(node1), "Node 1 should be deleted");
    }

    // 4. Test proposing
    function testPropose() public {
        vm.warp(block.timestamp + 10000000000); 
        uint256 amount = 1 ether;
        assertLe(amount, strategicFund.calcRelease(block.timestamp), "No more relaxed amount");

        vm.prank(node1);
        strategicFund.propose(node2, amount, "Test Proposal");

        (address proposer, string memory content, address targetAddr,,,) = strategicFund.proposalMsg(1);
        assertEq(proposer, node1, "Proposer should be node1");
        assertEq(content, "Test Proposal", "Proposal content should be correct");
        assertEq(targetAddr, node2, "Target address should be node2");
    }

    // 5. Test voting and executing proposal
    function testVote() public {
        vm.warp(block.timestamp + 100000000000); 
        uint256 amount = 1 ether;
        assertLe(amount, strategicFund.calcRelease(block.timestamp), "No more relaxed amount");

        vm.deal(address(strategicFund), 10 ether);
        vm.prank(node1);
        strategicFund.propose(node2, amount, "Test Proposal");
        
        vm.prank(node2);
        strategicFund.vote(1);

        vm.prank(node3);
        strategicFund.vote(1);

        (, , , , bool proposalSta,) = strategicFund.proposalMsg(1);
        assertTrue(proposalSta, "Proposal should be executed after voting");
    }

    // 6. Test preventing double voting
    function testCannotVoteTwice() public {
        vm.warp(block.timestamp + 100000000000); 
        uint256 amount = 1 ether;
        assertLe(amount, strategicFund.calcRelease(block.timestamp), "No more relaxed amount");

        vm.deal(address(strategicFund), 10 ether);
        vm.prank(node1);
        strategicFund.propose(node2, 1 ether, "Test Proposal");

        vm.prank(node2);
        strategicFund.vote(1);

        vm.expectRevert("The proposer has already voted");
        vm.prank(node2);
        strategicFund.vote(1);
    }

    // 7. Test proposal expiration
    function testCannotVoteAfterExpiration() public {
        vm.warp(block.timestamp + 100000000000); 
        uint256 amount = 1 ether;
        assertLe(amount, strategicFund.calcRelease(block.timestamp), "No more relaxed amount");

        vm.prank(node1);
        strategicFund.propose(node2, 1 ether, "Test Proposal");

        // Simulate the passage of time to exceed the voting period
        vm.warp(block.timestamp + 3 days);  // The voting period is 2 days, exceed it

        vm.expectRevert("The vote on the proposal has expired");
        vm.prank(node2);
        strategicFund.vote(1);
    }

    // 8. Test non-node cannot propose
    function testNonNodeCannotPropose() public {
        vm.warp(block.timestamp + 100000000000); 
        uint256 amount = 1 ether;
        assertLe(amount, strategicFund.calcRelease(block.timestamp), "No more relaxed amount");

        vm.expectRevert("The caller is not the nodeAddr");
        vm.prank(nonNode);
        strategicFund.propose(node2, 1 ether, "Non-node Proposal");
    }

    // 9. Test non-node cannot vote
    function testNonNodeCannotVote() public {
        vm.warp(block.timestamp + 100000000000); 
        uint256 amount = 1 ether;
        assertLe(amount, strategicFund.calcRelease(block.timestamp), "No more relaxed amount");

        vm.prank(node1);
        strategicFund.propose(node2, 1 ether, "Test Proposal");

        vm.expectRevert("The caller is not the nodeAddr");
        vm.prank(nonNode);
        strategicFund.vote(1);
    }

    // 10. Test updating the voting period
    function testUpdateVotingPeriod() public {
        vm.prank(owner);
        strategicFund.updateVotingPeriod(10 days);

        assertEq(strategicFund.votingPeriod(), 10 days, "Voting period should be updated");
    }

    // 11. Test token withdrawal
    function testWithdrawToken() public {
        // Ensure the contract has a balance
        deal(address(strategicFund), 7500_000e18 + 1 ether);
        

        //deal(owner, 1 ether);
        vm.prank(owner);
        strategicFund.withdraw(address(0x8A239732871AdC8829EA2f47e94087C5FBad47b6));

        assertEq(address(0x8A239732871AdC8829EA2f47e94087C5FBad47b6).balance, 1 ether, "Owner should withdraw correct amount");
        assertEq(address(strategicFund).balance, 7500_000e18, "TechnologyFund need be 1650*1e22");
    }
}