// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0 ;

interface IERC20 {
    function approve(address spender, uint256 amount) external returns(bool);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
}

interface IPancakeRouter{
    function swapExactTokensForTokens(uint amountIn,uint amountOutMin,address[] calldata path,address to,uint deadline) external returns (uint[] memory amounts);
    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);
}

interface ICrosschain {
    function stakeToken(string memory _chain, string memory receiveAddr, address tokenAddr, uint256 _amount) external;
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

contract Purchase is Initializable,Ownable{
    bool private reentrancyLock;
    address public exector;
    address public router;
    address public usdc;
    address public nmtToken;
    address public crosschain;
    string public receiver;                           
    mapping(string => bool) public orderId;  
    
    event SwapToken(uint256 _amount, string _orderId);
    
    modifier nonReentrant() {
        require(!reentrancyLock);
        reentrancyLock = true;
        _;
        reentrancyLock = false;
    }

    constructor(){_disableInitializers();}

    function init(address _router, address _usdc, address _nmtToken, address _exector, address _crosschain, string memory _receiver) external initializer{
        __Ownable_init_unchained();
        __Purchase_init_unchained(_router, _usdc, _nmtToken, _exector, _crosschain, _receiver);
    }

    function __Purchase_init_unchained(address _router, address _usdc, address _nmtToken, address _exector, address _crosschain, string memory _receiver) internal initializer{
        router = _router;
        usdc = _usdc;
        nmtToken = _nmtToken;
        exector = _exector;
        crosschain = _crosschain;
        receiver = _receiver;
    }
    
    function updateReceiver(string memory _receiver) external onlyOwner{
        receiver = _receiver;
    }

    function updateExector(address _exector) external onlyOwner{
        require(_exector != address(0), "The address is 0");
        exector = _exector;
    }
    
    function swapToken(uint256 _amount, uint256 _minOut, string memory _orderId) external nonReentrant{
        require(msg.sender == exector, "exector error");
        require(!orderId[_orderId], "orderId error");
        orderId[_orderId] = true;
        require(IERC20(usdc).balanceOf(address(this)) >= _amount, "Insufficient balance");
        IERC20(usdc).approve(router, _amount);
        address[] memory paths = new address[](2);
        paths[0] = usdc;
        paths[1] = nmtToken;
        uint[] memory amounts = IPancakeRouter(router).swapExactTokensForTokens(
            _amount,
            _minOut,
            paths,
            address(this),
            block.timestamp+100
        );
        amounts[1] = amounts[1] / 100000000000 * 100000000000;
        IERC20(nmtToken).approve(crosschain, amounts[1]);
        ICrosschain(crosschain).stakeToken("Netmind", receiver, nmtToken, amounts[1]);
        emit SwapToken(_amount, _orderId);
    }
    
    function calculateAmountOutMin(uint amountIn) public view returns (uint) {
        address[] memory path = new address[](2);
        path[0] = usdc;
        path[1] = nmtToken;
        uint[] memory amounts = IPancakeRouter(router).getAmountsOut(amountIn, path);
        return amounts[1]; 
    }

}

