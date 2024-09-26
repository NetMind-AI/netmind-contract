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


    uint256 investmentPeriod = 30;
    uint256 unlockIntervalDays = 30;
    uint256 unlockPercentage = 20;
    uint256 sellNMTQuantity = 1000;
    address tokenReceiveAddress = address(0x1111);
    uint256 paymentPrice = 10;

    function setUp() public {
        nmtToken = INetMindToken(address(new NetMindTokenProxy(address(new NetMindToken()))));
        nmtToken.initialize(address(this), address(this));
    
        financeToken = IFinanceToken(address(new FinanceTokenProxy(address(new FinanceToken()))));
        financeToken.initialize(address(nmtToken));

        paymentToken = new PayToken();
    }
    
    function testLaunch() public {
        nmtToken.mint(user1, sellNMTQuantity);
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

        uint256 amountToSend = 10 ether;
        vm.deal(user1, amountToSend);
        vm.expectEmit(true, true, true, true);
        emit FinanceToken.PurchaseNMTWithToken(2, user1, amountToSend * paymentPrice / 10**18, address(0), amountToSend * paymentPrice / 10**18);
        financeToken.purchaseNMTWithETH{value: amountToSend}(1);
        (address user, uint256 startTime, uint256 unlockIntervalUser, uint256 percentageUser, uint256 withdrawnAmount, uint256 purchaseQuantity) = financeToken.userMsg(2);
        assertEq(user, user1, "User in userMsg should be user1 after purchase with ETH");
        assertEq(unlockIntervalUser, unlockIntervalDays * 1 days, "Unlock interval days in userMsg should be correct after purchase with ETH");
        assertEq(percentageUser, unlockPercentage, "Unlock percentage in userMsg should be correct after purchase with ETH");
        assertEq(withdrawnAmount, 0, "Withdrawn amount in userMsg should initially be zero after purchase with ETH");
        assertEq(purchaseQuantity, amountToSend * paymentPrice / 10**18, "Purchase NMT quantity in userMsg should be correct after purchase with ETH");
        (, , , , , , , , uint256 soldQuantity) = financeToken.financeMsg(1);
        assertEq(soldQuantity, amountToSend * paymentPrice / 10**18, "Sold NMT quantity in financeMsg should be updated after purchase with ETH");
        vm.stopPrank();
    }

    function testPurchaseNMTWithToken() public {
        vm.startPrank(user1);
        financeToken.launch(investmentPeriod, unlockIntervalDays, unlockPercentage, sellNMTQuantity, tokenReceiveAddress, address(paymentToken), paymentPrice);
        paymentToken.mint(user1, 1000);
        vm.expectEmit(true, true, true, true);
        emit FinanceToken.PurchaseNMTWithToken(3, user1, 1000 * paymentPrice / 10**18, address(paymentToken), 1000 * paymentPrice / 10**18);
        financeToken.purchaseNMTWithToken(1, address(paymentToken), 1000);
        (address user, uint256 startTime, uint256 unlockIntervalUser, uint256 percentageUser, uint256 withdrawnAmount, uint256 purchaseQuantity) = financeToken.userMsg(3);
        assertEq(user, user1, "User in userMsg should be user1 after purchase with token");
        assertEq(unlockIntervalUser, unlockIntervalDays * 1 days, "Unlock interval days in userMsg should be correct after purchase with token");
        assertEq(percentageUser, unlockPercentage, "Unlock percentage in userMsg should be correct after purchase with token");
        assertEq(withdrawnAmount, 0, "Withdrawn amount in userMsg should initially be zero after purchase with token");
        assertEq(purchaseQuantity, 1000 * paymentPrice / 10**18, "Purchase NMT quantity in userMsg should be correct after purchase with token");
        (,,,,,,,,uint256 soldQuantity) = financeToken.financeMsg(1);
        assertEq(soldQuantity, 1000 * paymentPrice / 10**18, "Sold NMT quantity in financeMsg should be updated after purchase with token");
        vm.stopPrank();
    }

    function testWithdrawNMTToken() public {
        vm.startPrank(user1);
        financeToken.launch(investmentPeriod, unlockIntervalDays, unlockPercentage, sellNMTQuantity, tokenReceiveAddress, address(paymentToken), paymentPrice); 
        financeToken.purchaseNMTWithToken(1, address(paymentToken), 1000);
        uint256[] memory purchaseNumbers = new uint256[](1);
        purchaseNumbers[0] = 4;
        vm.expectEmit(true, true, true, true);
        emit FinanceToken.WithdrawNMTToken(4, 10);
        financeToken.withdrawNMTToken(purchaseNumbers);
        (address user, uint256 startTime, uint256 unlockIntervalUser, uint256 percentageUser, uint256 withdrawnAmount, uint256 purchaseQuantity) = financeToken.userMsg(4);
        assertEq(withdrawnAmount, 10, "Withdrawn amount in userMsg should be updated after withdrawal");
        vm.stopPrank();
    }

    function testRefund() public {
        vm.startPrank(user1);
        financeToken.launch(investmentPeriod, unlockIntervalDays, unlockPercentage, sellNMTQuantity, tokenReceiveAddress, address(paymentToken), paymentPrice);
        vm.warp(block.timestamp + investmentPeriod * 1 days + 1);
        vm.expectEmit(true, true, true, true);
        emit FinanceToken.Refund(1, sellNMTQuantity);
        financeToken.refund(1);
        (,,,,,,,, uint256 soldQuantity) = financeToken.financeMsg(1);
        assertEq(soldQuantity, sellNMTQuantity, "Sold NMT quantity in financeMsg should be updated after refund");
        vm.stopPrank();
    }
}