// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {NetMindToken} from "../contracts/NetMindToken.sol";
import {NetMindTokenProxy} from "../contracts/proxy/NetMindToken_proxy.sol";
import {INetMindToken} from "./interfaces/INetMindToken.sol";
import {Airdrop} from "../contracts/Airdrop.sol";



contract AirdropTest is Test {
    INetMindToken public netMindToken;
    Airdrop public airdrop;
    address public owner = 0x2cD77303737430D78F5a5FbCf8B8f8064d2a92a9;
    address public minter = 0xA82d72F648037c075554882Bd4FBF0C80E950644;
    address public bank = 0x70Da4f87fE2E695a058E5CBdB324c0935efd836C;

    function setUp() public {
        vm.startPrank(owner);
        netMindToken = INetMindToken(address(new NetMindTokenProxy(address(new NetMindToken()))));
        netMindToken.initialize(owner,minter);
        airdrop = new Airdrop(address(netMindToken), bank);
        vm.stopPrank();
    }

    function testAirdrop() public {
        vm.prank(minter);
        netMindToken.mint(bank,1e21);
        vm.prank(bank);
        netMindToken.approve(address(airdrop),1e21);
        address[] memory _addrs = new address[](2);
        _addrs[0] = address(1); _addrs[1] = address(2);
        uint256[] memory amts = new uint256[](2);
        amts[0] = 1e19; amts[1] = 3e19;
        vm.prank(owner);
        airdrop.airdrop(_addrs,1e20);
        assertEq(netMindToken.balanceOf(address(1)), 1e20);
        assertEq(netMindToken.balanceOf(address(2)), 1e20);
        vm.prank(owner);
        airdrop.airdrop(_addrs,amts);
        assertEq(netMindToken.balanceOf(address(1)), 1e20 + 1e19);
        assertEq(netMindToken.balanceOf(address(2)), 1e20 + 3e19);
    }

}
