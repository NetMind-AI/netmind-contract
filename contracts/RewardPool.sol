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


interface IConf {
    function acts(address ) external view returns(bool);
}


contract RewardPool is Initializable, Ownable {
    bytes32 public CONTRACT_DOMAIN;
    address public conf;
    address public Rewardcontract;
    uint256 public DailyMaxMove;
    uint256 public SigNum;
    uint256 public MoveNonce;
    mapping(uint256 => uint256) public DailyMoved;

    //manage move amount
    uint256 public Moveable;
    uint256 public BurnNonce;

    event Move(uint256 indexed day, uint256 timestamp, address op, uint256 amt);
    event Burn(uint256 indexed day, uint256 timestamp, address op, uint256 amt);


    struct Sig {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    function setMoveable(uint256  amt) public onlyOwner{
        Moveable = amt;
    }

    function setSigNum(uint256 num) public onlyOwner{
        SigNum = num;
    }
    
    function setDailyMaxMove(uint256 amt) public onlyOwner{
        DailyMaxMove = amt;
    }

    constructor(){_disableInitializers();}

    function init(address _conf, address _reward, uint256 _dailymaxmove, uint256 _signum, uint256 _moveable) public initializer{
        require(_conf != address(0), "_conf is zero address");
        require(_reward != address(0), "_reward is zero address");

        conf = _conf;
        Rewardcontract = _reward;
        DailyMaxMove = _dailymaxmove;
        SigNum = _signum;
        Moveable = _moveable;

        __Ownable_init_unchained();
        CONTRACT_DOMAIN = keccak256('Netmind RewardPool V1.0');
    }

    function move(uint256 nonce, uint256 amt,uint256 expir, uint8[] calldata vs, bytes32[] calldata rs) public{
        //check input
        require(nonce == MoveNonce++, "error nonce");
        require(amt <= Moveable, "out of moveable");
        require(block.timestamp <= expir, "sign expired");
        
        //check sign
        uint256 counter;
        uint256 len = vs.length;
        require(len*2 == rs.length, "Signature parameter length mismatch");
        bytes32 digest = getDigest(nonce, amt, expir);
        address[] memory signAddrs = new address[](len);
        for (uint256 i = 0; i < len; i++) {
            (bool result, address signAddr) = verifySign(digest, Sig(vs[i], rs[i*2], rs[i*2+1]));
            signAddrs[i] = signAddr;
            if (result){
                counter++;
            }
        }
        require(counter >= SigNum, "lack of signature");
        require(areElementsUnique(signAddrs), "duplicate signature");

        //move 
        uint256 day = block.timestamp / 1 days;
        DailyMoved[day]+= amt;
        require(DailyMoved[day] <= DailyMaxMove, "Out of daily max move");
        Moveable -= amt;
        payable(Rewardcontract).transfer(amt);
    
        emit Move(day, block.timestamp, msg.sender, amt);
    }

    function burn(uint256 nonce, uint256 amt,uint256 expir, uint8[] calldata vs, bytes32[] calldata rs) public{
        //check input
        require(nonce == BurnNonce++, "error nonce");
        require(amt <= Moveable, "out of moveable");
        require(block.timestamp <= expir, "sign expired");
        
        //check sign
        uint256 counter;
        uint256 len = vs.length;
        require(len*2 == rs.length, "Signature parameter length mismatch");
        bytes32 digest = getDigest(nonce, amt, expir);
        address[] memory signAddrs = new address[](len);
        for (uint256 i = 0; i < len; i++) {
            (bool result, address signAddr) = verifySign(digest, Sig(vs[i], rs[i*2], rs[i*2+1]));
            signAddrs[i] = signAddr;
            if (result){
                counter++;
            }
        }
        require(counter >= SigNum, "lack of signature");
        require(areElementsUnique(signAddrs), "duplicate signature");

        //move 
        uint256 day = block.timestamp / 1 days;
        DailyMoved[day]+= amt;
        require(DailyMoved[day] <= DailyMaxMove, "Out of daily max move");
        Moveable -= amt;
        payable(address(0)).transfer(amt);
    
        emit Burn(day, block.timestamp, msg.sender, amt);
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
        bool isActs = IConf(conf).acts(signer); 
        return(isActs, signer); 
    }
    
    function getDigest(uint256 nonce, uint256 amt, uint256 expir) internal view returns(bytes32 digest){
        digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR(),
                keccak256(abi.encode(nonce, amt, expir)))
        );
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
}

