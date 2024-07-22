// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0 ;

interface ILedger {
    function updateLedger(
        address[] calldata _userAddrs, 
        uint256[] calldata _nonces,
        address[] calldata _tokenAddrs, 
        uint256[] calldata _amounts,
        string[] calldata _txHashs
    )  external;
}

interface Iconf {
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

contract Ledger is Initializable, ILedger{
    Iconf public conf;
    uint256 ledgerNum; 
    mapping(uint256 => LedgerMsg)  ledgerIndex;
    mapping(address => mapping(uint256 => uint256)) ledgerMsg;

    event UpdateLedger(address userAddr, uint256 nonce, address token, uint256 amount, string txHash); 
    event UpdateLedgerFail(address userAddr, uint256 nonce, address token, uint256 amount, string txHash); 
 
    struct DataMsg{
        address token;                        
        uint256 amount;
        string txHash;
    }

    struct LedgerMsg{
        uint256  nodeVoteNum;
        mapping(uint256 => DataMsg) dataFlag;
        uint256 dataFlagNum;
        mapping(uint256 => uint256) dataFlagIndex;
        mapping(uint256 => uint256) dataIndexFlag;
        mapping(uint256 => uint256) dataVotes;
        mapping(address => bool) addrSta;
        address[] voteAddrList;          
        bool consensusSta;       
    }

    constructor(){_disableInitializers();}

    function init(address _conf) external initializer{
        conf = Iconf(_conf);
    }
    
    function updateLedger(
        address[] calldata _userAddrs, 
        uint256[] calldata _nonces,
        address[] calldata _tokenAddrs, 
        uint256[] calldata _amounts,
        string[] calldata _txHashs
    ) override external {
        address _sender = msg.sender;
        uint256 len = _userAddrs.length;
        require(len == _nonces.length, "Number of parameters does not match"); 
        require(_nonces.length == _tokenAddrs.length, "Number of parameters does not match"); 
        require(_tokenAddrs.length == _amounts.length , "Number of parameters does not match"); 
        require(_txHashs.length == _amounts.length , "Number of parameters does not match"); 
        require(conf.acts(_sender), "only accountant");
        for (uint256 i=0; i < len; i++){
             _updatLedger(_userAddrs[i],_nonces[i],_tokenAddrs[i],_amounts[i],_txHashs[i],_sender);
        }
    }

    function _updatLedger(
        address _userAddr, 
        uint256 _nonce,
        address _tokenAddr, 
        uint256 _amount,
        string memory _txHash,
        address _sender
    ) internal{
        uint256 _ledgerNum = ledgerMsg[_userAddr][_nonce];
        LedgerMsg storage _ledgerMsg = ledgerIndex[_ledgerNum];
        if(_ledgerNum == 0){
            _ledgerNum = ++ledgerNum;
            _ledgerMsg = ledgerIndex[_ledgerNum];
            ledgerMsg[_userAddr][_nonce] = _ledgerNum;
        }
        require(!_ledgerMsg.addrSta[_sender], "The node address has already been voted"); 
        _ledgerMsg.addrSta[_sender] = true;
        _ledgerMsg.voteAddrList.push(_sender);
        if(!_ledgerMsg.consensusSta){
            bytes32 _dataFlagHash = keccak256(abi.encode(_tokenAddr, _amount, _txHash));
            uint256 _dataFlag = bytes32ToUint(_dataFlagHash);
            DataMsg memory _dataMsg = DataMsg(_tokenAddr, _amount, _txHash);
            uint256 _dataFlagIndex = _ledgerMsg.dataFlagIndex[_dataFlag];
            if (_dataFlagIndex == 0){
                _dataFlagIndex = ++_ledgerMsg.dataFlagNum;
                _ledgerMsg.dataFlagIndex[_dataFlag] = _dataFlagIndex;
                _ledgerMsg.dataIndexFlag[_dataFlagIndex] = _dataFlag;
                _ledgerMsg.dataFlag[_dataFlag] = _dataMsg;
            }
            _ledgerMsg.dataVotes[_dataFlag]++;
            uint256 _nodeVoteNum = ++_ledgerMsg.nodeVoteNum;
            if(_nodeVoteNum > 0){
                _dataRank(_userAddr, _nonce, _ledgerMsg);
            }
        }
    }

    function _dataRank(address _userAddr, uint256 _nonce, LedgerMsg storage _ledgerMsg) internal {
        uint256 _dataFlagNum = _ledgerMsg.dataFlagNum;
        for (uint256 i=1; i <= _dataFlagNum; i++){
            for (uint256 j=i+1 ; j <= _dataFlagNum; j++){
                uint256 nextData = _ledgerMsg.dataIndexFlag[j];
                uint256 prefixData = _ledgerMsg.dataIndexFlag[i];
                if (_ledgerMsg.dataVotes[prefixData] < _ledgerMsg.dataVotes[nextData]){
                    _ledgerMsg.dataFlagIndex[prefixData] = j;
                    _ledgerMsg.dataFlagIndex[nextData] = i;
                    _ledgerMsg.dataIndexFlag[i] = nextData;
                    _ledgerMsg.dataIndexFlag[j] = prefixData;
                }
            }
        }
        uint256 _dataFlag = _ledgerMsg.dataIndexFlag[1];
        DataMsg memory _dataMsg = _ledgerMsg.dataFlag[_dataFlag];
        if(_ledgerMsg.dataVotes[_dataFlag] >= 2){
            _ledgerMsg.consensusSta = true;
            emit UpdateLedger(_userAddr, _nonce, _dataMsg.token, _dataMsg.amount, _dataMsg.txHash);
        }else if(_ledgerMsg.nodeVoteNum > 2){
            uint256 _ledgerNum = ++ledgerNum;
            ledgerMsg[_userAddr][_nonce] = _ledgerNum;
            emit UpdateLedgerFail(_userAddr, _nonce, _dataMsg.token, _dataMsg.amount, _dataMsg.txHash);
        }
    }

    function bytes32ToUint(bytes32 b) internal pure returns (uint256){
        uint256 number;
        for(uint i= 0; i<b.length; i++){
            number = number + uint8(b[i])*(2**(8*(b.length-(i+1))));
        }
        return  number;
    }

    function queryVotes(address userAddr, uint256 nonce) 
        external 
        view 
        returns(
            bool,
            uint256,
            address[] memory, 
            address,
            uint256, 
            string memory,
            uint256)
    {
        uint256 _ledgerNum = ledgerMsg[userAddr][nonce];
        LedgerMsg storage _ledgerMsg = ledgerIndex[_ledgerNum];
        uint256 _dataFlag = _ledgerMsg.dataIndexFlag[1];
        DataMsg memory _dataMsg = _ledgerMsg.dataFlag[_dataFlag];
        uint256 _dataVotes = _ledgerMsg.dataVotes[_dataFlag];
        return (_ledgerMsg.consensusSta, _ledgerMsg.nodeVoteNum, _ledgerMsg.voteAddrList, _dataMsg.token, _dataMsg.amount, _dataMsg.txHash,_dataVotes);
    }
}

