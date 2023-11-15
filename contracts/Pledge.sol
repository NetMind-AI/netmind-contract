// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0 ;

interface IERC20 {
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
}

interface IPledge {
    function addNodeAddr(address[] calldata _nodeAddrs) external;
    function deleteNodeAddr(address[] calldata _nodeAddrs) external;
    function stake(address _nodeAddr) payable external;
    function cancleStake(uint256[] calldata _indexs) external;
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

contract Pledge is Initializable,Ownable,IPledge{
    uint256 public  nodeNum;                           
    mapping(address => uint256) nodeAddrIndex;  
    mapping(uint256 => address) public nodeIndexAddr;  
    mapping(address => uint256) nodeStakeAmount;     
    mapping(address => bool) public nodeAddrSta;
    uint256 public  stakeTokenNum;         
    mapping(uint256 => StakeTokenMsg) public stakeTokenMsg;  
    mapping(address => uint256) public userStakeTokenNum;  
    mapping(address => mapping(uint256 => uint256)) public userStakeTokenIndex;
    mapping(address => address) nodeIdByAddr;  
    mapping(address => address) nodeAddrById;  
    mapping(address => address) walletById; 
    event UpadeNodesMapping(address nodeId, address oldAddr, address newAddr);
    event UpadeNodesWallet(address nodeId, address walAddr);
    event AddNodeAddr(address _nodeAddr);
    event DeleteNodeAddr(address _nodeAddr);
    event StakeToken(uint256 indexed _stakeIndex, address _userAddr, address _nodeAddr, uint256 _amount, uint256 _time);
    event CancleStakeToken(uint256 indexed _stakeIndex, address indexed _userAddr, address _nodeAddr, uint256 _time);

    struct StakeTokenMsg {
        address userAddr;    
        address nodeAddr;   
        uint256 start;  
        uint256 end;  
        uint256 tokenAmount;  
    }

    modifier onlyNodeAddr(address _nodeAddr) {
        require(nodeAddrSta[_nodeAddr], "StakeContract: The Stake address is not a node address");
        _;
    }

    function init() external initializer{
        __Ownable_init_unchained();
    }

    receive() payable external{

    }
    
    fallback() payable external{

    }

    function updateMapping(
        address[] calldata _nodeIds, 
        address[] calldata _newAddrs,
        address[] calldata _walAddrs
        ) external onlyOwner{
        require(_nodeIds.length == _newAddrs.length && _nodeIds.length == _walAddrs.length, "parameter length mismatch");
        address _nodeId;
        address _oldAddr;
        address _newAddr;
        address _walAddr;
        for (uint256 i = 0; i< _nodeIds.length; i++){
            _nodeId = _nodeIds[i];
            _newAddr = _newAddrs[i];
            _walAddr = _walAddrs[i];
            require(nodeAddrSta[_nodeId],"not node addr");
            if(_newAddr!=address(0)){
                _oldAddr = getNodeAddrById(_nodeId);
                require(!nodeAddrSta[_newAddr] && nodeIdByAddr[_newAddr] == address(0) && nodeAddrById[_newAddr] == address(0) , "node exist");
                nodeIdByAddr[_newAddr] = _nodeId;
                nodeAddrById[_nodeId] = _newAddr;
                emit UpadeNodesMapping(_nodeId, _oldAddr, _newAddr);
            }
            if(_walAddr!=address(0)){
                require(!nodeAddrSta[_walAddr] && nodeIdByAddr[_walAddr] == address(0) && nodeAddrById[_walAddr] == address(0) , "walAddr exist");
                walletById[_nodeId] = _walAddr;
                emit UpadeNodesWallet(_nodeId, _walAddr);
            }
            
        }
    }
  
    /**
    * @notice A method to add a list of trusted nodes
    * @param _nodeAddrs a list of trusted nodes
    */
    function addNodeAddr(address[] calldata _nodeAddrs) override external onlyOwner{
        for (uint256 i = 0; i< _nodeAddrs.length; i++){
            address _nodeAddr = _nodeAddrs[i];
            require(!nodeAddrSta[_nodeAddr], "This node is already a stake node");
            nodeAddrSta[_nodeAddr] = true;
            uint256 _nodeAddrIndex = nodeAddrIndex[_nodeAddr];
            if (_nodeAddrIndex == 0){
                _nodeAddrIndex = ++nodeNum;
                nodeAddrIndex[_nodeAddr] = _nodeAddrIndex;
                nodeIndexAddr[_nodeAddrIndex] = _nodeAddr;
                addNodeStake(_nodeAddrIndex);
            }
            emit AddNodeAddr(_nodeAddrs[i]);
        }
    }
    
    /**
    * @notice A method to cancel the list of untrusted nodes
    * @param _nodeAddrs the list of untrusted nodes
    */
    function deleteNodeAddr(address[] calldata _nodeAddrs) override external onlyOwner{
        for (uint256 i = 0; i< _nodeAddrs.length; i++){
            address _nodeAddr = _nodeAddrs[i];
            require(nodeAddrSta[_nodeAddr], "This node is not a Stake node");
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
                cancelNodeStake(_lastNodeAddr);
            }
            emit DeleteNodeAddr(_nodeAddrs[i]);
        }
    }

