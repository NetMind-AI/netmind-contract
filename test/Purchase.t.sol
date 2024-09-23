// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Purchase, IPancakeRouter, ICrosschain, IERC20} from "../contracts/Purchase.sol";
import {PurchaseProxy} from "../contracts/proxy/Purchase_proxy.sol";
import {IPurchase} from "./interfaces/IPurchase.sol";



contract PurchaseTest is Test {
    IPurchase public purchase;
    address public owner = 0x483f21C9542b2Fa9D918dA8BCFeB4d05a809E081;
    IPancakeRouter router = IPancakeRouter(0xCc7aDc94F3D80127849D2b41b6439b7CF1eB4Ae0);
    IERC20 usdc = IERC20(0x7E8B81D247A14610768B4A94855D99b5215A8A76);
    IERC20 nmt = IERC20(0x1656bEcA3704a9E1269fc45f221D9718dDecb952);
    address exector = 0x0551fB497B436fdBDB6109B6F8c4949C7e16b6ac;
    ICrosschain crosschain = ICrosschain(0xaFA745C67e19731eE3a233494357365934e086b5);
    string receiver = "0x70Da4f87fE2E695a058E5CBdB324c0935efd836C";
    

    function setUp() public {
        vm.createSelectFork("bscTest", 43853077);
        vm.startPrank(owner);
        purchase = IPurchase(address(new PurchaseProxy(address(new Purchase()))));
        purchase.init(address(router), address(usdc), address(nmt), exector, address(crosschain), receiver);
        deal(address(usdc), address(purchase), 1e50);
        assertEq(usdc.balanceOf(address(purchase)), 1e50);
        vm.stopPrank();
    }

    function testOwner() public {
        assertEq(purchase.owner(), owner);
    }

    function testSwapToken() public {
        uint256 minOut = purchase.calculateAmountOutMin(1e16);
        vm.prank(exector);
        purchase.swapToken(1e16, minOut*98/100, "test");
        assertEq(usdc.balanceOf(address(purchase)), 1e50 - 1e16);
    }

    function testWithdraw() public {
        deal(address(nmt), address(purchase), 1e20);
        assertEq(nmt.balanceOf(address(purchase)), 1e20);
        vm.prank(owner);
        purchase.withdraw(address(1));
        assertEq(nmt.balanceOf(address(1)), 1e20);
    }






}
