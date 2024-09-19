// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {RewardContract} from "../contracts/RewardContract.sol";
import {RewardProxy} from "../contracts/proxy/Reward_proxy.sol";
import {IRewardContract} from "./interfaces/IRewardContract.sol";
import {Pledge} from "../contracts/Pledge.sol";
import {PledgeProxy} from "../contracts/proxy/Pledge_proxy.sol";
import {IPledge} from "./interfaces/IPledge.sol";
import {ConfInit} from "./ConfInit.sol";


contract RewardContractTest is ConfInit {
    IRewardContract public rewardContract;
    IPledge public pledge;
    address public owner = 0x2cD77303737430D78F5a5FbCf8B8f8064d2a92a9;
    address acts1; uint256 acts1Pk;
    address acts2; uint256 acts2Pk;
    address acts3; uint256 acts3Pk;
    address acts4; uint256 acts4Pk;
    address acts5; uint256 acts5Pk;
    address acts6; uint256 acts6Pk;
    address acts7; uint256 acts7Pk;
    address acts8; uint256 acts8Pk;
    address acts9; uint256 acts9Pk;
    address acts10; uint256 acts10Pk;
    address acts11; uint256 acts11Pk;
    address acts12; uint256 acts12Pk;
    address acts13; uint256 acts13Pk;
    address acts14; uint256 acts14Pk;
    address acts15; uint256 acts15Pk;
    address acts16; uint256 acts16Pk;
    address acts17; uint256 acts17Pk;
    address acts18; uint256 acts18Pk;



    uint8 v; bytes32 r; bytes32 s;

    function setUp() public {
        vm.startPrank(owner);
        ConfInit.init();
        rewardContract = IRewardContract(address(new RewardProxy(address(new RewardContract()))));
        rewardContract.init(address(conf));
        pledge = IPledge(address(new PledgeProxy(address(new Pledge()))));
        pledge.init();
        address[] memory addrs = new address[](18);
        (acts1, acts1Pk) = makeAddrAndKey("acts1Pk");
        (acts2, acts2Pk) = makeAddrAndKey("acts2Pk");
        (acts3, acts3Pk) = makeAddrAndKey("acts3Pk");
        (acts4, acts4Pk) = makeAddrAndKey("acts4Pk");
        (acts5, acts5Pk) = makeAddrAndKey("acts5Pk");
        (acts6, acts6Pk) = makeAddrAndKey("acts6Pk");
        (acts7, acts7Pk) = makeAddrAndKey("acts7Pk");
        (acts8, acts8Pk) = makeAddrAndKey("acts8Pk");
        (acts9, acts9Pk) = makeAddrAndKey("acts9Pk");
        (acts10, acts10Pk) = makeAddrAndKey("acts10Pk");
        (acts11, acts11Pk) = makeAddrAndKey("acts11Pk");
        (acts12, acts12Pk) = makeAddrAndKey("acts12Pk");
        (acts13, acts13Pk) = makeAddrAndKey("acts13Pk");
        (acts14, acts14Pk) = makeAddrAndKey("acts14Pk");
        (acts15, acts15Pk) = makeAddrAndKey("acts15Pk");
        (acts16, acts16Pk) = makeAddrAndKey("acts16Pk");
        (acts17, acts17Pk) = makeAddrAndKey("acts17Pk");
        (acts18, acts18Pk) = makeAddrAndKey("acts18Pk");
        addrs[0] = acts1; addrs[1] = acts2; addrs[2] = acts3;
        addrs[3] = acts4; addrs[4] = acts5; addrs[5] = acts6;
        addrs[6] = acts7; addrs[7] = acts8; addrs[8] = acts9;
        addrs[9] = acts10; addrs[10] = acts11; addrs[11] = acts12;
        addrs[12] = acts13; addrs[13] = acts14; addrs[14] = acts15;
        addrs[15] = acts16; addrs[16] = acts17; addrs[17] = acts18;
        pledge.addNodeAddr(addrs);
        conf.file(Staking, address(pledge));
        vm.deal(address(rewardContract),1e32);
        vm.stopPrank();
    }

    function testOwner() public {
        assertEq(rewardContract.owner(), owner);
    }

    function testBlackerlist() public {
        address blacker = 0x38045Ad4B008c3aE7Eb11C3fA1A4AD7a946A6b15;
        vm.prank(owner);
        rewardContract.setBlacker(blacker);
        assertEq(rewardContract.blacklist(address(1)), false);
        vm.prank(blacker);
        rewardContract.addBlacklist(address(1));
        assertEq(rewardContract.blacklist(address(1)), true);
        vm.prank(owner);
        rewardContract.removeBlacklist(address(1));
        assertEq(rewardContract.blacklist(address(1)), false);
    }

    
    function test_withdrawToken() public {
        vm.prank(owner);
        rewardContract.updateThreshold(1e20);
        uint8[] memory vs = new uint8[](18);
        bytes32[] memory rs = new bytes32[](36);
        address withdrawUser = 0xC3cAD069A30a58737c3B0B94fA208c5Ce553661b;
        address[2] memory addrs = [withdrawUser, address(0)];
        uint256[2] memory uints = [1e19, block.timestamp + 1 days];
        bytes32 digest = getDigest( addrs[0], addrs[1], uints[0], uints[1]);
        ( v,  r,  s) = vm.sign(acts1Pk, digest);
        vs[0] = v; rs[0] = r; rs[1] = s;
        (v, r, s) = vm.sign(acts2Pk, digest);
        vs[1] = v; rs[2] = r; rs[3] = s;
        (v, r, s) = vm.sign(acts3Pk, digest);
        vs[2] = v; rs[4] = r; rs[5] = s;
        (v, r, s) = vm.sign(acts4Pk, digest);
        vs[3] = v; rs[6] = r; rs[7] = s;
        (v, r, s) = vm.sign(acts5Pk, digest);
        vs[4] = v; rs[8] = r; rs[9] = s;
        (v, r, s) = vm.sign(acts6Pk, digest);
        vs[5] = v; rs[10] = r; rs[11] = s;
        (v, r, s) = vm.sign(acts7Pk, digest);
        vs[6] = v; rs[12] = r; rs[13] = s;
        (v, r, s) = vm.sign(acts8Pk, digest);
        vs[7] = v; rs[14] = r; rs[15] = s;
        (v, r, s) = vm.sign(acts9Pk, digest);
        vs[8] = v; rs[16] = r; rs[17] = s;
        (v, r, s) = vm.sign(acts10Pk, digest);
        vs[9] = v; rs[18] = r; rs[19] = s;
        (v, r, s) = vm.sign(acts11Pk, digest);
        vs[10] = v; rs[20] = r; rs[21] = s;
        (v, r, s) = vm.sign(acts12Pk, digest);
        vs[11] = v; rs[22] = r; rs[23] = s;
        (v, r, s) = vm.sign(acts13Pk, digest);
        vs[12] = v; rs[24] = r; rs[25] = s;
        (v, r, s) = vm.sign(acts14Pk, digest);
        vs[13] = v; rs[26] = r; rs[27] = s;
        (v, r, s) = vm.sign(acts15Pk, digest);
        vs[14] = v; rs[28] = r; rs[29] = s;
        (v, r, s) = vm.sign(acts16Pk, digest);
        vs[15] = v; rs[30] = r; rs[31] = s;
        (v, r, s) = vm.sign(acts17Pk, digest);
        vs[16] = v; rs[32] = r; rs[33] = s;
        (v, r, s) = vm.sign(acts18Pk, digest);
        vs[17] = v; rs[34] = r; rs[35] = s;
        vm.prank(addrs[0], addrs[0]);
        rewardContract.withdrawToken(addrs, uints, vs, rs);
        assertEq(address(withdrawUser).balance, uints[0]);
        assertEq(address(rewardContract).balance, 1e32 - uints[0]);
    }



    function getDigest(address userAddr, address contractAddr, uint256 amount, uint256 expiration) internal view returns(bytes32 digest){
        bytes32 hash = keccak256(
            abi.encodePacked(
                '\x19\x01',
                rewardContract.DOMAIN_SEPARATOR(),
                keccak256(abi.encode(userAddr, contractAddr,  amount, expiration, rewardContract.nonce(userAddr))))
        );
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        digest = keccak256(abi.encodePacked(prefix, hash));
    }


}
