// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {AccountManage} from "../contracts/AccountManage.sol";
import {AccountManageProxy} from "../contracts/proxy/AccountManage_proxy.sol";
import {IAccountManage} from "./interfaces/IAccountManage.sol";
import {ConfInit} from "./ConfInit.sol";


contract AccountManageTest is ConfInit {
    IAccountManage public accountManage;

    

    function setUp() public {
        ConfInit.init();
        AccountManage accountManageImp = new AccountManage();
        AccountManageProxy accountManageProxy = new AccountManageProxy(address(accountManageImp));

        accountManage = IAccountManage(address(accountManageProxy));
        accountManage.init(address(conf));
    }

    function test_updateSignNum(uint256 _signNum) public {
        vm.assume(_signNum > 0);
        accountManage.updateSignNum(_signNum);
        assertEq(accountManage.signNum(), _signNum);
    }

    function test_updateAuthSta(address _addr) public {
        vm.assume(_addr !=  address(0));
        assertEq(accountManage.authSta(_addr), false);
        accountManage.updateAuthSta(_addr,true);
        assertEq(accountManage.authSta(_addr), true);
    }


    function test_blacklist() public {
        address[] memory _addrs = new address[](2);
        address executor = 0xA82d72F648037c075554882Bd4FBF0C80E950644;
        conf.file(execDeductionExecutor, executor);
        vm.startPrank(executor);
        _addrs[0] = 0x70Da4f87fE2E695a058E5CBdB324c0935efd836C;
        _addrs[1] = 0x2cD77303737430D78F5a5FbCf8B8f8064d2a92a9;
        for (uint256 i = 0; i< _addrs.length; i++){
            assertEq(accountManage.whiteAddr(_addrs[i]), false);
        }
        accountManage.addBlacklist(_addrs);
        for (uint256 i = 0; i< _addrs.length; i++){
            assertEq(accountManage.whiteAddr(_addrs[i]), true);
        }
        accountManage.removeBlacklist(_addrs);
        for (uint256 i = 0; i< _addrs.length; i++){
            assertEq(accountManage.whiteAddr(_addrs[i]), false);
        }
        vm.stopPrank();
    }

    function test_initUserId(string memory _userId, address _addr) public {
        address executor = 0xA82d72F648037c075554882Bd4FBF0C80E950644;
        conf.file(accountManageExecutor, executor);
        vm.startPrank(executor);
        accountManage.initUserId(_userId, _addr);
        uint256 _num = accountManage.userAccountById(_userId);
        (uint256 balance, uint256 freezed, string memory userId, address addr, uint256 usd, uint256 overdraft, uint256 cny, uint256 cnyOverdraft) = accountManage.userAccountMsg(_num);
        assertEq(addr, _addr);
        vm.stopPrank();
    }

    function test_updateAccount(string memory _userId, address _addr, address _newAddr) public {
        address executor = 0xA82d72F648037c075554882Bd4FBF0C80E950644;
        conf.file(accountManageExecutor, executor);
        vm.startPrank(executor);
        accountManage.initUserId(_userId, _addr);
        uint256 _num = accountManage.userAccountById(_userId);
        (uint256 balance, uint256 freezed, string memory userId, address addr, uint256 usd, uint256 overdraft, uint256 cny, uint256 cnyOverdraft) = accountManage.userAccountMsg(_num);
        assertEq(addr, _addr);
        accountManage.updateAccount(_userId, _newAddr);
        (balance, freezed, userId, addr, usd, overdraft, cny, cnyOverdraft) = accountManage.userAccountMsg(_num);
        assertEq(addr, _newAddr);
        vm.stopPrank();
    }


    function test_updateAccountUsd(string memory _userId, string memory _orderId, uint256 _usd, bool _type) public {
        vm.assume(_usd < 1e30);
        vm.assume(_usd >1e18);
        address executor = 0xA82d72F648037c075554882Bd4FBF0C80E950644;
        conf.file(accountUsdExecutor, executor);
        conf.file(accountManageExecutor, executor);
        vm.startPrank(executor);
        accountManage.initUserId(_userId, 0x70Da4f87fE2E695a058E5CBdB324c0935efd836C);
        uint256 _num = accountManage.userAccountById(_userId);
        (uint256 balance, uint256 freezed,  ,  , uint256 usd, uint256 overdraft, uint256 cny, uint256 cnyOverdraft) = accountManage.userAccountMsg(_num);
        uint256 _price = 10000000000000000000;
        accountManage.updateAccountUsd(_userId, _orderId, _usd, _type, _price);
        (,  , ,  , uint256 usd2,  ,  ,  ) = accountManage.userAccountMsg(_num);
        if(_type){
            assertEq(usd2, usd + _usd);
        }
        vm.stopPrank();
    }




}
