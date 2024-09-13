// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {FiatoSettle} from "../contracts/FiatoSettle.sol";
import {FiatoSettleProxy} from "../contracts/proxy/FiatoSettle_proxy.sol";
import {IFiatoSettle} from "./interfaces/IFiatoSettle.sol";



contract FiatoSettleTest is Test {
    IFiatoSettle public fiatoSettle;
    address public owner = 0x2cD77303737430D78F5a5FbCf8B8f8064d2a92a9;
    address public payment = 0xA82d72F648037c075554882Bd4FBF0C80E950644;
    address public burnAddr = 0xab3eE52D0C7d0f946ebc808d3F166938DC4a5F28;

    function setUp() public {
        vm.startPrank(owner);
        fiatoSettle = IFiatoSettle(address(new FiatoSettleProxy(address(new FiatoSettle()))));
        fiatoSettle.init(payment);
        fiatoSettle.setBurnAddr(burnAddr);
        vm.stopPrank();
    }

    function testOwner() public {
        assertEq(fiatoSettle.owner(), owner);
    }

    function testDistribute() public {
        vm.deal(address(fiatoSettle), 1 ether);
        vm.prank(payment);
        fiatoSettle.distribute(0x3bF26D161691316b37144EE04346e6f199F926cf, 0.3 ether, 0.5 ether);
        assertEq(0x3bF26D161691316b37144EE04346e6f199F926cf.balance, 0.3 ether);
        assertEq(burnAddr.balance, 0.5 ether);
    }







}
