// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0 ;

interface IConf {
    function trainingTaskExecutor() external returns (address);
}

interface IAccountManage {
    function freeze(string memory _userId, uint256 freezeValue, uint256 jobType) external returns(bool);
    function execDebit(string memory _userId, uint256 useValue, uint256 offsetValue, uint256 jobType) external returns(bool);
    function queryUserMsgById(string memory _userId) external view returns (uint256, uint256, address);
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

contract TrainingTask is Ownable{
    IAccountManage public accountManage;
    address public conf;
    uint256 public num;
    mapping(uint256 => JobMsg) public jobMsg;
    mapping(string => uint256) public userJobMsg;
    mapping(string => bool) public upateOrderIdSta;
    mapping(string => bool) public execOrderIdSta;

    event ExecJob(string userId, string jobId,uint256 freezeAmount, uint256 state, uint256 jobType);
    event UpdateJob(string userId, string jobId,uint256 freezeAmount, uint256 state, uint256 jobType, string orderId);
    event EndJob(string userId, string jobId,uint256 usageAmount, uint256 surplusAmount, uint256 state, uint256 jobType);
    event ExecJobDebit(string userId, string jobId, uint256 freezeAmount, uint256 usageAmount, uint256 jobType, string orderId);
    

    struct JobMsg{
        string userId;
        uint256 freezeAmount;
        uint256 usageAmount;
        uint256 surplusAmount;                           
        uint256 state; 
        uint256 jobType; 
    }

    struct OrderMsg{
        string userId;
        uint256 value;
        uint256 price; 
    }
    
    modifier onlyExecutor() {
        require(msg.sender == IConf(conf).trainingTaskExecutor(), "caller is not the trainingTaskExecutor");
        _;
    }

    function init(
        address _conf,
        address _accountManage
    )  external 
       initializer
    {
        __Ownable_init_unchained();
        __TrainingTask_init_unchained(_conf, _accountManage);
    }

    function __TrainingTask_init_unchained(
        address _conf,
        address _accountManage
    ) internal 
      initializer
    {
       accountManage = IAccountManage(_accountManage);
       conf = _conf;
    }
    
    function execJob(string memory userId, string memory jobId, uint256 freezeAmount, uint256 jobType) external onlyExecutor{
        require(userJobMsg[jobId] == 0, "JobId is already occupied");
        uint256 _num = ++num;
        JobMsg storage _jobMsg = jobMsg[_num];
        userJobMsg[jobId] = _num;
        _jobMsg.userId = userId;
        (uint256 userBalance,,) = accountManage.queryUserMsgById(userId);
        require(userBalance >= freezeAmount, "Insufficient balance");
        require(accountManage.freeze(userId, freezeAmount, jobType), "Failed to freeze user amount");
        _jobMsg.freezeAmount = freezeAmount;
        _jobMsg.state = 1;
        _jobMsg.jobType = jobType;
        emit ExecJob(userId, jobId, _jobMsg.freezeAmount, _jobMsg.state, _jobMsg.jobType);
    }

    function updateJob(string memory userId, string memory jobId, uint256 freezeAmount, string memory orderId) external onlyExecutor{
        uint256 _num = userJobMsg[jobId];
        require( _num > 0, "JobId does not exist");
        require(!upateOrderIdSta[orderId], "The order number has already been used");
        upateOrderIdSta[orderId] = true;
        JobMsg storage _jobMsg = jobMsg[_num];
        require(keccak256(abi.encodePacked(_jobMsg.userId)) == keccak256(abi.encodePacked(userId)), "userId does not match");
        require(_jobMsg.state == 1 || _jobMsg.state == 4, "task status error");
        (uint256 userBalance,,) = accountManage.queryUserMsgById(userId);
        require(userBalance >= freezeAmount, "Insufficient balance");
        require(accountManage.freeze(userId, freezeAmount, _jobMsg.jobType), "Failed to freeze user amount");
        _jobMsg.freezeAmount = _jobMsg.freezeAmount + freezeAmount;
        _jobMsg.state = 1;
        emit UpdateJob(userId, jobId, freezeAmount, _jobMsg.state, _jobMsg.jobType, orderId);
    }

    function execJobDebit(string memory userId, string memory jobId, uint256 usageAmount, string memory orderId) external onlyExecutor{
        uint256 _num = userJobMsg[jobId];
        require( _num > 0, "JobId does not exist");
        require(!execOrderIdSta[orderId], "The order number has already been used");
        execOrderIdSta[orderId] = true;
        JobMsg storage _jobMsg = jobMsg[_num];
        require(_jobMsg.state == 1 || _jobMsg.state == 4, "task status error");
        require(keccak256(abi.encodePacked(_jobMsg.userId)) == keccak256(abi.encodePacked(userId)), "userId does not match");
        require(_jobMsg.freezeAmount >= usageAmount, "The frozen quantity is not enough to be deducted");
        _jobMsg.usageAmount = _jobMsg.usageAmount + usageAmount;
        _jobMsg.freezeAmount = _jobMsg.freezeAmount - usageAmount;
        require(accountManage.execDebit(userId, usageAmount, 0, _jobMsg.jobType), "Deduction failed");
        emit ExecJobDebit(userId, jobId, _jobMsg.freezeAmount, usageAmount, _jobMsg.jobType, orderId);
    }

    function endJob(string memory userId, string memory jobId, uint256 usageAmount, uint256 state) external onlyExecutor{
        uint256 _num = userJobMsg[jobId];
        require( _num > 0, "JobId does not exist");
        JobMsg storage _jobMsg = jobMsg[_num];
        require(_jobMsg.state == 1 || _jobMsg.state == 4, "task status error");
        require(keccak256(abi.encodePacked(_jobMsg.userId)) == keccak256(abi.encodePacked(userId)), "userId does not match");
        require(_jobMsg.freezeAmount >= usageAmount, "The frozen quantity is not enough to be deducted");
        _jobMsg.usageAmount = _jobMsg.usageAmount + usageAmount;
        _jobMsg.surplusAmount = _jobMsg.freezeAmount - usageAmount;
        _jobMsg.freezeAmount = 0;
        require(accountManage.execDebit(userId, usageAmount, _jobMsg.surplusAmount, _jobMsg.jobType), "Deduction failed");
        _jobMsg.state = state;
        emit EndJob(userId, jobId, usageAmount, _jobMsg.surplusAmount, state, _jobMsg.jobType);
    }

    function queryJobMsg(string memory jobId) external view returns (uint256, uint256, uint256, uint256, uint256) {
        uint256 _num = userJobMsg[jobId];
        JobMsg storage _jobMsg = jobMsg[_num];
        return (_jobMsg.freezeAmount, _jobMsg.usageAmount, _jobMsg.surplusAmount, _jobMsg.state, _jobMsg.jobType);
    }

}
