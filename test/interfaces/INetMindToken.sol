// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface INetMindToken {
    error AccessControlBadConfirmation();
    error AccessControlUnauthorizedAccount(address account, bytes32 neededRole);
    error ECDSAInvalidSignature();
    error ECDSAInvalidSignatureLength(uint256 length);
    error ECDSAInvalidSignatureS(bytes32 s);
    error ERC20InsufficientAllowance(
        address spender,
        uint256 allowance,
        uint256 needed
    );
    error ERC20InsufficientBalance(
        address sender,
        uint256 balance,
        uint256 needed
    );
    error ERC20InvalidApprover(address approver);
    error ERC20InvalidReceiver(address receiver);
    error ERC20InvalidSender(address sender);
    error ERC20InvalidSpender(address spender);
    error ERC2612ExpiredSignature(uint256 deadline);
    error ERC2612InvalidSigner(address signer, address owner);
    error InvalidAccountNonce(address account, uint256 currentNonce);
    error InvalidInitialization();
    error NotInitializing();
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event EIP712DomainChanged();
    event Initialized(uint64 version);
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function DEFAULT_ADMIN_ROLE() external view returns (bytes32);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function MINTER_ROLE() external view returns (bytes32);

    function allowance(address owner, address spender)
    external
    view
    returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function burn(uint256 value) external;

    function burnFrom(address account, uint256 value) external;

    function decimals() external view returns (uint8);

    function eip712Domain()
    external
    view
    returns (
        bytes1 fields,
        string memory name,
        string memory version,
        uint256 chainId,
        address verifyingContract,
        bytes32 salt,
        uint256[] memory extensions
    );

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function hasRole(bytes32 role, address account)
    external
    view
    returns (bool);

    function initialize(address defaultAdmin, address minter) external;

    function mint(address to, uint256 amount) external returns (bool);

    function name() external view returns (string memory);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function renounceRole(bytes32 role, address callerConfirmation) external;

    function revokeRole(bytes32 role, address account) external;

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}
