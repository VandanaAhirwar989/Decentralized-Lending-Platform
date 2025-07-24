      // SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title Enhanced Decentralized Lending Platform
 * @dev A comprehensive lending platform with advanced features for DeFi
 */
contract Project is ReentrancyGuard, Ownable, Pausable {
    using SafeMath for uint256;

    // Structs
    struct LenderInfo {
        uint256 depositedAmount;
        uint256 lastUpdateTime;
        uint256 accruedInterest;
        uint256 rewardTokens;
        uint256 stakingTime;
        uint8 tierLevel;
        uint256 totalEarned;
        uint256 compoundCount;
        bool autoCompoundEnabled;
    }

    struct BorrowerInfo {
        uint256 borrowedAmount;
        uint256 collateralAmount;
        uint256 lastUpdateTime;
        uint256 accruedInterest;
        uint256 liquidationThreshold;
        uint256 creditScore;
        bool isWhitelisted;
        uint256 totalRepaid;
        uint256 loanStartTime;
        uint256 maxLoanDuration;
    }

    struct PoolInfo {
        uint256 totalSupply;
        uint256 totalBorrows;
        uint256 reserveFactor;
        uint256 utilizationRate;
        uint256 currentLendingRate;
        uint256 currentBorrowingRate;
        uint256 lastUpdateTime;
    }

    struct GovernanceProposal {
        uint256 id;
        string description;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 endTime;
        bool executed;
        address proposer;
        mapping(address => bool) hasVoted;
        uint256 proposalType; // 1: Parameter change, 2: Feature toggle, 3: Treasury action
        bytes proposalData;
    }

    struct YieldFarmingPool {
        IERC20 stakingToken;
        uint256 totalStaked;
        uint256 rewardRate;
        uint256 lastUpdateTime;
        uint256 rewardPerTokenStored;
        uint256 poolEndTime;
        uint256 minStakingPeriod;
        mapping(address => uint256) userStaked;
        mapping(address => uint256) userRewardPerTokenPaid;
        mapping(address => uint256) rewards;
        mapping(address => uint256) stakingStartTime;
    }

    struct Insurance {
        uint256 totalCoverage;
        uint256 premiumRate;
        mapping(address => uint256) userCoverage;
        mapping(address => uint256) premiumsPaid;
        mapping(address => bool) isCovered;
        mapping(address => uint256) claimHistory;
        uint256 maxClaimAmount;
        uint256 claimCooldown;
    }

    struct LiquidationInfo {
        uint256 liquidationBonus;
        uint256 maxLiquidationPercent;
        mapping(address => bool) isProtectedFromLiquidation;
        mapping(address => uint256) liquidationCooldown;
    }

    struct FlashLoanInfo {
        uint256 totalFlashLoaned;
        uint256 flashLoanCount;
        mapping(address => uint256) userFlashLoanCount;
        mapping(address => uint256) userFlashLoanVolume;
        mapping(address => bool) flashLoanWhitelist;
    }

    struct NFTBoost {
        mapping(address => bool) hasNFTBoost;
        mapping(address => uint256) boostMultiplier; // 100 = 1x, 150 = 1.5x
        mapping(address => uint256) boostExpiry;
        address nftContract; // NFT contract for boost verification
    }

    struct TreasuryInfo {
        uint256 totalTreasuryFees;
        uint256 lastDistributionTime;
        uint256 distributionInterval;
        mapping(address => uint256) userTreasuryShares;
        uint256 totalTreasuryShares;
    }

    struct LoanPackage {
        uint256 id;
        string name;
        uint256 minAmount;
        uint256 maxAmount;
        uint256 interestRate;
        uint256 maxDuration;
        uint256 collateralRatio;
        bool isActive;
        uint256 totalLoaned;
        uint256 loanCount;
    }

    // NEW STRUCTURES FOR ADDITIONAL FEATURES

    struct SubscriptionPlan {
        uint256 id;
        string name;
        uint256 monthlyFee;
        uint256 discountRate; // Percentage discount on interest rates
        uint256 maxUsers;
        uint256 currentUsers;
        bool isActive;
        uint256 minStakingPeriod;
        mapping(address => uint256) subscribers;
        mapping(address => uint256) subscriptionExpiry;
    }

    struct StakingTier {
        uint256 minAmount;
        uint256 maxAmount;
        uint256 aprRate;
        uint256 lockupPeriod;
        uint256 earlyWithdrawalPenalty;
        bool isActive;
    }

    struct CreditLine {
        uint256 creditLimit;
        uint256 usedCredit;
        uint256 interestRate;
        uint256 lastPaymentTime;
        uint256 minimumPayment;
        bool isActive;
        uint256 creditScore;
        uint256 paymentHistory; // Score out of 100
    }

    struct Option {
        uint256 id;
        address owner;
        uint256 strikePrice;
        uint256 expiryTime;
        uint256 premium;
        bool isCall; // true for call, false for put
        bool isExercised;
        uint256 underlyingAmount;
        address underlyingToken;
    }

    struct Auction {
        uint256 id;
        address seller;
        uint256 amount;
        uint256 startingPrice;
        uint256 currentBid;
        address highestBidder;
        uint256 endTime;
        bool isActive;
        bool isCompleted;
        address tokenAddress;
    }

    struct CrossChainBridge {
        mapping(uint256 => bool) supportedChains;
        mapping(address => mapping(uint256 => uint256)) userBalances;
        mapping(bytes32 => bool) processedTransactions;
        uint256 bridgeFee;
        bool isActive;
    }

    struct AIRiskModel {
        mapping(address => uint256) riskScores;
        mapping(address => uint256) lastRiskUpdate;
        uint256 riskThreshold;
        bool isActive;
        mapping(address => bool) highRiskUsers;
    }

    struct DynamicPricing {
        mapping(address => uint256) demandFactors;
        mapping(address => uint256) lastPriceUpdate;
        uint256 priceVolatility;
        bool isDynamicPricingEnabled;
    }

    struct Gamification {
        mapping(address => uint256) userLevel;
        mapping(address => uint256) experience;
        mapping(address => uint256) achievements;
        mapping(address => uint256) streaks;
        mapping(uint256 => uint256) levelRequirements;
        mapping(address => uint256) lastActivityTime;
    }

    struct Escrow {
        uint256 id;
        address buyer;
        address seller;
        uint256 amount;
        bool isCompleted;
        bool isDisputed;
        address arbitrator;
        uint256 createdTime;
        uint256 releaseTime;
    }

    // Token addresses (replace with real ones before deployment)
    address constant LENDING_TOKEN_ADDRESS = 0x0000000000000000000000000000000000000001;
    address constant COLLATERAL_TOKEN_ADDRESS = 0x0000000000000000000000000000000000000002;
    address constant GOVERNANCE_TOKEN_ADDRESS = 0x0000000000000000000000000000000000000003;

    // Tokens
    IERC20 public lendingToken;
    IERC20 public collateralToken;
    IERC20 public governanceToken;

    // Enhanced Constants
    uint256 public constant BASE_LENDING_RATE = 2;
    uint256 public constant BASE_BORROWING_RATE = 5;
    uint256 public constant RATE_MULTIPLIER = 20;
    uint256 public constant OPTIMAL_UTILIZATION = 80;
    uint256 public constant COLLATERAL_RATIO = 150;
    uint256 public constant LIQUIDATION_THRESHOLD = 120;
    uint256 public constant LIQUIDATION_PENALTY = 10;
    uint256 public constant RESERVE_FACTOR = 10;
    uint256 public constant SECONDS_PER_YEAR = 365 days;
    uint256 public constant MAX_BORROW_LIMIT = 1000000 * 10**18;
    uint256 public constant TIER_THRESHOLD = 30 days;
    uint256 public constant MIN_VOTING_POWER = 1000 * 10**18;
    uint256 public constant MAX_LOAN_DURATION = 365 days;
    uint256 public constant COMPOUND_FREQUENCY = 1 days;

    // State variables
    uint256 public totalDeposits;
    uint256 public totalBorrows;
    uint256 public availableLiquidity;
    uint256 public totalReserves;
    uint256 public flashLoanFee = 9;
    uint256 public rewardTokensPerSecond = 1 * 10**15;
    uint256 public proposalCounter;
    uint256 public votingDuration = 7 days;
    uint256 public insuranceFund;
    uint256 public loanPackageCounter;
    uint256 public dynamicInterestEnabled = 1; // 1 = enabled, 0 = disabled
    uint256 public autoLiquidationEnabled = 1;
    uint256 public stakingRewardsMultiplier = 100; // 100 = 1x
    
    // NEW STATE VARIABLES
    uint256 public subscriptionPlanCounter;
    uint256 public optionCounter;
    uint256 public auctionCounter;
    uint256 public escrowCounter;
    uint256 public totalCreditLines;
    uint256 public maxCreditMultiplier = 300; // 3x leverage
    
    bool public flashLoansEnabled = true;
    bool public borrowingEnabled = true;
    bool public depositsEnabled = true;
    bool public yieldFarmingEnabled = true;
    bool public governanceEnabled = true;
    bool public insuranceEnabled = true;
    bool public crossChainEnabled = false;
    bool public leverageEnabled = false; // New: leverage trading feature
    bool public subscriptionEnabled = true;
    bool public optionsEnabled = true;
    bool public auctionEnabled = true;
    bool public aiRiskEnabled = true;
    bool public gamificationEnabled = true;

    // Mappings
    mapping(address => LenderInfo) public lenders;
    mapping(address => BorrowerInfo) public borrowers;
    mapping(address => bool) public authorizedLiquidators;
    mapping(address => uint256) public userBorrowLimits;
    mapping(uint256 => GovernanceProposal) public proposals;
    mapping(address => uint256) public votingPower;
    mapping(address => uint256) public referralRewards;
    mapping(address => address) public referrers;
    mapping(uint256 => YieldFarmingPool) public yieldPools;
    mapping(address => bool) public whitelistedTokens;
    mapping(uint256 => LoanPackage) public loanPackages;
    
    // Multi-collateral support
    mapping(address => uint256) public collateralFactors;
    mapping(address => mapping(address => uint256)) public userCollaterals;

    // New advanced mappings
    mapping(address => uint256) public lastActivity; // For activity tracking
    mapping(address => uint256) public loyaltyPoints; // Loyalty program
    mapping(address => bool) public vipMembers; // VIP membership
    mapping(address => uint256) public socialScore; // Social credit score
    mapping(address => mapping(address => uint256)) public p2pLending; // Peer-to-peer lending
    mapping(address => uint256) public leveragePositions; // Leverage trading positions
    mapping(address => bool) public blacklistedUsers; // Blacklist functionality
    mapping(address => uint256) public userRiskScore; // Risk assessment
    mapping(address => uint256) public depositLimits; // Individual deposit limits
    mapping(address => bool) public automationEnabled; // Automation preferences

    // NEW MAPPINGS FOR ADDITIONAL FEATURES
    mapping(uint256 => SubscriptionPlan) public subscriptionPlans;
    mapping(address => CreditLine) public creditLines;
    mapping(uint256 => StakingTier) public stakingTiers;
    mapping(uint256 => Option) public options;
    mapping(uint256 => Auction) public auctions;
    mapping(uint256 => Escrow) public escrows;
    mapping(address => uint256) public perpetualSwapPositions;
    mapping(address => mapping(address => uint256)) public tokenSwapRates;
    mapping(address => uint256) public autoRepayThresholds;
    mapping(address => bool) public autoRepayEnabled;

    Insurance public insurance;
    LiquidationInfo public liquidationInfo;
    FlashLoanInfo public flashLoanInfo;
    NFTBoost public nftBoost;
    TreasuryInfo public treasury;
    CrossChainBridge public crossChainBridge;
    AIRiskModel public aiRiskModel;
    DynamicPricing public dynamicPricing;
    Gamification public gamification;
    uint256 public yieldPoolCounter;

    // Arrays for iteration
    address[] public lendersList;
    address[] public borrowersList;
    address[] public supportedCollaterals;
    address[] public vipMembersList;
    address[] public creditLineUsers;

    // New Events for Additional Features
    event SubscriptionPlanCreated(uint256 indexed planId, string name, uint256 monthlyFee);
    event UserSubscribed(address indexed user, uint256 indexed planId, uint256 expiry);
    event CreditLineApproved(address indexed user, uint256 creditLimit);
    event CreditUsed(address indexed user, uint256 amount, uint256 remaining);
    event OptionCreated(uint256 indexed optionId, address indexed owner, uint256 strikePrice);
    event OptionExercised(uint256 indexed optionId, address indexed exerciser, uint256 profit);
    event AuctionCreated(uint256 indexed auctionId, address indexed seller, uint256 startingPrice);
    event BidPlaced(uint256 indexed auctionId, address indexed bidder, uint256 amount);
    event AuctionCompleted(uint256 indexed auctionId, address indexed winner, uint256 finalPrice);
    event EscrowCreated(uint256 indexed escrowId, address indexed buyer, address indexed seller, uint256 amount);
    event EscrowReleased(uint256 indexed escrowId, address indexed recipient);
    event LevelUp(address indexed user, uint256 newLevel);
    event AchievementUnlocked(address indexed user, uint256 achievementId);
    event PerpetualPositionOpened(address indexed user, uint256 amount, bool isLong);
    event AutoRepayExecuted(address indexed user, uint256 amount);
    event TokensSwapped(address indexed user, address tokenA, address tokenB, uint256 amountIn, uint256 amountOut);

    // Original Events
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount, uint256 interest);
    event Borrow(address indexed user, uint256 borrowAmount, uint256 collateralAmount);
    event Repay(address indexed user, uint256 amount, uint256 interest);
    event Liquidation(address indexed borrower, address indexed liquidator, uint256 collateralSeized, uint256 debtCovered);
    event FlashLoan(address indexed borrower, uint256 amount, uint256 fee);
    event InterestRatesUpdated(uint256 lendingRate, uint256 borrowingRate);
    event ReservesWithdrawn(uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support, uint256 votes);
    event ProposalExecuted(uint256 indexed proposalId);
    event YieldFarmingPoolCreated(uint256 indexed poolId, address indexed stakingToken);
    event Staked(uint256 indexed poolId, address indexed user, uint256 amount);
    event Unstaked(uint256 indexed poolId, address indexed user, uint256 amount);
    event InsuranceClaimed(address indexed user, uint256 amount);
    event ReferralReward(address indexed referrer, address indexed referee, uint256 reward);
    event TierUpgraded(address indexed user, uint8 newTier);
    event CollateralAdded(address indexed token, uint256 factor);
    event LoyaltyPointsAwarded(address indexed user, uint256 points);
    event VIPStatusGranted(address indexed user);
    event LoanPackageCreated(uint256 indexed packageId, string name);
    event LeveragePositionOpened(address indexed user, uint256 amount, uint256 leverage);
    event AutoCompoundExecuted(address indexed user, uint256 amount);
    event SocialScoreUpdated(address indexed user, uint256 newScore);
    event P2PLoanCreated(address indexed lender, address indexed borrower, uint256 amount);
    event TreasuryDistribution(uint256 totalAmount, uint256 recipientCount);
    event NFTBoostActivated(address indexed user, uint256 multiplier, uint256 expiry);

    // Modifiers
    modifier whenDepositsEnabled() {
        require(depositsEnabled, "Deposits are disabled");
        _;
    }

    modifier whenBorrowingEnabled() {
        require(borrowingEnabled, "Borrowing is disabled");
        _;
    }

    modifier onlyAuthorizedLiquidator() {
        require(authorizedLiquidators[msg.sender] || owner() == msg.sender, "Not authorized liquidator");
        _;
    }

    modifier onlyGovernance() {
        require(governanceEnabled && votingPower[msg.sender] >= MIN_VOTING_POWER, "Insufficient governance power");
        _;
    }

    modifier notBlacklisted() {
        require(!blacklistedUsers[msg.sender], "User is blacklisted");
        _;
    }

    modifier onlyVIP() {
        require(vipMembers[msg.sender], "VIP access required");
        _;
    }

    modifier updateActivity() {
        lastActivity[msg.sender] = block.timestamp;
        _updateGamification(msg.sender);
        _;
    }

    modifier onlySubscriber(uint256 _planId) {
        SubscriptionPlan storage plan = subscriptionPlans[_planId];
        require(plan.subscribers[msg.sender] > 0, "Not subscribed");
        require(plan.subscriptionExpiry[msg.sender] > block.timestamp, "Subscription expired");
        _;
    }

    constructor() Ownable(msg.sender) {
        lendingToken = IERC20(LENDING_TOKEN_ADDRESS);
        collateralToken = IERC20(COLLATERAL_TOKEN_ADDRESS);
        governanceToken = IERC20(GOVERNANCE_TOKEN_ADDRESS);
        authorizedLiquidators[msg.sender] = true;
        
        // Initialize default collateral
        collateralFactors[COLLATERAL_TOKEN_ADDRESS] = 150;
        supportedCollaterals.push(COLLATERAL_TOKEN_ADDRESS);
        whitelistedTokens[COLLATERAL_TOKEN_ADDRESS] = true;
        
        // Initialize insurance
        insurance.premiumRate = 100; // 1% annual premium
        insurance.maxClaimAmount = 100000 * 10**18;
        insurance.claimCooldown = 30 days;
        
        // Initialize liquidation info
        liquidationInfo.liquidationBonus = 5; // 5% bonus for liquidators
        liquidationInfo.maxLiquidationPercent = 50; // Max 50% liquidation per transaction
        
        // Initialize treasury
        treasury.distributionInterval = 7 days;
        treasury.lastDistributionTime = block.timestamp;
        
        // Initialize AI Risk Model
        aiRiskModel.riskThreshold = 75;
        aiRiskModel.isActive = true;
        
        // Initialize gamification levels
        _initializeGamification();
        
        // Create default subscription plans
        _createDefaultSubscriptionPlans();
        
        // Create default staking tiers
        _createDefaultStakingTiers();
        
        // Create default loan packages
        _createDefaultLoanPackages();
    }

    // NEW FEATURE 11: Subscription Plans
    function createSubscriptionPlan(
        string memory _name,
        uint256 _monthlyFee,
        uint256 _discountRate,
        uint256 _maxUsers,
        uint256 _minStakingPeriod
    ) external onlyOwner {
        subscriptionPlanCounter = subscriptionPlanCounter.add(1);
        
        SubscriptionPlan storage plan = subscriptionPlans[subscriptionPlanCounter];
        plan.id = subscriptionPlanCounter;
        plan.name = _name;
        plan.monthlyFee = _monthlyFee;
        plan.discountRate = _discountRate;
        plan.maxUsers = _maxUsers;
        plan.currentUsers = 0;
        plan.isActive = true;
        plan.minStakingPeriod = _minStakingPeriod;
        
        emit SubscriptionPlanCreated(subscriptionPlanCounter, _name, _monthlyFee);
    }

    function subscribeToSPlan(uint256 _planId) external nonReentrant updateActivity {
        require(subscriptionEnabled, "Subscriptions disabled");
        SubscriptionPlan storage plan = subscriptionPlans[_planId];
        require(plan.isActive, "Plan not active");
        require(plan.currentUsers < plan.maxUsers, "Plan at max capacity");
        require(plan.subscribers[msg.sender] == 0, "Already subscribed");
        
        require(lendingToken.transferFrom(msg.sender, address(this), plan.monthlyFee), "Payment failed");
        
        plan.subscribers[msg.sender] = _planId;
        plan.subscriptionExpiry[msg.sender] = block.timestamp.add(30 days);
        plan.currentUsers = plan.currentUsers.add(1);
        
        // Award loyalty points for subscription
        _awardLoyaltyPoints(msg.sender, plan.monthlyFee.div(100));
        
        emit UserSubscribed(msg.sender, _planId, plan.subscriptionExpiry[msg.sender]);
    }

    // NEW FEATURE 12: Credit Lines
    function approveCreditLine(address _user, uint256 _creditLimit, uint256 _interestRate) external onlyOwner {
        require(_creditLimit > 0, "Invalid credit limit");
        
        CreditLine storage creditLine = creditLines[_user];
        creditLine.creditLimit = _creditLimit;
        creditLine.usedCredit = 0;
        creditLine.interestRate = _interestRate;
        creditLine.lastPaymentTime = block.timestamp;
        creditLine.minimumPayment = _creditLimit.div(12); // 1/12th monthly minimum
        creditLine.isActive = true;
        creditLine.creditScore = _calculateInitialCreditScore(_user);
        creditLine.paymentHistory = 100; // Start with perfect score
        
        if (creditLine.creditLimit == _creditLimit) {
            creditLineUsers.push(_user);
            totalCreditLines = totalCreditLines.add(1);
        }
        
        emit CreditLineApproved(_user, _creditLimit);
    }

    function drawFromCreditLine(uint256 _amount) external nonReentrant updateActivity {
        CreditLine storage creditLine = creditLines[msg.sender];
        require(creditLine.isActive, "Credit line not active");
        require(creditLine.usedCredit.add(_amount) <= creditLine.creditLimit, "Exceeds credit limit");
        require(availableLiquidity >= _amount, "Insufficient liquidity");
        
        creditLine.usedCredit = creditLine.usedCredit.add(_amount);
        availableLiquidity = availableLiquidity.sub(_amount);
        
        require(lendingToken.transfer(msg.sender, _amount), "Transfer failed");
        
        emit CreditUsed(msg.sender, _amount, creditLine.creditLimit.sub(creditLine.usedCredit));
    }

    // NEW FEATURE 13: Options Trading
    function createOption(
        uint256 _strikePrice,
        uint256 _expiryTime,
        uint256 _premium,
        bool _isCall,
        uint256 _underlyingAmount,
        address _underlyingToken
    ) external nonReentrant updateActivity {
        require(optionsEnabled, "Options disabled");
        require(_expiryTime > block.timestamp, "Invalid expiry");
        require(whitelistedTokens[_underlyingToken], "Token not supported");
        
        optionCounter = optionCounter.add(1);
        
        Option storage option = options[optionCounter];
        option.id = optionCounter;
        option.owner = msg.sender;
        option.strikePrice = _strikePrice;
        option.expiryTime = _expiryTime;
        option.premium = _premium;
        option.isCall = _isCall;
        option.isExercised = false;
        option.underlyingAmount = _underlyingAmount;
        option.underlyingToken = _underlyingToken;
        
        // Collect premium
        require(lendingToken.transferFrom(msg.sender, address(this), _premium), "Premium payment failed");
        
        emit OptionCreated(optionCounter, msg.sender, _strikePrice);
    }

    function exerciseOption(uint256 _optionId) external nonReentrant updateActivity {
        Option storage option = options[_optionId];
        require(!option.isExercised, "Already exercised");
        require(block.timestamp <= option.expiryTime, "Option expired");
        require(msg.sender != option.owner, "Cannot exercise own option");
        
        // Simplified exercise logic (would need oracle for real prices)
        uint256 currentPrice = _getTokenPrice(option.underlyingToken);
        uint256 profit = 0;
        
        if (option.isCall && currentPrice > option.strikePrice) {
            profit = currentPrice.sub(option.strikePrice).mul(option.underlyingAmount).div(10**18);
        } else if (!option.isCall && currentPrice < option.strikePrice) {
            profit = option.strikePrice.sub(currentPrice).mul(option.underlyingAmount).div(10**18);
        }
        
        require(profit > 0, "Option not profitable");
        
        option.isExercised = true;
        
        // Transfer profit
        require(lendingToken.transfer(msg.sender, profit), "Profit transfer failed");
        
        emit OptionExercised(_optionId, msg.sender, profit);
    }

    // NEW FEATURE 14: Token Auction System
    function createAuction(
        uint256 _amount,
        uint256 _startingPrice,
        uint256 _duration,
        address _tokenAddress
    ) external nonReentrant updateActivity {
        require(auctionEnabled, "Auctions disabled");
        require(whitelistedTokens[_tokenAddress] || _tokenAddress == address(lendingToken), "Token not supported");
        
        IERC20(_tokenAddress).transferFrom(msg.sender, address(this), _amount);
        
        auctionCounter = auctionCounter.add(1);
        
        Auction storage auction = auctions[auctionCounter];
        auction.id = auctionCounter;
        auction.seller = msg.sender;
        auction.amount = _amount;
        auction.startingPrice = _startingPrice;
        auction.currentBid = _startingPrice;
        auction.highestBidder = address(0);
        auction.endTime = block.timestamp.add(_duration);
        auction.isActive = true;
        auction.isCompleted = false;
        auction.tokenAddress = _tokenAddress;
        
        emit AuctionCreated(auctionCounter, msg.sender, _startingPrice);
    }

    function placeBid(uint256 _auctionId, uint256 _bidAmount) external nonReentrant updateActivity {
        Auction storage auction = auctions[_auctionId];
        require(auction.isActive, "Auction not active");
        require(block.timestamp < auction.endTime, "Auction ended");
        require(_bidAmount > auction.currentBid, "Bid too low");
        require(msg.sender != auction.seller, "Cannot bid on own auction");
        
        // Refund previous highest bidder
        if (auction.highestBidder != address(0)) {
            lendingToken.transfer(auction.highestBidder, auction.currentBid);
        }
        
        // Transfer new bid
        require(lendingToken.transferFrom(msg.sender, address(this), _bidAmount), "Bid transfer failed");
        
        auction.currentBid = _bidAmount;
        auction.highestBidder = msg.sender;
        
        emit BidPlaced(_auctionId, msg.sender, _bidAmount);
    }

    function finalizeAuction(uint256 _auctionId) external nonReentrant {
        Auction storage auction = auctions[_auctionId];
        require(auction.isActive, "Auction not active");
        require(block.timestamp >= auction.endTime, "Auction not ended");
        require(!auction.isCompleted, "Already completed");
        
        auction.isActive = false;
        auction.isCompleted = true;
        
        if (auction.highestBidder != address(0)) {
            // Transfer tokens to winner
            IERC20(auction.tokenAddress).transfer(auction.highestBidder, auction.amount);
            // Transfer payment to seller
            lendingToken.transfer(auction.seller, auction.currentBid);
            
            emit AuctionCompleted(_auctionId, auction.highestBidder, auction.currentBid);
        } else {
            // No bids, return tokens to seller
            IERC20(auction.tokenAddress).transfer(auction.seller, auction.amount);
        }
    }

    // NEW FEATURE 15: Escrow Services
    function createEscrow(
        address _seller,
        uint256 _amount,
        uint256 _releaseTime,
        address _arbitrator  
