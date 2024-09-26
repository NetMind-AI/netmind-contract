// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IFinanceToken {
    struct UserMsg {
        address user;
        uint256 startTime;
        uint256 unlockIntervalDays;
        uint256 unlockPercentage;
        uint256 withdrawnAmount;
        uint256 purchaseNMTQuantity;
    }
    event Launch( uint256 indexed financingId,address indexed sponsor ) ;
    event PurchaseNMTWithToken( uint256 _purchaseNumber,address _sender,uint256 _purchaseNMTQuantity,address _paymentToken,uint256 _paymentTokenAmount ) ;
    event Refund( uint256 _financingId,uint256 amount ) ;
    event WithdrawNMTToken( uint256 _purchaseNumber,uint256 withdrawAmount ) ;
    function day(  ) external view returns (uint256 ) ;
    function financeMsg( uint256  ) external view returns (address sponsor, uint256 endTime, uint256 unlockIntervalDays, uint256 unlockPercentage, uint256 sellNMTQuantity, address tokenReceiveAddress, address paymentToken, uint256 paymentPrice, uint256 soldNMTQuantity) ;
    function financingId(  ) external view returns (uint256 ) ;
    function initialize( address _nmtToken ) external   ;
    function launch( uint256 investmentPeriod,uint256 unlockIntervalDays,uint256 unlockPercentage,uint256 sellNMTQuantity,address tokenReceiveAddress,address paymentToken,uint256 paymentPrice ) external   ;
    function nmtToken(  ) external view returns (address ) ;
    function purchaseNMTWithETH( uint256 _financingId ) external payable  ;
    function purchaseNMTWithToken( uint256 _financingId,address _paymentToken,uint256 _paymentAmount ) external;
    function purchaseNumber(  ) external view returns (uint256 ) ;
    function queryUserMsg( address _userAddr ) external view returns (uint256[] memory , uint256[] memory , UserMsg[] memory ) ;
    function refund( uint256 _financingId ) external   ;
    function userMsg( uint256  ) external view returns (address user, uint256 startTime, uint256 unlockIntervalDays, uint256 unlockPercentage, uint256 withdrawnAmount, uint256 purchaseNMTQuantity) ;
    function withdrawNMTToken( uint256[] memory _purchaseNumbers ) external   ;
}
