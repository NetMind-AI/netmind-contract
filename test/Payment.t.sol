// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Payment} from "../contracts/Payment.sol";
import {PaymentProxy} from "../contracts/proxy/Payment_proxy.sol";
import {IPayment} from "./interfaces/IPayment.sol";
import {FiatoSettle} from "../contracts/FiatoSettle.sol";
import {FiatoSettleProxy} from "../contracts/proxy/FiatoSettle_proxy.sol";
import {IFiatoSettle} from "./interfaces/IFiatoSettle.sol";
import {ConfInit} from "./ConfInit.sol";


contract PaymentTest is ConfInit {
    IPayment public payment;
    IFiatoSettle public fiatoSettle;
    address public owner = 0x2cD77303737430D78F5a5FbCf8B8f8064d2a92a9;
    address public agent = 0x3c59211297F9E3215E60BC02B4A8Ec3A78Eca169;
    address public payer = 0xb14969273A5EDB552fC6F9463D0E7496c0DF9802;
    
    uint256 acts1Pk = 0x8f71bc2fcff2b84fe9c56f1c8b292555ad0a0441749af588f0d39893ac97ba20;
    address acts1 = vm.addr(acts1Pk);
    uint256 acts2Pk = 0x8f71bc3fcff2b84fe9c56f1c8b292555ad0a0441749af588f0d39893ac97ba20;
    address acts2 = vm.addr(acts2Pk);
        
    function setUp() public {
        vm.startPrank(owner);
        ConfInit.init();
        conf.file(acts1,true);
        conf.file(acts2,true);
        
        payment = IPayment(address(new PaymentProxy(address(new Payment()))));
        fiatoSettle = IFiatoSettle(address(new FiatoSettleProxy(address(new FiatoSettle()))));
        fiatoSettle.init(address(payment));
        vm.deal(address(fiatoSettle), 10 ether);
        payment.init(address(conf),1);
        payment.setAgent(agent); 
        payment.setCleaner(address(fiatoSettle)); 
        vm.stopPrank();
    }

    function testOwner() public {
        assertEq(payment.owner(), owner);
    }

    function testWhiteList(address addr) public {
        address[] memory _addrs = new address[](2);
        vm.startPrank(agent);
        _addrs[0] = 0x70Da4f87fE2E695a058E5CBdB324c0935efd836C;
        _addrs[1] = 0x2cD77303737430D78F5a5FbCf8B8f8064d2a92a9;
        payment.setWhiteList(_addrs);
        address[] memory getWhiteList = payment.getWhiteList();
        for (uint256 i = 0; i< getWhiteList.length; i++){
            assertEq(getWhiteList[i], _addrs[i]);
        }
        vm.stopPrank();
    }

    function test_Payment() public {
        vm.deal(payer, 1 ether); 
        vm.prank(payer, payer); 
        payment.payment{value: 1 ether}("payment1", 1 ether, 1000);

        (address payerAddress, uint256 amount, uint256 worth, , , ) = payment.recipts("payment1");
        assertEq(payerAddress, payer);
        assertEq(amount, 1 ether);
        assertEq(worth, 1000);
    }

    function test_AgentPayment() public {
        vm.prank(agent, agent); 
        payment.agentPayment("payment1", "paycode1", 1000);

        (string memory paycode, uint256 worth, , ) = payment.agentRecipts("payment1");
        assertEq(paycode, "paycode1");
        assertEq(worth, 1000);
    }

    function test_Refund() public {
        vm.deal(payer, 1 ether);
        vm.prank(payer, payer);
        payment.payment{value: 1 ether}("payment1", 1 ether, 1000);

        uint8[] memory vs = new uint8[](2);
        bytes32[] memory rs = new bytes32[](4);

        bytes32 digest = getDigest("payment1", 0.5 ether, block.timestamp + 1 days);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(acts1Pk, digest);
        vs[0] = v; rs[0] = r; rs[1] = s;
        (v, r, s) = vm.sign(acts2Pk, digest);
        vs[1] = v; rs[2] = r; rs[3] = s;
        vm.prank(owner, owner);
        payment.refund("payment1", 0.5 ether, block.timestamp + 1 days, vs, rs);

        (, , , uint256 refundAmt, , ) = payment.recipts("payment1");
        assertEq(refundAmt, 0.5 ether);
    }
   
    function test_Distribute() public {
        vm.deal(payer, 1 ether);
        vm.prank(payer, payer);
        payment.payment{value: 1 ether}("payment1", 1 ether, 1000);

        address[] memory _addrs = new address[](2);
        vm.prank(agent);
        _addrs[0] = 0x70Da4f87fE2E695a058E5CBdB324c0935efd836C;
        _addrs[1] = 0x2cD77303737430D78F5a5FbCf8B8f8064d2a92a9;
        payment.setWhiteList(_addrs);

        uint8[] memory vs = new uint8[](2);
        bytes32[] memory rs = new bytes32[](4);

        bytes32 digest = getDigest("payment1", 0x2cD77303737430D78F5a5FbCf8B8f8064d2a92a9, 0.5 ether, 0.1 ether, block.timestamp + 1 days);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(acts1Pk, digest);
        vs[0] = v; rs[0] = r; rs[1] = s;
        (v, r, s) = vm.sign(acts2Pk, digest);
        vs[1] = v; rs[2] = r; rs[3] = s;
        vm.prank(owner, owner);

        payment.distribute("payment1", 0x2cD77303737430D78F5a5FbCf8B8f8064d2a92a9, 0.5 ether, 0.1 ether, block.timestamp + 1 days, vs, rs);

        (, , , , , uint256 distributedAmt) = payment.recipts("payment1");
        assertEq(distributedAmt, 0.6 ether); 
        assertEq(0x2cD77303737430D78F5a5FbCf8B8f8064d2a92a9.balance, 0.5 ether);
        assertEq(fiatoSettle.burnAddr().balance, 0.1 ether); 
    }

    function test_agentDistribute() public {
        vm.deal(payer, 1 ether);
        vm.prank(agent, agent); 
        payment.agentPayment("payment1", "paycode1", 1000);

        address[] memory _addrs = new address[](2);
        vm.prank(agent);
        _addrs[0] = 0x70Da4f87fE2E695a058E5CBdB324c0935efd836C;
        _addrs[1] = 0x2cD77303737430D78F5a5FbCf8B8f8064d2a92a9;
        payment.setWhiteList(_addrs);

        uint8[] memory vs = new uint8[](2);
        bytes32[] memory rs = new bytes32[](4);

        bytes32 digest = getDigest("payment1", 0x2cD77303737430D78F5a5FbCf8B8f8064d2a92a9, 500, 0.5 ether, 100, 0.1 ether, block.timestamp + 1 days);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(acts1Pk, digest);
        vs[0] = v; rs[0] = r; rs[1] = s;
        (v, r, s) = vm.sign(acts2Pk, digest);
        vs[1] = v; rs[2] = r; rs[3] = s;
        vm.prank(owner, owner);

        payment.agentDistribute("payment1", 0x2cD77303737430D78F5a5FbCf8B8f8064d2a92a9, 500, 0.5 ether, 100, 0.1 ether, block.timestamp + 1 days, vs, rs);

        (, , , uint256 distributedAmt) = payment.agentRecipts("payment1");
        assertEq(distributedAmt, 600); 
        assertEq(0x2cD77303737430D78F5a5FbCf8B8f8064d2a92a9.balance, 0.5 ether);
        assertEq(fiatoSettle.burnAddr().balance, 0.1 ether); 
    }

    function getDigest(string memory paymentId, uint256 amt, uint256 expir) internal view returns(bytes32 digest){
        bytes32 hash = keccak256(
            abi.encodePacked(
                '\x19\x01',
                payment.DOMAIN_SEPARATOR(),
                keccak256(abi.encode(paymentId, amt, expir)))
        );
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        digest = keccak256(abi.encodePacked(prefix, hash));
    }

    function getDigest(string memory paymentId, address gpu_provider, uint256 gpu_fee, uint256 platform_fee, uint256 expir) internal view returns(bytes32 digest){
        bytes32 hash = keccak256(
            abi.encodePacked(
                '\x19\x01',
                payment.DOMAIN_SEPARATOR(),
                keccak256(abi.encode(paymentId, gpu_provider, gpu_fee, platform_fee, expir)))
        );
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        digest = keccak256(abi.encodePacked(prefix, hash));
    }

    function getDigest(string memory paymentId, address gpu_provider, uint256 gpu_fee, uint256 gpu_nmt, uint256 platform_fee, uint256 platform_nmt, uint256 expir) internal view returns(bytes32 digest){
        bytes32 hash = keccak256(
            abi.encodePacked(
                '\x19\x01',
                payment.DOMAIN_SEPARATOR(),
                keccak256(abi.encode(paymentId, gpu_provider, gpu_fee, gpu_nmt, platform_fee,platform_nmt, expir)))
        );
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        digest = keccak256(abi.encodePacked(prefix, hash));
    }


}
