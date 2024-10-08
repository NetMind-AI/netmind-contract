// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0 ;

interface IERC20 {
    function transfer(address _to, uint256 _value) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function mint(address to, uint256 value) external returns (bool);
    function burn(uint256 amount) external;
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
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
     * @dev Initializes the contract setting the management contract as the initial owner.
     */
    function __Ownable_init_unchained(address _management) internal initializer {
        require( _management != address(0),"management address cannot be 0");
        _owner = _management;
        emit OwnershipTransferred(address(0), _management);
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

contract Crosschain  is Initializable,Ownable {
    bool public pause;
    uint256 public nodeNum;
    uint256 public stakeNum;
    bytes32 public CONTRACT_DOMAIN;
    bool public mainChainSta;
    mapping(string => mapping(address => uint256)) public chargeRate;
    mapping(address => uint256) public tokenSta;
    mapping(address => uint256) feeAmount;
    mapping(string => bool) public chainSta;
    mapping(string => mapping(string => bool)) status;
    mapping(address => uint256) nodeAddrIndex;
    mapping(uint256 => address) public nodeIndexAddr;
    mapping(address => bool) public nodeAddrSta;
    mapping(uint256 => Stake) public stakeMsg;
    address public exector;
    mapping(address => uint256) public stakeThreshold;
    mapping(address => mapping(uint256 => uint256)) public stakingDailyUsage;
    uint256 public signNum;
    address public trader;
    bool private reentrancyLock;
    mapping(address => uint256) public transferThreshold;
    mapping(address => mapping(uint256 => uint256)) public transferDailyUsage;
    address public blacker;
    mapping(address => bool) public blacklist;
    event UpdatePause(bool sta);
    event WithdrawChargeAmount(address tokenAddr, uint256 amount);
    event AddNodeAddr(address[] nodeAddrs);
    event DeleteNodeAddr(address[] nodeAddrs);
    event UpdateChainCharge(string chain, bool sta, address[] tokens, uint256[] fees);
    event TransferToken(address indexed _tokenAddr, address _receiveAddr, uint256 _amount, string chain, string txid);
    event StakeToken(address indexed _tokenAddr, address indexed _userAddr, string receiveAddr, uint256 amount, uint256 fee,string chain);
    event UpdateThreshold(address tokenAddr, uint256 thresholdType, uint256 threshold);
    
    struct Data {
        address userAddr;
        address contractAddr;
        uint256 amount;
        uint256 expiration;
        string chain;
        string txid;
    }

    struct Stake {
        address tokenAddr;
        address userAddr;
        string receiveAddr;
        uint256 amount;
        uint256 fee;
        string chain;
    }

    struct Sig {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    modifier nonReentrant() {
        require(!reentrancyLock);
        reentrancyLock = true;
        _;
        reentrancyLock = false;
    }

    modifier onlyBlocker{
        require(msg.sender == blacker, "only blocker");
        _;
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

    modifier onlyGuard() {
        require(!pause, "Crosschain: The system is suspended");
        _;
    }

    constructor(){_disableInitializers();}

    function init(
        address _management,
        bool _sta
    )  external initializer{
        __Ownable_init_unchained(_management);
        __Crosschain_init_unchained(_sta);
    }

    function __Crosschain_init_unchained(bool _sta) internal initializer{
        mainChainSta = _sta;
         CONTRACT_DOMAIN = keccak256('Netmind Crosschain V1.0');
    }

    function updateTrader(address _trader) external onlyOwner{
        require(_trader != address(0), "The address is 0");
        trader = _trader;
    }
    
    function setBlacker(address guy) public onlyOwner{
        require(guy != address(0), "zero address");
        blacker = guy;
    }
   
    function addBlacklist(address[] memory guys) public onlyBlocker {
        for (uint256 i = 0; i< guys.length; i++){
            require(guys[i] != address(0), "zero address");
            require(!blacklist[guys[i]], "Already blacklisted");
            blacklist[guys[i]] = true;
        }
    }

    function removeBlacklist(address[] memory guys) public onlyOwner{
        for (uint256 i = 0; i< guys.length; i++){
            require(blacklist[guys[i]], "Not a blacklist");
            blacklist[guys[i]] = false;
        }
    }

    function updateExector(address _exector) external onlyOwner{
        require(_exector != address(0), "The address is 0");
        exector = _exector;
    }

    function updateThreshold(address[] calldata _tokens, uint256[] calldata _thresholdTypes, uint256[] calldata _thresholds) external onlyOwner{
        require(_tokens.length == _thresholdTypes.length && _tokens.length == _thresholds.length , "Parameter array length does not match");
        for (uint256 i = 0; i< _tokens.length; i++){
            require(_thresholdTypes[i] == 1 || _thresholdTypes[i] == 2, "Parameter error");
            if(_thresholdTypes[i] == 1){
                stakeThreshold[_tokens[i]] = _thresholds[i];
            }else {
                transferThreshold[_tokens[i]] = _thresholds[i];
            }
            emit UpdateThreshold(_tokens[i], _thresholdTypes[i], _thresholds[i]);
        }
    }

    function updateSignNum(uint256 _signNum) external onlyOwner{
        require(_signNum > nodeNum/2, " parameter error");
        signNum = _signNum;
    }

    function updatePause(bool _sta) external onlyOwner{
        pause = _sta;
        emit UpdatePause(_sta);
    }
    
    function close() external{
        require(exector == msg.sender, "not exector");
        pause = true;
    }

    function updateChainCharge(
        string calldata _chain, 
        bool _sta, 
        address[] calldata _tokens, 
        uint256[] calldata _fees,
        uint256[] calldata _stas
    ) external onlyOwner
    {
        chainSta[_chain] = _sta;
        require(_tokens.length == _fees.length && _fees.length == _stas.length, "Parameter array length does not match");
        for (uint256 i = 0; i< _tokens.length; i++){
            chargeRate[_chain][_tokens[i]] = _fees[i];
            require(_stas[i] < 3, "Incorrect token state setting");
            tokenSta[_tokens[i]] = _stas[i];
        }
        emit UpdateChainCharge(_chain, _sta, _tokens, _fees);
    }

    function withdrawChargeAmount(address[] calldata tokenAddrs, address receiveAddr) external onlyOwner nonReentrant(){
        require( receiveAddr != address(0),"receiveAddr address cannot be 0");
        for (uint256 i = 0; i< tokenAddrs.length; i++){
            uint256 _feeAmount = feeAmount[tokenAddrs[i]];
            feeAmount[tokenAddrs[i]] = 0;
            if(tokenAddrs[i] == address(0x0)){
                require(address(this).balance >= _feeAmount, "Insufficient amount of balance");
                payable(receiveAddr).transfer(_feeAmount);
            }else{
                IERC20 token = IERC20(tokenAddrs[i]);
                token.transfer(receiveAddr,_feeAmount);
            }
            emit WithdrawChargeAmount(tokenAddrs[i], _feeAmount);
        }
    }

    function addNodeAddr(address[] calldata _nodeAddrs) external onlyOwner{
        for (uint256 i = 0; i< _nodeAddrs.length; i++){
            address _nodeAddr = _nodeAddrs[i];
            require(!nodeAddrSta[_nodeAddr], "This node is already a node address");
            nodeAddrSta[_nodeAddr] = true;
            uint256 _nodeAddrIndex = nodeAddrIndex[_nodeAddr];
            if (_nodeAddrIndex == 0){
                _nodeAddrIndex = ++nodeNum;
                nodeAddrIndex[_nodeAddr] = _nodeAddrIndex;
                nodeIndexAddr[_nodeAddrIndex] = _nodeAddr;
            }
        }
        emit AddNodeAddr(_nodeAddrs);
    }

    function deleteNodeAddr(address[] calldata _nodeAddrs) external onlyOwner{
        for (uint256 i = 0; i< _nodeAddrs.length; i++){
            address _nodeAddr = _nodeAddrs[i];
            require(nodeAddrSta[_nodeAddr], "This node is not a pledge node");
            nodeAddrSta[_nodeAddr] = false;
            uint256 _nodeAddrIndex = nodeAddrIndex[_nodeAddr];
            if (_nodeAddrIndex > 0){
                uint256 _nodeNum = nodeNum;
                address _lastNodeAddr = nodeIndexAddr[_nodeNum];
                nodeAddrIndex[_lastNodeAddr] = _nodeAddrIndex;
                nodeIndexAddr[_nodeAddrIndex] = _lastNodeAddr;
                nodeAddrIndex[_nodeAddr] = 0;
                nodeIndexAddr[_nodeNum] = address(0x0);
                nodeNum--;
            }
        }
        emit DeleteNodeAddr(_nodeAddrs);
    }

    function stakeToken(string memory _chain, string memory receiveAddr, address tokenAddr, uint256 _amount) payable external onlyGuard nonReentrant(){
        address _sender = msg.sender;
        require( chainSta[_chain], "Crosschain: The chain does not support transfer");
        uint256 _sta = tokenSta[tokenAddr];
        IERC20 token = IERC20(tokenAddr);
        if(tokenAddr == address(0)){
            _amount = msg.value;
        }else {
            require(msg.value == 0, "Value must be equal to 0");
            require(_sta > 0, "Incorrect token state setting");
            require(token.transferFrom(_sender,address(this),_amount), "Token transfer failed");
        }
        require(_amount > 0, "The _amount is 0");
        require(verfylimit(tokenAddr, 1 , _amount),"Extraction limit exceeded");
        uint256 _fee = chargeRate[_chain][tokenAddr];
        require(_amount > _fee, "Amount must be greater than fee");
        _amount = _amount - _fee;
        feeAmount[tokenAddr] = feeAmount[tokenAddr] + _fee;
        stakeMsg[++stakeNum] = Stake(tokenAddr, _sender, receiveAddr, _amount, _fee, _chain);
        if(_sta == 2){
            token.burn(_amount);
        }
        emit StakeToken(tokenAddr, _sender, receiveAddr, _amount, _fee, _chain);
    }

    function bridgeToken(
        address[2] calldata addrs,
        uint256[2] calldata uints,
        string[] calldata strs,
        uint8[] calldata vs,
        bytes32[] calldata rssMetadata
    )
        external
        onlyGuard
        nonReentrant()
        notContract()
    {
        require(!blacklist[addrs[0]], "Crosschain: access denied");
        require( trader == msg.sender, "Crosschain: The trader error");
        require( block.timestamp<= uints[1], "Crosschain: The transaction exceeded the time limit");
        require( !status[strs[0]][strs[1]], "Crosschain: The transaction has been withdrawn");
        status[strs[0]][strs[1]] = true;
        uint256 len = vs.length;
        uint256 counter;
        require(len*2 == rssMetadata.length, "Crosschain: Signature parameter length mismatch");
        require(verfylimit(addrs[1], 2, uints[0]),"Extraction limit exceeded");
        bytes32 digest = getDigest(Data( addrs[0], addrs[1], uints[0], uints[1], strs[0], strs[1]));
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
        uint256 _signNum = (signNum != 0) ? signNum : nodeNum/2;
        require(
            counter > _signNum,
            "The number of signed accounts did not reach the minimum threshold"
        );
        require(areElementsUnique(signAddrs), "Signature parameter not unique");
        _transferToken(addrs, uints, strs);
    }
    
    function queryLimit(address token) external view returns (uint256, uint256, uint256, uint256, uint256) {
        uint256 day = block.timestamp/86400;
        uint256 flashTime = (day+1) *86400;
        return (stakeThreshold[token],
                stakingDailyUsage[token][day], 
                transferThreshold[token],
                transferDailyUsage[token][day],
                flashTime);
    }

    function queryCharge(address[] calldata addrs) external view returns (address[] memory, uint256[] memory) {
        address[] memory _addrArray = new address[](1) ;
        uint256[] memory _chargeAmount = new uint256[](1) ;
        uint256 len = addrs.length;
        _addrArray = new address[](len) ;
        _chargeAmount = new uint256[](len) ;
        for (uint256 i = 0; i < len; i++) {
            _addrArray[i] = addrs[i];
            _chargeAmount[i] = feeAmount[addrs[i]];
        }
        return (_addrArray, _chargeAmount);
    }
        
    function queryNode() external view returns (address[] memory) {
        address[] memory _addrArray = new address[](nodeNum) ;
        uint j;
        for (uint256 i = 1; i <= nodeNum; i++) {
            address _nodeAddr = nodeIndexAddr[i];
            _addrArray[j] = _nodeAddr;
            j++;
        }
        return (_addrArray);
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

    function _transferToken(address[2] memory addrs, uint256[2] memory uints, string[] memory strs) internal {
        if(addrs[1] == address(0)){
            require(address(this).balance >= uints[0], "Insufficient amount of balance");
            payable(addrs[0]).transfer(uints[0]);
        }else {
            require( tokenSta[addrs[1]] >0 , "Crosschain: The token does not support transfers");
            IERC20 token = IERC20(addrs[1]);
            if(tokenSta[addrs[1]] == 1){
                require(token.transfer(addrs[0], uints[0]), "Token transfer failed");
            }else{
                require(token.mint(addrs[0], uints[0]), "Token transfer failed");
            }
            
        }
        emit TransferToken(addrs[0], addrs[1], uints[0], strs[0], strs[1]);
    }

    function verifySign(bytes32 _digest,Sig memory _sig) internal view returns (bool, address)  {
        require(uint256(_sig.s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(uint8(_sig.v) == 27 || uint8(_sig.v) == 28, "ECDSA: invalid signature 'v' value");
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 hash = keccak256(abi.encodePacked(prefix, _digest));
        address _nodeAddr = ecrecover(hash, _sig.v, _sig.r, _sig.s);
        require(_nodeAddr !=address(0),"Illegal signature");
        return (nodeAddrSta[_nodeAddr], _nodeAddr);
    }
    
    function verfylimit(address token, uint256 thresholdType, uint256 amount) internal returns (bool) {
        uint256 day = block.timestamp/86400;
        if(thresholdType == 1){
            stakingDailyUsage[token][day] += amount;
            return stakeThreshold[token] > stakingDailyUsage[token][day];
        }else {
            transferDailyUsage[token][day] += amount;
            return transferThreshold[token] > transferDailyUsage[token][day];
        }
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

    function getDigest(Data memory _data) internal view returns(bytes32 digest){
        digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR(),
                keccak256(abi.encode(_data.userAddr, _data.contractAddr,  _data.amount, _data.expiration, _data.chain, _data.txid))
            )
        );
    }
    
}

