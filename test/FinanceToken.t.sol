// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {FinanceToken} from "contracts/FinanceToken.sol";
import "contracts/proxy/FinanceToken_proxy.sol";
import "./interfaces/IFinanceToken.sol";
import "contracts/proxy/NetMindToken_proxy.sol";
import "./interfaces/INetmindToken.sol";
import {NetMindToken} from "contracts/NetmindToken.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract PayToken is ERC20 {
    constructor() ERC20("Payment Token", "PAY") {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}



contract FinanceTokenTest is Test {
    IFinanceToken financeToken;
    INetMindToken nmtToken;
    PayToken paymentToken;

    //address paymentToken;
    address user1 = address(0x5678);
    address user2 = address(0x9abc);
    address buyer = address(0x19abc);


    uint256 investmentPeriod = 30;
    uint256 unlockIntervalDays = 30;
    uint256 unlockPercentage = 20;
    uint256 sellNMTQuantity = 1e22;
    address tokenReceiveAddress = address(0x1111);
    uint256 paymentPrice = 1e20;

    function setUp() public {
        nmtToken = INetMindToken(address(new NetMindTokenProxy(address(new NetMindToken()))));
        nmtToken.initialize(address(this), address(this));
    
        financeToken = IFinanceToken(address(new FinanceTokenProxy(address(new FinanceToken()))));
        financeToken.initialize(address(nmtToken));

        paymentToken = new PayToken();
    }
    
    function testLaunch() public {
        deal(address(nmtToken), user1, sellNMTQuantity);
        vm.startPrank(user1);
        nmtToken.approve(address(financeToken), sellNMTQuantity);
        financeToken.launch(investmentPeriod, unlockIntervalDays, unlockPercentage, sellNMTQuantity, tokenReceiveAddress, address(paymentToken), paymentPrice);
        (address sponsor, uint256 endTime, uint256 unlockInterval, uint256 percentage, , , , , uint256 soldQuantity) = financeToken.financeMsg(1);
        assertEq(sponsor, user1, "Sponsor address in financeMsg should match user1");
        assertEq(endTime, block.timestamp + investmentPeriod * 1 days, "End time in financeMsg should be correct");
        assertEq(unlockInterval, unlockIntervalDays * 1 days, "Unlock interval days in financeMsg should be correct");
        assertEq(percentage, unlockPercentage, "Unlock percentage in financeMsg should be correct");
        assertEq(soldQuantity, 0, "Sold NMT quantity in financeMsg should initially be zero");
        vm.stopPrank();
    }

    function testPurchaseNMTWithETH() public payable {
        nmtToken.mint(user1, sellNMTQuantity);
        vm.startPrank(user1);
        nmtToken.approve(address(financeToken), sellNMTQuantity);
        financeToken.launch(investmentPeriod, unlockIntervalDays, unlockPercentage, sellNMTQuantity, tokenReceiveAddress, address(0), paymentPrice);
        vm.stopPrank();
        uint financingId = financeToken.financingId();
        uint256 amountToSend = 10 ether;
        vm.deal(buyer, amountToSend);
        vm.prank(buyer);
        financeToken.purchaseNMTWithETH{value: amountToSend}(financingId);
        uint purchaseNumber = financeToken.purchaseNumber();
        (address user, uint256 startTime, uint256 unlockIntervalUser, uint256 percentageUser, uint256 withdrawnAmount, uint256 purchaseQuantity) = financeToken.userMsg(purchaseNumber);
        assertEq(user, buyer, "User in userMsg should be user1 after purchase with ETH");
        assertEq(unlockIntervalUser, unlockIntervalDays * 1 days, "Unlock interval days in userMsg should be correct after purchase with ETH");
        assertEq(percentageUser, unlockPercentage, "Unlock percentage in userMsg should be correct after purchase with ETH");
        assertEq(withdrawnAmount, 0, "Withdrawn amount in userMsg should initially be zero after purchase with ETH");
        assertEq(purchaseQuantity, purchaseQuantity, "Purchase NMT quantity in userMsg should be correct after purchase with ETH");
        (, , , , , , , , uint256 soldQuantity) = financeToken.financeMsg(financingId);
        assertEq(soldQuantity, purchaseQuantity, "Sold NMT quantity in financeMsg should be updated after purchase with ETH");
        
    }

    function testWithdrawNMTToken() public {
        nmtToken.mint(user1, sellNMTQuantity);
        vm.startPrank(user1);
        nmtToken.approve(address(financeToken), sellNMTQuantity);
        financeToken.launch(investmentPeriod, unlockIntervalDays, unlockPercentage, sellNMTQuantity, tokenReceiveAddress, address(0), paymentPrice);
        vm.stopPrank();
        uint financingId = financeToken.financingId();
        uint256 amountToSend = 10 ether;
        vm.deal(buyer, amountToSend);
        vm.startPrank(buyer);
        financeToken.purchaseNMTWithETH{value: amountToSend}(financingId);
        uint purchaseNumber = financeToken.purchaseNumber();
        ( , uint256 startTime, uint256 unlockIntervalUser, uint256 percentageUser, uint256 withdrawnAmount, uint256 purchaseQuantity) = financeToken.userMsg(purchaseNumber);
        vm.warp(block.timestamp + 65 days);
        uint256[] memory rs = new uint256[](1);
        rs[0] = purchaseNumber;
        assertEq(nmtToken.balanceOf(buyer), 0);
        financeToken.withdrawNMTToken(rs);
        assertEq(nmtToken.balanceOf(buyer), (purchaseQuantity * unlockPercentage) * (startTime / 86400 / unlockIntervalDays) / 100, "Withdrawn amount in userMsg should be updated after withdrawal");

        vm.warp(block.timestamp + 151 days);
        rs[0] = purchaseNumber;
        financeToken.withdrawNMTToken(rs);
        vm.stopPrank();
        assertEq(nmtToken.balanceOf(buyer), purchaseQuantity, "Withdrawn amount in userMsg should be updated after withdrawal");
       
    }

    function testRefund() public {
        nmtToken.mint(user1, sellNMTQuantity);
        vm.startPrank(user1);
        nmtToken.approve(address(financeToken), sellNMTQuantity);
        financeToken.launch(investmentPeriod, unlockIntervalDays, unlockPercentage, sellNMTQuantity, tokenReceiveAddress, address(0), paymentPrice);
        vm.stopPrank();
        uint financingId = financeToken.financingId();
        uint256 amountToSend = 10 ether;
        vm.deal(buyer, amountToSend);
        vm.startPrank(buyer);
        financeToken.purchaseNMTWithETH{value: amountToSend}(financingId);
        vm.stopPrank();
        uint256 bal  = nmtToken.balanceOf(user1);
        ( ,  ,  ,  , uint256 sellNMTQuantity,  ,  ,  , uint256 soldNMTQuantity)  = financeToken.financeMsg(financingId);
        vm.warp(block.timestamp + 32 days);
        vm.prank(user1);
        financeToken.refund(financingId);
        assertEq(nmtToken.balanceOf(user1), bal + sellNMTQuantity - soldNMTQuantity);
        (,,,,,,,, uint256 soldQuantity) = financeToken.financeMsg(financingId);
        assertEq(soldQuantity, sellNMTQuantity, "Sold NMT quantity in financeMsg should be updated after refund");
    }

    function testPurchaseNMTWithToken() public {
        nmtToken.mint(user1, sellNMTQuantity);
        vm.startPrank(user1);
        nmtToken.approve(address(financeToken), sellNMTQuantity);
        financeToken.launch(investmentPeriod, unlockIntervalDays, unlockPercentage, sellNMTQuantity, tokenReceiveAddress, address(paymentToken), paymentPrice);
        vm.stopPrank();
        uint financingId = financeToken.financingId();
        uint256 amountToSend = 10 ether;
        deal(address(paymentToken), buyer, amountToSend);
        vm.prank(buyer);
        paymentToken.approve(address(financeToken), amountToSend);
        vm.prank(buyer);
        financeToken.purchaseNMTWithToken(financingId, address(paymentToken), amountToSend);
        uint purchaseNumber = financeToken.purchaseNumber();
        (address user, uint256 startTime, uint256 unlockIntervalUser, uint256 percentageUser, uint256 withdrawnAmount, uint256 purchaseQuantity) = financeToken.userMsg(purchaseNumber);
        assertEq(user, buyer, "User in userMsg should be user1 after purchase with ETH");
        assertEq(unlockIntervalUser, unlockIntervalDays * 1 days, "Unlock interval days in userMsg should be correct after purchase with ETH");
        assertEq(percentageUser, unlockPercentage, "Unlock percentage in userMsg should be correct after purchase with ETH");
        assertEq(withdrawnAmount, 0, "Withdrawn amount in userMsg should initially be zero after purchase with ETH");
        assertEq(purchaseQuantity, purchaseQuantity, "Purchase NMT quantity in userMsg should be correct after purchase with ETH");
        (, , , , , , , , uint256 soldQuantity) = financeToken.financeMsg(financingId);
        assertEq(soldQuantity, purchaseQuantity, "Sold NMT quantity in financeMsg should be updated after purchase with ETH");
        
    }

    function testWithdrawNMTToken2() public {
        nmtToken.mint(user1, sellNMTQuantity);
        vm.startPrank(user1);
        nmtToken.approve(address(financeToken), sellNMTQuantity);
        financeToken.launch(investmentPeriod, unlockIntervalDays, unlockPercentage, sellNMTQuantity, tokenReceiveAddress, address(paymentToken), paymentPrice);
        vm.stopPrank();
        uint financingId = financeToken.financingId();
        uint256 amountToSend = 10 ether;
        deal(address(paymentToken), buyer, amountToSend);
        vm.startPrank(buyer);
        paymentToken.approve(address(financeToken), amountToSend);
        financeToken.purchaseNMTWithToken(financingId, address(paymentToken), amountToSend);
        uint purchaseNumber = financeToken.purchaseNumber();
        ( , uint256 startTime, uint256 unlockIntervalUser, uint256 percentageUser, uint256 withdrawnAmount, uint256 purchaseQuantity) = financeToken.userMsg(purchaseNumber);
        vm.warp(block.timestamp + 65 days);
        uint256[] memory rs = new uint256[](1);
        rs[0] = purchaseNumber;
        assertEq(nmtToken.balanceOf(buyer), 0);
        financeToken.withdrawNMTToken(rs);
        assertEq(nmtToken.balanceOf(buyer), (purchaseQuantity * unlockPercentage) * (startTime / 86400 / unlockIntervalDays) / 100, "Withdrawn amount in userMsg should be updated after withdrawal");

        vm.warp(block.timestamp + 151 days);
        rs[0] = purchaseNumber;
        financeToken.withdrawNMTToken(rs);
        vm.stopPrank();
        assertEq(nmtToken.balanceOf(buyer), purchaseQuantity, "Withdrawn amount in userMsg should be updated after withdrawal");
       
    }

    function testRefund2() public {
        nmtToken.mint(user1, sellNMTQuantity);
        vm.startPrank(user1);
        nmtToken.approve(address(financeToken), sellNMTQuantity);
        financeToken.launch(investmentPeriod, unlockIntervalDays, unlockPercentage, sellNMTQuantity, tokenReceiveAddress, address(paymentToken), paymentPrice);
        vm.stopPrank();
        uint financingId = financeToken.financingId();
        uint256 amountToSend = 10 ether;
        deal(address(paymentToken), buyer, amountToSend);
        vm.startPrank(buyer);
        paymentToken.approve(address(financeToken), amountToSend);
        financeToken.purchaseNMTWithToken(financingId, address(paymentToken), amountToSend);
        vm.stopPrank();
        uint256 bal  = nmtToken.balanceOf(user1);
        ( ,  ,  ,  , uint256 sellNMTQuantity,  ,  ,  , uint256 soldNMTQuantity)  = financeToken.financeMsg(financingId);
        vm.warp(block.timestamp + 32 days);
        vm.prank(user1);
        financeToken.refund(financingId);
        assertEq(nmtToken.balanceOf(user1), bal + sellNMTQuantity - soldNMTQuantity);
        (,,,,,,,, uint256 soldQuantity) = financeToken.financeMsg(financingId);
        assertEq(soldQuantity, sellNMTQuantity, "Sold NMT quantity in financeMsg should be updated after refund");
    }



}