// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {NetMindToken} from "../contracts/NetMindToken.sol";
import {NetMindTokenProxy} from "../contracts/proxy/NetMindToken_proxy.sol";
import {INetMindToken} from "./interfaces/INetMindToken.sol";



contract NetMindTokenTest is Test {
    INetMindToken public netMindToken;
    address public owner = 0x2cD77303737430D78F5a5FbCf8B8f8064d2a92a9;
    address public minter = 0x70Da4f87fE2E695a058E5CBdB324c0935efd836C;
    

    function setUp() public {
        vm.startPrank(owner);
        netMindToken = INetMindToken(address(new NetMindTokenProxy(address(new NetMindToken()))));
        netMindToken.initialize(owner,minter);
        vm.stopPrank();
    }

    function testMint() public {
        vm.prank(minter);
        netMindToken.mint(address(1),1e20);
        assertEq(netMindToken.balanceOf(address(1)), 1e20);
        assertEq(netMindToken.totalSupply(), 1e20);
    }

}
