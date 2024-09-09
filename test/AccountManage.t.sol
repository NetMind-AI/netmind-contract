// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

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
        accountManage.init(address(ConfInit));
    }

    function test_updateSignNum() public {
        accountManage.updateSignNum(3);
        assertEq(accountManage.signNum(), 3);
    }

}
