// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {LiquidityFundsManage, IPancakeRouter02, IERC20} from "../contracts/LiquidityFundsManage.sol";
import {LiquidityFundsManageProxy} from "../contracts/proxy/LiquidityFundsManage_proxy.sol";
import {ILiquidityFundsManage} from "./interfaces/ILiquidityFundsManage.sol";



contract LiquidityFundsManageTest is Test {
    ILiquidityFundsManage public liquidityFundsManage;
    address public owner = 0x483f21C9542b2Fa9D918dA8BCFeB4d05a809E081;
    IPancakeRouter02 router = IPancakeRouter02(0xCc7aDc94F3D80127849D2b41b6439b7CF1eB4Ae0);
    IERC20 usdc = IERC20(0x7E8B81D247A14610768B4A94855D99b5215A8A76);
    IERC20 nmt = IERC20(0x1656bEcA3704a9E1269fc45f221D9718dDecb952);
    address pair = 0xCb89b92d1f9a46FfC7B986B76e76DC1C2267e1fd;
    address manager = 0x0551fB497B436fdBDB6109B6F8c4949C7e16b6ac;
    address manager2 = owner;
    address manager3 = address(1);

    function setUp() public {
        vm.createSelectFork("bscTest", 43853077);
        vm.startPrank(owner);
        liquidityFundsManage = ILiquidityFundsManage(address(new LiquidityFundsManageProxy(address(new LiquidityFundsManage()))));
        liquidityFundsManage.init(address(nmt), address(usdc), address(router), pair, 18);
        deal(address(nmt), address(liquidityFundsManage), 1e50); 
        assertEq(nmt.balanceOf(address(liquidityFundsManage)), 1e50); 
        deal(address(usdc), address(liquidityFundsManage), 1e50); 
        assertEq(usdc.balanceOf(address(liquidityFundsManage)), 1e50); 
        vm.stopPrank();
    }

    function testOwner() public {
        assertEq(liquidityFundsManage.owner(), owner);
    }

    function testManager() public {
        vm.startPrank(owner);
        liquidityFundsManage.addManager(manager);
        address[] memory managersList = liquidityFundsManage.managersList();
        assertEq(managersList[0], manager);
        vm.stopPrank();
    }

    function addManager() internal {
        vm.startPrank(owner);
        liquidityFundsManage.addManager(manager);
        liquidityFundsManage.addManager(manager2);
        liquidityFundsManage.addManager(manager3);
        vm.stopPrank();
    }

    function test_AddLiquidityProposal() public {
        addManager();

        vm.prank(manager); 
        uint256 proposalId = liquidityFundsManage.addLiquidity_P(100); 

        (ILiquidityFundsManage.ProposalMsg memory proposal,) = liquidityFundsManage.GetProposalMSG(proposalId);

        assertEq(proposal.usdc, 100 * 1e18); 
        assertEq(proposal.nmt, liquidityFundsManage.calculateDesired(100 * 1e18)); 
        assertEq(proposal.opType, 2); 
        
        vm.prank(manager2); 
        liquidityFundsManage.vote(proposalId);

        (proposal,) = liquidityFundsManage.GetProposalMSG(proposalId);
        assertEq(proposal.assentors.length, 2); 
        assertTrue(proposal.isPass);
    }


    function test_removeLiquidity_P() public {
        addManager();
        vm.prank(manager); 
        uint256 proposalId = liquidityFundsManage.addLiquidity_P(100); 

        (ILiquidityFundsManage.ProposalMsg memory proposal,) = liquidityFundsManage.GetProposalMSG(proposalId);
        vm.prank(manager2); 
        liquidityFundsManage.vote(proposalId);
        (proposal,) = liquidityFundsManage.GetProposalMSG(proposalId);
        assertTrue(proposal.isPass);
        
        vm.prank(manager); 
        uint256 proposalId2 = liquidityFundsManage.removeLiquidity_P(100); 
        vm.prank(manager2); 
        liquidityFundsManage.vote(proposalId2);
        assertTrue(proposal.isPass);
    }


    function test_buy_P() public {
        addManager();
        vm.prank(manager); 
        uint256 proposalId = liquidityFundsManage.addLiquidity_P(100); 

        (ILiquidityFundsManage.ProposalMsg memory proposal,) = liquidityFundsManage.GetProposalMSG(proposalId);
        vm.prank(manager2); 
        liquidityFundsManage.vote(proposalId);
        (proposal,) = liquidityFundsManage.GetProposalMSG(proposalId);
        assertTrue(proposal.isPass);
        
        vm.prank(manager); 
        uint256 proposalId2 = liquidityFundsManage.buy_P(100,2); 
        vm.prank(manager2); 
        liquidityFundsManage.vote(proposalId2);
        assertTrue(proposal.isPass);
    }

    function test_sell_P() public {
        addManager();
        vm.prank(manager); 
        uint256 proposalId = liquidityFundsManage.addLiquidity_P(100000000000); 

        (ILiquidityFundsManage.ProposalMsg memory proposal,) = liquidityFundsManage.GetProposalMSG(proposalId);
        vm.prank(manager2); 
        liquidityFundsManage.vote(proposalId);
        (proposal,) = liquidityFundsManage.GetProposalMSG(proposalId);
        assertTrue(proposal.isPass);
        
        vm.prank(manager); 
        uint256 proposalId2 = liquidityFundsManage.sell_P(10,100); 
        vm.prank(manager2); 
        liquidityFundsManage.vote(proposalId2);
        assertTrue(proposal.isPass);
    }

    function test_transfer_P() public {
        addManager();
        vm.prank(manager); 
        uint256 proposalId = liquidityFundsManage.transfer_P(address(2), 100, 300); 

        (ILiquidityFundsManage.ProposalMsg memory proposal,) = liquidityFundsManage.GetProposalMSG(proposalId);
        vm.prank(manager2); 
        liquidityFundsManage.vote(proposalId);
        (proposal,) = liquidityFundsManage.GetProposalMSG(proposalId);
        assertTrue(proposal.isPass);
        assertEq(usdc.balanceOf(address(2)), 1e20); 
        assertEq(nmt.balanceOf(address(2)), 3e20); 
    }





}
