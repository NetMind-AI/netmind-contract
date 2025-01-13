// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0 ;

interface IConf {
    function p_settlement() external returns (uint256);
    function v_settlement() external returns (uint256);
    function accountManageExecutor() external returns (address);
    function accountUsdExecutor() external returns (address);
    function execDeductionExecutor() external returns (address);
    function Staking() external returns (address);
    function acts(address ) external view returns(bool);
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

contract Ownable is Initializable{
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init_unchained() internal initializer {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IFiatoSettle {
    function distribute(address receiver, uint256 amount, uint256 burn) external returns(bool);
    function distribute(address gpu_provider, uint256 gpu_nmt, address platform, uint256 platform_nmt, uint256 burn) external returns(bool);
}

contract AccountManage is Ownable{
    address public conf;
    uint256 public burnAmount;
    uint256 public num;
    mapping(uint256 => UserAccountMsg) public userAccountMsg;
    mapping(string => uint256) public userAccountById;
    mapping(address => uint256) public userAccountByAddr;
    mapping(address => bool) public authSta;
    uint256 public providerFeeSum;
    bytes32 public CONTRACT_DOMAIN;
    mapping(address => uint256) public nonce;
    mapping(address => mapping(uint256 => uint256)) public withdrawData;
    uint256 public signNum;
    bool private reentrancyLock;
    uint256 public quota;
    mapping(string => bool) public orderId;
    uint256 public useFeeSum;
    mapping(string => OrderMsg) public orderMsg;
    mapping(address => bool) whiteAddr;
    address public fiatoSettle;
    mapping(bytes32=>bool) digestSta;
    address public feeTo;
    mapping(string => OrderCnyMsg) public orderCnyMsg;
    uint256 public quotaCny;
    
    event WithdrawToken(address indexed _userAddr, uint256 _nonce, uint256 _amount);
    event UpdateAuthSta(address _addr, bool sta);
    event InitAccount(string userId, address userAddr);
    event UpdateAccount(string userId, address userAddr);
    event DeleteAccount(string userId, address userAddr);
    event TokenCharge(string userId, uint256 value, uint256 nmtbalance, address chargeAddr);
    event Withdraw(address userAddr, string userId, uint256 value, uint256 nmtbalance);
    event Freeze(string userId, uint256 value, uint256 balance, uint256 jobType);
    event ExecDebit(string userId, uint256 useValue, uint256 offsetValue, uint256 balance, uint256 jobType);
    event UpdateAccountUsd(string userId, string orderId, uint256 usd, uint256 usdBalance, bool _type);
    event ExecDeduction(string userId, string orderId, string _msg, uint256 nmt, uint256 nmtBalance, uint256 usd, uint256 usdBalance, uint256 overdraft, uint256 overdraftBalance);
    event ExecCnyDeduction(string userId, string orderId, string _msg, uint256 cny, uint256 cnyBalance, uint256 cnyOverdraft, uint256 cnyOverdraftBalance);
    event Refund(string userId, string deductionOrderId, string orderId, uint256 nmt, uint256 nmtBalance, uint256 usd, uint256 usdBalance, uint256 overdraft, uint256 overdraftBalance);
    event RefundCny(string userId, string deductionOrderId, string orderId, uint256 cny, uint256 cnyBalance, uint256 cnyOverdraft, uint256 cnyOverdraftBalance);
    event CaclAccountBalance(string userId, uint256 nmt, uint256 nmtBalance, uint256 usd, uint256 usdBalance, uint256 overdraft, uint256 overdraftBalance, uint256 price);
    event DistributeNmt(string id, address reciver, uint256 amount, uint256 feeAmount);
    event DistributeUsd(string id, address reciver, uint256 usdAmount, uint256 nmtAmount, uint256 feeUsdAmount, uint256 feeNmtAmount);
    event UpdateAccountCny(string userId, string orderId, uint256 cny, uint256 cnyBalance, bool _type);
    event CaclAccountCnyBalance(string userId, uint256 cny, uint256 cnyBalance, uint256 cnyOverdraft, uint256 cnyOverdraftBalance);
    event DistributeCny(string id, address reciver, uint256 usdAmount, uint256 nmtAmount, uint256 feeUsdAmount, uint256 feeNmtAmount);
    event DistributeAndBurnNmt(string paymentId, address gpu_provider, uint256 gpu_fee, address platform, uint256 platform_fee, uint256 burn);
    event DistributeAndBurnUsd(string paymentId, address gpu_provider, address platform, uint256[6] parm);
    event DistributeAndBurnCny(string paymentId, address gpu_provider, address platform, uint256[6] parm);
    
    
    struct UserAccountMsg {
        uint256 balance;
        uint256 freezed;
        string userId;
        address addr;
        uint256 usd;
        uint256 overdraft;
        uint256 cny;
        uint256 cnyOverdraft;
    }

    struct OrderMsg {
        uint256 nmtAmount;
        uint256 usd;
        uint256 overdraft;
        uint256 refundNmt;
        uint256 refundUsd;
        uint256 refundOverdraft;
        uint256 distributeNmt;
        uint256 distributeUsd;
    }
    
    struct OrderCnyMsg {
        uint256 cny;
        uint256 overdraft;
        uint256 refundCny;
        uint256 refundOverdraft;
        uint256 distributeCny;
    }
    
    struct Sig {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    modifier notContract() {
        require((!_isContract(msg.sender)) && (msg.sender == tx.origin), "contract not allowed");
        _;
    }

    function _isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    modifier nonReentrant() {
        require(!reentrancyLock);
        reentrancyLock = true;
        _;
        reentrancyLock = false;
    }

    modifier onlyExecutor() {
        require(IConf(conf).accountManageExecutor() == msg.sender, "not accountManageExecutor");
        _;
    }

    modifier onlyAccountUsdExecutor() {
        require(IConf(conf).accountUsdExecutor() == msg.sender, "not accountUsdExecutor");
        _;
    }

    modifier onlyExecDeductionExecutor() {
        require(IConf(conf).execDeductionExecutor() == msg.sender, "not execDeductionExecutor");
        _;
    }

    modifier onlyAuth() {
        require(authSta[msg.sender], "no permission");
        _;
    }

    constructor(){_disableInitializers();}

    function init(address _conf)  external 
       initializer
    {
        __Ownable_init_unchained();
        __AccountManage_init_unchained(_conf);
    }

    function __AccountManage_init_unchained(address _conf) internal 
      initializer
    {
       require(_conf != address(0), "_conf error");
       conf = _conf;
       CONTRACT_DOMAIN = keccak256('Netmind AccountManage V1.0');
       signNum = 2;
    }
 
    function updateSignNum(uint256 _signNum) external onlyOwner{
        require(_signNum > 0, "signNum error");
        signNum = _signNum;
    }

    function updateAuthSta(address _addr, bool _sta) external onlyOwner{
        authSta[_addr] = _sta;
        emit UpdateAuthSta(_addr, _sta);
    }

    function updateQuota(uint256 _quota) external onlyOwner{
        quota = _quota;
    }
  
    function updateQuotaCny(uint256 _quotaCny) external onlyOwner{
        quotaCny = _quotaCny;
    }
  
    function setFiatoSettle(address _fiatoSettle) external onlyOwner{
        require(_fiatoSettle != address(0), "zero address");
        fiatoSettle = _fiatoSettle;
    }

    function setFeeTo(address _feeTo) public onlyOwner{
        feeTo = _feeTo;
    }

    function initUserId(string memory _userId, address _addr) external onlyExecutor{
        require(userAccountById[_userId] == 0, "Userid occupied");
        require(userAccountByAddr[_addr] == 0, "User address occupied");
        uint256 _num = ++num;
        UserAccountMsg storage _userAccountMsg = userAccountMsg[_num];
        _userAccountMsg.userId = _userId;
        userAccountById[_userId] = _num;
        if(_addr != address(0x00)){
            _userAccountMsg.addr = _addr;
            userAccountByAddr[_addr] = _num;
        }
        emit InitAccount(_userId, _addr);
    }

    function updateAccount(string memory _userId, address _addr) external onlyExecutor{
        uint256 _num = userAccountById[_userId];
        UserAccountMsg storage _userAccountMsg = userAccountMsg[_num];
        require(_num > 0, "not exist");
        userAccountByAddr[_userAccountMsg.addr] = 0;
        _userAccountMsg.addr = _addr;
        if(_addr != address(0x00)){
            require(userAccountByAddr[_addr] == 0, "address occupied");
            userAccountByAddr[_addr] = _num;
        }
        emit UpdateAccount(_userId, _addr);
    }
 
    function deleteAccount(string memory _userId) external onlyExecutor{
        UserAccountMsg storage _userAccountMsg = getUserAccountMsg(_userId);
        userAccountByAddr[_userAccountMsg.addr] = 0;
        userAccountById[_userId] = 0;
         emit DeleteAccount(_userId, _userAccountMsg.addr);
    }
 
    function updateAccountUsd(string memory _userId, string memory _orderId, uint256 _usd, bool _type, uint256 _price) external onlyAccountUsdExecutor{
        UserAccountMsg storage _userAccountMsg = getUserAccountMsg(_userId, _orderId);
        if(_type){
            _userAccountMsg.usd = _userAccountMsg.usd + _usd;
        }else {
            _userAccountMsg.usd = _userAccountMsg.usd - _usd;
        }
        emit UpdateAccountUsd(_userId, _orderId, _usd, _userAccountMsg.usd, _type);
        require(_caclAccountBalance(_userId, _price), "caclAccountBalance error");
    }
 
    function updateAccountCny(string memory _userId, string memory _orderId, uint256 _cny, bool _type) external onlyAccountUsdExecutor{
        UserAccountMsg storage _userAccountMsg = getUserAccountMsg(_userId, _orderId);
        if(_type){
            _userAccountMsg.cny = _userAccountMsg.cny + _cny;
        }else {
            _userAccountMsg.cny = _userAccountMsg.cny - _cny;
        }
        emit UpdateAccountCny(_userId, _orderId, _cny, _userAccountMsg.cny, _type);
        uint256 cnyOverdraft = _userAccountMsg.cnyOverdraft;
        if(cnyOverdraft> 0){
            if(_userAccountMsg.cny >= cnyOverdraft){
                _userAccountMsg.cny = _userAccountMsg.cny - cnyOverdraft;
                _userAccountMsg.cnyOverdraft = 0;
                emit CaclAccountCnyBalance(_userId, cnyOverdraft, _userAccountMsg.cny, cnyOverdraft, 0);
            }else {
                _userAccountMsg.cnyOverdraft = cnyOverdraft - _userAccountMsg.cny;
                _userAccountMsg.cny = 0;
                emit CaclAccountCnyBalance(_userId, _userAccountMsg.cny, 0, _userAccountMsg.cny, _userAccountMsg.cnyOverdraft);
            }
        }
    }
 
    function caclAccountBalance(string memory _userId, uint256 _price) external onlyAccountUsdExecutor returns(bool){
        return _caclAccountBalance(_userId, _price);
    }

    function execDeduction(string memory _userId, string memory _orderId, uint256 _nmt, uint256 _usd, uint256 _overdraft, string memory _msg) external onlyExecDeductionExecutor{
        UserAccountMsg storage _userAccountMsg = getUserAccountMsg(_userId, _orderId);
        _userAccountMsg.usd = _userAccountMsg.usd - _usd;
        _userAccountMsg.overdraft = _userAccountMsg.overdraft + _overdraft;
        require(_userAccountMsg.overdraft <= quota, "quota error");
        useFeeSum += _nmt;
        _userAccountMsg.balance = _userAccountMsg.balance - _nmt;
        orderMsg[_orderId] = OrderMsg(_nmt, _usd, _overdraft, 0, 0, 0, 0, 0);
        emit ExecDeduction(_userId, _orderId, _msg, _nmt, _userAccountMsg.balance, _usd, _userAccountMsg.usd, _overdraft, _userAccountMsg.overdraft);
    }

    function execCnyDeduction(string memory _userId, string memory _orderId, uint256 _cny, uint256 _cnyOverdraft, string memory _msg) external onlyExecDeductionExecutor{
        UserAccountMsg storage _userAccountMsg = getUserAccountMsg(_userId, _orderId);
        _userAccountMsg.cny = _userAccountMsg.cny - _cny;
        _userAccountMsg.cnyOverdraft = _userAccountMsg.cnyOverdraft + _cnyOverdraft;
        require(_userAccountMsg.cnyOverdraft <= quotaCny, "quotaCny error");
        orderCnyMsg[_orderId] = OrderCnyMsg(_cny, _cnyOverdraft, 0, 0, 0);
        emit ExecCnyDeduction(_userId, _orderId, _msg, _cny, _userAccountMsg.cny, _cnyOverdraft, _userAccountMsg.cnyOverdraft);
    }
    
    function refund(string memory _userId, string memory _deductionOrderId, string memory _orderId, uint256 _nmt, uint256 _usd, uint256 _overdraft) external onlyExecDeductionExecutor{
        OrderMsg storage _orderMsg = orderMsg[_deductionOrderId];
        require(
            _orderMsg.nmtAmount >= _orderMsg.refundNmt + _nmt && 
            _orderMsg.usd + _orderMsg.overdraft + 500 >= _orderMsg.refundUsd + _usd + _orderMsg.refundOverdraft + _overdraft, 
            "orderIdMsg error"
        );
        _orderMsg.refundNmt += _nmt;
        _orderMsg.refundUsd += _usd;
        _orderMsg.refundOverdraft += _overdraft;
        UserAccountMsg storage _userAccountMsg = getUserAccountMsg(_userId, _orderId);
        _userAccountMsg.usd = _userAccountMsg.usd + _usd;
        require(_userAccountMsg.overdraft >= _overdraft, "overdraft error");
        _userAccountMsg.overdraft = _userAccountMsg.overdraft - _overdraft;
        useFeeSum -= _nmt;
        _userAccountMsg.balance = _userAccountMsg.balance + _nmt;
        emit Refund(_userId, _deductionOrderId, _orderId, _nmt, _userAccountMsg.balance, _usd, _userAccountMsg.usd, _overdraft, _userAccountMsg.overdraft);
    }
   
    function refundCny(string memory _userId, string memory _deductionOrderId, string memory _orderId, uint256 _cny, uint256 _cnyOverdraft) external onlyExecDeductionExecutor{
        OrderCnyMsg storage _orderCnyMsg = orderCnyMsg[_deductionOrderId];
        require(
            _orderCnyMsg.cny + _orderCnyMsg.overdraft >= _orderCnyMsg.refundCny + _cny + _orderCnyMsg.refundOverdraft + _cnyOverdraft, 
            "orderIdMsg error"
        );
        _orderCnyMsg.refundCny+= _cny;
        _orderCnyMsg.refundOverdraft += _cnyOverdraft;
        UserAccountMsg storage _userAccountMsg = getUserAccountMsg(_userId, _orderId);
        _userAccountMsg.cny = _userAccountMsg.cny + _cny;
        require(_userAccountMsg.cnyOverdraft >= _cnyOverdraft, "cnyOverdraft error");
        _userAccountMsg.cnyOverdraft = _userAccountMsg.cnyOverdraft - _cnyOverdraft;
        emit RefundCny(_userId, _deductionOrderId, _orderId, _cny, _userAccountMsg.cny, _cnyOverdraft, _userAccountMsg.cnyOverdraft);
    }
    
    function tokenCharge(string memory _userId) external payable{
        UserAccountMsg storage _userAccountMsg = getUserAccountMsg(_userId);
        _userAccountMsg.balance = _userAccountMsg.balance + msg.value;
        emit TokenCharge(_userAccountMsg.userId, msg.value, _userAccountMsg.balance, msg.sender);
    }

    function withdraw(uint256 value) external nonReentrant(){
        address sender = msg.sender;
        uint256 _num = userAccountByAddr[sender];
        require(_num > 0, "The user id does not exist");
        UserAccountMsg storage _userAccountMsg = userAccountMsg[_num];
        require(address(this).balance >= value, "Insufficient balance");
        _userAccountMsg.balance = _userAccountMsg.balance - value;
        require(sender != address(0), "The address is 0");
        payable(sender).transfer(value);
        emit Withdraw(sender, _userAccountMsg.userId, value, _userAccountMsg.balance);
    }

    function freeze(string memory _userId, uint256 freezeValue, uint256 jobType) external onlyAuth returns(bool){
        UserAccountMsg storage _userAccountMsg = getUserAccountMsg(_userId);
        _userAccountMsg.balance = _userAccountMsg.balance - freezeValue;
        _userAccountMsg.freezed = _userAccountMsg.freezed + freezeValue;
        emit Freeze(_userId, freezeValue, _userAccountMsg.balance, jobType);
        return true;
    }

    function execDebit(string memory _userId, uint256 useValue, uint256 offsetValue, uint256 jobType) external onlyAuth returns(bool){
        UserAccountMsg storage _userAccountMsg = getUserAccountMsg(_userId);
        _userAccountMsg.freezed = _userAccountMsg.freezed - useValue - offsetValue;
        _userAccountMsg.balance = _userAccountMsg.balance + offsetValue;
        uint256 _settlement;
        if(jobType == 1){
            _settlement = IConf(conf).p_settlement();
        }else if(jobType == 2){
            _settlement = IConf(conf).v_settlement();
        }
        uint256 fee = _settlement * useValue / 10000 ;
        providerFeeSum = providerFeeSum + fee;
        fee = useValue - fee;
        payable(address(0x00)).transfer(fee);
        burnAmount = burnAmount + fee;
        emit ExecDebit(_userId, useValue, offsetValue, _userAccountMsg.balance, jobType);
        return true;
    }

    function distributeNmt(string memory paymentId, address gpu_provider, uint256 gpu_fee, uint256 platform_fee, uint256 expir, uint8[] calldata vs, bytes32[] calldata rs) public notContract{
        bytes32 digest =  keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR(),
                keccak256(abi.encode(paymentId, gpu_provider, gpu_fee, platform_fee, expir)))
        );
        _orderNmtMsgUpdate(paymentId, gpu_fee + platform_fee);
        _verifyParm(digest, expir, vs, rs);
        if (gpu_fee > 0) payable(gpu_provider).transfer(gpu_fee);
        if (platform_fee > 0) payable(feeTo).transfer(platform_fee);
        emit DistributeNmt(paymentId, gpu_provider, gpu_fee, platform_fee);
    }

    function distributeAndBurnNmt(string memory paymentId, address gpu_provider, uint256 gpu_fee, address platform, uint256 platform_fee, uint256 burn, uint256 expir, uint8[] calldata vs, bytes32[] calldata rs) public notContract{
        bytes32 digest =  keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR(),
                keccak256(abi.encode(paymentId, gpu_provider, gpu_fee, platform, platform_fee, burn, expir)))
        );
        _orderNmtMsgUpdate(paymentId, gpu_fee + platform_fee + burn);
        _verifyParm(digest, expir, vs, rs);
        if (gpu_fee > 0) payable(gpu_provider).transfer(gpu_fee);
        if (platform_fee > 0) payable(platform).transfer(platform_fee);
        if (burn > 0) payable(address(0)).transfer(burn);
        emit DistributeAndBurnNmt(paymentId, gpu_provider, gpu_fee, platform, platform_fee, burn);
    }

