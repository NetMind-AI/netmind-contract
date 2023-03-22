// SPDX-License-Identifier: MIT
pragma solidity 0.8.0 ;

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

contract FundManagement is Ownable{
    using SafeMath for uint256;
    uint256 startTime;
    // uint256 public technologyFund;
    // uint256 public sponsorFund;
    // uint256 public investFund;
    // uint256 public vcFund;
    uint256 fundDataNum;
    mapping(uint256 => FundData) fundData;
    mapping(address => uint256) fundAddrData;
    mapping(string => bool) fundNameSta;
    struct FundData {
        string fundName;
        address fundAddr;
        uint256 fundAmount; 
        uint256 lockYear; 
        uint256 withdrawAmount; 
    }

    function init(
        uint256 _startTime,
        address[4] calldata _addrs
    )  external 
       initializer
    {
        __Ownable_init_unchained();
        __FundManagement_init_unchained(_startTime, _addrs);
    }

    function __FundManagement_init_unchained(
        uint256 _startTime,
        address[4] calldata _addrs
    ) internal 
      initializer
    {
        startTime = _startTime;
        fundDataNum = _addrs.length;
        fundData[1] = FundData("technologyFund", _addrs[0], 10 * 10 ** 18, 10, 0);
        require(fundAddrData[_addrs[0]] == 0, "This address is already occupied");
        fundAddrData[_addrs[0]] = 1;
        fundData[2] = FundData("sponsorFund", _addrs[1], 10 * 10 ** 18, 5, 0);
        require(fundAddrData[_addrs[1]] == 0, "This address is already occupied");
        fundAddrData[_addrs[1]] = 2;
        fundData[3] = FundData("investFund", _addrs[2], 10 * 10 ** 18, 5, 0);
        require(fundAddrData[_addrs[2]] == 0, "This address is already occupied");
        fundAddrData[_addrs[2]] = 3;
        fundData[4] = FundData("vcFund", _addrs[3], 10 * 10 ** 18, 5, 0);
        require(fundAddrData[_addrs[3]] == 0, "This address is already occupied");
        fundAddrData[_addrs[3]] = 4;
    }
    
    function withdrawtoken() external{
        address _sender = msg.sender;
        uint256 index = fundAddrData[_sender];
        require(index > 0, "illegal user");
        FundData storage _fundData = fundData[index];
        uint256 _withdrawAmount = _calcWithdrawAmount(_fundData);
        _fundData.withdrawAmount += _withdrawAmount;
        require(address(this).balance >= _withdrawAmount, "Insufficient balance");
        payable(_sender).transfer(_withdrawAmount);
    }

    function _calcWithdrawAmount(FundData storage _fundData) view internal returns (uint256){
        uint256 time = block.timestamp.sub(startTime).div(31536000);
        if(time> _fundData.lockYear){
            time = _fundData.lockYear;
        }
        uint256 _withdrawAmount = _fundData.fundAmount.mul(time).div(_fundData.lockYear).sub(_fundData.withdrawAmount);
        return _withdrawAmount;
    }

    function queryWithdraw(address _addr) external view returns (string memory, uint256, uint256, uint256, uint256) {
        uint256 index = fundAddrData[_addr];
        if(index == 0){
            return ("invalidAddr", 0, 0, 0, 0);
        }else{
            FundData storage _fundData = fundData[index];
            uint256 _withdrawAmount = _calcWithdrawAmount(_fundData);
            return (_fundData.fundName, _fundData.fundAmount, _fundData.lockYear, _fundData.withdrawAmount, _withdrawAmount);
        }
    }

    function queryAllFundAddr() 
        external 
        view 
        returns (
            string[] memory fundNames, 
            address[] memory fundAddrs, 
            uint256[] memory fundAmounts, 
            uint256[] memory lockYears, 
            uint256[] memory withdrawAmounts,
            uint256[] memory extractableAmounts
        ) 
    {   
        fundNames = new string[](fundDataNum);
        fundAddrs = new address[](fundDataNum);
        fundAmounts = new uint256[](fundDataNum);
        lockYears = new uint256[](fundDataNum);
        withdrawAmounts = new uint256[](fundDataNum);
        extractableAmounts = new uint256[](fundDataNum);
        FundData storage _fundData;
        uint256 _extractableAmount;
        uint256 j;
        for (uint256 i = 1; i <= fundDataNum; i++) {
            _fundData = fundData[i];
            _extractableAmount = _calcWithdrawAmount(_fundData);
            fundNames[j] = _fundData.fundName;
            fundAddrs[j] = _fundData.fundAddr;
            fundAmounts[j] = _fundData.fundAmount;
            lockYears[j] = _fundData.lockYear;
            withdrawAmounts[j] = _fundData.withdrawAmount;
            extractableAmounts[j] = _extractableAmount;
            j++;
        }
    }


}
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}
