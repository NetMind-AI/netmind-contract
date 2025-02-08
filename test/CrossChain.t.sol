// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "contracts/Crosschain.sol";
import "contracts/proxy/Crosschain_proxy.sol";
import "./interfaces/ICrosschain.sol";
import {NetMindToken} from "../contracts/NetMindToken.sol";
import {NetMindTokenProxy} from "../contracts/proxy/NetMindToken_proxy.sol";
import {INetMindToken} from "./interfaces/INetMindToken.sol";


contract CrosschainTest is Test {
    ICrosschain public crosschain;
    INetMindToken public netMindToken;
    address owner = address(0x123);
    address newOwner = address(0x456);
    address trader = address(0x789);
    address tokenAddr = address(0xABC);
    address blacker = address(0xDEF);
    address staker = address(0xDDD);
    address receiver = address(0xDDDE);
    address[] nodeAddrs;
    address acts1; uint256 acts1Pk;
    address acts2; uint256 acts2Pk;
    address acts3; uint256 acts3Pk;
    uint8 v; bytes32 r; bytes32 s;

    function setUp() public {
        // Deploy the contract and initialize it
        crosschain = ICrosschain(address(new CrossChainProxy(address(new Crosschain()))));
        crosschain.init(owner, true);
        netMindToken = INetMindToken(address(new NetMindTokenProxy(address(new NetMindToken()))));
        netMindToken.initialize(owner,address(crosschain));
        (acts1, acts1Pk) = makeAddrAndKey("acts1Pk");
        (acts2, acts2Pk) = makeAddrAndKey("acts2Pk");
        (acts3, acts3Pk) = makeAddrAndKey("acts3Pk");
    }

    function testInitialState() public {
        assertEq(crosschain.owner(), owner);
        assertEq(crosschain.pause(), false);
        //assertEq(crosschain.mainChainSta(), true);
    }

    function testUpdateTrader() public {
        vm.prank(owner);
        crosschain.updateTrader(trader);
        assertEq(crosschain.trader(), trader);
    }

    function testSetBlacker() public {
        vm.prank(owner);
        crosschain.setBlacker(blacker);
        assertEq(crosschain.blacker(), blacker);
    }

    function testPause() public {
        vm.prank(owner);
        crosschain.updatePause(true);
        assertEq(crosschain.pause(), true);
    }

    function testAddNode() public {
        nodeAddrs.push(address(0x1));
        nodeAddrs.push(address(0x2));

        vm.prank(owner);
        crosschain.addNodeAddr(nodeAddrs);

        assertTrue(crosschain.nodeAddrSta(address(0x1)));
        assertTrue(crosschain.nodeAddrSta(address(0x2)));
    }

    function testRemoveNode() public {
        nodeAddrs.push(address(0x1));
        nodeAddrs.push(address(0x2));

        vm.prank(owner);
        crosschain.addNodeAddr(nodeAddrs);

        vm.prank(owner);
        crosschain.deleteNodeAddr(nodeAddrs);

        assertFalse(crosschain.nodeAddrSta(address(0x1)));
        assertFalse(crosschain.nodeAddrSta(address(0x2)));
    }

    function testUpdateChainCharge() public {
        address[] memory tokenAddrs = new address[](1);
        uint256[] memory fees = new uint256[](1);
        uint256[] memory stas = new uint256[](1);

        tokenAddrs[0] = address(0x10001);
        fees[0] = 1e18;
        stas[0] = 2;

        vm.prank(owner);
        crosschain.updateChainCharge("ETH", true, tokenAddrs, fees, stas);
        
        uint256 fee = crosschain.chargeRate("ETH", address(0x10001));
        uint256 sta = crosschain.tokenSta(address(0x10001));
        
        assertEq(fee, 1e18, "fee should be 1e18");
        assertEq(sta, 2, "sta should be 2");
    }

    function updateConf() public {
        address[] memory tokenAddrs = new address[](1);
        uint256[] memory fees = new uint256[](1);
        uint256[] memory stas = new uint256[](1);
        //Native token
        tokenAddrs[0] = address(0);
        fees[0] = 1e16;
        stas[0] = 1;

        uint256[] memory _thresholdTypes = new uint256[](2);
        uint256[] memory _thresholds = new uint256[](2);
        address[] memory _tokens = new address[](2);
        _tokens[0] = address(0); _tokens[1] = address(0);
        _thresholds[0] = 1e22; _thresholds[1] = 1e22;
        _thresholdTypes[0] = 1; _thresholdTypes[1] = 2;
        vm.startPrank(owner);
        crosschain.updateChainCharge("ETH", true, tokenAddrs, fees, stas);
        crosschain.updateThreshold(_tokens, _thresholdTypes, _thresholds);
        vm.stopPrank();
    }

    function testStakeToken() public {
        updateConf();

        uint256 amount = 1 ether;
        vm.deal(staker, 2 ether);

        vm.prank(staker);
        crosschain.stakeToken{value: amount}("ETH", "0x0000000000000000000000000000000000000009", address(0), amount);


        (address token, address from, string memory to, uint256 amt, uint fee, string memory chain) = crosschain.stakeMsg(1);
        assertEq(token, address(0), "adderess should be 0x0");
        assertEq(from, staker, "from address should be staker");
        assertEq(to, "0x0000000000000000000000000000000000000009", "to address should be 0x9");
        assertEq(amt, amount - fee, "amt should be 1 ether");
        assertEq(fee, 1e16, "fee should be 1e16");
        assertEq(chain, "ETH", "chain should be ETH");
    }


    function testBridgeToken() public {
        vm.startPrank(owner);
        crosschain.updateTrader(trader);
        nodeAddrs.push(acts1);nodeAddrs.push(acts2);nodeAddrs.push(acts3);
        crosschain.addNodeAddr(nodeAddrs);
        crosschain.updateSignNum(2);
        vm.stopPrank();
        vm.deal(address(crosschain),1e32);
        updateConf();

        string[] memory strs = new string[](2);
        address[2] memory addrs = [receiver, address(0)];
        uint256[2] memory uints = [1e19, block.timestamp + 1 days];
        uint8[] memory vs = new uint8[](3);
        bytes32[] memory rs = new bytes32[](6);
        strs[0] = "testchain"; strs[1] = "testtxid";
        bytes32 digest = getDigest( addrs[0], addrs[1], uints[0], uints[1], strs[0], strs[1]);
        ( v,  r,  s) = vm.sign(acts1Pk, digest);
        vs[0] = v; rs[0] = r; rs[1] = s;
        (v, r, s) = vm.sign(acts2Pk, digest);
        vs[1] = v; rs[2] = r; rs[3] = s;
        (v, r, s) = vm.sign(acts3Pk, digest);
        vs[2] = v; rs[4] = r; rs[5] = s;

        vm.prank(trader,trader);
        crosschain.bridgeToken(addrs, uints, strs, vs, rs);
        assertEq(address(receiver).balance, 1e19, "balance should be 1e19");
    }

    function updateConf2() public {
        address[] memory tokenAddrs = new address[](1);
        uint256[] memory fees = new uint256[](1);
        uint256[] memory stas = new uint256[](1);
        //Native token
        tokenAddrs[0] = address(netMindToken);
        fees[0] = 1e16;
        stas[0] = 2;

        uint256[] memory _thresholdTypes = new uint256[](2);
        uint256[] memory _thresholds = new uint256[](2);
        address[] memory _tokens = new address[](2);
        _tokens[0] = address(netMindToken); _tokens[1] = address(netMindToken);
        _thresholds[0] = 1e22; _thresholds[1] = 1e22;
        _thresholdTypes[0] = 1; _thresholdTypes[1] = 2;
        vm.startPrank(owner);
        crosschain.updateChainCharge("Netmind", true, tokenAddrs, fees, stas);
        crosschain.updateThreshold(_tokens, _thresholdTypes, _thresholds);
        vm.stopPrank();
    }

    function testStakeToken2() public {
        updateConf2();

        uint256 amount = 1 ether;
        deal(address(netMindToken), staker, 2 ether);

        vm.prank(staker);
        netMindToken.approve(address(crosschain), amount);
        vm.prank(staker);
        crosschain.stakeToken("Netmind", "0x0000000000000000000000000000000000000009", address(netMindToken), amount);


        (address token, address from, string memory to, uint256 amt, uint fee, string memory chain) = crosschain.stakeMsg(1);
        assertEq(token, address(netMindToken), "adderess should be 0x0");
        assertEq(from, staker, "from address should be staker");
        assertEq(to, "0x0000000000000000000000000000000000000009", "to address should be 0x9");
        assertEq(amt, amount - fee, "amt should be 1 ether");
        assertEq(fee, 1e16, "fee should be 1e16");
        assertEq(chain, "Netmind", "chain should be ETH");
    }


    function testBridgeToken2() public {
        vm.startPrank(owner);
        crosschain.updateTrader(trader);
        nodeAddrs.push(acts1);nodeAddrs.push(acts2);nodeAddrs.push(acts3);
        crosschain.addNodeAddr(nodeAddrs);
        crosschain.updateSignNum(2);
        vm.stopPrank();
        deal(address(netMindToken), address(crosschain),1e32);
        updateConf2();

        string[] memory strs = new string[](2);
        address[2] memory addrs = [receiver, address(netMindToken)];
        uint256[2] memory uints = [1e19, block.timestamp + 1 days];
        uint8[] memory vs = new uint8[](3);
        bytes32[] memory rs = new bytes32[](6);
        strs[0] = "testchain"; strs[1] = "testtxid";
        bytes32 digest = getDigest( addrs[0], addrs[1], uints[0], uints[1], strs[0], strs[1]);
        ( v,  r,  s) = vm.sign(acts1Pk, digest);
        vs[0] = v; rs[0] = r; rs[1] = s;
        (v, r, s) = vm.sign(acts2Pk, digest);
        vs[1] = v; rs[2] = r; rs[3] = s;
        (v, r, s) = vm.sign(acts3Pk, digest);
        vs[2] = v; rs[4] = r; rs[5] = s;

        vm.prank(trader,trader);
        crosschain.bridgeToken(addrs, uints, strs, vs, rs);
        assertEq(netMindToken.balanceOf(receiver), 1e19, "balance should be 1e19");
    }



    function getDigest(address userAddr, address contractAddr, uint256 amount, uint256 expiration, string memory chain,string memory txid) internal view returns(bytes32 digest){
        bytes32 hash = keccak256(
            abi.encodePacked(
                '\x19\x01',
                crosschain.DOMAIN_SEPARATOR(),
                keccak256(abi.encode(userAddr, contractAddr,  amount, expiration, chain, txid)))
        );
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        digest = keccak256(abi.encodePacked(prefix, hash));
    }

}