    function distributeUsd(string memory paymentId, address gpu_provider, uint256 gpu_fee, uint256 gpu_nmt, uint256 platform_fee, uint256 platform_nmt, uint256 expir, uint8[] calldata vs, bytes32[] calldata rs) public notContract{
        _orderUsdMsgUpdate(paymentId, gpu_fee + platform_fee);
        _distribute(paymentId, gpu_provider, gpu_fee, gpu_nmt, platform_fee, platform_nmt, expir, vs, rs);
        emit DistributeUsd(paymentId, gpu_provider, gpu_fee, gpu_nmt, platform_fee, platform_nmt);
    }

    function distributeCny(string memory paymentId, address gpu_provider, uint256 gpu_fee, uint256 gpu_nmt, uint256 platform_fee, uint256 platform_nmt, uint256 expir, uint8[] calldata vs, bytes32[] calldata rs) public notContract{
        _orderCnyMsgUpdate(paymentId, gpu_fee + platform_fee);
        _distribute(paymentId, gpu_provider, gpu_fee, gpu_nmt, platform_fee, platform_nmt, expir, vs, rs);
        emit DistributeCny(paymentId, gpu_provider, gpu_fee, gpu_nmt, platform_fee, platform_nmt);
    }

    function distributeAndBurnUsd(string memory paymentId, address gpu_provider, address platform, uint256[6] calldata parm, uint256 expir, uint8[] calldata vs, bytes32[] calldata rs) public notContract{
        _orderUsdMsgUpdate(paymentId, parm[0] + parm[2] + parm[4]);
        _distributeAndBurn(paymentId, gpu_provider, platform, parm, expir, vs, rs);
        emit DistributeAndBurnUsd(paymentId, gpu_provider, platform, parm);
    }

