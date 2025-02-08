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

contract FiatoSettle is Initializable, Ownable{
    bool private reentrancyLock;
    address public payment;
    address public burnAddr;
    address public accountManage;
    event Distribute(address receiver, uint256 amount, uint256 burn);
    event DistributeAndBurn(address gpu_provider, uint256 gpu_nmt, address platform, uint256 platform_nmt, uint256 burn);
    
    modifier nonReentrant() {
        require(!reentrancyLock);
        reentrancyLock = true;
        _;
        reentrancyLock = false;
    }

    constructor(){_disableInitializers();}

    function init(address _payment) external initializer{
        __Ownable_init_unchained();
        __FiatoSettle_init_unchained(_payment);
    }

    function __FiatoSettle_init_unchained(address _payment) internal initializer{
        payment = _payment;
    }
    
    function setAccountManage(address _accountManage) external onlyOwner{
        accountManage = _accountManage;
    }
 
    function setBurnAddr(address _burnAddr) external onlyOwner{
        burnAddr = _burnAddr;
    }

    function distribute(address receiver, uint256 amount, uint256 burn) external nonReentrant returns(bool){
        require(msg.sender == payment || msg.sender == accountManage, "sender error");
        require(address(this).balance >= amount + burn, "fiatoSettle error");
        if (amount > 0) payable(receiver).transfer(amount);
        if (burn> 0) payable(burnAddr).transfer(burn);
        emit Distribute(receiver, amount, burn);
        return true;
    }
    
    function distribute(address gpu_provider, uint256 gpu_nmt, address platform, uint256 platform_nmt, uint256 burn) external returns(bool){
        require(msg.sender == payment || msg.sender == accountManage, "sender error");
        require(address(this).balance >= gpu_nmt + platform_nmt + burn, "fiatoSettle error");
        if (gpu_nmt > 0) payable(gpu_provider).transfer(gpu_nmt);
        if (platform_nmt > 0) payable(platform).transfer(platform_nmt);
        if (burn> 0) payable(0).transfer(burn);
        emit DistributeAndBurn(gpu_provider, gpu_nmt, platform, platform_nmt, burn);
        return true;
    }
}

