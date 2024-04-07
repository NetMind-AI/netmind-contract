// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Initialize {
    bool internal initialized;

    modifier init(){
        require(!initialized, "initialized");
        _;
        initialized = true;
    }

    function _disableInitializers() internal {
        initialized = true;
    }
}

contract Conf is Initialize {
    // --- Auth ---
    mapping (address => uint) public wards;
    function rely(address guy) external auth { wards[guy] = 1; }
    function deny(address guy) external auth { wards[guy] = 0; }
    modifier auth { require(wards[msg.sender] == 1); _; }

    // --- NetMind contracts ---
    address public WNMT;
    address public Training;
    address public Inference;
    address public Price;
    address public Credit;
    address public Staking;
    address public Award;
    
    
    // --- Award msg （obsolete）---              part per ten-thousandth unit [THD]
    uint256 private begin;            //timestamp of the contratc start
    uint256 private award;            //total award => 10 billions
    uint256 private miner_awd_1;      //Award of first 10 years => 1%     [THD]
    uint256 private miner_awd_2;      //Award of 11-40 years => 0.5%      [THD]
    uint256 private miner_awd_3;      //Award of 41-100 years => 0.25%    [THD]
    uint256 private og_awd;           //Award of OG including node operator, liquidity and staking => 0.3% per year [THD]
    uint256 private node_awd;         //Award of node operator proportion => 20%     [THD]
    uint256 private staking_awd;      //Award of staking operator proportion => 80%  [THD]
    uint256 private staking_gini;     //Award of staking coefficients => 8%          [THD]

    // --- Payment ---
    uint256 public p_settlement;     //novc-settlement proportion => 50%
    uint256 public N;                
    address public accountManageExecutor;
    address public priceServiceExecutor;
    address public trainingTaskExecutor;
    uint256 public v_settlement;     //vc-settlement proportion => 80%    
    uint256 public fmr_awd;          //Fully Managed Rewards => 1.1      
    uint256 public non_vc_awd;       //Only non-VC mode rewards => 0.95   
    uint256 public vc_awd;           //Only VC mode rewards  => 1         

    // --- Accountant （obsolete）---
    mapping(address=> bool) public acts;  //accountants is the signer of ledger, snapshot, accountMange and rewardPool     


    // --- Award msg addtion ---
    //new reward opition, that will reset the reward proportion. new reward proportion: staking => 50%, liquidity => 30%, node => 20%
    uint256 private liquidity_awd; //Award of liquidity proportion => 30% [THD]


    constructor(){_disableInitializers();}
    
    function initialize() external init {
        begin = block.timestamp;
        award = 10**28;
        wards[msg.sender] = 1;
    }

    // --- Administration ---
    function file(bytes32 what, address dst) public auth {
        require(dst != address(0), "zero address");
        if (what == "WNMT") WNMT = dst;
        else if (what == "Training") Training = dst;
        else if (what == "Inference") Inference = dst;
        else if (what == "Price") Price = dst;
        else if (what == "Credit") Credit = dst;
        else if (what == "Staking") Staking = dst;
        else if (what == "Award") Award = dst;
        else if (what == "AccountManageExecutor") accountManageExecutor = dst;
        else if (what == "PriceServiceExecutor") priceServiceExecutor = dst;
        else if (what == "TrainingTaskExecutor") trainingTaskExecutor = dst;
    }

    function file(bytes32 what, uint256 data) public auth {
        if (what == "miner_awd_1") miner_awd_1 = data;
        else if (what == "miner_awd_2") miner_awd_2 = data;
        else if (what == "miner_awd_3") miner_awd_3 = data;
        else if (what == "og_awd") og_awd = data;
        else if (what == "node_awd") node_awd = data;
        else if (what == "liquidity_awd") liquidity_awd = data;
        else if (what == "staking_awd") staking_awd = data;
        else if (what == "staking_gini") staking_gini = data;
        else if (what == "p_settlement") p_settlement = data;
        else if (what == "v_settlement") v_settlement = data;
        else if (what == "N") N = data;
        else if (what == "fmr_awd") fmr_awd = data;
        else if (what == "non_vc_awd") non_vc_awd = data;
        else if (what == "vc_awd") vc_awd = data;
    }

    function file(address act, bool flag) public auth {
        acts[act] = flag;
    }


    // --- New award design --- 
    // go live data 2024-04-16 00:00:00  1713225600
    function awardDetals() public view returns (uint256 miner, uint256 node, uint256 lp, uint256 staking){
        uint256 phase_1 = 1713225600;             
        uint256 phase_2 = phase_1 + 2 * 365 days;
        uint256 phase_3 = phase_2 + 2 * 365 days;
        uint256 phase_4 = phase_3 + 2 * 365 days;
        uint256 phase_5 = phase_4 + 2 * 365 days;
        
        if (block.timestamp < phase_1 || block.timestamp > phase_5 + 2*365 days) return (0,0,0,0);  //out of phase range
        else if (block.timestamp < phase_2 )return (27397_260270e12, 4109_589041e12 *2/10, 4109_589041e12 *3/10, 4109_589041e12 /2);  //phase_1
        else if (block.timestamp < phase_3 )return (20547_945210e12, 3424_657534e12 *2/10, 3424_657534e12 *3/10, 3424_657534e12 /2);  //phase_2
        else if (block.timestamp < phase_4 )return (13698_630140e12, 2739_726027e12 *2/10, 2739_726027e12 *3/10, 2739_726027e12 /2);  //phase_3
        else if (block.timestamp < phase_5 )return (10273_972600e12, 2739_726027e12 *2/10, 2739_726027e12 *3/10, 2739_726027e12 /2);  //phase_4
        else                                return ( 6849_315068e12, 2739_726027e12 *2/10, 2739_726027e12 *3/10, 2739_726027e12 /2);  //phase_5
    }

    function getAwradMSG() public view 
    returns(
        uint256 miner_award, 
        uint256 node_award, 
        uint256 liquidity_award,
        uint256 staking_award, 
        uint256 staking_gini_, 
        uint256 award_N,
        uint256 fmr_awd_,
        uint256 non_vc_awd_,
        uint256 vc_awd_
    ){
        require(begin > 0, "begin not set");
        require(node_awd > 0, "node_awd not set");
        if (block.timestamp < 1713225600){
                uint256 i;
                if (block.timestamp < begin + 10 * 365 days) i = miner_awd_1;
                else if(block.timestamp < begin + 40 * 365 days) i = miner_awd_2;
                else i = miner_awd_3;
                uint256 og_award = award * og_awd /365 /10**4;

                miner_award     = award * i /365 /10**4;
                node_award      = og_award * node_awd /10**4;
                liquidity_award = og_award * liquidity_awd /10**4;
                staking_award   = og_award * staking_awd /10**4;
        }else {
                (miner_award, node_award, liquidity_award, staking_award) = awardDetals();
        }
        
        staking_gini_ = staking_gini;
        award_N = N;
        fmr_awd_ = fmr_awd;
        non_vc_awd_ = non_vc_awd;
        vc_awd_ = vc_awd;
    }
}
