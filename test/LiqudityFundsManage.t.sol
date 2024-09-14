// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {LiquidityFundsManage, IPancakeRouter02, IERC20} from "../contracts/LiquidityFundsManage.sol";
import {LiquidityFundsManageProxy} from "../contracts/proxy/LiquidityFundsManage_proxy.sol";
import {ILiquidityFundsManage} from "./interfaces/ILiquidityFundsManage.sol";



contract LiqudityFundsManageTest is Test {
    ILiquidityFundsManage public liquidityFundsManage;
    address public owner = 0x0551fB497B436fdBDB6109B6F8c4949C7e16b6ac;
    IPancakeRouter02 router = IPancakeRouter02(0xCc7aDc94F3D80127849D2b41b6439b7CF1eB4Ae0);
    IERC20 usdc = IERC20(0x7E8B81D247A14610768B4A94855D99b5215A8A76);
    IERC20 nmt = IERC20(0x1656bEcA3704a9E1269fc45f221D9718dDecb952);
    address pair = 0xCb89b92d1f9a46FfC7B986B76e76DC1C2267e1fd;

    function setUp() public {
        vm.createSelectFork("bscTest", 43853077);
        vm.startPrank(owner);
        liquidityFundsManage = ILiquidityFundsManage(address(new LiquidityFundsManageProxy(address(new LiquidityFundsManage()))));
        liquidityFundsManage.init(address(nmt), address(usdc), address(router), pair, 18);
        vm.stopPrank();
    }

    function testOwner() public {
        assertEq(liquidityFundsManage.owner(), owner);
    }

  





}
