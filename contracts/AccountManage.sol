// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0 ;

interface IConf {
    function p_settlement() external returns (uint256);
    function v_settlement() external returns (uint256);
    function accountManageExecutor() external returns (address);
    function Staking() external returns (address);
    function acts(address ) external view returns(bool);
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


contract AccountManage is Ownable{
    address public conf;
    uint256 public burnAmount;
    uint256 public num;
    mapping(uint256 => UserAccountMsg) public userAccountMsg;
    mapping(string => uint256) public userAccountById;
    mapping(address => uint256) public userAccountByAddr;
    mapping(address => bool) public authSta;
    uint256 public providerFeeSum;
    bytes32 public CONTRACT_DOMAIN;
    mapping(address => uint256) public nonce;
    mapping(address => mapping(uint256 => uint256)) public withdrawData;
    uint256 public signNum;
    bool private reentrancyLock;
    
    event WithdrawToken(address indexed _userAddr, uint256 _nonce, uint256 _amount);
    event UpdateAuthSta(address _addr, bool sta);
    event InitAccount(string userId, address userAddr);
    event UpdateAccount(string userId, address userAddr);
    event TokenCharge(string userId, uint256 value, address chargeAddr);
    event Withdraw(address userAddr, string userId, uint256 value);
    event Freeze(string userId, uint256 value, uint256 balance, uint256 jobType);
    event ExecDebit(string userId, uint256 useValue, uint256 offsetValue, uint256 balance, uint256 jobType);

    struct UserAccountMsg {
        uint256 balance;
        uint256 freezed;
        string userId;
        address addr;
    }
    
    struct Data {
        address userAddr;
        uint256 amount;
        uint256 expiration;
    }

    struct Sig {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

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

    modifier nonReentrant() {
        require(!reentrancyLock);
        reentrancyLock = true;
        _;
        reentrancyLock = false;
    }

    modifier onlyExecutor() {
        require(IConf(conf).accountManageExecutor() == msg.sender, "caller is not the accountManageExecutor");
        _;
    }

    modifier onlyAuth() {
        require(authSta[msg.sender], "The caller does not have permission");
        _;
    }

    constructor(){_disableInitializers();}

    function init(address _conf)  external 
       initializer
    {
        __Ownable_init_unchained();
        __AccountManage_init_unchained(_conf);
    }

    function __AccountManage_init_unchained(address _conf) internal 
      initializer
    {
       conf = _conf;
       CONTRACT_DOMAIN = keccak256('Netmind AccountManage V1.0');
       signNum = 2;
    }
 
    function updateSignNum(uint256 _signNum) external onlyOwner{
        require(_signNum > 0, "signNum error");
        signNum = _signNum;
    }

    function updateAuthSta(address _addr, bool _sta) external onlyOwner{
        authSta[_addr] = _sta;
        emit UpdateAuthSta(_addr, _sta);
    }

    function initUserId(string memory _userId, address _addr) external onlyExecutor{
        require(userAccountById[_userId] == 0, "User id is already occupied");
        require(userAccountByAddr[_addr] == 0, "User address is already occupied");
        uint256 _num = ++num;
        UserAccountMsg storage _userAccountMsg = userAccountMsg[_num];
        _userAccountMsg.addr = _addr;
        _userAccountMsg.userId = _userId;
        userAccountById[_userId] = _num;
        userAccountByAddr[_addr] = _num;
        emit InitAccount(_userId, _addr);
    }

    function updateAccount(string memory _userId, address _addr) external onlyExecutor{
        uint256 _num = userAccountById[_userId];
        UserAccountMsg storage _userAccountMsg = userAccountMsg[_num];
        require(_num > 0, "The user id does not exist");
        userAccountByAddr[_userAccountMsg.addr] = 0;
        _userAccountMsg.addr = _addr;
        if(_addr != address(0x00)){
            require(userAccountByAddr[_addr] == 0, "This address is already in use");
            userAccountByAddr[_addr] = _num;
        }
        emit UpdateAccount(_userId, _addr);
    }

    function tokenCharge() external payable{
        address sender = msg.sender;
        uint256 _num = userAccountByAddr[sender];
        require(_num > 0, "The user id does not exist");
        UserAccountMsg storage _userAccountMsg = userAccountMsg[_num];
        _userAccountMsg.balance = _userAccountMsg.balance + msg.value;
        emit TokenCharge(_userAccountMsg.userId, msg.value, sender);
    }

    function withdraw(uint256 value) external nonReentrant(){
        address sender = msg.sender;
        uint256 _num = userAccountByAddr[sender];
        require(_num > 0, "The user id does not exist");
        UserAccountMsg storage _userAccountMsg = userAccountMsg[_num];
        require(address(this).balance >= value, "Insufficient balance");
        _userAccountMsg.balance = _userAccountMsg.balance - value;
        require(sender != address(0), "The address is 0");
        payable(sender).transfer(value);
        emit Withdraw(sender, _userAccountMsg.userId, value);
    }

    function freeze(string memory _userId, uint256 freezeValue, uint256 jobType) external onlyAuth returns(bool){
        uint256 _num = userAccountById[_userId];
        require(_num > 0, "The user id does not exist");
        UserAccountMsg storage _userAccountMsg = userAccountMsg[_num];
        _userAccountMsg.balance = _userAccountMsg.balance - freezeValue;
        _userAccountMsg.freezed = _userAccountMsg.freezed + freezeValue;
        emit Freeze(_userId, freezeValue, _userAccountMsg.balance, jobType);
        return true;
    }

    function execDebit(string memory _userId, uint256 useValue, uint256 offsetValue, uint256 jobType) external onlyAuth returns(bool){
        uint256 _num = userAccountById[_userId];
        require(_num > 0, "The user id does not exist");
        UserAccountMsg storage _userAccountMsg = userAccountMsg[_num];
        _userAccountMsg.freezed = _userAccountMsg.freezed - useValue - offsetValue;
        _userAccountMsg.balance = _userAccountMsg.balance + offsetValue;
        uint256 _settlement;
        if(jobType == 1){
            _settlement = IConf(conf).p_settlement();
        }else if(jobType == 2){
            _settlement = IConf(conf).v_settlement();
        }
        uint256 fee = _settlement * useValue / 10000 ;
        providerFeeSum = providerFeeSum + fee;
        fee = useValue - fee;
        payable(address(0x00)).transfer(fee);
        burnAmount = burnAmount + fee;
        emit ExecDebit(_userId, useValue, offsetValue, _userAccountMsg.balance, jobType);
        return true;
    }

    function withdrawComputingFee(
        address addr,
        uint256[2] calldata uints,
        uint8[] calldata vs,
        bytes32[] calldata rssMetadata
    )
        external
        nonReentrant()
        notContract()
    {   
        require(providerFeeSum >= uints[0], "Withdrawal quantity exceeds available quantity");
        require( block.timestamp<= uints[1], "The transaction exceeded the time limit");
        uint256 len = vs.length;
        uint256 counter;
        uint256 _nonce = nonce[addr]++;
        require(len*2 == rssMetadata.length, "Signature parameter length mismatch");
        bytes32 digest = getDigest(Data( addr, uints[0], uints[1]), _nonce);
        address[] memory signAddrs = new address[](len);
        for (uint256 i = 0; i < len; i++) {
            (bool result, address signAddr) = verifySign(
                digest,
                Sig(vs[i], rssMetadata[i*2], rssMetadata[i*2+1])
            );
            signAddrs[i] = signAddr;
            if (result){
                counter++;
            }
        }
       
        require(
            counter >= signNum,
            "The number of signed accounts did not reach the minimum threshold"
        );
        require(areElementsUnique(signAddrs), "Signature parameter not unique");
        withdrawData[addr][_nonce] =  uints[0];
        payable(addr).transfer(uints[0]);
        providerFeeSum = providerFeeSum - uints[0];
        emit WithdrawToken(addr, _nonce, uints[0]);
    }
    
    function queryUserMsgById(string memory _userId) external view returns (uint256, uint256, address) {
        uint256 _num = userAccountById[_userId];
        require(_num > 0, "The user id does not exist");
        UserAccountMsg storage _userAccountMsg = userAccountMsg[_num];
        return (_userAccountMsg.balance, _userAccountMsg.freezed, _userAccountMsg.addr);
    }

    function queryUserMsgByAddr(address _addr) external view returns (uint256, uint256, string memory) {
        uint256 _num = userAccountByAddr[_addr];
        require(_num > 0, "The user id does not exist");
        UserAccountMsg storage _userAccountMsg = userAccountMsg[_num];
        return (_userAccountMsg.balance, _userAccountMsg.freezed, _userAccountMsg.userId);
    }

    function DOMAIN_SEPARATOR() public view returns(bytes32){
        return keccak256(
            abi.encode(
                keccak256('EIP712Domain(uint256 chainId,address verifyingContract)'),
                block.chainid,
                address(this)
            )
        );
    }

    function areElementsUnique(address[] memory arr) internal pure returns (bool) {
        for(uint i = 0; i < arr.length - 1; i++) {
            for(uint j = i + 1; j < arr.length; j++) {
                if (arr[i] == arr[j]) {
                    return false; 
                }
            }
        }
        return true; 
    }
     
    function verifySign(bytes32 _digest,Sig memory _sig) internal view returns (bool, address)  {
        require(uint256(_sig.s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(uint8(_sig.v) == 27 || uint8(_sig.v) == 28, "ECDSA: invalid signature 'v' value");
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 hash = keccak256(abi.encodePacked(prefix, _digest));
        address signer = ecrecover(hash, _sig.v, _sig.r, _sig.s);
        //uint256 _nodeRank = IPledgeContract(IConf(conf).Staking()).queryNodeIndex(_accessAccount);
        //return (_nodeRank < 22 && _nodeRank > 0, _accessAccount);
        bool isActs = IConf(conf).acts(signer); 

        return(isActs, signer); 
    }
    
    function getDigest(Data memory _data, uint256 _nonce) internal view returns(bytes32 digest){
        digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR(),
                keccak256(abi.encode(_data.userAddr, _data.amount, _data.expiration, _nonce))
            )
        );
    }
}
