// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Snapshoot} from "../contracts/Snapshoot.sol";
import {SnapshootProxy} from "../contracts/proxy/Snapshoot_proxy.sol";
import {ISnapshootInterface} from "./interfaces/ISnapshoot.sol";
import {ConfInit} from "./ConfInit.sol";


contract SnapshootTest is ConfInit {
    ISnapshootInterface public snapshoot;

    uint256 acts1Pk = 0x8f71bc2fcff2b84fe9c56f1c8b292555ad0a0441749af588f0d39893ac97ba20;
    address acts1 = vm.addr(acts1Pk);
    uint256 acts2Pk = 0x8f71bc3fcff2b84fe9c56f1c8b292555ad0a0441749af588f0d39893ac97ba20;
    address acts2 = vm.addr(acts2Pk);
    uint8 v; bytes32 r; bytes32 s;

    function setUp() public {
        ConfInit.init();
        conf.file(acts1,true);
        conf.file(acts2,true);

        snapshoot = ISnapshootInterface(address(new SnapshootProxy(address(new Snapshoot()))));
        snapshoot.init(address(conf));
    }


    function test_updateSnapshoot() public {
        vm.warp(86400 *100);
        uint256[] memory _types = new uint256[](1);
        _types[0] = 1; 
        uint256[] memory _days = new uint256[](1);
        _days[0] = 55; 
        string[] memory _dataHashs = new string[](1);
        _dataHashs[0] = "5602a2aadc620fc8fa8417af505a3ff5"; 
        string[] memory _dataIds = new string[](1);
        _dataIds[0] = "bafybeibi56bthi6qyjxikiwb63l7chdn7yzeulqht7fwvidfu63z6op2q4";  
        
        vm.prank(acts1);
        snapshoot.updateSnapshoot(_types, _days, _dataHashs, _dataIds);
        vm.prank(acts2);
        snapshoot.updateSnapshoot(_types, _days, _dataHashs, _dataIds);
        (, uint256 consensusSta, , , , , string memory dataId, string memory dataHash, ) = snapshoot.queryVotes(1, 55);
        assertEq(consensusSta, 1);
        assertEq(dataId, _dataIds[0]);
        assertEq(dataHash, _dataHashs[0]);

    }

   


}
