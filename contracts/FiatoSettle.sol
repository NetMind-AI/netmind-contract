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

contract FiatoSettle is Initializable{
    bool private reentrancyLock;
    address public payment;
    event Distribute(address receiver, uint256 amount, uint256 burn);
    
    modifier nonReentrant() {
        require(!reentrancyLock);
        reentrancyLock = true;
        _;
        reentrancyLock = false;
    }

    constructor(){_disableInitializers();}

    function init(address _payment) external initializer{
        __FiatoSettle_init_unchained(_payment);
    }

    function __FiatoSettle_init_unchained(address _payment) internal initializer{
        payment = _payment;
    }
    
    function distribute(address receiver, uint256 amount, uint256 burn) external nonReentrant returns(bool){
        require(msg.sender == payment, "payment error");
        require(address(this).balance >= amount + burn, "payment error");
        if (amount > 0) payable(receiver).transfer(amount);
        if (burn> 0) payable(address(0)).transfer(burn);
        emit Distribute(receiver, amount, burn);
        return true;
    }
    
}

