// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Ledger} from "../contracts/Ledger.sol";
import {LedgerProxy} from "../contracts/proxy/Ledger_proxy.sol";
import {ILedgerInterface} from "./interfaces/ILedger.sol";
import {ConfInit} from "./ConfInit.sol";


contract LedgerTest is ConfInit {
    ILedgerInterface public ledger;
    address acts1 = address(123);
    address acts2 = address(456);

    function setUp() public {
        ConfInit.init();
        conf.file(acts1,true);
        conf.file(acts2,true);
        ledger = ILedgerInterface(address(new LedgerProxy(address(new Ledger()))));
        ledger.init(address(conf));
    }


    function test_updateLedger() public {
        address[] memory _userAddrs = new address[](2);
        _userAddrs[0] = address(1); _userAddrs[1] = address(2); 
        uint256[] memory _nonces = new uint256[](2);
        _nonces[0] = 1;_nonces[1] = 1; 
        address[] memory _tokenAddrs = new address[](2);
        _tokenAddrs[0] = address(999); _tokenAddrs[1] = address(999); 
        uint256[] memory _amounts = new uint256[](2);
        _amounts[0] = 3e20; _amounts[1] = 4e21; 
        string[] memory _txHashs = new string[](2);
        _txHashs[0] = "hash1"; _txHashs[1] = "hash2"; 

        vm.prank(acts1);
        ledger.updateLedger(_userAddrs, _nonces, _tokenAddrs, _amounts, _txHashs);
        vm.prank(acts2);
        ledger.updateLedger(_userAddrs, _nonces, _tokenAddrs, _amounts, _txHashs);
        (bool consensusSta, uint256 nodeVoteNum, , address token, uint256 amount, string memory txHash, ) = ledger.queryVotes(_userAddrs[0], _nonces[0]);
        assertTrue(consensusSta);
        assertEq(nodeVoteNum, 2);
        assertEq(token, _tokenAddrs[0]);
        assertEq(amount, _amounts[0]);
        assertEq(txHash, _txHashs[0]);
        ( consensusSta, nodeVoteNum, ,  token, amount, txHash, ) = ledger.queryVotes(_userAddrs[1], _nonces[1]);
        assertTrue(consensusSta);
        assertEq(nodeVoteNum, 2);
        assertEq(token, _tokenAddrs[0]);
        assertEq(amount, _amounts[1]);
        assertEq(txHash, _txHashs[1]);
        
    }




}
