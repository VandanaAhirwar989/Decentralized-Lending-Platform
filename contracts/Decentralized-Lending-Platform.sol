// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title Ultra-Enhanced Decentralized Lending Platform with Comprehensive DeFi Features
 * @dev A complete DeFi ecosystem with cutting-edge features
 */
contract UltraEnhancedProject is ReentrancyGuard, Ownable, Pausable {
    using SafeMath for uint256;

    // NEW ADVANCED FEATURES

    // 1. Dynamic Interest Rate Model
    struct InterestRateModel {
        uint256 baseRate;           // Base interest rate
        uint256 multiplier;         // Interest rate multiplier
        uint256 jumpMultiplier;     // Jump multiplier after optimal utilization
        uint256 optimalUtilization; // Optimal utilization rate
        bool isActive;
    }

    // 2. Liquidation Engine with Dutch Auction
    struct DutchAuction {
        uint256 id;
        address borrower;
        address collateralToken;
        uint256 collateralAmount;
        uint256 debtAmount;
        uint256 startPrice;
        uint256 endPrice;
        uint256 startTime;
        uint256 duration;
        bool isActive;
        bool isCompleted;
        address winner;
        uint256 finalPrice;
    }

    // 3. Multi-Signature Governance Proposals
    struct GovernanceProposal {
        uint256 id;
        string title;
        string description;
        address proposer;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 votesAbstain;
        uint256 startTime;
        uint256 endTime;
        uint256 executionTime;
        bool isExecuted;
        bool isActive;
        ProposalType proposalType;
        bytes callData;
        mapping(address => bool) hasVoted;
        mapping(address => VoteType) userVotes;
    }

    enum ProposalType { PARAMETER_CHANGE, CONTRACT_UPGRADE, TREASURY_SPENDING, EMERGENCY_ACTION }
    enum VoteType { FOR, AGAINST, ABSTAIN }

    // 4. Sophisticated Staking with Lock Periods and Multipliers
    struct StakingTier {
        uint256 id;
        string name;
        uint256 minStakeAmount;
        uint256 lockPeriod;
        uint256 rewardMultiplier;
        uint256 maxCapacity;
        uint256 currentStaked;
        bool isActive;
    }

    struct UserStake {
        uint256 tierId;
        uint256 amount;
        uint256 startTime;
        uint256 lockEndTime;
        uint256 pendingRewards;
        uint256 claimedRewards;
        bool isActive;
    }

    // 5. Automated Market Making (AMM) with Custom Curves
    struct LiquidityPool {
        uint256 id;
        string name;
        address tokenA;
        address tokenB;
        uint256 reserveA;
        uint256 reserveB;
        uint256 totalLPTokens;
        uint256 feeRate;
        CurveType curveType;
        uint256 amplificationFactor; // For stable coin pools
        bool isActive;
        mapping(address => uint256) lpBalances;
        mapping(address => uint256) feesEarned;
    }

    enum CurveType { CONSTANT_PRODUCT, STABLE_SWAP, WEIGHTED, CONCENTRATED }

    // 6. Insurance Coverage with Risk Assessment
    struct InsuranceCoverage {
        uint256 id;
        string coverageName;
        address coveredProtocol;
        uint256 coverageAmount;
        uint256 premium;
        uint256 startTime;
        uint256 endTime;
        RiskLevel riskLevel;
        bool isActive;
        bool hasClaimed;
        address policyholder;
        uint256 claimAmount;
    }

    enum RiskLevel { LOW, MEDIUM, HIGH, CRITICAL }

    // 7. Real Estate Tokenization
    struct RealEstateToken {
        uint256 id;
        string propertyName;
        string location;
        uint256 totalValue;
        uint256 totalTokens;
        uint256 tokensIssued;
        uint256 annualRent;
        address propertyManager;
        bool isActive;
        mapping(address => uint256) tokenHolders;
        mapping(address => uint256) rentClaimed;
        uint256 lastRentDistribution;
    }

    // 8. Decentralized Identity and Reputation System
    struct UserProfile {
        address userAddress;
        string did; // Decentralized Identity
        uint256 reputationScore;
        uint256 totalTransactions;
        uint256 successfulLiquidations;
        uint256 defaultCount;
        bool isKYCVerified;
        bool isAccreditedInvestor;
        mapping(bytes32 => bool) credentials;
        mapping(address => uint256) peerRatings;
    }

    // 9. Perpetual Futures Trading
    struct PerpetualPosition {
        uint256 id;
        address trader;
        address underlying;
        bool isLong;
        uint256 size;
        uint256 collateral;
        uint256 leverage;
        uint256 entryPrice;
        uint256 liquidationPrice;
        uint256 fundingPayment;
        uint256 unrealizedPnL;
        bool isActive;
        uint256 lastFundingTime;
    }

    // 10. Algorithmic Stable Coin with Elastic Supply
    struct StableCoinPool {
        uint256 id;
        string name;
        address stableCoin;
        address collateralToken;
        uint256 targetPrice;
        uint256 currentPrice;
        uint256 totalSupply;
        uint256 collateralRatio;
        uint256 liquidationRatio;
        RebalanceStrategy strategy;
        bool isActive;
        mapping(address => uint256) userMintedAmount;
        mapping(address => uint256) userCollateral;
    }

    enum RebalanceStrategy { ALGORITHMIC, GOVERNANCE_CONTROLLED, HYBRID }

    // EXISTING STRUCTURES (keeping all previous ones)
    struct FlashLoan {
        uint256 id;
        address borrower;
        address token;
        uint256 amount;
        uint256 fee;
        uint256 timestamp;
        bool isRepaid;
    }

    struct CrossChainBridge {
        uint256 id;
        string destinationChain;
        address destinationContract;
        uint256 minAmount;
        uint256 maxAmount;
        uint256 bridgeFee;
        bool isActive;
        mapping(bytes32 => bool) processedTransactions;
    }

    struct NFTCollateral {
        uint256 tokenId;
        address nftContract;
        address owner;
        uint256 valuationAmount;
        uint256 loanAmount;
        uint256 interestRate;
        uint256 loanDuration;
        uint256 startTime;
        bool isActive;
        bool isLiquidated;
        address valuationOracle;
    }

    struct YieldVault {
        uint256 id;
        string name;
        address depositToken;
        uint256 totalDeposits;
        uint256 currentAPY;
        uint256 lockPeriod;
        uint256 managementFee;
        uint256 withdrawalFee;
        bool isActive;
        mapping(address => uint256) userDeposits;
        mapping(address => uint256) depositTime;
        mapping(address => uint256) earnedYield;
        address[] strategyContracts;
    }

    struct OrderBook {
        uint256 orderId;
        address maker;
        address tokenA;
        address tokenB;
        uint256 amountA;
        uint256 amountB;
        uint256 price;
        uint256 expiry;
        bool isActive;
        bool isFilled;
        OrderType orderType;
    }

    enum OrderType { MARKET, LIMIT, STOP_LOSS, TAKE_PROFIT }

    struct CreditDelegation {
        address delegator;
        address delegatee;
        address asset;
        uint256 creditLimit;
        uint256 usedCredit;
        uint256 interestRate;
        uint256 expiryTime;
        bool isActive;
    }

    struct OptionsContract {
        uint256 id;
        address underlying;
        uint256 strikePrice;
        uint256 premium;
        uint256 expiry;
        bool isCall;
        address writer;
        address buyer;
        bool isExercised;
        bool isActive;
        uint256 collateralAmount;
    }

    // STATE VARIABLES FOR NEW FEATURES
    uint256 public dutchAuctionCounter;
    uint256 public governanceProposalCounter;
    uint256 public stakingTierCounter;
    uint256 public liquidityPoolCounter;
    uint256 public insuranceCoverageCounter;
    uint256 public realEstateTokenCounter;
    uint256 public perpetualPositionCounter;
    uint256 public stableCoinPoolCounter;

    // EXISTING COUNTERS
    uint256 public flashLoanCounter;
    uint256 public crossChainBridgeCounter;
    uint256 public nftCollateralCounter;
    uint256 public yieldVaultCounter;
    uint256 public orderBookCounter;
    uint256 public creditDelegationCounter;
    uint256 public optionsCounter;

    // NEW MAPPINGS
    mapping(uint256 => DutchAuction) public dutchAuctions;
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    mapping(uint256 => StakingTier) public stakingTiers;
    mapping(address => mapping(uint256 => UserStake)) public userStakes;
    mapping(uint256 => LiquidityPool) public liquidityPools;
    mapping(uint256 => InsuranceCoverage) public insuranceCoverages;
    mapping(uint256 => RealEstateToken) public realEstateTokens;
    mapping(address => UserProfile) public userProfiles;
    mapping(uint256 => PerpetualPosition) public perpetualPositions;
    mapping(uint256 => StableCoinPool) public stableCoinPools;
    mapping(address => InterestRateModel) public interestRateModels;

    // EXISTING MAPPINGS
    mapping(uint256 => FlashLoan) public flashLoans;
    mapping(uint256 => CrossChainBridge) public crossChainBridges;
    mapping(uint256 => NFTCollateral) public nftCollaterals;
    mapping(uint256 => YieldVault) public yieldVaults;
    mapping(uint256 => OrderBook) public orderBooks;
    mapping(uint256 => CreditDelegation) public creditDelegations;
    mapping(uint256 => OptionsContract) public optionsContracts;

    // ADDITIONAL MAPPINGS
    mapping(address => uint256[]) public userFlashLoans;
    mapping(address => uint256[]) public userNFTCollaterals;
    mapping(address => uint256[]) public userOrders;
    mapping(address => uint256[]) public userStakingTiers;
    mapping(address => uint256[]) public userLiquidityPools;
    mapping(address => uint256[]) public userInsurancePolicies;
    mapping(address => uint256[]) public userRealEstateTokens;
    mapping(address => uint256[]) public userPerpetualPositions;
    mapping(address => bool) public authorizedNFTContracts;
    mapping(address => address) public nftPriceOracles;
    mapping(address => bool) public whitelistedTokens;
    mapping(address => uint256) public lastActivity;
    mapping(address => uint256) public loyaltyPoints;
    mapping(address => uint256) public totalFeesEarned;
    mapping(address => bool) public strategists;
    mapping(address => uint256) public reputationScores;

    // NEW FEATURE FLAGS
    bool public dynamicInterestEnabled = true;
    bool public dutchAuctionEnabled = true;
    bool public governanceEnabled = true;
    bool public advancedStakingEnabled = true;
    bool public ammEnabled = true;
    bool public insuranceEnabled = true;
    bool public realEstateEnabled = true;
    bool public perpetualTradingEnabled = true;
    bool public algorithmicStableCoinEnabled = true;

    // EXISTING FEATURE FLAGS
    bool public flashLoansEnabled = true;
    bool public crossChainEnabled = true;
    bool public nftCollateralEnabled = true;
    bool public yieldVaultsEnabled = true;
    bool public orderBookEnabled = true;
    bool public creditDelegationEnabled = true;
    bool public optionsEnabled = true;

    // PROTOCOL PARAMETERS
    uint256 public flashLoanFeeRate = 9; // 0.09% fee
    uint256 public constant FLASH_LOAN_FEE_PRECISION = 10000;
    uint256 public governanceQuorum = 4000; // 40% quorum required
    uint256 public votingPeriod = 3 days;
    uint256 public executionDelay = 1 days;
    uint256 public maxLeverage = 10; // 10x max leverage
    uint256 public liquidationThreshold = 8000; // 80%
    uint256 public protocolTreasuryFee = 100; // 1%

    // CORE TOKENS
    IERC20 public lendingToken;
    IERC20 public governanceToken;
    uint256 public availableLiquidity;

    // NEW EVENTS
    event DutchAuctionStarted(uint256 indexed auctionId, address indexed borrower, uint256 collateralAmount, uint256 startPrice);
    event DutchAuctionCompleted(uint256 indexed auctionId, address indexed winner, uint256 finalPrice);
    event GovernanceProposalCreated(uint256 indexed proposalId, address indexed proposer, string title);
    event GovernanceVoteCast(uint256 indexed proposalId, address indexed voter, VoteType voteType, uint256 weight);
    event StakingTierCreated(uint256 indexed tierId, string name, uint256 minStakeAmount, uint256 lockPeriod);
    event UserStaked(uint256 indexed tierId, address indexed user, uint256 amount, uint256 lockEndTime);
    event StakingRewardsClaimed(address indexed user, uint256 indexed tierId, uint256 rewardAmount);
    event LiquidityPoolCreated(uint256 indexed poolId, string name, address tokenA, address tokenB);
    event LiquidityAdded(uint256 indexed poolId, address indexed provider, uint256 amountA, uint256 amountB, uint256 lpTokens);
    event LiquidityRemoved(uint256 indexed poolId, address indexed provider, uint256 lpTokens, uint256 amountA, uint256 amountB);
    event TokensSwapped(uint256 indexed poolId, address indexed trader, address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut);
    event InsurancePolicyPurchased(uint256 indexed coverageId, address indexed policyholder, uint256 coverageAmount, uint256 premium);
    event InsuranceClaimSubmitted(uint256 indexed coverageId, address indexed policyholder, uint256 claimAmount);
    event RealEstateTokenized(uint256 indexed tokenId, string propertyName, uint256 totalValue, uint256 totalTokens);
    event RealEstateRentDistributed(uint256 indexed tokenId, uint256 totalRentAmount, uint256 perTokenAmount);
    event PerpetualPositionOpened(uint256 indexed positionId, address indexed trader, address underlying, bool isLong, uint256 size, uint256 leverage);
    event PerpetualPositionClosed(uint256 indexed positionId, address indexed trader, uint256 pnl);
    event StableCoinMinted(uint256 indexed poolId, address indexed user, uint256 collateralAmount, uint256 mintedAmount);
    event StableCoinRedeemed(uint256 indexed poolId, address indexed user, uint256 burnedAmount, uint256 collateralReturned);
    event InterestRateUpdated(address indexed token, uint256 newRate, uint256 utilizationRate);
    event ReputationScoreUpdated(address indexed user, uint256 newScore, string reason);

    // EXISTING EVENTS
    event FlashLoanInitiated(uint256 indexed loanId, address indexed borrower, address token, uint256 amount, uint256 fee);
    event FlashLoanRepaid(uint256 indexed loanId, address indexed borrower, uint256 totalAmount);
    event CrossChainTransferInitiated(uint256 indexed bridgeId, address indexed user, string destinationChain, uint256 amount);
    event NFTCollateralDeposited(uint256 indexed collateralId, address indexed user, address nftContract, uint256 tokenId, uint256 loanAmount);
    event NFTCollateralLiquidated(uint256 indexed collateralId, address indexed user, uint256 liquidationAmount);
    event YieldVaultDeposit(uint256 indexed vaultId, address indexed user, uint256 amount);
    event YieldVaultWithdraw(uint256 indexed vaultId, address indexed user, uint256 amount, uint256 yield);
    event OrderPlaced(uint256 indexed orderId, address indexed maker, address tokenA, address tokenB, uint256 amountA, uint256 price);
    event OrderFilled(uint256 indexed orderId, address indexed taker, uint256 filledAmount);
    event CreditDelegated(address indexed delegator, address indexed delegatee, address asset, uint256 creditLimit);
    event OptionsContractCreated(uint256 indexed optionId, address indexed writer, address underlying, uint256 strikePrice, bool isCall);
    event OptionsExercised(uint256 indexed optionId, address indexed buyer, uint256 payout);

    // MODIFIERS
    modifier onlyStrategist() {
        require(strategists[msg.sender] || owner() == msg.sender, "Not authorized strategist");
        _;
    }

    modifier updateActivity() {
        lastActivity[msg.sender] = block.timestamp;
        _;
    }

    modifier onlyKYCVerified() {
        require(userProfiles[msg.sender].isKYCVerified, "KYC verification required");
        _;
    }

    modifier onlyAccreditedInvestor() {
        require(userProfiles[msg.sender].isAccreditedInvestor, "Accredited investor status required");
        _;
    }

    constructor() Ownable(msg.sender) {
        strategists[msg.sender] = true;
        // Initialize default user profile for owner
        userProfiles[msg.sender].userAddress = msg.sender;
        userProfiles[msg.sender].reputationScore = 1000;
        userProfiles[msg.sender].isKYCVerified = true;
        userProfiles[msg.sender].isAccreditedInvestor = true;
    }

    // NEW FEATURE 1: Dynamic Interest Rate Model
    function setInterestRateModel(
        address _token,
        uint256 _baseRate,
        uint256 _multiplier,
        uint256 _jumpMultiplier,
        uint256 _optimalUtilization
    ) external onlyOwner {
        require(dynamicInterestEnabled, "Dynamic interest rates disabled");
        require(_optimalUtilization <= 10000, "Invalid optimal utilization");
        
        InterestRateModel storage model = interestRateModels[_token];
        model.baseRate = _baseRate;
        model.multiplier = _multiplier;
        model.jumpMultiplier = _jumpMultiplier;
        model.optimalUtilization = _optimalUtilization;
        model.isActive = true;
    }

    function calculateInterestRate(address _token, uint256 _utilization) public view returns (uint256) {
        InterestRateModel storage model = interestRateModels[_token];
        if (!model.isActive) return 500; // Default 5% if no model set
        
        if (_utilization <= model.optimalUtilization) {
            return model.baseRate.add(_utilization.mul(model.multiplier).div(model.optimalUtilization));
        } else {
            uint256 normalRate = model.baseRate.add(model.multiplier);
            uint256 excessUtilization = _utilization.sub(model.optimalUtilization);
            uint256 maxExcessUtilization = uint256(10000).sub(model.optimalUtilization);
            return normalRate.add(excessUtilization.mul(model.jumpMultiplier).div(maxExcessUtilization));
        }
    }

    // NEW FEATURE 2: Dutch Auction Liquidation
    function startDutchAuction(
        address _borrower,
        address _collateralToken,
        uint256 _collateralAmount,
        uint256 _debtAmount,
        uint256 _startPrice,
        uint256 _endPrice,
        uint256 _duration
    ) external onlyStrategist {
        require(dutchAuctionEnabled, "Dutch auctions disabled");
        require(_startPrice > _endPrice, "Invalid price range");
        require(_duration >= 1 hours && _duration <= 24 hours, "Invalid duration");
        
        dutchAuctionCounter = dutchAuctionCounter.add(1);
        
        DutchAuction storage auction = dutchAuctions[dutchAuctionCounter];
        auction.id = dutchAuctionCounter;
        auction.borrower = _borrower;
        auction.collateralToken = _collateralToken;
        auction.collateralAmount = _collateralAmount;
        auction.debtAmount = _debtAmount;
        auction.startPrice = _startPrice;
        auction.endPrice = _endPrice;
        auction.startTime = block.timestamp;
        auction.duration = _duration;
        auction.isActive = true;
        
        emit DutchAuctionStarted(dutchAuctionCounter, _borrower, _collateralAmount, _startPrice);
    }

    function bidOnDutchAuction(uint256 _auctionId) external payable nonReentrant updateActivity {
        require(_auctionId > 0 && _auctionId <= dutchAuctionCounter, "Invalid auction");
        DutchAuction storage auction = dutchAuctions[_auctionId];
        require(auction.isActive, "Auction not active");
        require(block.timestamp <= auction.startTime.add(auction.duration), "Auction ended");
        
        uint256 currentPrice = getCurrentAuctionPrice(_auctionId);
        require(msg.value >= currentPrice, "Bid too low");
        
        // Transfer collateral to winner
        require(IERC20(auction.collateralToken).transfer(msg.sender, auction.collateralAmount), "Collateral transfer failed");
        
        // Update auction state
        auction.isActive = false;
        auction.isCompleted = true;
        auction.winner = msg.sender;
        auction.finalPrice = currentPrice;
        
        // Return excess payment
        if (msg.value > currentPrice) {
            payable(msg.sender).transfer(msg.value.sub(currentPrice));
        }
        
        emit DutchAuctionCompleted(_auctionId, msg.sender, currentPrice);
    }

    function getCurrentAuctionPrice(uint256 _auctionId) public view returns (uint256) {
        DutchAuction storage auction = dutchAuctions[_auctionId];
        if (!auction.isActive) return 0;
        
        uint256 timeElapsed = block.timestamp.sub(auction.startTime);
        if (timeElapsed >= auction.duration) return auction.endPrice;
        
        uint256 priceDrop = auction.startPrice.sub(auction.endPrice);
        uint256 currentDrop = priceDrop.mul(timeElapsed).div(auction.duration);
        return auction.startPrice.sub(currentDrop);
    }

    // NEW FEATURE 3: Advanced Governance System
    function createGovernanceProposal(
        string memory _title,
        string memory _description,
        ProposalType _proposalType,
        bytes memory _callData
    ) external nonReentrant updateActivity {
        require(governanceEnabled, "Governance disabled");
        require(userProfiles[msg.sender].reputationScore >= 500, "Insufficient reputation to propose");
        require(governanceToken.balanceOf(msg.sender) >= 1000 * 10**18, "Insufficient governance tokens");
        
        governanceProposalCounter = governanceProposalCounter.add(1);
        
        GovernanceProposal storage proposal = governanceProposals[governanceProposalCounter];
        proposal.id = governanceProposalCounter;
        proposal.title = _title;
        proposal.description = _description;
        proposal.proposer = msg.sender;
        proposal.startTime = block.timestamp;
        proposal.endTime = block.timestamp.add(votingPeriod);
        proposal.executionTime = block.timestamp.add(votingPeriod).add(executionDelay);
        proposal.proposalType = _proposalType;
        proposal.callData = _callData;
        proposal.isActive = true;
        
        emit GovernanceProposalCreated(governanceProposalCounter, msg.sender, _title);
    }

    function voteOnProposal(uint256 _proposalId, VoteType _voteType) external nonReentrant updateActivity {
        require(_proposalId > 0 && _proposalId <= governanceProposalCounter, "Invalid proposal");
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.isActive, "Proposal not active");
        require(block.timestamp <= proposal.endTime, "Voting period ended");
        require(!proposal.hasVoted[msg.sender], "Already voted");
        
        uint256 votingPower = governanceToken.balanceOf(msg.sender);
        require(votingPower > 0, "No voting power");
        
        proposal.hasVoted[msg.sender] = true;
        proposal.userVotes[msg.sender] = _voteType;
        
        if (_voteType == VoteType.FOR) {
            proposal.votesFor = proposal.votesFor.add(votingPower);
        } else if (_voteType == VoteType.AGAINST) {
            proposal.votesAgainst = proposal.votesAgainst.add(votingPower);
        } else {
            proposal.votesAbstain = proposal.votesAbstain.add(votingPower);
        }
        
        emit GovernanceVoteCast(_proposalId, msg.sender, _voteType, votingPower);
    }

    function executeProposal(uint256 _proposalId) external nonReentrant {
        require(_proposalId > 0 && _proposalId <= governanceProposalCounter, "Invalid proposal");
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.isActive, "Proposal not active");
        require(block.timestamp >= proposal.executionTime, "Too early to execute");
        require(!proposal.isExecuted, "Already executed");
        
        uint256 totalVotes = proposal.votesFor.add(proposal.votesAgainst).add(proposal.votesAbstain);
        uint256 totalSupply = governanceToken.totalSupply();
        require(totalVotes.mul(10000).div(totalSupply) >= governanceQuorum, "Quorum not reached");
        require(proposal.votesFor > proposal.votesAgainst, "Proposal rejected");
        
        proposal.isExecuted = true;
        proposal.isActive = false;
        
        // Execute the proposal (this would need specific implementation based on proposal type)
        if (proposal.callData.length > 0) {
            (bool success,) = address(this).call(proposal.callData);
            require(success, "Proposal execution failed");
        }
    }

    // NEW FEATURE 4: Advanced Staking with Tiers
    function createStakingTier(
        string memory _name,
        uint256 _minStakeAmount,
        uint256 _lockPeriod,
        uint256 _rewardMultiplier,
        uint256 _maxCapacity
    ) external onlyOwner {
        require(advancedStakingEnabled, "Advanced staking disabled");
        require(_lockPeriod >= 1 days, "Lock period too short");
        require(_rewardMultiplier >= 100 && _rewardMultiplier <= 1000, "Invalid multiplier");
        
        stakingTierCounter = stakingTierCounter.add(1);
        
        StakingTier storage tier = stakingTiers[stakingTierCounter];
        tier.id = stakingTierCounter;
        tier.name = _name;
        tier.minStakeAmount = _minStakeAmount;
        tier.lockPeriod = _lockPeriod;
        tier.rewardMultiplier = _rewardMultiplier;
        tier.maxCapacity = _maxCapacity;
        tier.isActive = true;
        
        emit StakingTierCreated(stakingTierCounter, _name, _minStakeAmount, _lockPeriod);
    }

    function stakeTokens(uint256 _tierId, uint256 _amount) external nonReentrant updateActivity {
        require(_tierId > 0 && _tierId <= stakingTierCounter, "Invalid tier");
        StakingTier storage tier = stakingTiers[_tierId];
        require(tier.isActive, "Tier not active");
        require(_amount >= tier.minStakeAmount, "Amount below minimum");
        require(tier.currentStaked.add(_amount) <= tier.maxCapacity, "Tier capacity exceeded");
        
        require(governanceToken.transferFrom(msg.sender, address(this), _amount), "Stake transfer failed");
        
        UserStake storage stake = userStakes[msg.sender][_tierId];
        stake.tierId = _tierId;
        stake.amount = stake.amount.add(_amount);
        stake.startTime = block.timestamp;
        stake.lockEndTime = block.timestamp.add(tier.lockPeriod);
        stake.isActive = true;
        
        tier.currentStaked = tier.currentStaked.add(_amount);
        userStakingTiers[msg.sender].push(_tierId);
        
        emit UserStaked(_tierId, msg.sender, _amount, stake.lockEndTime);
    }

    function unstakeTokens(uint256 _tierId) external nonReentrant updateActivity {
        UserStake storage stake = userStakes[msg.sender][_tierId];
        require(stake.isActive, "No active stake");
        require(block.timestamp >= stake.lockEndTime, "Still locked");
        
        uint256
