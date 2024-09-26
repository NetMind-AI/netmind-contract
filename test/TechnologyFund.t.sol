// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {TechnologyFund} from "../contracts/TechnologyFund.sol";
import {TechnologyFundProxy} from "../contracts/proxy/TechnologyFund_proxy.sol";
import {ITechnologyFund} from "./interfaces/ITechnologyFund.sol";

contract TechnologyFundTest is Test {
    ITechnologyFund public technologyFund;

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

        technologyFund = ITechnologyFund(address(new TechnologyFundProxy(address(new TechnologyFund()))));
        technologyFund.init(initialNodes, block.timestamp);

        vm.stopPrank();
    }

    // 1. Test contract initialization
    function testInitialization() view public {
        assertEq(technologyFund.owner(), owner, "Owner should be correct");
        assertEq(technologyFund.nodeNum(), 4, "Initial node count should be correct");
        assertTrue(technologyFund.nodeAddrSta(node1), "Node 1 should be initialized");
        assertTrue(technologyFund.nodeAddrSta(node2), "Node 2 should be initialized");
        assertTrue(technologyFund.nodeAddrSta(node3), "Node 3 should be initialized");
        assertTrue(technologyFund.nodeAddrSta(node4), "Node 4 should be initialized");
    }

    // 2. Test adding a node
    function testAddNode() public {
        address[] memory newNodes = new address[](1);

        newNodes[0] = address(7);

        vm.prank(owner);
        technologyFund.addNodeAddr(newNodes);

        assertEq(technologyFund.nodeNum(), 5, "Node count should be 5 after adding a node");
        assertTrue(technologyFund.nodeAddrSta(address(7)), "New node should be added");
    }

    // 3. Test removing a node
    function testDeleteNode() public {
        vm.prank(owner);
        address[] memory deleNodes = new address[](1);
        deleNodes[0] = node1;
        technologyFund.deleteNodeAddr(deleNodes);

        assertEq(technologyFund.nodeNum(), 3, "Node count should be 3 after deleting a node");
        assertFalse(technologyFund.nodeAddrSta(node1), "Node 1 should be deleted");
    }

    // 4. Test proposing
    function testPropose() public {
        vm.warp(block.timestamp + 10000000000); 
        uint256 amount = 1 ether;
        assertLe(amount, technologyFund.calcRelease(block.timestamp), "No more relaxed amount");

        vm.prank(node1);
        technologyFund.propose(node2, amount, "Test Proposal");

        (address proposer, string memory content, address targetAddr,,,) = technologyFund.proposalMsg(1);
        assertEq(proposer, node1, "Proposer should be node1");
        assertEq(content, "Test Proposal", "Proposal content should be correct");
        assertEq(targetAddr, node2, "Target address should be node2");
    }

    // 5. Test voting and executing proposal
    function testVote() public {
        vm.warp(block.timestamp + 100000000000); 
        uint256 amount = 1 ether;
        assertLe(amount, technologyFund.calcRelease(block.timestamp), "No more relaxed amount");

        vm.deal(address(technologyFund), 10 ether);
        vm.prank(node1);
        technologyFund.propose(node2, amount, "Test Proposal");
        
        vm.prank(node2);
        technologyFund.vote(1);

        vm.prank(node3);
        technologyFund.vote(1);

        (, , , , bool proposalSta,) = technologyFund.proposalMsg(1);
        assertTrue(proposalSta, "Proposal should be executed after voting");
    }

    // 6. Test preventing double voting
    function testCannotVoteTwice() public {
        vm.warp(block.timestamp + 100000000000); 
        uint256 amount = 1 ether;
        assertLe(amount, technologyFund.calcRelease(block.timestamp), "No more relaxed amount");

        vm.deal(address(technologyFund), 10 ether);
        vm.prank(node1);
        technologyFund.propose(node2, 1 ether, "Test Proposal");

        vm.prank(node2);
        technologyFund.vote(1);

        vm.expectRevert("The proposer has already voted");
        vm.prank(node2);
        technologyFund.vote(1);
    }

    // 7. Test proposal expiration
    function testCannotVoteAfterExpiration() public {
        vm.warp(block.timestamp + 100000000000); 
        uint256 amount = 1 ether;
        assertLe(amount, technologyFund.calcRelease(block.timestamp), "No more relaxed amount");

        vm.prank(node1);
        technologyFund.propose(node2, 1 ether, "Test Proposal");

        // Simulate the passage of time to exceed the voting period
        vm.warp(block.timestamp + 3 days);  // The voting period is 2 days, exceed it

        vm.expectRevert("The vote on the proposal has expired");
        vm.prank(node2);
        technologyFund.vote(1);
    }

    // 8. Test non-node cannot propose
    function testNonNodeCannotPropose() public {
        vm.warp(block.timestamp + 100000000000); 
        uint256 amount = 1 ether;
        assertLe(amount, technologyFund.calcRelease(block.timestamp), "No more relaxed amount");

        vm.expectRevert("The caller is not the nodeAddr");
        vm.prank(nonNode);
        technologyFund.propose(node2, 1 ether, "Non-node Proposal");
    }

    // 9. Test non-node cannot vote
    function testNonNodeCannotVote() public {
        vm.warp(block.timestamp + 100000000000); 
        uint256 amount = 1 ether;
        assertLe(amount, technologyFund.calcRelease(block.timestamp), "No more relaxed amount");

        vm.prank(node1);
        technologyFund.propose(node2, 1 ether, "Test Proposal");

        vm.expectRevert("The caller is not the nodeAddr");
        vm.prank(nonNode);
        technologyFund.vote(1);
    }

    // 10. Test updating the voting period
    function testUpdateVotingPeriod() public {
        vm.prank(owner);
        technologyFund.updateVotingPeriod(10 days);

        assertEq(technologyFund.votingPeriod(), 10 days, "Voting period should be updated");
    }

    // 11. Test token withdrawal
    function testWithdrawToken() public {
        // Ensure the contract has a balance
        deal(address(technologyFund), 10000000 * 10 ** 18 + 1 ether);
        

        //deal(owner, 1 ether);
        vm.prank(owner);
        technologyFund.withdraw(address(0x8A239732871AdC8829EA2f47e94087C5FBad47b6));

        assertEq(address(0x8A239732871AdC8829EA2f47e94087C5FBad47b6).balance, 1 ether, "Owner should withdraw correct amount");
        assertEq(address(technologyFund).balance, 10000000 * 10 ** 18, "TechnologyFund need be 1650*1e22");
    }
}