    function distributeAndBurnCny(string memory paymentId, address gpu_provider,address platform, uint256[6] calldata parm, uint256 expir, uint8[] calldata vs, bytes32[] calldata rs) public notContract{
        _orderCnyMsgUpdate(paymentId, parm[0] + parm[2] + parm[4]);
        _distributeAndBurn(paymentId, gpu_provider, platform, parm, expir, vs, rs);
        emit DistributeAndBurnCny(paymentId, gpu_provider, platform, parm);
    }

    function withdrawComputingFee(
        address addr,
        uint256[2] calldata uints,
        uint8[] calldata vs,
        bytes32[] calldata rssMetadata
    )
        external
        nonReentrant()
        notContract()
    {   
        require(providerFeeSum >= uints[0], "withdrawComputingFee error");
        transferToken(addr, uints, vs, rssMetadata);
        providerFeeSum = providerFeeSum - uints[0];
    }
    
    function queryUserMsgById(string memory _userId) external view returns (uint256, uint256, uint256, uint256, uint256, uint256, address) {
        UserAccountMsg storage _userAccountMsg = getUserAccountMsg(_userId);
        return (_userAccountMsg.balance, _userAccountMsg.usd, _userAccountMsg.overdraft, _userAccountMsg.cny, _userAccountMsg.cnyOverdraft, _userAccountMsg.freezed, _userAccountMsg.addr);
    }

