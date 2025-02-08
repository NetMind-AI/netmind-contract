// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Management} from "../contracts/Management.sol";
import {IManagemenInterface} from "./interfaces/IManagement.sol";
import {FiatoSettle} from "../contracts/FiatoSettle.sol";
import {FiatoSettleProxy} from "../contracts/proxy/FiatoSettle_proxy.sol";
import {IFiatoSettle} from "./interfaces/IFiatoSettle.sol";
import {NetMindToken} from "../contracts/NetMindToken.sol";


contract ManagementTest is Test {
    IManagemenInterface public management;
    FiatoSettleProxy public fiatoSettleProxy;
    IFiatoSettle public fiatoSettle;
    NetMindToken public netMindToken;


    address public owner = 0x149f2ed2F5855c286a06566235923Ce9d9d4A25a;
    address public voter1 = 0x691D320f224625713c6097Af152C75588142FDd0;
    address public voter2 = 0xfc1c3A46e84846DE3C0dd6F7C0F70601321787D9;
    address public voter3 = 0xc4E9F25cE5323DAf8f8A9f16C815AbD534562Ebf;
    address public voter4 = 0xE8cfb1A486C05eb1062Af9B233c298F13dCeF13c;
    address public voter5 = 0x11269Ec12B71CCD43D201C62f16095aB2F3d0bea;
    address public voter6 = 0xc0a8F6ac9EF75453BE712412aB8fD5be5fc3Cc50;

    address public payment = 0xA82d72F648037c075554882Bd4FBF0C80E950644;
    address public newPayment = 0xab3eE52D0C7d0f946ebc808d3F166938DC4a5F28;

//    function setUp() public {
//        vm.startPrank(owner);
//        address[] memory _addrs = new address[](5);
//        _addrs[0] = voter1;_addrs[1] = voter2;_addrs[2] = voter3;_addrs[3] = voter4;_addrs[4] = voter5;
//        management = IManagemenInterface(address(new Management(_addrs)));
//        fiatoSettleProxy = new FiatoSettleProxy(address(new FiatoSettle()));
//        fiatoSettleProxy.changeAdmin(address(management));
//        fiatoSettle = IFiatoSettle(address(fiatoSettleProxy));
//        fiatoSettle.init(payment);
//        fiatoSettle.transferOwnership(address(management));
//        vm.stopPrank();
//    }

    function setUp() public {
        vm.createSelectFork("mainnet", 21225939);
        management = IManagemenInterface(0x2A9Da57EE6E79bb17b90D122f49785917d24dfd9);
        netMindToken = new NetMindToken();

    }

    function testMainnetVote() public {
        vm.prank(0xD7C4B80Dc0Bc08Ef92a60d50269c3ECeC2b459b8);
        management.vote(14);
    }

    function testMainnetProposal() public {
        vm.prank(owner);
        management.updateProxyUpgradPropose(0x03AA6298F1370642642415EDC0db8b957783e8D6, 0xde1c06414aB6eB6Ef32ea0d37282B20E980bE811);
        uint256 _proposalId = management.proposalCount();
        vote(_proposalId);
        vm.prank(0xD7C4B80Dc0Bc08Ef92a60d50269c3ECeC2b459b8);
        management.vote(_proposalId);

        bytes memory data = hex"0e8cc705000000000000000000000000000000000000000000000000000000000000004000000000000000000000000058d37fddab1059692e5c40fa562570e49be655280000000000000000000000000000000000000000000000000000000000000004000000000000000000000000514910771af9ca656af840dff83e8264ecf986ca00000000000000000000000003aa6298f1370642642415edc0db8b957783e8d6000000000000000000000000a0b86991c6218b36c1d19d4a2e9eb0ce3606eb48000000000000000000000000dac17f958d2ee523a2206206994597c13d831ec7";
        vm.prank(voter1);
        management.excContractPropose(0x03AA6298F1370642642415EDC0db8b957783e8D6, data);
        _proposalId = management.proposalCount();
        vote(_proposalId);
        vm.prank(0xD7C4B80Dc0Bc08Ef92a60d50269c3ECeC2b459b8);
        management.vote(_proposalId);
        (bool proposalSta, address targetAddr, address addr,  ,  ,  , string memory label) = management.proposalMsg(_proposalId);
    }

    function vote(uint256 _proposalId) public {
        vm.prank(voter2);
        management.vote(_proposalId);
        vm.prank(voter3);
        management.vote(_proposalId);
        vm.prank(voter4);
        management.vote(_proposalId);

    }

    function testNodePropose() public {
        assertFalse(management.nodeAddrSta(voter6));
        vm.prank(voter1);
        management.addNodePropose(voter6);
        uint256 _proposalId = management.proposalCount();
        vote(_proposalId);
        assertTrue(management.nodeAddrSta(voter6));
        (bool proposalSta, address targetAddr, address addr,  ,  ,  , string memory label) = management.proposalMsg(_proposalId);
        assertTrue(proposalSta);
        assertEq(addr, voter6);
        assertEq(label, "addNode");

        vm.prank(voter6);
        management.deleteNodePropose(voter6);
        _proposalId = management.proposalCount();
        vm.prank(voter4);
        management.vote(_proposalId);
        vote(_proposalId);
        assertFalse(management.nodeAddrSta(voter6));
        (bool proposalSta2,  , address addr2,  ,  ,  , string memory label2) = management.proposalMsg(_proposalId);
        assertTrue(proposalSta2);
        assertEq(addr2, voter6);
        assertEq(label2, "deleteNode");
    }

    function testUpdateProxyAdminPropose() public {
        address admin =  address(1);
        vm.prank(voter1);
        management.updateProxyAdminPropose(address(fiatoSettleProxy), admin);
        uint256 _proposalId = management.proposalCount();
        vote(_proposalId);
        (bool proposalSta, address targetAddr, address addr, bytes memory data ,  ,  , string memory label) = management.proposalMsg(_proposalId);
        assertTrue(proposalSta);
        assertEq(targetAddr, address(fiatoSettleProxy));
        assertEq(addr, admin);
        assertEq(label, "updateProxyAdmin");
        assertEq(fiatoSettleProxy.admin(), admin);

    }

    function testUpdateProxyUpgradPropose() public {
        FiatoSettle fiatoSettleImp = new FiatoSettle();
        vm.prank(voter1);
        management.updateProxyUpgradPropose(address(fiatoSettleProxy), address(fiatoSettleImp));
        uint256 _proposalId = management.proposalCount();
        vote(_proposalId);
        (bool proposalSta, address targetAddr, address addr, bytes memory data ,  ,  , string memory label) = management.proposalMsg(_proposalId);
        assertTrue(proposalSta);
        assertEq(targetAddr, address(fiatoSettleProxy));
        assertEq(addr, address(fiatoSettleImp));
        assertEq(label, "updateProxyUpgrad");
        assertEq(fiatoSettleProxy.logic(), address(fiatoSettleImp));

    }

    function testExcContractPropose() public {
        address accountManage =  address(1);
        vm.prank(voter1);
        management.excContractPropose(address(fiatoSettle), abi.encodeWithSignature("setAccountManage(address)", accountManage));
        uint256 _proposalId = management.proposalCount();
        vote(_proposalId);
        (bool proposalSta, address targetAddr, address addr, bytes memory data ,  ,  , string memory label) = management.proposalMsg(_proposalId);
        assertTrue(proposalSta);
        assertEq(targetAddr, address(fiatoSettle));
        assertEq(data, abi.encodeWithSignature("setAccountManage(address)", accountManage));
        assertEq(label, "excContract");
        assertEq(fiatoSettle.accountManage(), accountManage);

    }

    function testExcContractProposes() public {
        address accountManage =  address(1);
        address burnAddr =  address(2);
        address[] memory targetAddrs = new address[](2);
        bytes[] memory datas = new bytes[](2);
        datas[0] = abi.encodeWithSignature("setAccountManage(address)", accountManage);  datas[1] = abi.encodeWithSignature("setBurnAddr(address)", burnAddr);
        targetAddrs[0] = address(fiatoSettle);  targetAddrs[1] = address(fiatoSettle);
        vm.prank(voter1);
        management.excContractProposes(targetAddrs, datas);
        vote(1);
        (bool proposalSta, address targetAddr, address addr, bytes memory data ,  ,  , string memory label) = management.proposalMsg(1);
        assertTrue(proposalSta);
        assertEq(targetAddr, address(fiatoSettle));
        assertEq(data, abi.encodeWithSignature("setAccountManage(address)", accountManage));
        assertEq(label, "excContract");
        assertEq(fiatoSettle.accountManage(), accountManage);
        vote(2);
        (bool proposalSta2, address targetAddr2, address addr2, bytes memory data2 ,  ,  , string memory label2) = management.proposalMsg(2);
        assertTrue(proposalSta2);
        assertEq(targetAddr2, address(fiatoSettle));
        assertEq(data2, abi.encodeWithSignature("setBurnAddr(address)", burnAddr));
        assertEq(label2, "excContract");
        assertEq(fiatoSettle.burnAddr(), burnAddr);

    }







}
