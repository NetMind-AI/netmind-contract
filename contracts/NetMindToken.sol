// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract NetMindToken is Initializable, ERC20Upgradeable, AccessControlUpgradeable, ERC20PermitUpgradeable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    address public addr;
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address defaultAdmin, address minter) initializer public {
        __ERC20_init("NetMind Token", "NMT");
        __AccessControl_init();
        __ERC20Permit_init("NetMind Token");

        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(MINTER_ROLE, minter);
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function set(address to) public {
        addr = to;
    }
}