// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {FixedLock} from "../contracts/FixedLock.sol";
import {FixedLockProxy} from "../contracts/proxy/FixedLock_proxy.sol";
import {IFixedLock} from "./interfaces/IFixedLock.sol";


contract FixedLockTest is Test {
    IFixedLock public fixedLock;


    function setUp() public {
        FixedLock fixedLockImp = new FixedLock();
        FixedLockProxy fixedLockProxy = new FixedLockProxy(address(fixedLockImp));
        fixedLock = IFixedLock(address(fixedLockProxy));
        vm.warp(2028801600);
        fixedLock.init(block.timestamp + 30 days, 50, 7 days);

    }

    function testOwner() public {
        address owner = fixedLock.owner();
        assertEq(owner, address(this));
    }

    function testLock() public {
        vm.warp(2028801601);
        uint256 lockAmount = 1;
        address user = 0x2cD77303737430D78F5a5FbCf8B8f8064d2a92a9;
        vm.deal(user, lockAmount * 1e18);
        vm.startPrank(user,user);
        uint256 id = fixedLock.lock{value: lockAmount * 1e18}(lockAmount);
        (address owner, uint256 locked, , ,) = fixedLock.lockInfo(id);
        assertEq(owner, user);
        assertEq(locked, lockAmount * 1e18);
        vm.stopPrank();
    }

    function testUnlock() public {
        vm.warp(2028801601);
        uint256 lockAmount = 1;
        address user = 0x2cD77303737430D78F5a5FbCf8B8f8064d2a92a9;
        vm.deal(user, lockAmount * 1e18);
        vm.startPrank(user,user);
        uint256 id = fixedLock.lock{value: lockAmount * 1e18}(lockAmount);
        
        uint time = block.timestamp + 365 days * 6;
        vm.warp(time); 
        uint256 releasable = fixedLock.released(id);

        assertEq(releasable, lockAmount * 1e18); 
        assertEq(address(fixedLock).balance, lockAmount * 1e18); 
        fixedLock.unlock(id, lockAmount); 
        vm.stopPrank();
    }

    function testClaimReward() public {
        vm.warp(2028801601);
        uint256 lockAmount = 1;
        address user = 0x2cD77303737430D78F5a5FbCf8B8f8064d2a92a9;
        vm.deal(user, lockAmount * 1e18);
        vm.startPrank(user,user);
        uint256 id = fixedLock.lock{value: lockAmount * 1e18}(lockAmount);
        
        vm.warp(block.timestamp + 8 days); 
        uint256 reward = fixedLock.checkReward(id);
        assertEq(reward, lockAmount * 1e18 * 50 / 1000); 
        vm.deal(address(fixedLock), lockAmount * 1e18 *2);
        fixedLock.claimReward(id); 
    }





}
