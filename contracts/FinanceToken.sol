// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0 ;

interface IERC20 {
    function decimals() external view returns (uint8);
    function approve(address spender, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
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
    using SafeERC20 for IERC20;
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
        require(unlockPercentage > 0 && unlockPercentage < 100, "percentage error");
        require(tokenReceiveAddress != address(0), "tokenReceiveAddress error");
        require(investmentPeriod < 30, "investmentPeriod error");
        SafeERC20.safeTransferFrom(IERC20(nmtToken), msg.sender, address(this),sellNMTQuantity);
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
        payable(finance.tokenReceiveAddress).transfer(msg.value);
        uint256 _purchaseNMTQuantity = msg.value * finance.paymentPrice / 10**18;
        uint256 _purchaseNumber = ++purchaseNumber;
        userMsg[_purchaseNumber] = UserMsg(_sender, finance.endTime, finance.unlockIntervalDays, finance.unlockPercentage, 0, _purchaseNMTQuantity);
        userInfo[_sender].push(_purchaseNumber);
        finance.soldNMTQuantity += _purchaseNMTQuantity;
        require(finance.soldNMTQuantity <= finance.sellNMTQuantity, "Limit Exceeded");
        emit PurchaseNMTWithToken(_purchaseNumber, _sender, _purchaseNMTQuantity, address(0), msg.value);
    }

    function purchaseNMTWithToken(uint256 _financingId, address _paymentToken, uint256 _paymentAmount) external nonReentrant(){
        address _sender = msg.sender;
        FinanceMsg storage finance = financeMsg[_financingId];
        require(finance.endTime >= block.timestamp, "time error");
        require(_paymentToken != address(0) && finance.paymentToken == _paymentToken, "token error");
        SafeERC20.safeTransferFrom(IERC20(_paymentToken), _sender,finance.tokenReceiveAddress,_paymentAmount);
        uint256 decimals = IERC20(_paymentToken).decimals();
        uint256 _purchaseNMTQuantity = _paymentAmount * finance.paymentPrice / 10**decimals;
        uint256 _purchaseNumber = ++purchaseNumber;
        userMsg[_purchaseNumber] = UserMsg(_sender, finance.endTime, finance.unlockIntervalDays, finance.unlockPercentage, 0, _purchaseNMTQuantity);
        userInfo[_sender].push(_purchaseNumber);
        finance.soldNMTQuantity += _purchaseNMTQuantity;
        require(finance.soldNMTQuantity <= finance.sellNMTQuantity, "Limit Exceeded");
        emit PurchaseNMTWithToken(_purchaseNumber, _sender, _purchaseNMTQuantity, _paymentToken, _paymentAmount);
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
        SafeERC20.safeTransfer(IERC20(nmtToken), msg.sender,withdraw);
    }

    function refund(uint256 _financingId) external nonReentrant(){
        FinanceMsg storage finance = financeMsg[_financingId];
        require(finance.sellNMTQuantity > 0, "wrong quantity");
        require(finance.endTime < block.timestamp, "time error");
        uint256 _amount = finance.sellNMTQuantity - finance.soldNMTQuantity;
        require(_amount > 0, "refund error");
        finance.soldNMTQuantity = finance.sellNMTQuantity;
        SafeERC20.safeTransfer(IERC20(nmtToken), finance.sponsor,_amount);
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

library SafeERC20 {
    using Address for address;

    /**
     * @dev An operation with an ERC20 token failed.
     */
    error SafeERC20FailedOperation(address token);

    /**
     * @dev Indicates a failed `decreaseAllowance` request.
     */
    error SafeERC20FailedDecreaseAllowance(address spender, uint256 currentAllowance, uint256 requestedDecrease);

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transfer, (to, value)));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transferFrom, (from, to, value)));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        forceApprove(token, spender, oldAllowance + value);
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `requestedDecrease`. If `token` returns no
     * value, non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 requestedDecrease) internal {
        unchecked {
            uint256 currentAllowance = token.allowance(address(this), spender);
            if (currentAllowance < requestedDecrease) {
                revert SafeERC20FailedDecreaseAllowance(spender, currentAllowance, requestedDecrease);
            }
            forceApprove(token, spender, currentAllowance - requestedDecrease);
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeCall(token.approve, (spender, value));

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeCall(token.approve, (spender, 0)));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data);
        if (returndata.length != 0 && !abi.decode(returndata, (bool))) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return success && (returndata.length == 0 || abi.decode(returndata, (bool))) && address(token).code.length > 0;
    }
}
library Address {
    /**
     * @dev The ETH balance of the account is not enough to perform the operation.
     */
    error AddressInsufficientBalance(address account);

    /**
     * @dev There's no code at `target` (it is not a contract).
     */
    error AddressEmptyCode(address target);

    /**
     * @dev A call to an address target failed. The target may have reverted.
     */
    error FailedInnerCall();

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.20/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        if (address(this).balance < amount) {
            revert AddressInsufficientBalance(address(this));
        }

        (bool success, ) = recipient.call{value: amount}("");
        if (!success) {
            revert FailedInnerCall();
        }
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason or custom error, it is bubbled
     * up by this function (like regular Solidity function calls). However, if
     * the call reverted with no returned reason, this function reverts with a
     * {FailedInnerCall} error.
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        if (address(this).balance < value) {
            revert AddressInsufficientBalance(address(this));
        }
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and reverts if the target
     * was not a contract or bubbling up the revert reason (falling back to {FailedInnerCall}) in case of an
     * unsuccessful call.
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata
    ) internal view returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            // only check if target is a contract if the call was successful and the return data is empty
            // otherwise we already know that it was a contract
            if (returndata.length == 0 && target.code.length == 0) {
                revert AddressEmptyCode(target);
            }
            return returndata;
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and reverts if it wasn't, either by bubbling the
     * revert reason or with a default {FailedInnerCall} error.
     */
    function verifyCallResult(bool success, bytes memory returndata) internal pure returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            return returndata;
        }
    }

    /**
     * @dev Reverts with returndata if present. Otherwise reverts with {FailedInnerCall}.
     */
    function _revert(bytes memory returndata) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert FailedInnerCall();
        }
    }
}