    /**
    * @notice A method in which users Stake stake to trusted nodes. 
    * The nodes must be in the top 11 of the Stake, 
    * and the user's Stake can obtain the Stake income
    * @param _nodeAddr trusted node
    */
    function stake(address _nodeAddr) override payable external onlyNodeAddr(_nodeAddr){
        uint256 _amount = msg.value;
        require(_amount > 0, "The pledge amount cannot be less than the minimum value");
        address _sender = msg.sender;
        uint256 _nodeNum = nodeNum;
        uint256 _nodeAddrIndex = nodeAddrIndex[_nodeAddr];
        if (_nodeAddrIndex == 0){
            _nodeAddrIndex = ++nodeNum;
            _nodeNum = _nodeAddrIndex;
            nodeAddrIndex[_nodeAddr] = _nodeAddrIndex;
            nodeIndexAddr[_nodeAddrIndex] = _nodeAddr;
        }
        uint256 _stakeTokenNum = ++stakeTokenNum;
        uint256 _userStakeTokenNum = ++userStakeTokenNum[_sender];
        userStakeTokenIndex[_sender][_userStakeTokenNum] = _stakeTokenNum;
        nodeStakeAmount[_nodeAddr] += _amount;
        stakeTokenMsg[_stakeTokenNum] = StakeTokenMsg(_sender, _nodeAddr, block.timestamp, 0, _amount);
        addNodeStake(_nodeAddrIndex);
        emit StakeToken(_stakeTokenNum, _sender, _nodeAddr, _amount, block.timestamp);
    }
    
    
    /**
    * @notice A method to the user cancels the stake
    * @param _indexs the user stake a collection of ids
    */
    function cancleStake(uint256[] calldata _indexs) override external {
        address _sender = msg.sender;
        uint256 _amount;
        for (uint256 i = 0; i < _indexs.length; i++) {
            uint256 _stakeTokenMark = _indexs[i];
            if (_stakeTokenMark > 0){
                StakeTokenMsg storage _stakeTokenMsg = stakeTokenMsg[_stakeTokenMark];
                require(_stakeTokenMsg.userAddr == _sender, "Has no authority to remove the Stake not his own");
                require(_stakeTokenMsg.end == 0, "The Stake has been redeemed");
                _stakeTokenMsg.end = block.timestamp;
                _amount += _stakeTokenMsg.tokenAmount;
                nodeStakeAmount[_stakeTokenMsg.nodeAddr] = nodeStakeAmount[_stakeTokenMsg.nodeAddr] - _stakeTokenMsg.tokenAmount;
                if (nodeAddrSta[_stakeTokenMsg.nodeAddr]){           
                    cancelNodeStake(_stakeTokenMsg.nodeAddr);
                }
                emit CancleStakeToken(_stakeTokenMark, _sender, _stakeTokenMsg.nodeAddr, block.timestamp);
            }
        }
        payable(_sender).transfer(_amount);
    }
    
    function queryStakeToken(
        address _userAddr,
        uint256 _page,
        uint256 _limit
    )
        external
        view
        returns(
            address[] memory nodeAddrs,
            uint256[] memory stakeMsgData,
            uint256 _num
        )
    {
        _num = userStakeTokenNum[_userAddr];
        if (_limit > _num){
            _limit = _num;
        }
        if (_page<2){
            _page = 1;
        }
        _page--;
        uint256 start = _page * _limit;
        uint256 end = start + _limit;
        if (end > _num){
            end = _num;
            _limit = end - start;
        }
        nodeAddrs = new address[](_limit);
        stakeMsgData = new uint256[](_limit*4);
        if (_num > 0){
            require(end > start, "Query index range out of limit");
            uint256 j;
            for (uint256 i = start; i < end; i++) {
                uint256 _index;
                _index = userStakeTokenIndex[_userAddr][i+ 1];
                StakeTokenMsg memory _stakeTokenMsg = stakeTokenMsg[_index];
                nodeAddrs[j] = _stakeTokenMsg.nodeAddr;
                stakeMsgData[j*4] = _stakeTokenMsg.start;
                stakeMsgData[j*4+1] = _stakeTokenMsg.end;
                stakeMsgData[j*4+2] = _stakeTokenMsg.tokenAmount;
                stakeMsgData[j*4+3] = _index;
                j++;
            }
        }
    }
   
