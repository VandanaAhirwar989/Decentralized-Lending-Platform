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

    // ===== NEW FUNCTIONALITY 1: ADVANCED PORTFOLIO MANAGEMENT =====
    struct Portfolio {
        uint256 id;
        address owner;
        string name;
        uint256 totalValue;
        uint256 riskScore;
        PortfolioStrategy strategy;
        bool isActive;
        bool isPublic;
        uint256 managementFee;
        uint256 performanceFee;
        mapping(address => uint256) tokenAllocations;
        mapping(address => uint256) targetAllocations;
        uint256 lastRebalance;
        uint256 totalInvestors;
        mapping(address => uint256) investorShares;
    }

    enum PortfolioStrategy { CONSERVATIVE, BALANCED, AGGRESSIVE, CUSTOM }

    struct RebalanceConfig {
        uint256 threshold; // Percentage deviation that triggers rebalance
        uint256 cooldownPeriod; // Minimum time between rebalances
        bool autoRebalanceEnabled;
        uint256 maxSlippage;
    }

    // ===== NEW FUNCTIONALITY 2: DECENTRALIZED DERIVATIVES EXCHANGE =====
    struct DerivativeContract {
        uint256 id;
        DerivativeType derivativeType;
        address underlying;
        address creator;
        uint256 notionalAmount;
        uint256 strikePrice;
        uint256 premium;
        uint256 expiryTime;
        uint256 marginRequirement;
        bool isSettled;
        bool isActive;
        mapping(address => Position) positions;
        uint256 totalLongPositions;
        uint256 totalShortPositions;
    }

    struct Position {
        uint256 size;
        bool isLong;
        uint256 entryPrice;
        uint256 margin;
        uint256 unrealizedPnL;
        uint256 lastUpdateTime;
    }

    enum DerivativeType { SWAP, FORWARD, FUTURE, OPTION }

    // ===== NEW FUNCTIONALITY 3: MULTI-CHAIN YIELD FARMING =====
    struct YieldFarm {
        uint256 id;
        string name;
        address[] tokens;
        uint256[] weights;
        uint256 totalStaked;
        uint256 rewardRate;
        uint256 lockPeriod;
        uint256 withdrawalFee;
        bool isActive;
        mapping(address => FarmPosition) userPositions;
        address[] rewardTokens;
        uint256[] rewardRates;
        uint256 lastRewardTime;
    }

    struct FarmPosition {
        uint256 stakedAmount;
        uint256 entryTime;
        uint256 lockEndTime;
        uint256 pendingRewards;
        uint256 claimedRewards;
        mapping(address => uint256) tokenRewards;
    }

    // ===== NEW FUNCTIONALITY 4: SOCIAL TRADING PLATFORM =====
    struct Trader {
        address traderAddress;
        string username;
        uint256 totalFollowers;
        uint256 totalCopiers;
        uint256 performanceScore;
        uint256 riskScore;
        uint256 totalPnL;
        uint256 totalTrades;
        uint256 winRate;
        bool isVerified;
        mapping(address => bool) followers;
        mapping(address => CopyTradeConfig) copyTraders;
    }

    struct CopyTradeConfig {
        uint256 copyAmount;
        uint256 maxRiskPerTrade;
        uint256 stopLossPercent;
        uint256 takeProfitPercent;
        bool isActive;
        mapping(address => bool) allowedTokens;
    }

    // ===== NEW FUNCTIONALITY 5: CROSS-CHAIN BRIDGE WITH VALIDATION =====
    struct BridgeTransaction {
        uint256 id;
        address sender;
        address recipient;
        address token;
        uint256 amount;
        string sourceChain;
        string destinationChain;
        bytes32 txHash;
        BridgeStatus status;
        uint256 timestamp;
        uint256 validatorCount;
        mapping(address => bool) validatorApprovals;
        uint256 fee;
    }

    enum BridgeStatus { PENDING, VALIDATED, COMPLETED, FAILED, DISPUTED }

    struct ChainConfig {
        string chainName;
        address bridgeContract;
        uint256 minValidators;
        uint256 bridgeFee;
        bool isActive;
        mapping(address => bool) validators;
        uint256 validatorCount;
    }

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

    // NEW FEATURE COUNTERS
    uint256 public portfolioCounter;
    uint256 public derivativeCounter;
    uint256 public yieldFarmCounter;
    uint256 public bridgeTransactionCounter;

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

    // NEW FUNCTIONALITY MAPPINGS
    mapping(uint256 => Portfolio) public portfolios;
    mapping(address => uint256[]) public userPortfolios;
    mapping(uint256 => RebalanceConfig) public rebalanceConfigs;
    mapping(uint256 => DerivativeContract) public derivativeContracts;
    mapping(uint256 => YieldFarm) public yieldFarms;
    mapping(address => Trader) public traders;
    mapping(address => address[]) public followedTraders;
    mapping(uint256 => BridgeTransaction) public bridgeTransactions;
    mapping(string => ChainConfig) public chainConfigs;
    mapping(address => bool) public bridgeValidators;

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
    
    // NEW FUNCTIONALITY FLAGS
    bool public portfolioManagementEnabled = true;
    bool public derivativesEnabled = true;
    bool public yieldFarmingEnabled = true;
    bool public socialTradingEnabled = true;
    bool public crossChainBridgeEnabled = true;

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

    // NEW EVENTS FOR ADDED FUNCTIONALITY
    event PortfolioCreated(uint256 indexed portfolioId, address indexed owner, string name, PortfolioStrategy strategy);
    event PortfolioRebalanced(uint256 indexed portfolioId, address indexed rebalancer, uint256 timestamp);
    event PortfolioInvestment(uint256 indexed portfolioId, address indexed investor, uint256 amount, uint256 shares);
    event DerivativeContractCreated(uint256 indexed contractId, DerivativeType derivativeType, address indexed creator, address underlying);
    event DerivativePositionOpened(uint256 indexed contractId, address indexed trader, bool isLong, uint256 size, uint256 margin);
    event YieldFarmCreated(uint256 indexed farmId, string name, address[] tokens, uint256 rewardRate);
    event YieldFarmStaked(uint256 indexed farmId, address indexed user, uint256 amount, uint256 lockEndTime);
    event TraderRegistered(address indexed trader, string username);
    event TradeAction(address indexed trader, address indexed token, bool isBuy, uint256 amount, uint256 price);
    event CopyTradeExecuted(address indexed originalTrader, address indexed copyTrader, address token, uint256 amount);
    event BridgeTransactionInitiated(uint256 indexed txId, address indexed sender, string sourceChain, string destinationChain, uint256 amount);
    event BridgeTransactionValidated(uint256 indexed txId, address indexed validator);
    event BridgeTransactionCompleted(uint256 indexed txId, address indexed recipient, uint256 amount);

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

    modifier onlyValidator() {
        require(bridgeValidators[msg.sender], "Not authorized validator");
        _;
    }

    constructor() Ownable(msg.sender) {
        strategists[msg.sender] = true;
        bridgeValidators[msg.sender] = true;
        // Initialize default user profile for owner
        userProfiles[msg.sender].userAddress = msg.sender;
        userProfiles[msg.sender].reputationScore = 1000;
        userProfiles[msg.sender].isKYCVerified = true;
        userProfiles[msg.sender].isAccreditedInvestor = true;
    }

    // ===== NEW FUNCTIONALITY 1: ADVANCED PORTFOLIO MANAGEMENT =====
    
    function createPortfolio(
        string memory _name,
        PortfolioStrategy _strategy,
        bool _isPublic,
        uint256 _managementFee,
        uint256 _performanceFee
    ) external nonReentrant updateActivity {
        require(portfolioManagementEnabled, "Portfolio management disabled");
        require(_managementFee <= 500, "Management fee too high"); // Max 5%
        require(_performanceFee <= 2000, "Performance fee too high"); // Max 20%
        
        portfolioCounter = portfolioCounter.add(1);
        
        Portfolio storage portfolio = portfolios[portfolioCounter];
        portfolio.id = portfolioCounter;
        portfolio.owner = msg.sender;
        portfolio.name = _name;
        portfolio.strategy = _strategy;
        portfolio.isActive = true;
        portfolio.isPublic = _isPublic;
        portfolio.managementFee = _managementFee;
        portfolio.performanceFee = _performanceFee;
        portfolio.lastRebalance = block.timestamp;
        
        userPortfolios[msg.sender].push(portfolioCounter);
        
        emit PortfolioCreated(portfolioCounter, msg.sender, _name, _strategy);
    }

    function investInPortfolio(uint256 _portfolioId, uint256 _amount) external nonReentrant updateActivity {
        require(_portfolioId > 0 && _portfolioId <= portfolioCounter, "Invalid portfolio");
        Portfolio storage portfolio = portfolios[_portfolioId];
        require(portfolio.isActive, "Portfolio not active");
        require(portfolio.isPublic || portfolio.owner == msg.sender, "Portfolio not public");
        
        require(lendingToken.transferFrom(msg.sender, address(this), _amount), "Investment transfer failed");
        
        uint256 shares = _amount; // Simplified share calculation
        if (portfolio.totalValue > 0) {
            shares = _amount.mul(portfolio.totalInvestors).div(portfolio.totalValue);
        }
        
        portfolio.investorShares[msg.sender] = portfolio.investorShares[msg.sender].add(shares);
        portfolio.totalValue = portfolio.totalValue.add(_amount);
        portfolio.totalInvestors = portfolio.totalInvestors.add(1);
        
        emit PortfolioInvestment(_portfolioId, msg.sender, _amount, shares);
    }

    function rebalancePortfolio(uint256 _portfolioId) external nonReentrant {
        require(_portfolioId > 0 && _portfolioId <= portfolioCounter, "Invalid portfolio");
        Portfolio storage portfolio = portfolios[_portfolioId];
        require(portfolio.isActive, "Portfolio not active");
        require(portfolio.owner == msg.sender || strategists[msg.sender], "Not authorized");
        
        RebalanceConfig storage config = rebalanceConfigs[_portfolioId];
        require(block.timestamp >= portfolio.lastRebalance.add(config.cooldownPeriod), "Cooldown period not met");
        
        // Rebalancing logic would go here
        portfolio.lastRebalance = block.timestamp;
        
        emit PortfolioRebalanced(_portfolioId, msg.sender, block.timestamp);
    }

    // ===== NEW FUNCTIONALITY 2: DECENTRALIZED DERIVATIVES EXCHANGE =====
    
    function createDerivativeContract(
        DerivativeType _derivativeType,
        address _underlying,
        uint256 _notionalAmount,
        uint256 _strikePrice,
        uint256 _premium,
        uint256 _expiryTime,
        uint256 _marginRequirement
    ) external nonReentrant updateActivity onlyKYCVerified {
        require(derivativesEnabled, "Derivatives disabled");
        require(_expiryTime > block.timestamp, "Invalid expiry time");
        require(_marginRequirement >= _notionalAmount.div(10), "Insufficient margin requirement");
        
        derivativeCounter = derivativeCounter.add(1);
        
        DerivativeContract storage derivative = derivativeContracts[derivativeCounter];
        derivative.id = derivativeCounter;
        derivative.derivativeType = _derivativeType;
        derivative.underlying = _underlying;
        derivative.creator = msg.sender;
        derivative.notionalAmount = _notionalAmount;
        derivative.strikePrice = _strikePrice;
        derivative.premium = _premium;
        derivative.expiryTime = _expiryTime;
        derivative.marginRequirement = _marginRequirement;
        derivative.isActive = true;
        
        emit DerivativeCont
