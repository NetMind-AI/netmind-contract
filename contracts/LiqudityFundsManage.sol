// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

interface IPancakeRouter02 {
      function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function swapExactTokensForTokens(uint amountIn,uint amountOutMin,address[] calldata path,address to,uint deadline) external returns (uint[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);
}

interface IERC20{
      function totalSupply() external view returns (uint256);
      function balanceOf(address user) external returns (uint256);
      function approve(address user, uint256 amount) external returns (bool);
      function transfer(address to, uint256 amt) external returns(bool);
}



contract LiquidityFundsManage is Ownable{
      address public DexRouter;
      address public NMT;
      address public USDC;
      address public Pair;
      uint256 public USDC_Price; //1e18

      uint256 public Expire;    // 1 day
      uint256 public Tolerance; // Liquidity price tolerance

      address[] private Managers;
      
      enum OP_TYPE{
            BUY,
            SELL,
            ADDLIQUIDITY,
            REMOVELIQUIDITY,
            TRANSFER
      }
      mapping(OP_TYPE=>string) private OP_TYPE_NAME;

      struct ProposalMsg{
            address proposer;
            address receiver;
            bool isPass;
            OP_TYPE opType;
            uint256 expire;
            uint256 usdc;
            uint256 nmt;
            uint256 liquidity;
            address[] assentors;
      }
      uint256 public pid;
      mapping(uint256=>ProposalMsg) internal proposals;
      mapping(uint256=>mapping(address=>bool)) public voteRecord;

      modifier OnlyManager(){
            require(_isManger(msg.sender), "Only manager can call");
            _;
      }

      constructor(){_disableInitializers();}

      function init(address _nmt, address _usdc, address _router, address _pair,  uint256 _usdc_decamals) initializer public {

            NMT = _nmt;
            USDC = _usdc;
            DexRouter = _router;
            Pair = _pair;
            USDC_Price = 10 ** _usdc_decamals;

            Expire = 1 days;
            Tolerance = 10;   //10%


            OP_TYPE_NAME[OP_TYPE.BUY] =   "BUY";
            OP_TYPE_NAME[OP_TYPE.SELL] = "SELL";
            OP_TYPE_NAME[OP_TYPE.ADDLIQUIDITY] = "ADDLIQUIDITY";
            OP_TYPE_NAME[OP_TYPE.REMOVELIQUIDITY] = "REMOVELIQUIDITY";
            OP_TYPE_NAME[OP_TYPE.TRANSFER] = "TRANSFER";

            __Ownable_init_unchained();
      }

      function GetProposalMSG(uint256 id) external view returns(ProposalMsg memory, string memory){
            ProposalMsg storage p = proposals[id];
            return (p, OP_TYPE_NAME[p.opType]);
      }

      //--------- globle setting ------------------
      function setTolerance(uint256 t) external onlyOwner {
            require(t > 0 && t < 100, "out of range, need in 1~100");
            Tolerance = t;
      }

      function setExpire(uint256 t) external onlyOwner {
            Expire = t;
      }

      //--------- managers ------------------------
      

      function _isManger(address user)internal view returns(bool){
            for(uint i = 0; i < Managers.length;i++){
                  if(user == Managers[i]){return true;}
            }
            return false;
      }

      function addManager(address user) external onlyOwner{
            require(!_isManger(user), "user already in manager list");
            Managers.push(user);
      }

      function removeManager(address user) external onlyOwner{
            uint256 index = type(uint256).max;
            uint256 len = Managers.length;
            for(uint i = 0; i < len;i++){
                  if(user == Managers[i]){index = i;}
            }
            require(index < len, "user not in manager list");
            Managers[index] = Managers[len-1];
            Managers.pop();
      }

      function managersList() external view returns(address[] memory){
            return Managers;
      }


      function threshold() public view returns(uint256){
            return Managers.length / 2;
      }

      //--------- proposal ------------------------
      function addLiquidity_P(uint256 usdc) external OnlyManager returns(uint256){
            usdc = usdc*1e18;
            uint256 nmt = calculateDesired(usdc);

            pid++;
            address[] memory assentors;
            proposals[pid] = ProposalMsg(msg.sender, address(0), false, OP_TYPE.ADDLIQUIDITY, block.timestamp + Expire, usdc, nmt, 0, assentors);

            //vote
            proposals[pid].assentors.push(msg.sender);
            return pid;
      }


      function removeLiquidity_P(uint256 liquidityPropotion) external OnlyManager returns(uint256){
            uint256 liquidity = IERC20(Pair).balanceOf(address(this)) * liquidityPropotion / 100;
            require(liquidity > 0, "lack liquidity");

            uint256 totalSupplyLP = IERC20(Pair).totalSupply();
            uint256 nmt = liquidity * IERC20(NMT).balanceOf(Pair) / totalSupplyLP;
            uint256 usdc = liquidity * IERC20(USDC).balanceOf(Pair) / totalSupplyLP;


            pid++;
            address[] memory assentors;
            proposals[pid] = ProposalMsg(msg.sender, address(0), false, OP_TYPE.ADDLIQUIDITY, block.timestamp + Expire, usdc, nmt, liquidity, assentors);

            //vote
            proposals[pid].assentors.push(msg.sender);
            return pid;
      }

      function buy_P(uint256 usdc, uint256 slippage) external OnlyManager returns(uint256){
            usdc = usdc *1e18;
            require(IERC20(USDC).balanceOf(address(this)) >= usdc, "usdc out of balance");
            require(slippage > 0 && slippage <= 100, "invalid slippage, need 1~100");

            //colculate amountMinOut => NMT
            uint256 nmt = calculateAmountOutMin(USDC, NMT, usdc, slippage);

            pid++;
            address[] memory assentors;
            proposals[pid] = ProposalMsg(msg.sender, address(0), false, OP_TYPE.BUY, block.timestamp + Expire, usdc, nmt, 0, assentors);

            //vote
            proposals[pid].assentors.push(msg.sender);
            return pid;
      }

      function sell_P(uint256 nmt, uint256 slippage) external OnlyManager returns(uint256){
            nmt = nmt *1e18;
            require(IERC20(NMT).balanceOf(address(this)) >= nmt, "nmt out of balance");
            require(slippage > 0 && slippage <= 100, "invalid slippage, need 1~100");

            //colculate amountMinOut => USDC
            uint256 usdc = calculateAmountOutMin(USDC, NMT, nmt, slippage);

            pid++;
            address[] memory assentors;
            proposals[pid] = ProposalMsg(msg.sender, address(0), false, OP_TYPE.SELL, block.timestamp + Expire, usdc, nmt, 0, assentors);

            //vote
            proposals[pid].assentors.push(msg.sender);
            return pid;
      }

      function transfer_P(address to, uint256 usdc, uint256 nmt) external OnlyManager returns(uint256){
            (usdc, nmt)=(usdc*1e18, usdc*1e18);
            require(IERC20(USDC).balanceOf(address(this))>= usdc, "usdc out of balance");
            require(IERC20(NMT).balanceOf(address(this))>= nmt, "nmt out of balance");

            pid++;
            address[] memory assentors;
            proposals[pid] = ProposalMsg(msg.sender, to, false, OP_TYPE.TRANSFER, block.timestamp + Expire, usdc, nmt, 0, assentors);

            //vote
            proposals[pid].assentors.push(msg.sender);
            return pid;
      }


      //--------- vote ---------------------------

      function vote(uint256 id) external OnlyManager{
            //proposals check
            require(id  <= pid, "invalid id");
            ProposalMsg storage p = proposals[id];
            require(!p.isPass, "proposal already passed");
            require(block.timestamp < p.expire, "proposal expire");

            //vote check
            require(!voteRecord[id][msg.sender], "already voted this proposal");
            voteRecord[id][msg.sender] = true;
            p.assentors.push(msg.sender);
            if (p.assentors.length > threshold()) {
                  //exec proposal
                  if(p.opType == OP_TYPE.BUY){
                        //------- Buy NMT ----
                        
                        address[] memory path = new address[](2);
                        path[0] = USDC;
                        path[1] = NMT;
                        uint256 amountIn = p.usdc;
                        uint256 amountOutMin = p.nmt;

                        require(IERC20(USDC).approve(DexRouter, amountIn), "Approval USDC failed");
                        IPancakeRouter02(DexRouter).swapExactTokensForTokens(amountIn, amountOutMin, path, address(this), block.timestamp);
                  }else if (p.opType == OP_TYPE.SELL){
                        //------ sell NMT ----- 

                        address[] memory path = new address[](2);
                        path[0] = NMT;
                        path[1] = USDC;
                        uint256 amountIn = p.nmt;
                        uint256 amountOutMin = p.usdc;

                        require(IERC20(NMT).approve(DexRouter, amountIn), "Approval NMT failed");
                        IPancakeRouter02(DexRouter).swapExactTokensForTokens(amountIn, amountOutMin, path, address(this), block.timestamp);
                  }else if (p.opType == OP_TYPE.ADDLIQUIDITY){
                        //----- add liquidity  ----

                        require(IERC20(NMT).approve(DexRouter, p.nmt), "Approval NMT failed");
                        require(IERC20(USDC).approve(DexRouter, p.usdc), "Approval USDC failed");

                        //coculate amountsMin
                        uint256 nmtMin = calculateAmountMin(p.nmt);
                        uint256 usdcMin = calculateAmountMin(p.usdc);

                        IPancakeRouter02(DexRouter).addLiquidity(NMT, USDC, p.nmt, p.usdc, nmtMin, usdcMin, address(this), block.timestamp);
                  }else if (p.opType == OP_TYPE.REMOVELIQUIDITY){
                        //----- remove liquidity ----

                        require(IERC20(Pair).approve(DexRouter,p.liquidity), "Approval NMT/USDC failed");

                        //coculate amountsMin
                        uint256 nmtMin = calculateAmountMin(p.nmt);
                        uint256 usdcMin = calculateAmountMin(p.usdc);

                        IPancakeRouter02(DexRouter).removeLiquidity(NMT, USDC, p.liquidity, nmtMin, usdcMin, address(this), block.timestamp);
                  }else {
                        //----- transfer -----

                        IERC20(USDC).transfer(p.receiver, p.usdc);
                        IERC20(NMT).transfer(p.receiver, p.nmt);
                  }
            }

            p.isPass = true;
      }

      function calculateAmountOutMin(address tokenIn,address tokenOut, uint256 amountIn, uint256 slippage) public view returns (uint256) {
            address[] memory path = new address[](2);
            path[0] = tokenIn;
            path[1] = tokenOut;
            uint256[] memory amounts = IPancakeRouter02(DexRouter).getAmountsOut(amountIn, path);
            return amounts[1] - (slippage * amounts[1] / 100);  //Slippage Tolerance: 1/100
      }

     function getCurrentPrice() public view returns (uint256) {
            address[] memory path = new address[](2);
            path[0] = NMT;
            path[1] = USDC;

            uint256[] memory amountsOut = IPancakeRouter02(DexRouter).getAmountsOut(1e18, path);
            return amountsOut[1]; 
      }

      function calculateDesired(uint256 fixedValueUSDC) public view returns (uint256) {
            uint256 priceNMT = getCurrentPrice();
            uint256 priceUSDC = USDC_Price; 
            
            uint256 valueNMT = fixedValueUSDC * priceUSDC / priceNMT;

            uint256 tolerance = valueNMT * Tolerance / 100;
            return valueNMT + tolerance; 
      }

      function calculateAmountMin(uint256 desired) public view returns (uint256) {
            uint256 tolerance = desired * Tolerance / 100;
            return desired - tolerance;
      }
}