    function queryUserMsgByAddr(address _addr) external view returns (uint256, uint256, uint256, uint256, uint256, uint256, string memory) {
        uint256 _num = userAccountByAddr[_addr];
        require(_num > 0, "not exist");
        UserAccountMsg storage _userAccountMsg = userAccountMsg[_num];
        return (_userAccountMsg.balance, _userAccountMsg.usd, _userAccountMsg.overdraft, _userAccountMsg.cny, _userAccountMsg.cnyOverdraft, _userAccountMsg.freezed, _userAccountMsg.userId);
    }

    function DOMAIN_SEPARATOR() public view returns(bytes32){
        return keccak256(
            abi.encode(
                keccak256('EIP712Domain(uint256 chainId,address verifyingContract)'),
                block.chainid,
                address(this)
            )
        );
    }

    function _orderNmtMsgUpdate(string memory paymentId, uint256 amount) internal{
        require(orderId[paymentId], "paymentId error");
        OrderMsg storage _orderMsg = orderMsg[paymentId];
        require(_orderMsg.nmtAmount - _orderMsg.refundNmt - _orderMsg.distributeNmt >= amount, "distributeNmt out of range");
        _orderMsg.distributeNmt += amount;
    }

    function _orderUsdMsgUpdate(string memory paymentId, uint256 amount) internal{
        require(orderId[paymentId], "paymentId error");
        OrderMsg storage _orderMsg = orderMsg[paymentId];
        require(_orderMsg.usd + _orderMsg.overdraft - _orderMsg.refundUsd  - _orderMsg.distributeUsd >= amount, "distributeUsd out of range");
        _orderMsg.distributeUsd += amount;
    }

