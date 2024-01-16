// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0 ;

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

interface IERC20 {
    function transfer(address to, uint256 amt) external returns(bool);
    function transferFrom(address from, address to, uint256 amt) external returns(bool);
}

contract FixedLock is Initializable, Ownable {
    address public nmt;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public lockDuration;
    uint256 public rewardPropotion;
    uint256 public rewardDelay;

    uint256 public totalLocked;

    struct LockInfo{
        address owner;
        uint256 amount;
        uint256 lockTime;
        uint256 unlockTime;
        uint256 rewardsEarned;
        uint256 rewardsClaimTime;
    }

    uint256 public lockId;
    mapping(uint256 => LockInfo) public lockInfo;   //lockId => lockInfo
    mapping(address => uint256[]) private locks;     //owner  => lockId[]

    event Lock(uint256 indexed id, address indexed owner, uint256 amt);
    event Unlock(uint256 indexed id, address indexed owner, uint256 amt);
    event Claim(uint256 indexed id, address indexed owner, uint256 amt);

    function init(address _nmt, uint256 _strat, uint256 _end, uint256 _lockDuration, uint256 _rewardPropotion, uint256 _rewardDelay) public initializer{
        nmt = _nmt;
        startTime = _strat;
        endTime = _end;
        lockDuration = _lockDuration;
        rewardPropotion = _rewardPropotion;
        rewardDelay = _rewardDelay;

        __Ownable_init_unchained();
    }

    function getLocks(address guy) public view returns(uint256[] memory){
        return locks[guy];
    }

    function getLockInfos(address guy) public view returns(LockInfo[] memory){
        uint256[] memory lockIds = locks[guy];
        LockInfo[] memory ls = new LockInfo[](lockIds.length);
        for(uint256 i=0; i<lockIds.length; i++){
            ls[i] = lockInfo[lockIds[i]];
        }

        return ls;
    }

    function lock(uint256 amt) public returns(uint256 id){
        require(block.timestamp > startTime, "activit not start");
        require(block.timestamp < endTime, "activit end");

        //recever token 
        IERC20(nmt).transferFrom(msg.sender, address(this), amt);

        //save LockInfo
        totalLocked += amt;
        lockInfo[++lockId] = LockInfo(msg.sender, amt, block.timestamp, 0, 0, 0);
        locks[msg.sender].push(lockId);

        emit Lock(lockId, msg.sender, amt);

        return lockId;
    }

    function unlock(uint256 id) public {
        LockInfo storage lf = lockInfo[id];
        require(lf.amount > 0, "lockId unexsit");
        require(lf.unlockTime == 0, "already unlock");
        require(lf.owner == msg.sender, "only owner can call");
        require(block.timestamp > lf.lockTime + lockDuration, "unarrived unlock time");

        lf.unlockTime = block.timestamp;

        //release nmt
        totalLocked -= lf.amount;
        IERC20(nmt).transfer(lf.owner, lf.amount);

        emit Unlock(lockId, msg.sender, lf.amount);
    }

    function claim(uint256 id) public {
        LockInfo storage lf = lockInfo[id];
        require(lf.amount > 0, "lockId unexsit");
        require(lf.owner == msg.sender, "only owner can call");
        require(lf.rewardsClaimTime == 0, "already claim");
        require(block.timestamp > lf.lockTime + rewardDelay, "unarrived claim time");

        if(lf.unlockTime == 0){
            totalLocked -= lf.amount;
            lf.unlockTime = block.timestamp;
            IERC20(nmt).transfer(lf.owner, lf.amount);
            emit Unlock(lockId, msg.sender, lf.amount);
        }

        //claim reward
        uint256 reward = lf.amount * rewardPropotion / 1000;
        IERC20(nmt).transfer(lf.owner, reward);
        emit Claim(id, msg.sender, reward);

        //update lockInfo
        lf.rewardsEarned = reward;
        lf.rewardsClaimTime = block.timestamp;
    }
}