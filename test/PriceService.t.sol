// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {PriceService} from "../contracts/PriceService.sol";
import {PriceServiceProxy} from "../contracts/proxy/PriceService_proxy.sol";
import {IPriceService} from "./interfaces/IPriceService.sol";
import {ConfInit} from "./ConfInit.sol";


contract PriceServiceTest is ConfInit {
    IPriceService public priceService;
    address public owner = 0x2cD77303737430D78F5a5FbCf8B8f8064d2a92a9;
    address user = 0x70Da4f87fE2E695a058E5CBdB324c0935efd836C;
    address executor = 0xA82d72F648037c075554882Bd4FBF0C80E950644;

    function setUp() public {
        vm.startPrank(owner);
        ConfInit.init();
        conf.file(priceServiceExecutor, executor);

        priceService = IPriceService(address(new PriceServiceProxy(address(new PriceService()))));
        priceService.init(address(conf));
        vm.stopPrank();
    }


    function testOwner() public {
        assertEq(priceService.owner(), owner);
    }

    function test_updatePrice() public {
        vm.prank(executor);
        priceService.updatePrice(1e21);
        uint256 price = priceService.queryPrice();
        assertEq(price, 1e21);

    }




}
