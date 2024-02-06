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


contract Payment is Initializable, Ownable {
    bytes32 public CONTRACT_DOMAIN;
    address public conf;
    uint256 public SigNum;
    mapping(string=>recipt) public recipts;
    
    struct recipt{
       address payer;
       uint256 amount;
       uint256 worth;
       uint256 refund;
       uint256 timestamp;
    }
  
    struct Sig {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    event Pay(string id, address payer, uint256 amount, uint256 worth);
    event Refund(string id, address payer, uint256 amount);

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

    constructor(){_disableInitializers();}

    function init(address _conf, uint256 _signum) public initializer{
        require(_conf != address(0), "zero address");
        require(_signum > 0, "zero signum");
       
        conf = _conf;
        SigNum = _signum;
        __Ownable_init_unchained();

        uint chainId = block.chainid;
        CONTRACT_DOMAIN = keccak256('Netmind Payment V1.0');
    }

    function payment(string memory paymentId, uint256 amt, uint256 worth) public payable notContract{
         recipt storage R = recipts[paymentId];
         require(R.amount <= 0, "invalid payment Id");
         require(amt == msg.value, "invalid amt");

         R.amount = amt;
         R.payer = msg.sender;
         R.worth = worth;
         R.timestamp = block.timestamp;
    
         emit Pay(paymentId, R.payer, R.amount, R.worth);
    }

    function refund(string memory paymentId, uint256 amt, uint256 expir, uint8[] calldata vs, bytes32[] calldata rs) public notContract{
        //check args
        recipt storage R = recipts[paymentId];
        require(R.refund <= 0, "already refund");
        require(R.amount > 0, "invalid paymentId");
        require(R.amount >= amt, "invalid amt");
        require(block.timestamp <= expir, "sign expired");
      

        //check sign
        uint256 counter;
        uint256 len = vs.length;
        require(len*2 == rs.length, "Signature parameter length mismatch");

        bytes32 digest = getDigest(paymentId, amt, expir);
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

        //refund
        R.refund = amt;
        payable(R.payer).transfer(amt);
        emit Refund(paymentId, R.payer, amt);
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
    
    function getDigest(string memory paymentId, uint256 amt, uint256 expir) internal view returns(bytes32 digest){
        digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR(),
                keccak256(abi.encode(paymentId, amt, expir)))
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

