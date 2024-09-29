// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Management} from "../contracts/Management.sol";
import {IManagemenInterface} from "./interfaces/IManagement.sol";
import {FiatoSettle} from "../contracts/FiatoSettle.sol";
import {FiatoSettleProxy} from "../contracts/proxy/FiatoSettle_proxy.sol";
import {IFiatoSettle} from "./interfaces/IFiatoSettle.sol";



contract ManagementTest is Test {
    IManagemenInterface public management;
    FiatoSettleProxy public fiatoSettleProxy;
    IFiatoSettle public fiatoSettle;

    address public owner = 0x2cD77303737430D78F5a5FbCf8B8f8064d2a92a9;
    address public voter1 = 0xab3eE52D0C7d0f946ebc808d3F166938DC4a5F28;
    address public voter2 = 0x80A2bC738D283773519804F2F3Abc811E1A3FEf2;
    address public voter3 = 0xeACB50a28630a4C44a884158eE85cBc10d2B3F10;
    address public voter4 = 0x575cb05c9c2D0D5Ae7a073b4Fc1DB86BEEaA6eD1;
    address public voter5 = 0xaFA745C67e19731eE3a233494357365934e086b5;
    address public voter6 = 0xA82d72F648037c075554882Bd4FBF0C80E950644;
    
    address public payment = 0xA82d72F648037c075554882Bd4FBF0C80E950644;
    address public newPayment = 0xab3eE52D0C7d0f946ebc808d3F166938DC4a5F28;

    function setUp() public {
        vm.startPrank(owner);
        address[] memory _addrs = new address[](5);
        _addrs[0] = voter1;_addrs[1] = voter2;_addrs[2] = voter3;_addrs[3] = voter4;_addrs[4] = voter5;
        management = IManagemenInterface(address(new Management(_addrs)));
        fiatoSettleProxy = new FiatoSettleProxy(address(new FiatoSettle()));
        fiatoSettleProxy.changeAdmin(address(management));
        fiatoSettle = IFiatoSettle(address(fiatoSettleProxy));
        fiatoSettle.init(payment);
        fiatoSettle.transferOwnership(address(management));
        vm.stopPrank();
    }

    function vote(uint256 _proposalId) public {
        vm.prank(voter2);
        management.vote(_proposalId);
        vm.prank(voter3);
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