    function _orderCnyMsgUpdate(string memory paymentId, uint256 amount) internal{
        require(orderId[paymentId], "paymentId error");
        OrderCnyMsg storage _orderCnyMsg = orderCnyMsg[paymentId];
        require(_orderCnyMsg.cny  + _orderCnyMsg.overdraft- _orderCnyMsg.refundCny - _orderCnyMsg.distributeCny >= amount, "distributeCny out of range");
        _orderCnyMsg.distributeCny += amount;
    }

    function _distribute(string memory paymentId, address gpu_provider, uint256 gpu_fee, uint256 gpu_nmt, uint256 platform_fee, uint256 platform_nmt, uint256 expir, uint8[] calldata vs, bytes32[] calldata rs) internal{
        bytes32 digest = keccak256(
                abi.encodePacked(
                    '\x19\x01',
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(paymentId, gpu_provider, gpu_fee, gpu_nmt, platform_fee,platform_nmt, expir)))
            );
        _verifyParm(digest, expir, vs, rs);
        require(IFiatoSettle(fiatoSettle).distribute(gpu_provider, gpu_nmt, platform_nmt), "cleaner feild");
    }

    function _distributeAndBurn(string memory paymentId, address gpu_provider, address platform, uint256[6] calldata parm, uint256 expir, uint8[] calldata vs, bytes32[] calldata rs) internal{
        bytes32 digest = keccak256(
                abi.encodePacked(
                    '\x19\x01',
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(paymentId, gpu_provider, parm[0], parm[1], platform, parm[2],parm[3], parm[4], parm[5], expir)))
            );
        _verifyParm(digest, expir, vs, rs);
        require(IFiatoSettle(fiatoSettle).distribute(gpu_provider, parm[1], platform, parm[3], parm[5]), "cleaner feild");
    }

    function _verifyParm(bytes32 digest, uint256 expir, uint8[] calldata vs, bytes32[] calldata rs) internal{
        require(block.timestamp <= expir, "sign expired");
        uint256 counter;
        uint256 len = vs.length;
        require(len*2 == rs.length, "length mismatch");
        require(!digestSta[digest], "digest error"); 
        digestSta[digest] = true;
        address[] memory signAddrs = new address[](len);
        for (uint256 i = 0; i < len; i++) {
            (bool result, address signAddr) = verifySign(digest, Sig(vs[i], rs[i*2], rs[i*2+1]));
            signAddrs[i] = signAddr;
            if (result){
                counter++;
            }
        }
        require(counter >= signNum, "lack of signature");
        require(areElementsUnique(signAddrs), "duplicate signature"); 
    }

    function _caclAccountBalance(string memory _userId, uint256 _price) internal returns(bool){
        UserAccountMsg storage _userAccountMsg = getUserAccountMsg(_userId);
        uint256 overdraft = _userAccountMsg.overdraft;
        if(overdraft> 0){
            if(_userAccountMsg.usd >= overdraft){
                _userAccountMsg.usd = _userAccountMsg.usd - overdraft;
                _userAccountMsg.overdraft = 0;
                emit CaclAccountBalance(_userId, 0, _userAccountMsg.balance, overdraft, _userAccountMsg.usd, overdraft, 0, _price);
                return true;
            }else {
                if(_userAccountMsg.usd > 0){
                    uint256 offsetAmount = overdraft - _userAccountMsg.usd;
                    uint256 offsetNmtAmount = offsetAmount * 1e24 / _price;
                    if(_userAccountMsg.balance == 0){
                        _userAccountMsg.overdraft = overdraft - _userAccountMsg.usd; 
                        emit CaclAccountBalance(_userId, 0, 0, 0, 0, _userAccountMsg.usd, _userAccountMsg.overdraft, _price);
                        _userAccountMsg.usd = 0;
                        return true;
                    }else {
                        if(offsetNmtAmount * 1e10 <= _userAccountMsg.balance){
                            _userAccountMsg.balance = _userAccountMsg.balance - offsetNmtAmount * 1e10;
                            _userAccountMsg.overdraft = 0;
                            useFeeSum += offsetNmtAmount* 1e10;
                            emit CaclAccountBalance(_userId, offsetNmtAmount* 1e10, _userAccountMsg.balance, _userAccountMsg.usd, 0, overdraft, 0, _price);
                            _userAccountMsg.usd = 0;
                            return true;
                        }else {
                            uint256 offsetOverdraft = offsetNmtAmount - _userAccountMsg.balance/1e10;
                            _userAccountMsg.overdraft = offsetOverdraft * _price / 1e24; 
                            _userAccountMsg.balance = _userAccountMsg.balance - (offsetNmtAmount - offsetOverdraft)*1e10;
                            useFeeSum += (offsetNmtAmount - offsetOverdraft)*1e10;
                            emit CaclAccountBalance(_userId, (offsetNmtAmount - offsetOverdraft)*1e10, _userAccountMsg.balance, _userAccountMsg.usd, 0, overdraft - _userAccountMsg.overdraft, _userAccountMsg.overdraft, _price);
                            _userAccountMsg.usd = 0;
                            return true;
                        }
                    }
                }else {
                    uint256 offsetNmtAmount = _userAccountMsg.overdraft * 1e24 / _price;
                    if(offsetNmtAmount * 1e10 <= _userAccountMsg.balance){
                        _userAccountMsg.balance = _userAccountMsg.balance - offsetNmtAmount * 1e10;
                        useFeeSum += offsetNmtAmount* 1e10;
                        emit CaclAccountBalance(_userId, offsetNmtAmount * 1e10, _userAccountMsg.balance, 0, 0, overdraft, 0,_price);
                        _userAccountMsg.overdraft = 0;
                        return true;
                    }else {
                        uint256 offsetOverdraft = offsetNmtAmount - _userAccountMsg.balance/1e10;
                        _userAccountMsg.overdraft = offsetOverdraft * _price / 1e24; 
                        _userAccountMsg.balance = _userAccountMsg.balance - (offsetNmtAmount - offsetOverdraft)*1e10;
                        useFeeSum += (offsetNmtAmount - offsetOverdraft)*1e10;
                        emit CaclAccountBalance(_userId, (offsetNmtAmount - offsetOverdraft)*1e10, _userAccountMsg.balance, 0, 0, overdraft-_userAccountMsg.overdraft, _userAccountMsg.overdraft,_price);
                        return true;
                    }
                }
            }
        }
        return true;
    }
    
    function areElementsUnique(address[] memory arr) internal pure returns (bool) {
        for(uint i = 0; i < arr.length - 1; i++) {
            for(uint j = i + 1; j < arr.length; j++) {
                if (arr[i] == arr[j]) {
                    return false; 
                }
            }
        }
        return true; 
    }
      
    function transferToken(
        address addr,
        uint256[2] calldata uints,
        uint8[] calldata vs,
        bytes32[] calldata rssMetadata
    ) internal{
        require( block.timestamp<= uints[1], "exceeded limit");
        uint256 len = vs.length;
        uint256 counter;
        uint256 _nonce = nonce[addr]++;
        require(len*2 == rssMetadata.length, "length mismatch");
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR(),
                keccak256(abi.encode(addr, uints[0], uints[1], _nonce))
            )
        );
        address[] memory signAddrs = new address[](len);
        for (uint256 i = 0; i < len; i++) {
            (bool result, address signAddr) = verifySign(
                digest,
                Sig(vs[i], rssMetadata[i*2], rssMetadata[i*2+1])
            );
            signAddrs[i] = signAddr;
            if (result){
                counter++;
            }
        }
       
        require(
            counter >= signNum,
            "less than threshold"
        );
        require(areElementsUnique(signAddrs), "not unique");
        withdrawData[addr][_nonce] =  uints[0];
        payable(addr).transfer(uints[0]);
        emit WithdrawToken(addr, _nonce, uints[0]);
    }

    function getUserAccountMsg(string memory _userId, string memory _orderId) internal returns (UserAccountMsg storage)  {
        uint256 _num = userAccountById[_userId];
        UserAccountMsg storage _userAccountMsg = userAccountMsg[_num];
        require(_num > 0, "user not exist");
        require(!orderId[_orderId], "orderId error");
        orderId[_orderId] = true;
        return _userAccountMsg; 
    }

    function getUserAccountMsg(string memory _userId) internal view returns (UserAccountMsg storage)  {
        uint256 _num = userAccountById[_userId];
        UserAccountMsg storage _userAccountMsg = userAccountMsg[_num];
        require(_num > 0, "user not exist");
        return _userAccountMsg; 
    }

    function verifySign(bytes32 _digest,Sig memory _sig) internal view returns (bool, address)  {
        require(uint256(_sig.s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "invalid 's' value");
        require(uint8(_sig.v) == 27 || uint8(_sig.v) == 28, "invalid 'v' value");
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 hash = keccak256(abi.encodePacked(prefix, _digest));
        address signer = ecrecover(hash, _sig.v, _sig.r, _sig.s);
        require(signer != address(0), "0 address");
        bool isActs = IConf(conf).acts(signer); 
        return(isActs, signer); 
    }
}
