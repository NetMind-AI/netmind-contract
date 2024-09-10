// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {NetMindToken} from "../contracts/NetMindToken.sol";
import {NetMindTokenProxy} from "../contracts/proxy/NetMindToken_proxy.sol";
import {INetMindToken} from "./interfaces/INetMindToken.sol";


contract NetMindTokenTest is Test {
    INetMindToken public netMindToken;



    function setUp() public {
        NetMindToken netMindTokenImp = new NetMindToken();
        NetMindTokenProxy netMindTokenProxy = new NetMindTokenProxy(address(netMindTokenImp));

        netMindToken = INetMindToken(address(netMindTokenProxy));
        netMindToken.initialize(0xA82d72F648037c075554882Bd4FBF0C80E950644,0xA82d72F648037c075554882Bd4FBF0C80E950644);
    }

    function test_mint(address to, uint256 amount) public {
        vm.startPrank(0xA82d72F648037c075554882Bd4FBF0C80E950644);
        netMindToken.mint(to, amount);
//        ssertEq(addr, _addr);
        vm.stopPrank();
    }


}