    function queryNodeRank(uint256 start, uint256 end) external view returns (address[] memory addrs, uint256[] memory amounts) {
        (,addrs,,amounts) = _queryNode(start, end);
    }
    
    function queryNodeAddrAndId(uint256 start, uint256 end) external view returns (address[] memory, address[] memory, address[] memory, uint256[] memory) {
        return _queryNode(start, end);
    }
    
    function _queryNode(uint256 start, uint256 end) internal view returns (address[] memory, address[] memory, address[] memory, uint256[] memory) {
        require(start > 0, "start must larger than 0");
        if (end > nodeNum){
            end = nodeNum;
        }
        address[] memory _nodeIdArray = new address[](1) ;
        address[] memory _walArray = new address[](1) ;
        address[] memory _addrArray = new address[](1) ;
        uint256[] memory _stakeAmount = new uint256[](1) ;
        uint256 j;
        if (end >= start){
            uint256 len = end - start + 1;
            _nodeIdArray = new address[](len) ;
            _walArray = new address[](len) ;
            _addrArray = new address[](len) ;
            _stakeAmount = new uint256[](len) ;
            for (uint256 i = start; i <= end; i++) {
                address _nodeAddr = nodeIndexAddr[i];
                _nodeIdArray[j] = _nodeAddr;
                _addrArray[j] = getNodeAddrById(_nodeAddr);
                _walArray[j] = walletById[_nodeAddr];
                if(_walArray[j] == address(0))_walArray[j]=_nodeAddr;
                _stakeAmount[j] = nodeStakeAmount[_nodeAddr];
                j++;
            }
        }
        return (_nodeIdArray, _addrArray, _walArray, _stakeAmount);
    }
 
    function queryNodeIndex(address _nodeAddr) external view returns(uint256){
        address _nodeId = getNodeIdByAddr(_nodeAddr);
        uint256 index = nodeAddrIndex[_nodeId];
        if(getNodeAddrById(_nodeId) == _nodeAddr && _nodeAddr!= address(0)){
            return index;
        }else {
            return 0;
        }
    }

    function queryNodeStakeAmount(address _nodeAddr) external view returns(uint256){
        return nodeStakeAmount[_nodeAddr];
    }

    function getNodeWalById(address _nodeId) public view returns(address){
        address _nodeAddr = walletById[_nodeId];
        if(_nodeAddr == address(0) && nodeAddrSta[_nodeId]){
            return _nodeId;
        }else {
            return _nodeAddr;  
        }
    }

    function getNodeAddrById(address _nodeId) public view returns(address){
        address _nodeAddr = nodeAddrById[_nodeId];
        if(_nodeAddr == address(0) && nodeAddrSta[_nodeId]){
            return _nodeId;
        }else {
            return _nodeAddr;  
        }
    }

    function getNodeIdByAddr(address _nodeAddr) public view returns(address){
        address _nodeId = nodeIdByAddr[_nodeAddr];
        if(_nodeId == address(0) && nodeAddrSta[_nodeAddr] && nodeAddrById[_nodeAddr] == _nodeId){
            return _nodeAddr;
        }else {
            return _nodeId;
        }
    }

    function addNodeStake(uint256 _nodeAddrIndex) internal {
        for (uint256 i = _nodeAddrIndex; i > 1; i--) {
            address _nodeAddr = nodeIndexAddr[i];
            uint256 _prefixIndex = i - 1;
            address prefixAddr = nodeIndexAddr[_prefixIndex];
            uint256 _nodeSum = nodeStakeAmount[_nodeAddr];
            uint256 _prefixSum = nodeStakeAmount[prefixAddr];
            if (_prefixSum < _nodeSum){
                nodeAddrIndex[prefixAddr] = i;
                nodeAddrIndex[_nodeAddr] = _prefixIndex;
                nodeIndexAddr[i] = prefixAddr;
                nodeIndexAddr[_prefixIndex] = _nodeAddr;
            }else{
                break;
            }
        }
    }

    function cancelNodeStake(address _addr) internal {
        uint256 _nodeNum = nodeNum;
        uint256 _nodeAddrIndex = nodeAddrIndex[_addr];
        for (uint256 i = _nodeAddrIndex; i < _nodeNum; i++) {
            address _nodeAddr = nodeIndexAddr[i];
            uint256 _lastIndex = i + 1;
            address lastAddr = nodeIndexAddr[_lastIndex];
            uint256 _nodeSum = nodeStakeAmount[_nodeAddr];
            uint256 _lastSum = nodeStakeAmount[lastAddr];
            if (_lastSum > _nodeSum){
                nodeAddrIndex[lastAddr] = i;
                nodeAddrIndex[_nodeAddr] = _lastIndex;
                nodeIndexAddr[i] = lastAddr;
                nodeIndexAddr[_lastIndex] = _nodeAddr;
            }else{
                break;
            }
        }
    }

}

