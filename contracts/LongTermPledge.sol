// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0 ;

interface IPledge {
    function upadeNodesStake(
        address[] calldata addrs,
        uint256[] calldata uints,
        uint256 expiredTime,
        string calldata chain
    ) external;
    function nodeAddrSta(address nodeAddr) external view returns (bool);
    function nodeChainAmount(string memory chain, address nodeAddr) external view returns (uint256);
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

contract LongTermPledge is Ownable{
    bool private reentrancyLock;
    IPledge public pledgeContract;
    uint256 public lockPeriod;
    uint256 public stakeTokenNum;         
    mapping(uint256 => StakeTokenMsg) public stakeTokenMsg;  
    mapping(address => uint256[]) private stakeList;
    

    event StakeToken(uint256 indexed _stakeIndex, address _userAddr, address _nodeAddr, uint256 _amount, uint256 _time,  uint256 _lockTime, address _token);
    event CancleStakeToken(uint256 indexed _stakeIndex, address indexed _userAddr, address _nodeAddr, uint256 _time);
    event UpdateLockPeriod(uint256 time);
    event UpdateStake(uint256 indexed _stakeIndex, uint256 _lockTime);
    

    struct StakeTokenMsg {
        address userAddr;
        address nodeAddr;
        uint256 start;
        uint256 lockTime;
        uint256 end;
        uint256 tokenAmount;
        address tokenAddr;
    }

    modifier nonReentrant() {
        require(!reentrancyLock);
        reentrancyLock = true;
        _;
        reentrancyLock = false;
    }

    constructor(){_disableInitializers();}

    function init(address _pledgeContract) external initializer{
        __Ownable_init_unchained();
        __LongTermPledge_init_unchained(_pledgeContract);
    }

    function __LongTermPledge_init_unchained(address _pledgeContract) internal initializer{
        pledgeContract = IPledge(_pledgeContract);
        lockPeriod = 182 days;
        reentrancyLock = false;
    }

    function updateLockPeriod(uint256 _lockPeriod) external onlyOwner{
        require(_lockPeriod <= 2* 365 days && _lockPeriod >= 30 days, "lockPeriod error");
        lockPeriod = _lockPeriod;
        emit UpdateLockPeriod(_lockPeriod);
    }
    
    function stake(address _nodeAddr, address _token, uint256 _amount, bool _type) payable external nonReentrant(){
        _stake(msg.sender, _nodeAddr, _token, _amount, _type);
    }
      
    function migrateStake(address _sender, address _nodeAddr, bool _type) payable external{
        require(msg.sender == address(pledgeContract), "pledgeContract error");
        _stake(_sender, _nodeAddr, address(0), 0, _type);
    }
   
    function _stake(address _sender, address _nodeAddr, address _token, uint256 _amount, bool _type) internal{
        _amount = msg.value;
        require(_token == address(0), "token error");
        require(_amount >= 0, "value error");
        require(pledgeContract.nodeAddrSta(_nodeAddr), "nodeAddr error");
        uint256 _nodeStakeNum = pledgeContract.nodeChainAmount("Netmind", _nodeAddr) + _amount;
        address[] memory _addrArray = new address[](1) ;
        _addrArray[0] = _nodeAddr;
        uint256[] memory _stakeAmount = new uint256[](1);
        _stakeAmount[0] = _nodeStakeNum;
        pledgeContract.upadeNodesStake(_addrArray, _stakeAmount, block.timestamp+10, "Netmind");
        uint256 _stakeTokenNum = ++stakeTokenNum;
        uint256 _lockTime=0;
        if(!_type){
            _lockTime = block.timestamp + lockPeriod;
        }
        stakeTokenMsg[_stakeTokenNum] = StakeTokenMsg(_sender, _nodeAddr, block.timestamp, _lockTime, 0, _amount, _token);
        stakeList[_sender].push(_stakeTokenNum);
        emit StakeToken(_stakeTokenNum, _sender, _nodeAddr, _amount, block.timestamp, _lockTime,_token);
    }

    function cancleStake(uint256[] calldata _indexs) external nonReentrant(){
        address _sender = msg.sender;
        for (uint256 i = 0; i < _indexs.length; i++) {
            uint256 _stakeTokenMark = _indexs[i];
            if (_stakeTokenMark > 0){
                StakeTokenMsg storage _stakeTokenMsg = stakeTokenMsg[_stakeTokenMark];
                require(_stakeTokenMsg.userAddr == _sender, "sender error");
                require(_stakeTokenMsg.lockTime != 0 && _stakeTokenMsg.lockTime < block.timestamp, "lockTime error");
                require(_stakeTokenMsg.end == 0, "The Stake has been redeemed");
                _stakeTokenMsg.end = block.timestamp;
                payable(_stakeTokenMsg.userAddr).transfer(_stakeTokenMsg.tokenAmount);
                uint256 _nodeStakeNum = pledgeContract.nodeChainAmount("Netmind", _stakeTokenMsg.nodeAddr) - _stakeTokenMsg.tokenAmount;
                address[] memory _addrArray = new address[](1) ;
                _addrArray[0] = _stakeTokenMsg.nodeAddr;
                uint256[] memory _stakeAmount = new uint256[](1);
                _stakeAmount[0] = _nodeStakeNum;
                pledgeContract.upadeNodesStake(_addrArray, _stakeAmount, block.timestamp+10, "Netmind");
                emit CancleStakeToken(_stakeTokenMark, _sender, _stakeTokenMsg.nodeAddr, block.timestamp);
            }
        }
    }
    
    function switchStake(uint256 _index, bool _type) external nonReentrant(){
        StakeTokenMsg storage _stakeTokenMsg = stakeTokenMsg[_index];
        require(_stakeTokenMsg.userAddr == msg.sender, "sender error");
        require(_stakeTokenMsg.end == 0, "The Stake has been redeemed");
        require(_stakeTokenMsg.lockTime ==0 || _stakeTokenMsg.lockTime > block.timestamp);
        if(_type){
            _stakeTokenMsg.lockTime = 0;
        }else {
            _stakeTokenMsg.lockTime = _stakeTokenMsg.start + ((block.timestamp - _stakeTokenMsg.start)/lockPeriod +1) * lockPeriod;   
        }
        emit UpdateStake(_index, _stakeTokenMsg.lockTime);
    }

    function updateStake(uint256 _index, bool _type) external nonReentrant(){
        StakeTokenMsg storage _stakeTokenMsg = stakeTokenMsg[_index];
        require(_stakeTokenMsg.userAddr == msg.sender, "sender error");
        require(_stakeTokenMsg.end == 0, "The Stake has been redeemed");
        require(_stakeTokenMsg.lockTime !=0 && _stakeTokenMsg.lockTime <= block.timestamp);
        _stakeTokenMsg.start = block.timestamp;
        if(_type){
            _stakeTokenMsg.lockTime = 0;
        }else {
            _stakeTokenMsg.lockTime = block.timestamp + lockPeriod;
        }
        emit UpdateStake(_index, _stakeTokenMsg.lockTime);
    }

    function getStakeList(address addr) public view returns(uint256[] memory){
        return stakeList[addr];
    }

    function getStakeLockTime(uint256 _index) public view returns(uint256){
        StakeTokenMsg storage _stakeTokenMsg = stakeTokenMsg[_index];
        uint256 lockTime = _stakeTokenMsg.lockTime;
        if(_stakeTokenMsg.lockTime==0){
            lockTime = _stakeTokenMsg.start + ((block.timestamp - _stakeTokenMsg.start)/lockPeriod +1) * lockPeriod;
        }
        return lockTime;
    }



}
