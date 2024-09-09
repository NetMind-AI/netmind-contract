// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Conf} from "../contracts/Conf.sol";
import {ConfProxy} from "../contracts/proxy/Conf_proxy.sol";
import {IConf} from "./interfaces/IConf.sol";


contract ConfInit is Test {
    IConf public conf;

    function init() public {
        Conf confImp = new Conf();
        ConfProxy confProxy = new ConfProxy(address(confImp));

        conf = IConf(address(confProxy));
        conf.initialize();
    }

//    function test_wards() public {
//        conf.rely(0x3De7202890dD9Ad70a7A6ad832803F96993fD341);
//        assertEq(conf.wards(0x3De7202890dD9Ad70a7A6ad832803F96993fD341), 1);
//    }

}
