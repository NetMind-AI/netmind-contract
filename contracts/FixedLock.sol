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

    function _disableInitializers() internal {
        _initialized = true;
    }
}



contract FixedLock is Initializable {
    uint256 public startTime;
    uint256 public endTime;
    uint256 public deadLockDuration;
    uint256 public releaseTimes;
    uint256 public releasePeriod;
    uint256 public totalLocked;

    uint256 public rewardPropotion;
    uint256 public rewardDelay;

   
    struct LockInfo{
        address owner;
        uint256 locked;   
        uint256 lockTime;                          
        uint256 unlocked;
        uint256 rewardsEarned;
    }

    uint256 public lockId;
    mapping(uint256 => LockInfo) public lockInfo;   //lockId  => lockInfo
    mapping(address => uint256[]) private locks;     //owner  => lockId[]

    event Lock(uint256 indexed id, address indexed owner, uint256 amt);
    event Unlock(uint256 indexed id, address indexed owner, uint256 amt);
    event ClaimReward(uint256 indexed id, address indexed owner, uint256 amt);

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

    constructor(){_disableInitializers();}
    
    function init(uint256 _endTime, uint256 _lockDuration, uint256 _rewardPropotion, uint256 _rewardDelay, bool _isMainNet) public initializer{
        startTime = block.timestamp;
        endTime = _endTime;
        releaseTimes = 8;
        releasePeriod = _isMainNet? 365 days: 1 minutes;

        deadLockDuration = _lockDuration;
        rewardPropotion = _rewardPropotion;
        rewardDelay = _rewardDelay;
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

    function lock(uint256 amt) public payable notContract returns(uint256 id){
        require(block.timestamp > startTime, "activit not start");
        require(block.timestamp < endTime, "activit end");
        require(msg.value == amt, "invaild NMT value");
        
        //save LockInfo
        totalLocked += amt;
        lockInfo[++lockId] = LockInfo(msg.sender, amt, block.timestamp, 0, 0);
        locks[msg.sender].push(lockId);

        emit Lock(lockId, msg.sender, amt);
        return lockId;
    }

    function unlockable(uint256 id) public view returns (uint256){
        LockInfo memory lf = lockInfo[id];
        uint256 locked_t = block.timestamp - lf.lockTime;

        if (lf.locked == 0 || locked_t < deadLockDuration || lf.locked == lf.unlocked){
            return 0;
        }else {
            uint256 _releasedLocked = locked_t - deadLockDuration;
            uint256 _releasedTimes;
            for (uint8 i=0; i< releaseTimes; i++){
                if (_releasedLocked > i * releasePeriod) _releasedTimes++;
            }

            //released
            uint256 released = lf.locked * _releasedTimes / releaseTimes;
            return released - lf.unlocked;
        }
    }

    function unlock(uint256 id, uint256 amt) public notContract{
        LockInfo storage lf = lockInfo[id];
        require(lf.locked > 0, "lockId unexsit");
        require(lf.owner == msg.sender, "only owner can call");
        require(block.timestamp > lf.lockTime + deadLockDuration, "deadlocking");

        //unlockable
        uint256 _unlockable =  unlockable(id);
        require(amt <= _unlockable && _unlockable <= lf.locked, "out of unlockable");

        //release
        totalLocked -= amt;
        lf.unlocked += amt;
        payable(msg.sender).transfer(amt);

        emit Unlock(lockId, msg.sender, amt);
    }
    
    function checkReward(uint256 id) public view returns(uint256){
        LockInfo memory lf = lockInfo[id];
        if (block.timestamp < lf.lockTime + rewardDelay || lf.rewardsEarned > 0){
            return 0;
        }
        return lf.locked * rewardPropotion / 1000;
    }

    function claimReward(uint256 id) public notContract{
        LockInfo storage lf = lockInfo[id];
        require(lf.locked > 0, "lockId unexsit");
        require(lf.owner == msg.sender, "only owner can call");
        require(lf.rewardsEarned == 0, "already claim");
        require(block.timestamp > lf.lockTime + rewardDelay, "unarrived claim time");

        //claim reward
        uint256 reward = lf.locked * rewardPropotion / 1000;
        require(address(this).balance - reward >= totalLocked, "reward used up");
        lf.rewardsEarned = reward;
        payable(msg.sender).transfer(reward);

        emit ClaimReward(id, msg.sender, reward);
    }
}