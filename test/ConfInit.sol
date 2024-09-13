// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Conf} from "../contracts/Conf.sol";
import {ConfProxy} from "../contracts/proxy/Conf_proxy.sol";
import {IConf} from "./interfaces/IConf.sol";


contract ConfInit is Test {
    IConf public conf;
    bytes32 public accountManageExecutor = 0x4163636f756e744d616e6167654578656375746f720000000000000000000000;
    bytes32 public trainingTaskExecutor = 0x547261696e696e675461736b4578656375746f72000000000000000000000000;
    bytes32 public accountUsdExecutor = 0x6163636f756e745573644578656375746f720000000000000000000000000000;
    bytes32 public execDeductionExecutor = 0x65786563446564756374696f6e4578656375746f720000000000000000000000;
    bytes32 public N = 0x4e00000000000000000000000000000000000000000000000000000000000000;
    


    function init() public {
        Conf confImp = new Conf();
        ConfProxy confProxy = new ConfProxy(address(confImp));

        conf = IConf(address(confProxy));
        conf.initialize();
    }


}
