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
        uint256 _price = 10000000000000000000;
        if(_type){
            (uint256 balance, uint256 freezed,  ,  , uint256 usd, uint256 overdraft, uint256 cny, uint256 cnyOverdraft) = accountManage.userAccountMsg(_num);
            accountManage.updateAccountUsd(_userId, _orderId, _usd, true, _price);
            (,  , ,  , uint256 usd2,  ,  ,  ) = accountManage.userAccountMsg(_num);
            assertEq(usd2, usd + _usd);
        }else{
            accountManage.updateAccountUsd(_userId, "test", _usd+1e18, true, _price);
            (uint256 balance, uint256 freezed,  ,  , uint256 usd, uint256 overdraft, uint256 cny, uint256 cnyOverdraft) = accountManage.userAccountMsg(_num);
            accountManage.updateAccountUsd(_userId, _orderId, _usd, _type, _price);
            (,  , ,  , uint256 usd2,  ,  ,  ) = accountManage.userAccountMsg(_num);
            assertEq(1e18, usd - _usd);
        }
        vm.stopPrank();
    }

    function test_updateAccountCny(string memory _userId, string memory _orderId, uint256 _cny, bool _type) public {
        vm.assume(_cny < 1e30);
        vm.assume(_cny >1e18);
        address executor = 0xA82d72F648037c075554882Bd4FBF0C80E950644;
        conf.file(accountUsdExecutor, executor);
        conf.file(accountManageExecutor, executor);
        vm.startPrank(executor);
        accountManage.initUserId(_userId, 0x70Da4f87fE2E695a058E5CBdB324c0935efd836C);
        uint256 _num = accountManage.userAccountById(_userId);
        if(_type){
            (uint256 balance, uint256 freezed,  ,  , uint256 usd, uint256 overdraft, uint256 cny, uint256 cnyOverdraft) = accountManage.userAccountMsg(_num);
            accountManage.updateAccountCny(_userId, _orderId, _cny, true);
            (,  , ,  , ,  ,uint256 cny2  ,  ) = accountManage.userAccountMsg(_num);
            assertEq(cny2, cny + _cny);
        }else{
            accountManage.updateAccountCny(_userId, "test", _cny+1e18, true);
            (uint256 balance, uint256 freezed,  ,  , uint256 usd, uint256 overdraft, uint256 cny, uint256 cnyOverdraft) = accountManage.userAccountMsg(_num);
            accountManage.updateAccountCny(_userId, _orderId, _cny, _type);
            (,  , ,  , ,  , uint256 cny2 ,  ) = accountManage.userAccountMsg(_num);
            assertEq(1e18, cny - _cny);
        }
        vm.stopPrank();
    }

    function test_execDeduction(string memory _userId, string memory _orderId, string memory _orderId2, uint256 _nmt, uint256 _usd, uint256 _overdraft, string memory _msg) public {
        vm.assume(_nmt > 0.1 ether);
        vm.assume(_nmt < 1e30);
        vm.assume(_usd < 1e30);
        vm.assume(_overdraft < 1e30);
        vm.assume(keccak256(abi.encodePacked(_orderId)) != keccak256(abi.encodePacked(_orderId2)));
        uint256 _price = 10000000000000000000;
        address executor = 0xA82d72F648037c075554882Bd4FBF0C80E950644;
        conf.file(accountUsdExecutor, executor);
        conf.file(accountManageExecutor, executor);
        conf.file(execDeductionExecutor, executor);
        accountManage.updateQuota(500);
        _overdraft = _overdraft% 500;
        vm.startPrank(executor);
        address user = 0x70Da4f87fE2E695a058E5CBdB324c0935efd836C;
        accountManage.initUserId(_userId, user);
        vm.stopPrank();
        vm.deal(user,1e32);
        vm.prank(user);
        accountManage.tokenCharge{value: _nmt}();
        vm.startPrank(executor);
        accountManage.updateAccountUsd(_userId, _orderId, _usd + 500, true, _price);
        uint a = (_nmt% 10);
        if(a!=0)_nmt = _nmt /a;
        accountManage.execDeduction(_userId, _orderId2,_nmt,_usd,_overdraft,_msg);
        accountManage.caclAccountBalance(_userId, _price);
        vm.stopPrank();
    }

    function test_execCnyDeduction(string memory _userId, string memory _orderId, string memory _orderId2, uint256 _cny, uint256 _cnyOverdraft, string memory _msg) public {
        vm.assume(_cny < 1e30);
        vm.assume(_cnyOverdraft < 1e30);
        vm.assume(keccak256(abi.encodePacked(_orderId)) != keccak256(abi.encodePacked(_orderId2)));
        address executor = 0xA82d72F648037c075554882Bd4FBF0C80E950644;
        conf.file(accountUsdExecutor, executor);
        conf.file(accountManageExecutor, executor);
        conf.file(execDeductionExecutor, executor);
        accountManage.updateQuotaCny(5000);
        _cnyOverdraft = _cnyOverdraft% 5000;
        vm.startPrank(executor);
        address user = 0x70Da4f87fE2E695a058E5CBdB324c0935efd836C;
        accountManage.initUserId(_userId, user);
        vm.startPrank(executor);
        accountManage.updateAccountCny(_userId, _orderId, _cny + 5000, true);
        uint a = (_cny% 10);
        if(a!=0)_cny = _cny /a;
        accountManage.execCnyDeduction(_userId, _orderId2,_cny,_cnyOverdraft,_msg);
        accountManage.updateAccountCny(_userId, "test", 0, true);
        vm.stopPrank();
    }

    function test_refund(string memory _userId, string memory _orderId, string memory _orderId2, uint256 _nmt, uint256 _usd, uint256 _overdraft, string memory _msg) public {
        vm.assume(_nmt > 0.1 ether);
        vm.assume(_nmt < 1e30);
        vm.assume(_usd < 1e30);
        vm.assume(_overdraft < 1e30);
        vm.assume(keccak256(abi.encodePacked(_orderId)) != keccak256(abi.encodePacked(_orderId2)));
        uint256 _price = 10000000000000000000;
        address executor = 0xA82d72F648037c075554882Bd4FBF0C80E950644;
        conf.file(accountUsdExecutor, executor);
        conf.file(accountManageExecutor, executor);
        conf.file(execDeductionExecutor, executor);
        accountManage.updateQuota(500);
        _overdraft = _overdraft% 500;
        vm.startPrank(executor);
        address user = 0x70Da4f87fE2E695a058E5CBdB324c0935efd836C;
        accountManage.initUserId(_userId, user);
        vm.stopPrank();
        vm.deal(user,1e32);
        vm.prank(user);
        accountManage.tokenCharge{value: _nmt}();
        vm.startPrank(executor);
        accountManage.updateAccountUsd(_userId, _orderId, _usd + 500, true, _price);
        uint a = (_nmt% 10);
        if(a!=0)_nmt = _nmt /a;
        accountManage.execDeduction(_userId, _orderId2,_nmt,_usd,_overdraft,_msg);
        if(a!=0){
            _nmt = _nmt /a;
            _usd = _usd /a;
            _overdraft = _overdraft /a;
        }
        accountManage.refund(_userId, _orderId2, "test",  _nmt,_usd,_overdraft);
        vm.stopPrank();
    }

    function test_refundCny(string memory _userId, string memory _orderId, string memory _orderId2, uint256 _cny, uint256 _cnyOverdraft, string memory _msg) public {
        vm.assume(_cny < 1e30);
        vm.assume(_cnyOverdraft < 1e30);
        vm.assume(keccak256(abi.encodePacked(_orderId)) != keccak256(abi.encodePacked(_orderId2)));
        address executor = 0xA82d72F648037c075554882Bd4FBF0C80E950644;
        conf.file(accountUsdExecutor, executor);
        conf.file(accountManageExecutor, executor);
        conf.file(execDeductionExecutor, executor);
        accountManage.updateQuotaCny(5000);
        _cnyOverdraft = _cnyOverdraft% 5000;
        vm.startPrank(executor);
        address user = 0x70Da4f87fE2E695a058E5CBdB324c0935efd836C;
        accountManage.initUserId(_userId, user);
        vm.startPrank(executor);
        accountManage.updateAccountCny(_userId, _orderId, _cny + 5000, true);
        uint a = (_cny% 10);
        if(a!=0)_cny = _cny /a;
        accountManage.execCnyDeduction(_userId, _orderId2,_cny,_cnyOverdraft,_msg);
        if(a!=0){
            _cny = _cny /a;
            _cnyOverdraft = _cnyOverdraft /a;
        }
        accountManage.refundCny(_userId, _orderId2, "test",  _cny, _cnyOverdraft);
        vm.stopPrank();
    }

    function test_withdraw(string memory _userId, uint256 _nmt) public {
        address executor = 0xA82d72F648037c075554882Bd4FBF0C80E950644;
        conf.file(accountUsdExecutor, executor);
        conf.file(accountManageExecutor, executor);
        conf.file(execDeductionExecutor, executor);
        vm.startPrank(executor);
        address user = 0x70Da4f87fE2E695a058E5CBdB324c0935efd836C;
        accountManage.initUserId(_userId, user);
        uint256 _num = accountManage.userAccountById(_userId);
        vm.stopPrank();
        vm.deal(user,1e32);
        vm.assume(_nmt < 1e32);
        vm.assume(_nmt >0);
        vm.startPrank(user);
        accountManage.tokenCharge{value: _nmt}();
        uint a = (_nmt% 10);
        uint256 _withdraw;
        if(a!=0){ _withdraw = _nmt /a;}
        accountManage.withdraw(_withdraw);
        (uint256 balance, uint256 freezed,  ,  , uint256 usd, uint256 overdraft, uint256 cny, uint256 cnyOverdraft) = accountManage.userAccountMsg(_num);
        assertEq(balance, _nmt - _withdraw);    
        vm.stopPrank();
    }

    // function test_distributeNmt(string memory _userId, string memory _orderId, string memory _orderId2, uint256 _nmt, uint256 _usd, uint256 _overdraft, string memory _msg) public {
    //     vm.assume(_nmt > 0.1 ether);
    //     vm.assume(_nmt < 1e30);
    //     vm.assume(_usd < 1e30);
    //     vm.assume(_overdraft < 1e30);
    //     vm.assume(keccak256(abi.encodePacked(_orderId)) != keccak256(abi.encodePacked(_orderId2)));
    //     uint256 _price = 10000000000000000000;
    //     address executor = 0xA82d72F648037c075554882Bd4FBF0C80E950644;
    //     conf.file(accountUsdExecutor, executor);
    //     conf.file(accountManageExecutor, executor);
    //     conf.file(execDeductionExecutor, executor);
    //     accountManage.updateQuota(500);
    //     _overdraft = _overdraft% 500;
    //     vm.startPrank(executor);
    //     address user = 0x70Da4f87fE2E695a058E5CBdB324c0935efd836C;
    //     accountManage.initUserId(_userId, user);
    //     vm.stopPrank();
    //     vm.deal(user,1e32);
    //     vm.prank(user);
    //     accountManage.tokenCharge{value: _nmt}();
    //     vm.startPrank(executor);
    //     accountManage.updateAccountUsd(_userId, _orderId, _usd + 500, true, _price);
    //     uint a = (_nmt% 10);
    //     if(a!=0)_nmt = _nmt /a;
    //     accountManage.execDeduction(_userId, _orderId2,_nmt,_usd,_overdraft,_msg);
    //     accountManage.caclAccountBalance(_userId, _price);
    //     vm.stopPrank();
    // }






}
