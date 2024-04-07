// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0 ;

library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }


    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }


    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
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


contract FixedLock is Initializable {
    uint256 public startTime;
    uint256 public endTime;
    uint256 public releaseStart;      //2026-04-16 00:00:00
    uint256 public releaseEnd;        //2030-04-16 00:00:00    
    uint256 public releaseDuration;   
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

    //new tokenomic 
    bool public isReset;    

    event Lock(uint256 indexed id, address indexed owner, uint256 amt);
    event Unlock(uint256 indexed id, address indexed owner, uint256 amt);
    event ClaimReward(uint256 indexed id, address indexed owner, uint256 amt);

    modifier notContract() {
        require((!_isContract(msg.sender)) && (msg.sender == tx.origin), "contract not allowed");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner(), "only owner allowed");
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
        //already initialized
        
        /* 
        require(endTime > block.timestamp,"invalid time");
        startTime = block.timestamp;
        endTime = _endTime;
        releaseTimes = 8;
        releasePeriod = _isMainNet? 365 days: 1 minutes;

        deadLockDuration = _lockDuration;
        rewardPropotion = _rewardPropotion; 
        rewardDelay = _rewardDelay;
        */
    }

    function owner() public view returns(address){
        //EIP1967 Admin_solt: keccak-256 hash of "eip1967.proxy.admin" subtracted by 1
        bytes32 _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }
    
    function reset(uint256 start, uint256 target, address vestReceiver) public onlyOwner{
        require(!isReset, "already reset");
        //reset global state
        //releaseStart = 1776297600; //2026-04-16 00:00:00
        //tearget = 500_0000e18;
        releaseStart = start;
        releaseEnd = start + 4 * 365 days;
        releaseDuration = releaseEnd - releaseStart;

        uint256 newTotalLocked = target* 1e18;
       
        for(uint256 i = 1; i <= lockId; i++){
            lockInfo[i].locked = lockInfo[i].locked *  newTotalLocked / totalLocked;
        }

        uint256 vest = address(this).balance - newTotalLocked;
        payable(vestReceiver).transfer(vest);

        totalLocked = newTotalLocked;
        isReset = true;
    }

    function refund(uint256 id, uint256 amt) public onlyOwner{
        LockInfo storage lf = lockInfo[id];
        require(lf.locked >= amt, "out of locked");
        lf.locked -= amt;
        totalLocked -= amt;
        payable(lf.owner).transfer(amt);
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
        amt = amt * 1e18;
        require(block.timestamp > startTime, "activit not start");
        require(block.timestamp < endTime, "activit end");
        require(msg.value == amt , "invaild NMT value");
        
        //save LockInfo
        totalLocked += amt;
        lockInfo[++lockId] = LockInfo(msg.sender, amt, block.timestamp, 0, 0);
        locks[msg.sender].push(lockId);

        emit Lock(lockId, msg.sender, amt);
        return lockId;
    }

    function released(uint256 id) public view returns (uint256){
        LockInfo memory lf = lockInfo[id];
        if (lf.locked == 0 || block.timestamp < releaseStart || lf.locked == lf.unlocked){
            return 0;
        }

        uint256 released_t = block.timestamp <= releaseEnd? block.timestamp - releaseStart : releaseEnd - releaseStart; 
        return (lf.locked * released_t / releaseDuration) - lf.unlocked;
    }

    function unlock(uint256 id, uint256 amt) public notContract{
        amt = amt * 1e18;
        LockInfo storage lf = lockInfo[id];
        require(lf.locked > 0, "lockId unexsit");
        require(lf.owner == msg.sender, "only owner can call");
        require(amt > 0, "amt can not be zero");

        //unlockable
        uint256 _released =  released(id);
        require(amt <= _released && _released <= lf.locked, "out of unlockable");

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