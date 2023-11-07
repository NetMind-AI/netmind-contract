// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0 ;

interface IERC20 {
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
}

interface IPledgeContract {
    function queryNodeIndex(address _nodeAddr) external view returns(uint256);
}

interface IEfficacyContract {
    function verfiyParams(address[2] calldata addrs,uint256[2] calldata uints,bytes32 code, bytes32 digest) external view returns(bool);
}

interface IConf {
    function Staking() external returns (address);
}

interface IRewardContract {
    function withdrawToken(address[2] calldata addrs,uint256[2] calldata uints,uint8[] calldata vs,bytes32[] calldata rssMetadata) external;
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
contract RewardContract is Initializable,Ownable,IRewardContract {
    IConf public conf;
    bytes32 public DOMAIN_SEPARATOR;
    bool public pause;
    mapping(address => uint256) public nonce;
    mapping(address => mapping(uint256 => WithdrawData)) public withdrawData;
    IEfficacyContract public efficacyContract;
    address public exector;
    uint256 public threshold;
    mapping(uint256 => uint256) public withdrawLimit;
    uint256 public signNum;
    event WithdrawToken(address indexed _userAddr, address _tokenAddr,uint256 _nonce, uint256 _amount);

    struct Data {
        address userAddr;
        address contractAddr;
        uint256 amount;
        uint256 expiration;
    }

    struct WithdrawData {
        address tokenAddr;
        uint256 amount;
    }

    struct Sig {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    modifier onlyGuard() {
        require(!pause, "RewardContract: The system is suspended");
        _;
    }

    function init(address _conf) external initializer{
        __Ownable_init_unchained();
        __Reward_init_unchained(_conf);
    }
    
    function __Reward_init_unchained(address _conf) internal initializer{
        require(_conf != address(0), "conf address cannot be 0");
        conf = IConf(_conf);
        uint chainId;
        assembly {
            chainId := chainId
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(uint256 chainId,address verifyingContract)'),
                chainId,
                address(this)
            )
        );
    }

    receive() payable external{

    }

    function updateExector(address _exector) external onlyOwner{
        exector = _exector;
    }

    function updatePause(bool _sta) external onlyOwner{
        pause = _sta;
    }

    function updateThreshold(uint256 _threshold) external onlyOwner{
        threshold = _threshold;
    }

    function updateSignNum(uint256 _signNum) external onlyOwner{
        require(_signNum > 18, "IncentiveContracts: parameter error");
        signNum = _signNum;
    }
   
    function close() external{
        require(exector == msg.sender, "not exector");
        pause = true;
    }

    function withdrawToken(
        address[2] calldata addrs,
        uint256[2] calldata uints,
        uint8[] calldata vs,
        bytes32[] calldata rssMetadata
    )
        override
        external
        onlyGuard
    {
        require(addrs[0] == msg.sender, "RewardContract: Signing users are not the same as trading users");
        require( block.timestamp<= uints[1], "RewardContract: The transaction exceeded the time limit");
        uint256 len = vs.length;
        uint256 counter;
        uint256 _nonce = nonce[addrs[0]]++;
        require(len*2 == rssMetadata.length, "RewardContract: Signature parameter length mismatch");
        require(verfylimit(uints[0]),"Extraction limit exceeded");
        bytes32 digest = getDigest(Data( addrs[0], addrs[1], uints[0], uints[1]), _nonce);
        address[] memory signAddrs = new address[](len);
        for (uint256 i = 0; i < len; i++) {
            (bool result, address signAddr) = verifySign(
                digest,
                Sig(vs[i], rssMetadata[i*2], rssMetadata[i*2+1])
            );
            if (result){
                counter++;
                signAddrs[i] = signAddr;
            }
            if (counter >= 18){
                break;
            }
        }
        uint256 _signNum = (signNum != 0) ? signNum : 18;
        require(
            counter >= _signNum,
            "The number of signed accounts did not reach the minimum threshold"
        );
        require(areElementsUnique(signAddrs), "Signature parameter not unique");
        withdrawData[addrs[0]][_nonce] =  WithdrawData(addrs[1], uints[0]);
        if(addrs[1] == address(0x0)){
            require(address(this).balance >= uints[0], "Insufficient contract balance");
            payable(msg.sender).transfer(uints[0]);
        }else{
            IERC20 token = IERC20(addrs[1]);
            require(
                token.transfer(addrs[0],uints[0]),
                "Token transfer failed"
            );
        }
        emit WithdrawToken(addrs[0], addrs[1], _nonce, uints[0]);
    }
    
    function verifySign(bytes32 _digest,Sig memory _sig) internal returns (bool, address)  {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 hash = keccak256(abi.encodePacked(prefix, _digest));
        address _accessAccount = ecrecover(hash, _sig.v, _sig.r, _sig.s);
        uint256 _nodeRank = IPledgeContract(conf.Staking()).queryNodeIndex(_accessAccount);
        return (_nodeRank < 22 && _nodeRank > 0, _accessAccount);
    }
    
    function verfylimit(uint256 amount) internal returns (bool) {
        uint256 day = block.timestamp/86400;
        withdrawLimit[day] += amount;
        return threshold > withdrawLimit[day];
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

    function getDigest(Data memory _data, uint256 _nonce) internal view returns(bytes32 digest){
        digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(_data.userAddr, _data.contractAddr,  _data.amount, _data.expiration, _nonce))
            )
        );
    }
}

