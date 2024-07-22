// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0 ;

interface IERC20 {
    function decimals() external view returns (uint8);
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
}

abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    function _disableInitializers() internal {
        _initialized = true;
    }
}

contract FinanceToken is Initializable{
    uint256 constant public day = 1 days;
    bool private reentrancyLock;
    address public nmtToken;
    uint256 public financingId;
    mapping(uint256 => FinanceMsg) public financeMsg;
    uint256 public purchaseNumber;
    mapping(uint256 => UserMsg) public userMsg;
    mapping(address => uint256[]) private userInfo; 

    event Launch(uint256 indexed financingId, address indexed sponsor);
    event PurchaseNMTWithToken(uint256 _purchaseNumber, address _sender, uint256 _purchaseNMTQuantity, address _paymentToken, uint256 _paymentTokenAmount);
    event WithdrawNMTToken(uint256 _purchaseNumber, uint256 withdrawAmount);
    event Refund(uint256 _financingId, uint256 amount);
    
    struct FinanceMsg {
        address sponsor;
        uint256 endTime;
        uint256 unlockIntervalDays;
        uint256 unlockPercentage;
        uint256 sellNMTQuantity;
        address tokenReceiveAddress;
        address paymentToken;
        uint256 paymentPrice;
        uint256 soldNMTQuantity;
    }

    struct UserMsg{
        address user;
        uint256 startTime;
        uint256 unlockIntervalDays;
        uint256 unlockPercentage;
        uint256 withdrawnAmount;
        uint256 purchaseNMTQuantity;
    }

    modifier nonReentrant() {
        require(!reentrancyLock);
        reentrancyLock = true;
        _;
        reentrancyLock = false;
    }

    constructor(){_disableInitializers();}

    function initialize(address _nmtToken) external initializer{
        __FinanceToken_init_unchained(_nmtToken);
    }

    function __FinanceToken_init_unchained(address _nmtToken) internal initializer{
        require(_nmtToken != address(0), "The address is 0 address");
        nmtToken = _nmtToken;
        reentrancyLock = false;
    }

    function launch(
        uint256 investmentPeriod,
        uint256 unlockIntervalDays,
        uint256 unlockPercentage,
        uint256 sellNMTQuantity,
        address tokenReceiveAddress,
        address paymentToken,
        uint256 paymentPrice
    ) external{
        require(investmentPeriod < 100, "investmentPeriod error");
        require(unlockIntervalDays <= 365 * day, "unlockIntervalDays error");
        require(unlockPercentage < 100 && unlockPercentage > 0, "percentage error");
        require(tokenReceiveAddress != address(0), "tokenReceiveAddress error");
        require(IERC20(nmtToken).transferFrom(msg.sender, address(this),sellNMTQuantity), "Token transfer failed");
        require(paymentPrice > 0, "paymentPrice error");
        uint256 _financingId  = ++financingId;
        financeMsg[_financingId] = FinanceMsg(
                                                msg.sender, 
                                                block.timestamp + investmentPeriod * day,
                                                unlockIntervalDays * day,
                                                unlockPercentage,
                                                sellNMTQuantity,
                                                tokenReceiveAddress,
                                                paymentToken,
                                                paymentPrice,
                                                0
                                            );
        emit Launch(_financingId, msg.sender);
    }
      
    function purchaseNMTWithETH(uint256 _financingId) payable external nonReentrant(){
        address _sender = msg.sender;
        FinanceMsg storage finance = financeMsg[_financingId];
        require(finance.endTime >= block.timestamp, "time error");
        require(finance.paymentToken == address(0), "token error");
        uint256 _purchaseNMTQuantity = msg.value * finance.paymentPrice / 10**18;
        require(_purchaseNMTQuantity > 0, "purchaseNMTQuantity error");
        uint256 useAmount = _purchaseNMTQuantity * 10**18 / finance.paymentPrice;
        payable(finance.tokenReceiveAddress).transfer(useAmount);
        payable(_sender).transfer(msg.value - useAmount);
        uint256 _purchaseNumber = ++purchaseNumber;
        userMsg[_purchaseNumber] = UserMsg(_sender, finance.endTime, finance.unlockIntervalDays, finance.unlockPercentage, 0, _purchaseNMTQuantity);
        userInfo[_sender].push(_purchaseNumber);
        finance.soldNMTQuantity += _purchaseNMTQuantity;
        require(finance.soldNMTQuantity <= finance.sellNMTQuantity, "Limit Exceeded");
        emit PurchaseNMTWithToken(_purchaseNumber, _sender, _purchaseNMTQuantity, address(0), useAmount);
    }

    function purchaseNMTWithToken(uint256 _financingId, address _paymentToken, uint256 _paymentAmount) external nonReentrant(){
        address _sender = msg.sender;
        FinanceMsg storage finance = financeMsg[_financingId];
        require(finance.endTime >= block.timestamp, "time error");
        require(_paymentToken != address(0) && finance.paymentToken == _paymentToken, "token error");
        uint256 decimals = IERC20(_paymentToken).decimals();
        uint256 _purchaseNMTQuantity = _paymentAmount * finance.paymentPrice / 10**decimals;
        require(_purchaseNMTQuantity > 0, "purchaseNMTQuantity error");
        uint256 useAmount = _purchaseNMTQuantity * 10**decimals / finance.paymentPrice;
        require(IERC20(_paymentToken).transferFrom(_sender,finance.tokenReceiveAddress,useAmount), "Token transfer failed");
        IERC20(nmtToken).transfer(_sender,_paymentAmount - useAmount);
        uint256 _purchaseNumber = ++purchaseNumber;
        userMsg[_purchaseNumber] = UserMsg(_sender, finance.endTime, finance.unlockIntervalDays, finance.unlockPercentage, 0, _purchaseNMTQuantity);
        userInfo[_sender].push(_purchaseNumber);
        finance.soldNMTQuantity += _purchaseNMTQuantity;
        require(finance.soldNMTQuantity <= finance.sellNMTQuantity, "Limit Exceeded");
        emit PurchaseNMTWithToken(_purchaseNumber, _sender, _purchaseNMTQuantity, _paymentToken, useAmount);
    }

    function withdrawNMTToken(uint256[] memory _purchaseNumbers) external nonReentrant(){
        UserMsg storage _userMsg;
        uint256 withdraw;
        for (uint256 i = 0; i< _purchaseNumbers.length; i++){
            _userMsg = userMsg[_purchaseNumbers[i]];
            require(_userMsg.user == msg.sender, "user error");
            uint256 amount = calcToken(_userMsg);
            _userMsg.withdrawnAmount += amount;
            withdraw += amount;
            emit WithdrawNMTToken(_purchaseNumbers[i], amount);
        }
        require(withdraw > 0, "withdraw error");
        require(IERC20(nmtToken).transfer(msg.sender,withdraw), "Token transfer failed");
    }

    function refund(uint256 _financingId) external nonReentrant(){
        FinanceMsg storage finance = financeMsg[_financingId];
        require(finance.sellNMTQuantity > 0, "wrong quantity");
        require(finance.endTime < block.timestamp, "time error");
        uint256 _amount = finance.sellNMTQuantity - finance.soldNMTQuantity;
        require(_amount > 0, "refund error");
        finance.soldNMTQuantity = finance.sellNMTQuantity;
        require(IERC20(nmtToken).transfer(finance.sponsor,_amount), "Token transfer failed");
        emit Refund(_financingId, _amount);
    }
    
    function queryUserMsg(address _userAddr) external view returns (uint256[] memory, uint256[] memory, UserMsg[] memory){
        uint256[] memory userInfos = userInfo[_userAddr];
        uint256[] memory withdraws = new uint256[](userInfos.length);
        UserMsg[] memory userMsgs = new UserMsg[](userInfos.length);
        for (uint256 i = 0; i< userInfos.length; i++){
            userMsgs[i] = userMsg[userInfos[i]];
            withdraws[i] = calcToken(userMsgs[i]);
        }
        return (userInfos, withdraws, userMsgs);
    }

    function calcToken(UserMsg memory _userMsg) internal view returns (uint256){
        if(block.timestamp < _userMsg.startTime){
            return 0;
        }else {
            uint256 amount = ((block.timestamp - _userMsg.startTime) / _userMsg.unlockIntervalDays) * _userMsg.unlockPercentage *  _userMsg.purchaseNMTQuantity /100;
            if(amount > _userMsg.purchaseNMTQuantity){
                return _userMsg.purchaseNMTQuantity - _userMsg.withdrawnAmount;
            }else {
                return amount - _userMsg.withdrawnAmount;
            }
        }
    }
}
