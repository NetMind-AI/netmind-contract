// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {RewardPool} from "../contracts/RewardPool.sol";
import {RewardPoolProxy} from "../contracts/proxy/RewardPool_proxy.sol";
import {IRewardPool} from "./interfaces/IRewardPool.sol";
import {ConfInit} from "./ConfInit.sol";


contract RewardPoolTest is ConfInit {
    IRewardPool public rewardPool;
    address public owner = 0x2cD77303737430D78F5a5FbCf8B8f8064d2a92a9;
    address public reward = 0x38045Ad4B008c3aE7Eb11C3fA1A4AD7a946A6b15;
    
    uint256 acts1Pk = 0x8f71bc2fcff2b84fe9c56f1c8b292555ad0a0441749af588f0d39893ac97ba20;
    address acts1 = vm.addr(acts1Pk);
    uint256 acts2Pk = 0x8f71bc3fcff2b84fe9c56f1c8b292555ad0a0441749af588f0d39893ac97ba20;
    address acts2 = vm.addr(acts2Pk);
    uint8 v; bytes32 r; bytes32 s;

    function setUp() public {
        vm.startPrank(owner);
        ConfInit.init();
        conf.file(acts1,true);
        conf.file(acts2,true);

        rewardPool = IRewardPool(address(new RewardPoolProxy(address(new RewardPool()))));
        rewardPool.init(address(conf), reward, 1000 ether, 2, 10000 ether);
        vm.deal(address(rewardPool),1e32);
        vm.stopPrank();
    }

    function testOwner() public {
        assertEq(rewardPool.owner(), owner);
    }


    function test_move() public {
        uint256 moveNonce = rewardPool.MoveNonce();
        uint8[] memory vs = new uint8[](2);
        bytes32[] memory rs = new bytes32[](4);
        bytes32 digest = getDigest( moveNonce, 1e20, block.timestamp + 1 days);
        ( v,  r,  s) = vm.sign(acts1Pk, digest);
        vs[0] = v; rs[0] = r; rs[1] = s;
        (v, r, s) = vm.sign(acts2Pk, digest);
        vs[1] = v; rs[2] = r; rs[3] = s;
        rewardPool.move(moveNonce, 1e20, block.timestamp + 1 days, vs, rs);
        assertEq(reward.balance, 1e20);
        assertEq(address(rewardPool).balance, 1e32 - 1e20);
    }

    function test_burn() public {
        uint256 burnNonce = rewardPool.BurnNonce();
        uint8[] memory vs = new uint8[](2);
        bytes32[] memory rs = new bytes32[](4);
        bytes32 digest = getDigest( burnNonce, 1e20, block.timestamp + 1 days);
        ( v,  r,  s) = vm.sign(acts1Pk, digest);
        vs[0] = v; rs[0] = r; rs[1] = s;
        (v, r, s) = vm.sign(acts2Pk, digest);
        vs[1] = v; rs[2] = r; rs[3] = s;
        rewardPool.burn(burnNonce, 1e20, block.timestamp + 1 days, vs, rs);
        assertEq(address(0).balance, 1e20);
        assertEq(address(rewardPool).balance, 1e32 - 1e20);
    }



    function getDigest(uint256 nonce, uint256 amt, uint256 expir) internal view returns(bytes32 digest){
        bytes32 hash = keccak256(
            abi.encodePacked(
                '\x19\x01',
                rewardPool.DOMAIN_SEPARATOR(),
                keccak256(abi.encode(nonce, amt, expir)))
        );
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        digest = keccak256(abi.encodePacked(prefix, hash));
    }


}
