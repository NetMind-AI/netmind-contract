// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract NetMindToken is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable, AccessControlUpgradeable, ERC20PermitUpgradeable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant EXECUTE_ROLE = keccak256("EXECUTE_ROLE");
    address public receiver;


    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address defaultAdmin, address minter) initializer public {
        __ERC20_init("NetMind Token", "NMT");
        __ERC20Burnable_init();
        __AccessControl_init();
        __ERC20Permit_init("NetMind Token");

        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(MINTER_ROLE, minter);
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) returns (bool) {
        _mint(to, amount);
        return true;
    }

    function updateReceiver(address addr) public onlyRole(DEFAULT_ADMIN_ROLE){
        require(addr != address(0), "addr error");
        receiver = addr;
    }

    function withdrawTokens(address[] calldata tokens) public onlyRole(EXECUTE_ROLE) {
        require(receiver != address(0), "receiver error");
        for (uint256 i = 0; i < tokens.length; i++) {
            if(tokens[i] == address(0)){
                payable(receiver).transfer(address(this).balance);
            }else {
                (bool success, ) = address(tokens[i]).call(
                    abi.encodeWithSelector(IERC20(tokens[i]).transfer.selector, receiver, IERC20(tokens[i]).balanceOf(address(this)))
                );
                require(success, "Token transfer failed");
            }
        }
    }
}
