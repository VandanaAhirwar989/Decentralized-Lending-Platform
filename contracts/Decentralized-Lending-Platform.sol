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
    
    bool public flashLoansEnabled = true;
    bool public borrowingEnabled = true;
    bool public depositsEnabled = true;
    bool public yieldFarmingEnabled = true;
    bool public governanceEnabled = true;
    bool public insuranceEnabled = true;
    bool public crossChainEnabled = false;
    bool public leverageEnabled = false; // New: leverage trading feature

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

    Insurance public insurance;
    LiquidationInfo public liquidationInfo;
    FlashLoanInfo public flashLoanInfo;
    NFTBoost public nftBoost;
    TreasuryInfo public treasury;
    uint256 public yieldPoolCounter;

    // Arrays for iteration
    address[] public lendersList;
    address[] public borrowersList;
    address[] public supportedCollaterals;
    address[] public vipMembersList;

    // New Events
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
        
        // Create default loan packages
        _createDefaultLoanPackages();
    }

    // NEW FEATURE 1: Loan Packages System
    function createLoanPackage(
        string memory _name,
        uint256 _minAmount,
        uint256 _maxAmount,
        uint256 _interestRate,
        uint256 _maxDuration,
        uint256 _collateralRatio
    ) external onlyOwner {
        loanPackageCounter = loanPackageCounter.add(1);
        
        LoanPackage storage package = loanPackages[loanPackageCounter];
        package.id = loanPackageCounter;
        package.name = _name;
        package.minAmount = _minAmount;
        package.maxAmount = _maxAmount;
        package.interestRate = _interestRate;
        package.maxDuration = _maxDuration;
        package.collateralRatio = _collateralRatio;
        package.isActive = true;
        
        emit LoanPackageCreated(loanPackageCounter, _name);
    }

    function borrowWithPackage(uint256 _packageId, uint256 _amount, uint256 _duration) external 
        nonReentrant whenNotPaused whenBorrowingEnabled notBlacklisted updateActivity {
        LoanPackage storage package = loanPackages[_packageId];
        require(package.isActive, "Package not active");
        require(_amount >= package.minAmount && _amount <= package.maxAmount, "Amount out of range");
        require(_duration <= package.maxDuration, "Duration too long");
        
        BorrowerInfo storage borrower = borrowers[msg.sender];
        borrower.maxLoanDuration = _duration;
        borrower.loanStartTime = block.timestamp;
        
        package.totalLoaned = package.totalLoaned.add(_amount);
        package.loanCount = package.loanCount.add(1);
        
        // Award loyalty points
        _awardLoyaltyPoints(msg.sender, _amount.div(1000)); // 1 point per 1000 tokens
        
        // Continue with standard borrowing logic...
        _executeBorrow(msg.sender, _amount, package.collateralRatio);
    }

    // NEW FEATURE 2: Leverage Trading
    function openLeveragePosition(uint256 _amount, uint256 _leverage) external 
        nonReentrant whenNotPaused notBlacklisted updateActivity {
        require(leverageEnabled, "Leverage trading disabled");
        require(_leverage >= 2 && _leverage <= 10, "Invalid leverage");
        require(leveragePositions[msg.sender] == 0, "Position already open");
        
        uint256 totalPosition = _amount.mul(_leverage);
        require(availableLiquidity >= totalPosition.sub(_amount), "Insufficient liquidity");
        
        // Transfer collateral
        require(lendingToken.transferFrom(msg.sender, address(this), _amount), "Transfer failed");
        
        // Update state
        leveragePositions[msg.sender] = totalPosition;
        availableLiquidity = availableLiquidity.sub(totalPosition.sub(_amount));
        
        emit LeveragePositionOpened(msg.sender, _amount, _leverage);
    }

    function closeLeveragePosition() external nonReentrant updateActivity {
        uint256 position = leveragePositions[msg.sender];
        require(position > 0, "No open position");
        
        // Calculate P&L and close position
        leveragePositions[msg.sender] = 0;
        
        // Return funds (simplified - in reality would need price oracle)
        require(lendingToken.transfer(msg.sender, position.div(2)), "Transfer failed");
    }

    // NEW FEATURE 3: Peer-to-Peer Lending
    function createP2PLoan(address _borrower, uint256 _amount, uint256 _interestRate, uint256 _duration) external 
        nonReentrant updateActivity {
        require(_borrower != msg.sender, "Cannot lend to yourself");
        require(!blacklistedUsers[_borrower], "Borrower is blacklisted");
        
        // Transfer tokens to contract
        require(lendingToken.transferFrom(msg.sender, address(this), _amount), "Transfer failed");
        
        p2pLending[msg.sender][_borrower] = _amount;
        
        emit P2PLoanCreated(msg.sender, _borrower, _amount);
    }

    // NEW FEATURE 4: Automated Compound Interest
    function enableAutoCompound() external updateActivity {
        lenders[msg.sender].autoCompoundEnabled = true;
    }

    function disableAutoCompound() external updateActivity {
        lenders[msg.sender].autoCompoundEnabled = false;
    }

    function executeAutoCompound(address _user) external {
        LenderInfo storage lender = lenders[_user];
        require(lender.autoCompoundEnabled, "Auto compound not enabled");
        require(block.timestamp >= lender.lastUpdateTime.add(COMPOUND_FREQUENCY), "Too early to compound");
        
        _updateLenderInterest(_user);
        
        uint256 interest = lender.accruedInterest;
        if (interest > 0) {
            lender.accruedInterest = 0;
            lender.depositedAmount = lender.depositedAmount.add(interest);
            lender.compoundCount = lender.compoundCount.add(1);
            
            emit AutoCompoundExecuted(_user, interest);
        }
    }

    // NEW FEATURE 5: Loyalty Program
    function _awardLoyaltyPoints(address _user, uint256 _points) internal {
        loyaltyPoints[_user] = loyaltyPoints[_user].add(_points);
        
        // Check for VIP status
        if (loyaltyPoints[_user] >= 10000 && !vipMembers[_user]) {
            vipMembers[_user] = true;
            vipMembersList.push(_user);
            emit VIPStatusGranted(_user);
        }
        
        emit LoyaltyPointsAwarded(_user, _points);
    }

    function redeemLoyaltyPoints(uint256 _points) external updateActivity {
        require(loyaltyPoints[msg.sender] >= _points, "Insufficient points");
        
        loyaltyPoints[msg.sender] = loyaltyPoints[msg.sender].sub(_points);
        
        // Convert points to tokens (1000 points = 1 token)
        uint256 tokenReward = _points.div(1000);
        if (tokenReward > 0) {
            require(lendingToken.transfer(msg.sender, tokenReward), "Transfer failed");
        }
    }

    // NEW FEATURE 6: Social Credit System
    function updateSocialScore(address _user, uint256 _newScore) external onlyOwner {
        socialScore[_user] = _newScore;
        emit SocialScoreUpdated(_user, _newScore);
    }

    function getSocialScore(address _user) external view returns (uint256) {
        return socialScore[_user];
    }

    // NEW FEATURE 7: Risk Assessment
    function calculateUserRiskScore(address _user) public view returns (uint256) {
        BorrowerInfo storage borrower = borrowers[_user];
        uint256 riskScore = 100; // Base score
        
        // Factor in loan history
        if (borrower.totalRepaid > 0) {
            riskScore = riskScore.sub(borrower.creditScore.div(10));
        }
        
        // Factor in social score
        if (socialScore[_user] > 0) {
            riskScore = riskScore.sub(socialScore[_user].div(20));
        }
        
        // Factor in activity
        uint256 daysSinceActivity = (block.timestamp - lastActivity[_user]) / 1 days;
        if (daysSinceActivity > 30) {
            riskScore = riskScore.add(daysSinceActivity.div(10));
        }
        
        return riskScore > 1000 ? 1000 : riskScore;
    }

    // NEW FEATURE 8: NFT Boost System
    function activateNFTBoost(uint256 _multiplier, uint256 _duration) external onlyOwner {
        require(_multiplier >= 100 && _multiplier <= 300, "Invalid multiplier");
        
        nftBoost.hasNFTBoost[msg.sender] = true;
        nftBoost.boostMultiplier[msg.sender] = _multiplier;
        nftBoost.boostExpiry[msg.sender] = block.timestamp.add(_duration);
        
        emit NFTBoostActivated(msg.sender, _multiplier, nftBoost.boostExpiry[msg.sender]);
    }

    // NEW FEATURE 9: Treasury Management
    function distributeTreasuryRewards() external {
        require(block.timestamp >= treasury.lastDistributionTime.add(treasury.distributionInterval), "Too early");
        require(treasury.totalTreasuryShares > 0, "No treasury shares");
        
        uint256 distributionAmount = treasury.totalTreasuryFees.div(10); // Distribute 10% of treasury
        treasury.totalTreasuryFees = treasury.totalTreasuryFees.sub(distributionAmount);
        treasury.lastDistributionTime = block.timestamp;
        
        // Distribute to VIP members (simplified)
        uint256 perMemberReward = distributionAmount.div(vipMembersList.length);
        for (uint256 i = 0; i < vipMembersList.length; i++) {
            lendingToken.transfer(vipMembersList[i], perMemberReward);
        }
        
        emit TreasuryDistribution(distributionAmount, vipMembersList.length);
    }

    // NEW FEATURE 10: Advanced Liquidation Protection
    function enableLiquidationProtection() external payable onlyVIP {
        require(msg.value >= 0.1 ether, "Insufficient payment");
        liquidationInfo.isProtectedFromLiquidation[msg.sender] = true;
        liquidationInfo.liquidationCooldown[msg.sender] = block.timestamp.add(30 days);
    }

    // Enhanced deposit function with referrals and tier system
    function deposit(uint256 _amount, address _referrer) external nonReentrant whenNotPaused 
        whenDepositsEnabled notBlacklisted updateActivity {
        require(_amount > 0, "Amount must be greater than 0");
        
        // Check deposit limits
        if (depositLimits[msg.sender] > 0) {
            require(_amount <= depositLimits[msg.sender], "Exceeds deposit limit");
        }
        
        require(lendingToken.transferFrom(msg.sender, address(this), _amount), "Transfer failed");

        LenderInfo storage lender = lenders[msg.sender];
        
        // Handle referrals
        if (_referrer != address(0) && _referrer != msg.sender && referrers[msg.sender] == address(0)) {
            referrers[msg.sender] = _referrer;
            uint256 referralReward = _amount.mul(1).div(100); // 1% referral reward
            referralRewards[_referrer] = referralRewards[_referrer].add(referralReward);
            _awardLoyaltyPoints(_referrer, referralReward.div(100));
            emit ReferralReward(_referrer, msg.sender, referralReward);
        }
        
        // Add to lenders list if new lender
        if (lender.depositedAmount == 0) {
            lendersList.push(msg.sender);
            lender.stakingTime = block.timestamp;
        }

        _updateLenderInterest(msg.sender);
        _updateLenderRewards(msg.sender);
        _updateTier(msg.sender);

        lender.depositedAmount = lender.depositedAmount.add(_amount);
        lender.lastUpdateTime = block.timestamp;

        totalDeposits = totalDeposits.add(_amount);
        availableLiquidity = availableLiquidity.add(_amount);

        // Update voting power
        votingPower[msg.sender] = votingPower[msg.sender].add(_amount);
        
        // Award loyalty points
        _awardLoyaltyPoints(msg.sender, _amount.div(1000));

        _updateInterestRates();

        emit Deposit(msg.sender, _amount);
    }

    // Helper function for borrowing
    function _executeBorrow(address _user, uint256 _amount, uint256 _collateralRatio) internal {
        // Implementation details for borrowing logic
        BorrowerInfo storage borrower = borrowers[_user];
        borrower.borrowedAmount = borrower.borrowedAmount.add(_amount);
        borrower.lastUpdateTime = block.timestamp;
        
        totalBorrows = totalBorrows.add(_amount);
        availableLiquidity = availableLiquidity.sub(_amount);
        
        _updateInterestRates();
        
        require(lendingToken.transfer(_user, _amount), "Transfer failed");
    }

    // Create default loan packages
    function _createDefaultLoanPackages() internal {
        // Standard Package
        loanPackageCounter = loanPackageCounter.add(1);
        LoanPackage storage standard = loanPackages[loanPackageCounter];
        standard.id = loanPackageCounter;
        standard.name = "Standard";
        standard.minAmount = 1000 * 10**18;
        standard.maxAmount = 50000 * 10**18;
        standard.interestRate = 8;
        standard.maxDuration = 180 days;
        standard.collateralRatio = 150;
        standard.isActive = true;
        
        // Premium Package
        loanPackageCounter = loanPackageCounter.add(1);
        LoanPackage storage premium = loanPackages[loanPackageCounter];
        premium.id = loanPackageCounter;
        premium.name = "Premium";
        premium.minAmount = 50000 * 10**18;
        premium.maxAmount = 500000 * 10**18;
        premium.interestRate = 6;
        premium.maxDuration = 365 days;
        premium.collateralRatio = 130;
        premium.isActive = true;
    }

    // Multi-collateral borrow function (keeping original)
    function borrowWithMultiCollateral(
        uint256 _borrowAmount, 
        address[] memory _collateralTokens,
        uint256[] memory _collateralAmounts
    ) external nonReentrant whenNotPaused whenBorrowingEnabled notBlacklisted updateActivity {
        require(_borrowAmount > 0, "Borrow amount must be greater than 0");
        require(_collateralTokens.length == _collateralAmounts.length, "Array length mismatch");
        require(availableLiquidity >= _borrowAmount, "Insufficient liquidity");

        uint256 totalCollateralValue = 0;
        
        // Transfer and validate collaterals
        for (uint256 i = 0; i < _collateralTokens.length; i++) {
            require(whitelistedTokens[_collateralTokens[i]], "Token not whitelisted");
            require(_collateralAmounts[i] > 0, "Collateral amount must be greater than 0");
            
            IERC20(_collateralTokens[i]).transferFrom(msg.sender, address(this), _collateralAmounts[i]);
            
            uint256 collateralFactor = collateralFactors[_collateralTokens[i]];
            totalCollateralValue = totalCollateralValue.add(
                _collateralAmounts[i].mul(100).div(collateralFactor)
            );
            
            userCollaterals[msg.sender][_collateralTokens[i]] = 
                userCollaterals[msg.sender][_collateralTokens[i]].add(_collateralAmounts[i]);
        }

        require(totalCollateralValue >= _borrowAmount, "Insufficient collateral");

        BorrowerInfo storage borrower = borrowers[msg.sender];
        
        if (borrower.borrowedAmount == 0) {
            borrowersList.push(msg.sender);
        }

        _updateBorrowerInterest(msg.sender);
        _updateCreditScore(msg.sender);

        borrower.borrowedAmount = borrower.borrowedAmount.add(_borrowAmount);
        borrower.lastUpdateTime = block.timestamp;

        totalBorrows = totalBorrows.add(_borrowAmount);
        availableLiquidity = availableLiquidity.sub(_borrowAmount);

        // Award loyalty points
        _awardLoyaltyPoints(msg.sender, _borrowAmount.div(2000)); // Less points for borrowing

        _updateInterestRates();

        require(lendingToken.transfer(msg.sender, _borrowAmount), "Borrow transfer failed");

        emit Borrow(msg.sender, _borrowAmount, totalCollateralValue);
       
       

   
    
    
    

   
    
           
        
                

       
    
        
       
   

    
            
    
        
        
   
       
        
          
        
       
    
        
