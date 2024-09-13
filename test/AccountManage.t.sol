// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {AccountManage} from "../contracts/AccountManage.sol";
import {AccountManageProxy} from "../contracts/proxy/AccountManage_proxy.sol";
import {IAccountManage} from "./interfaces/IAccountManage.sol";
import {FiatoSettle} from "../contracts/FiatoSettle.sol";
import {FiatoSettleProxy} from "../contracts/proxy/FiatoSettle_proxy.sol";
import {IFiatoSettle} from "./interfaces/IFiatoSettle.sol";
import {ConfInit} from "./ConfInit.sol";


contract AccountManageTest is ConfInit {
    IAccountManage public accountManage;
    IFiatoSettle public fiatoSettle;
      
    uint256 acts1Pk = 0x8f71bc2fcff2b84fe9c56f1c8b292555ad0a0441749af588f0d39893ac97ba20;
    address acts1 = vm.addr(acts1Pk);
    uint256 acts2Pk = 0x8f71bc3fcff2b84fe9c56f1c8b292555ad0a0441749af588f0d39893ac97ba20;
    address acts2 = vm.addr(acts2Pk);
    uint8 v; bytes32 r; bytes32 s;

    function setUp() public {
        ConfInit.init();
        conf.file(acts1,true);
        conf.file(acts2,true);
        fiatoSettle = IFiatoSettle(address(new FiatoSettleProxy(address(new FiatoSettle()))));
        fiatoSettle.init(address(1));
        vm.deal(address(fiatoSettle), 100000 ether);
        AccountManage accountManageImp = new AccountManage();
        AccountManageProxy accountManageProxy = new AccountManageProxy(address(accountManageImp));

        accountManage = IAccountManage(address(accountManageProxy));
        fiatoSettle.setAccountManage(address(accountManage));
        accountManage.init(address(conf));
        accountManage.updateAuthSta(address(1), true);
        accountManage.setFiatoSettle(address(fiatoSettle));
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

    function test_freeze() public {
        address executor = 0xA82d72F648037c075554882Bd4FBF0C80E950644;
        string memory _userId = "test";
        conf.file(accountUsdExecutor, executor);
        conf.file(accountManageExecutor, executor);
        conf.file(execDeductionExecutor, executor);
        vm.prank(executor);
        address user = 0x70Da4f87fE2E695a058E5CBdB324c0935efd836C;
        accountManage.initUserId(_userId, user);
        uint256 _num = accountManage.userAccountById(_userId);
        vm.deal(user,1e32);
        vm.prank(user);
        accountManage.tokenCharge{value: 1e23}();
        vm.prank(address(1));
        accountManage.freeze(_userId, 1e20, 1);
        (uint256 balance, uint256 freezed,  ,  , uint256 usd, uint256 overdraft, uint256 cny, uint256 cnyOverdraft) = accountManage.userAccountMsg(_num);
        assertEq(freezed, 1e20);    
        assertEq(1e23, balance + 1e20);   
    }

    function test_execDebit() public {
        address executor = 0xA82d72F648037c075554882Bd4FBF0C80E950644;
        string memory _userId = "test";
        conf.file(accountUsdExecutor, executor);
        conf.file(accountManageExecutor, executor);
        conf.file(execDeductionExecutor, executor);
        conf.file(0x705f736574746c656d656e740000000000000000000000000000000000000000, 5000); //set p_settlement
        vm.prank(executor);
        address user = 0x70Da4f87fE2E695a058E5CBdB324c0935efd836C;
        accountManage.initUserId(_userId, user);
        uint256 _num = accountManage.userAccountById(_userId);
        vm.deal(user,1e32);
        vm.prank(user);
        accountManage.tokenCharge{value: 1e23}();
        vm.prank(address(1));
        accountManage.freeze(_userId, 1e20, 1);
        (uint256 balance, uint256 freezed,  ,  , , , , ) = accountManage.userAccountMsg(_num);
        assertEq(freezed, 1e20);    
        assertEq(1e23, balance + 1e20);  
        vm.prank(address(1));
        accountManage.execDebit(_userId, 4e19, 3e19, 1);
        (uint256 balance2, uint256 freezed2,  ,  , , , , ) = accountManage.userAccountMsg(_num);
        assertEq(freezed2, freezed - 4e19 - 3e19);    
        assertEq(balance2, balance + 3e19);   
    }

    function test_distributeNmt(uint256 _nmt, uint256 _usd, uint256 _overdraft) public {
        vm.assume(_nmt > 0.1 ether);
        vm.assume(_nmt < 1e30);
        vm.assume(_usd < 1e30);
        vm.assume(_overdraft < 1e30);
        uint256 _price = 10000000000000000000;
        address executor = 0xA82d72F648037c075554882Bd4FBF0C80E950644;
        conf.file(accountUsdExecutor, executor);
        conf.file(accountManageExecutor, executor);
        conf.file(execDeductionExecutor, executor);
        

        accountManage.updateQuota(500);
        _overdraft = _overdraft% 500;
        vm.startPrank(executor);
        address[] memory _addrs = new address[](1);
        _addrs[0] = 0xA82d72F648037c075554882Bd4FBF0C80E950644;
        accountManage.addBlacklist(_addrs);

        address user = 0x70Da4f87fE2E695a058E5CBdB324c0935efd836C;
        accountManage.initUserId("user", user);
        vm.stopPrank();
        vm.deal(user,1e32);
        vm.prank(user);
        accountManage.tokenCharge{value: _nmt}();
        vm.startPrank(executor);
        accountManage.updateAccountUsd("user", "orderId", _usd + 500, true, _price);
        uint a = (_nmt% 10);
        if(a!=0)_nmt = _nmt /a;
        accountManage.execDeduction("user", "orderId2",_nmt,_usd,_overdraft,"test execDeduction");
        if(a!=0){
            _nmt = _nmt /a;
            _usd = _usd /a;
            _overdraft = _overdraft /a;
        }
        vm.stopPrank();

        uint8[] memory vs = new uint8[](2);
        bytes32[] memory rs = new bytes32[](4);
        bytes32 digest = getDigest( "orderId2", _addrs[0], _nmt/3, _nmt/4, block.timestamp + 1 days);
        ( v,  r,  s) = vm.sign(acts1Pk, digest);
        vs[0] = v; rs[0] = r; rs[1] = s;
        (v, r, s) = vm.sign(acts2Pk, digest);
        vs[1] = v; rs[2] = r; rs[3] = s;
        vm.prank(address(1), address(1));
        accountManage.distributeNmt("orderId2", _addrs[0], _nmt/3, _nmt/4, block.timestamp + 1 days, vs, rs);
        assertEq(address(_addrs[0]).balance, _nmt/3);
        assertEq(accountManage.feeTo().balance, _nmt/4);
    }

    function test_distributeUsd(uint256 _usd, uint256 _overdraft) public {
        vm.assume(_usd < 1e5 && _usd > 12);
        vm.assume(_overdraft < 1e30);
        address executor = 0xA82d72F648037c075554882Bd4FBF0C80E950644;
        conf.file(accountUsdExecutor, executor);
        conf.file(accountManageExecutor, executor);
        conf.file(execDeductionExecutor, executor);
        

        accountManage.updateQuota(500);
        _overdraft = _overdraft% 500;
        vm.startPrank(executor);
        address[] memory _addrs = new address[](1);
        _addrs[0] = 0xA82d72F648037c075554882Bd4FBF0C80E950644;
        accountManage.addBlacklist(_addrs);

        address user = 0x70Da4f87fE2E695a058E5CBdB324c0935efd836C;
        accountManage.initUserId("user", user);
        accountManage.updateAccountUsd("user", "orderId", _usd + 500, true, 10000000000000000000);
        accountManage.execDeduction("user", "orderId2",0,_usd,_overdraft,"test execDeduction");
        
        vm.stopPrank();

        uint8[] memory vs = new uint8[](2);
        bytes32[] memory rs = new bytes32[](4);
        bytes32 digest = getDigest( "orderId2", _addrs[0], _usd/3,  _usd/3*1e17, _usd/4,  _usd/4*1e17, block.timestamp + 1 days);
        ( v,  r,  s) = vm.sign(acts1Pk, digest);
        vs[0] = v; rs[0] = r; rs[1] = s;
        (v, r, s) = vm.sign(acts2Pk, digest);
        vs[1] = v; rs[2] = r; rs[3] = s;
        vm.prank(address(1), address(1));
        accountManage.distributeUsd("orderId2", _addrs[0], _usd/3, _usd/3*1e17, _usd/4,  _usd/4*1e17, block.timestamp + 1 days, vs, rs);
        assertEq(address(_addrs[0]).balance, _usd/3*1e17);
        assertEq(accountManage.feeTo().balance, _usd/4*1e17);
    }

    function test_distributeCny(uint256 _cny, uint256 _cnyOverdraft) public {
        vm.assume(_cny < 1e5 && _cny > 12);
        vm.assume(_cnyOverdraft < 1e30);
        address executor = 0xA82d72F648037c075554882Bd4FBF0C80E950644;
        conf.file(accountUsdExecutor, executor);
        conf.file(accountManageExecutor, executor);
        conf.file(execDeductionExecutor, executor);
        accountManage.updateQuotaCny(5000);
        _cnyOverdraft = _cnyOverdraft% 5000;
        vm.startPrank(executor);
        address[] memory _addrs = new address[](1);
        _addrs[0] = 0xA82d72F648037c075554882Bd4FBF0C80E950644;
        accountManage.addBlacklist(_addrs);
        address user = 0x70Da4f87fE2E695a058E5CBdB324c0935efd836C;
        accountManage.initUserId("user", user);
        vm.startPrank(executor);
        accountManage.updateAccountCny("user", "orderId", _cny + 5000, true);
        accountManage.execCnyDeduction("user", "orderId2",_cny,_cnyOverdraft,"execCnyDeduction");
        vm.stopPrank();

        uint8[] memory vs = new uint8[](2);
        bytes32[] memory rs = new bytes32[](4);
        bytes32 digest = getDigest( "orderId2", _addrs[0], _cny/3,  _cny/3*1e17, _cny/4,  _cny/4*1e17, block.timestamp + 1 days);
        ( v,  r,  s) = vm.sign(acts1Pk, digest);
        vs[0] = v; rs[0] = r; rs[1] = s;
        (v, r, s) = vm.sign(acts2Pk, digest);
        vs[1] = v; rs[2] = r; rs[3] = s;
        vm.prank(address(1), address(1));
        accountManage.distributeCny("orderId2", _addrs[0], _cny/3, _cny/3*1e17, _cny/4,  _cny/4*1e17, block.timestamp + 1 days, vs, rs);
        assertEq(address(_addrs[0]).balance, _cny/3*1e17);
        assertEq(accountManage.feeTo().balance, _cny/4*1e17);
    }


    function test_withdrawComputingFee() public {
        address executor = 0xA82d72F648037c075554882Bd4FBF0C80E950644;
        string memory _userId = "test";
        conf.file(accountUsdExecutor, executor);
        conf.file(accountManageExecutor, executor);
        conf.file(execDeductionExecutor, executor);
        conf.file(0x705f736574746c656d656e740000000000000000000000000000000000000000, 5000); //set p_settlement
        vm.prank(executor);
        address user = 0x70Da4f87fE2E695a058E5CBdB324c0935efd836C;
        accountManage.initUserId(_userId, user);
        uint256 _num = accountManage.userAccountById(_userId);
        vm.deal(user,1e32);
        vm.prank(user);
        accountManage.tokenCharge{value: 1e23}();
        vm.prank(address(1));
        accountManage.freeze(_userId, 1e20, 1);
        (uint256 balance, uint256 freezed,  ,  , , , , ) = accountManage.userAccountMsg(_num);
        assertEq(freezed, 1e20);    
        assertEq(1e23, balance + 1e20);  
        vm.prank(address(1));
        accountManage.execDebit(_userId, 4e19, 3e19, 1);
        (uint256 balance2, uint256 freezed2,  ,  , , , , ) = accountManage.userAccountMsg(_num);
        assertEq(freezed2, freezed - 4e19 - 3e19);    
        assertEq(balance2, balance + 3e19);   

        uint8[] memory vs = new uint8[](2);
        bytes32[] memory rs = new bytes32[](4);
        address withdrawUser = 0xC3cAD069A30a58737c3B0B94fA208c5Ce553661b;
        bytes32 digest = getDigest( withdrawUser, 1e19, block.timestamp + 1 days);
        ( v,  r,  s) = vm.sign(acts1Pk, digest);
        vs[0] = v; rs[0] = r; rs[1] = s;
        (v, r, s) = vm.sign(acts2Pk, digest);
        vs[1] = v; rs[2] = r; rs[3] = s;
        vm.prank(withdrawUser, withdrawUser);
        accountManage.withdrawComputingFee(withdrawUser,[1e19, block.timestamp + 1 days], vs, rs);
        assertEq(address(withdrawUser).balance, 1e19);
    }

    function getDigest(address addr, uint256 amt, uint256 expir) internal view returns(bytes32 digest){
        bytes32 hash = keccak256(
            abi.encodePacked(
                '\x19\x01',
                accountManage.DOMAIN_SEPARATOR(),
                keccak256(abi.encode(addr, amt, expir,accountManage.nonce(addr))))
        );
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        digest = keccak256(abi.encodePacked(prefix, hash));
    }

    function getDigest(string memory paymentId, uint256 amt, uint256 expir) internal view returns(bytes32 digest){
        bytes32 hash = keccak256(
            abi.encodePacked(
                '\x19\x01',
                accountManage.DOMAIN_SEPARATOR(),
                keccak256(abi.encode(paymentId, amt, expir)))
        );
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        digest = keccak256(abi.encodePacked(prefix, hash));
    }

    function getDigest(string memory paymentId, address gpu_provider, uint256 gpu_fee, uint256 platform_fee, uint256 expir) internal view returns(bytes32 digest){
        bytes32 hash = keccak256(
            abi.encodePacked(
                '\x19\x01',
                accountManage.DOMAIN_SEPARATOR(),
                keccak256(abi.encode(paymentId, gpu_provider, gpu_fee, platform_fee, expir)))
        );
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        digest = keccak256(abi.encodePacked(prefix, hash));
    }

    function getDigest(string memory paymentId, address gpu_provider, uint256 gpu_fee, uint256 gpu_nmt, uint256 platform_fee, uint256 platform_nmt, uint256 expir) internal view returns(bytes32 digest){
        bytes32 hash = keccak256(
            abi.encodePacked(
                '\x19\x01',
                accountManage.DOMAIN_SEPARATOR(),
                keccak256(abi.encode(paymentId, gpu_provider, gpu_fee, gpu_nmt, platform_fee,platform_nmt, expir)))
        );
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        digest = keccak256(abi.encodePacked(prefix, hash));
    }

}
