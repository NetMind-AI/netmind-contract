// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0 ;

interface ISnapshoot {
    function updateSnapshoot(
        uint256[] calldata _types, 
        uint256[] calldata _days,
        string[] calldata _dataHashs,
        string[] calldata _dataIds
    )  external;
}

interface IPledgeContract {
    function queryNodeIndex(address _nodeAddr) external view returns(uint256);
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

contract Snapshoot is Initializable, ISnapshoot{
    using SafeMath for uint256;   
    IPledgeContract public pledgeContract;
    uint256 public startDay;
    uint256 snapshootNum; 
    mapping(uint256 => SnapshootMsg)  snapshootIndex;
    mapping(uint256 => mapping(uint256 => uint256)) snapshootMsg;

    event UpdateSnapshoot(uint256 _type, uint256 _day, string dataHash, string dataId); 
    event UpdateSnapshootFail(uint256 _type, uint256 _day, string dataHash, string dataId); 
 
    struct DataMsg{
        string dataId;
        string dataHash;
    }

    struct SnapshootMsg{
        uint256  nodeVoteNum;
        mapping(uint256 => DataMsg)  dataFlag;
        uint256  dataFlagNum;
        mapping(uint256 => uint256) dataFlagIndex;
        mapping(uint256 => uint256) dataIndexFlag;
        mapping(uint256 => uint256) dataVotes;
        mapping(address => bool) addrSta;
        address[] voteAddrList;
        uint256[] voteTimeList;          
        uint256  consensusSta;
        uint256  time;      
    }

    function init(address _pledgeContract) external initializer{
        __Snapshoot_init_unchained(_pledgeContract);
    }

    function __Snapshoot_init_unchained(address _pledgeContract) internal initializer{
        pledgeContract = IPledgeContract(_pledgeContract);
        startDay = (block.timestamp + 9900) / 86400;
    }
 
    fallback() external{

    }

    function updateSnapshoot(
        uint256[] calldata _types, 
        uint256[] calldata _days,
        string[] calldata _dataHashs,
        string[] calldata _dataIds
    ) override external {
        address _sender = msg.sender;
        uint256 len = _types.length;
        require(len == _days.length, "Number of parameters does not match"); 
        require(_days.length == _dataHashs.length, "Number of parameters does not match"); 
        require(_dataHashs.length == _dataIds.length , "Number of parameters does not match"); 
        uint256 _nodeRank = pledgeContract.queryNodeIndex(_sender);
        require(_nodeRank < 22 && _nodeRank > 0, "The caller is not the nodeAddr"); 
        for (uint256 i=0; i < len; i++){
             _updatSnapshoot(_types[i],_days[i],_dataHashs[i],_dataIds[i],_sender);
        }
    }

    function _updatSnapshoot(
        uint256 _type, 
        uint256 _day,
        string memory _dataHash, 
        string memory _dataId,
        address _sender
    ) internal{
        uint256 _snapshootNum = snapshootMsg[_type][_day];
        SnapshootMsg storage _snapshootMsg = snapshootIndex[_snapshootNum];
        if(_snapshootNum == 0){
            _snapshootNum = ++snapshootNum;
            _snapshootMsg = snapshootIndex[_snapshootNum];
            snapshootMsg[_type][_day] = _snapshootNum;
        }
        require(!_snapshootMsg.addrSta[_sender], "The node address has already been voted"); 
        require(_currentDay() >= _day, "Incorrect snapshot date");
        _snapshootMsg.addrSta[_sender] = true;
        _snapshootMsg.voteAddrList.push(_sender);
        _snapshootMsg.voteTimeList.push(block.timestamp);
        if(_snapshootMsg.consensusSta ==0){
            bytes32 _dataFlagHash = keccak256(abi.encode(_dataHash, _dataId));
            uint256 _dataFlag = bytes32ToUint(_dataFlagHash);
            DataMsg memory _dataMsg = DataMsg(_dataHash, _dataId);
            uint256 _dataFlagIndex = _snapshootMsg.dataFlagIndex[_dataFlag];
            if (_dataFlagIndex == 0){
                _dataFlagIndex = ++_snapshootMsg.dataFlagNum;
                _snapshootMsg.dataFlagIndex[_dataFlag] = _dataFlagIndex;
                _snapshootMsg.dataIndexFlag[_dataFlagIndex] = _dataFlag;
                _snapshootMsg.dataFlag[_dataFlag] = _dataMsg;
            }
            _snapshootMsg.dataVotes[_dataFlag]++;
            ++_snapshootMsg.nodeVoteNum;
            _dataRank(_type, _day, _snapshootMsg);
        }
    }

    function _dataRank(uint256 _type, uint256 _day, SnapshootMsg storage _snapshootMsg) internal {
        uint256 _dataFlagNum = _snapshootMsg.dataFlagNum;
        for (uint256 i=1; i <= _dataFlagNum; i++){
            for (uint256 j=i+1 ; j <= _dataFlagNum; j++){
                uint256 nextData = _snapshootMsg.dataIndexFlag[j];
                uint256 prefixData = _snapshootMsg.dataIndexFlag[i];
                if (_snapshootMsg.dataVotes[prefixData] < _snapshootMsg.dataVotes[nextData]){
                    _snapshootMsg.dataFlagIndex[prefixData] = j;
                    _snapshootMsg.dataFlagIndex[nextData] = i;
                    _snapshootMsg.dataIndexFlag[i] = nextData;
                    _snapshootMsg.dataIndexFlag[j] = prefixData;
                }
            }
        }
        uint256 _dataFlag = _snapshootMsg.dataIndexFlag[1];
        DataMsg memory _dataMsg = _snapshootMsg.dataFlag[_dataFlag];
        if(_snapshootMsg.dataVotes[_dataFlag] > 11){
            _snapshootMsg.consensusSta = 1;
            _snapshootMsg.time = block.timestamp;
            emit UpdateSnapshoot(_type, _day, _dataMsg.dataHash, _dataMsg.dataId);
        }else if(_snapshootMsg.nodeVoteNum > 16){
            _snapshootMsg.consensusSta = 2;
            _snapshootMsg.time = block.timestamp;
            uint256 _snapshootNum = ++snapshootNum;
            snapshootMsg[_type][_day] = _snapshootNum;
            emit UpdateSnapshootFail(_type, _day, _dataMsg.dataHash, _dataMsg.dataId);
        }
    }

    function bytes32ToUint(bytes32 b) internal pure returns (uint256){
        uint256 number;
        for(uint i= 0; i<b.length; i++){
            number = number + uint8(b[i])*(2**(8*(b.length-(i+1))));
        }
        return  number;
    }

    function currentDay() external view returns (uint256) {
        return _currentDay();
    }

    function _currentDay() internal  view returns (uint256) {
        return (block.timestamp + 9900) / 86400 - startDay +1;
    }

    
    function queryVotes(uint256 _type, uint256 _day) 
        external 
        view 
        returns(
            uint256,
            uint256,
            uint256,
            uint256,
            address[] memory, 
            uint256[] memory, 
            string memory,
            string memory,
            uint256)
    {
        uint256 _snapshootNum = snapshootMsg[_type][_day];
        SnapshootMsg storage _snapshootMsg = snapshootIndex[_snapshootNum];
        uint256 _dataFlag = _snapshootMsg.dataIndexFlag[1];
        DataMsg memory _dataMsg = _snapshootMsg.dataFlag[_dataFlag];
        uint256 _dataVotes = _snapshootMsg.dataVotes[_dataFlag];
        return (
            _currentDay(), 
            _snapshootMsg.consensusSta, 
            _snapshootMsg.time, 
            _snapshootMsg.nodeVoteNum, 
            _snapshootMsg.voteAddrList, 
            _snapshootMsg.voteTimeList, 
            _dataMsg.dataHash, 
            _dataMsg.dataId,
            _dataVotes
        );
    }

    function queryCurrentVotes(uint256 _type) 
        external 
        view 
        returns(
            uint256,
            uint256,
            uint256,
            uint256,
            address[] memory, 
            uint256[] memory, 
            string memory,
            string memory,
            uint256)
    {
        uint256 _day = _currentDay();
        uint256 _snapshootNum = snapshootMsg[_type][_day];
        SnapshootMsg storage _snapshootMsg = snapshootIndex[_snapshootNum];
        uint256 _dataFlag = _snapshootMsg.dataIndexFlag[1];
        DataMsg memory _dataMsg = _snapshootMsg.dataFlag[_dataFlag];
        uint256 _dataVotes = _snapshootMsg.dataVotes[_dataFlag];
        return (
            _day, 
            _snapshootMsg.consensusSta, 
            _snapshootMsg.time, 
            _snapshootMsg.nodeVoteNum, 
            _snapshootMsg.voteAddrList, 
            _snapshootMsg.voteTimeList, 
            _dataMsg.dataHash, 
            _dataMsg.dataId,
            _dataVotes
        );
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
