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
    }

    struct BorrowerInfo {
        uint256 borrowedAmount;
        uint256 collateralAmount;
        uint256 lastUpdateTime;
        uint256 accruedInterest;
        uint256 liquidationThreshold;
        uint256 creditScore;
        bool isWhitelisted;
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
    }

    struct YieldFarmingPool {
        IERC20 stakingToken;
        uint256 totalStaked;
        uint256 rewardRate;
        uint256 lastUpdateTime;
        uint256 rewardPerTokenStored;
        mapping(address => uint256) userStaked;
        mapping(address => uint256) userRewardPerTokenPaid;
        mapping(address => uint256) rewards;
    }

    struct Insurance {
        uint256 totalCoverage;
        uint256 premiumRate;
        mapping(address => uint256) userCoverage;
        mapping(address => uint256) premiumsPaid;
        mapping(address => bool) isCovered;
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
    
    bool public flashLoansEnabled = true;
    bool public borrowingEnabled = true;
    bool public depositsEnabled = true;
    bool public yieldFarmingEnabled = true;
    bool public governanceEnabled = true;
    bool public insuranceEnabled = true;

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
    
    // Multi-collateral support
    mapping(address => uint256) public collateralFactors;
    mapping(address => mapping(address => uint256)) public userCollaterals;

    Insurance public insurance;
    uint256 public yieldPoolCounter;

    // Arrays for iteration
    address[] public lendersList;
    address[] public borrowersList;
    address[] public supportedCollaterals;

    // Events
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
    }

    // Enhanced deposit function with referrals and tier system
    function deposit(uint256 _amount, address _referrer) external nonReentrant whenNotPaused whenDepositsEnabled {
        require(_amount > 0, "Amount must be greater than 0");
        require(lendingToken.transferFrom(msg.sender, address(this), _amount), "Transfer failed");

        LenderInfo storage lender = lenders[msg.sender];
        
        // Handle referrals
        if (_referrer != address(0) && _referrer != msg.sender && referrers[msg.sender] == address(0)) {
            referrers[msg.sender] = _referrer;
            uint256 referralReward = _amount.mul(1).div(100); // 1% referral reward
            referralRewards[_referrer] = referralRewards[_referrer].add(referralReward);
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

        _updateInterestRates();

        emit Deposit(msg.sender, _amount);
    }

    // Multi-collateral borrow function
    function borrowWithMultiCollateral(
        uint256 _borrowAmount, 
        address[] memory _collateralTokens,
        uint256[] memory _collateralAmounts
    ) external nonReentrant whenNotPaused whenBorrowingEnabled {
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

        _updateInterestRates();

        require(lendingToken.transfer(msg.sender, _borrowAmount), "Borrow transfer failed");

        emit Borrow(msg.sender, _borrowAmount, totalCollateralValue);
    }

    // Governance proposal creation
    function createProposal(string memory _description) external onlyGovernance {
        proposalCounter = proposalCounter.add(1);
        GovernanceProposal storage proposal = proposals[proposalCounter];
        
        proposal.id = proposalCounter;
        proposal.description = _description;
        proposal.endTime = block.timestamp.add(votingDuration);
        proposal.proposer = msg.sender;

        emit ProposalCreated(proposalCounter, msg.sender, _description);
    }

    // Voting function
    function vote(uint256 _proposalId, bool _support) external {
        GovernanceProposal storage proposal = proposals[_proposalId];
        require(block.timestamp <= proposal.endTime, "Voting period ended");
        require(!proposal.hasVoted[msg.sender], "Already voted");
        require(votingPower[msg.sender] > 0, "No voting power");

        proposal.hasVoted[msg.sender] = true;
        uint256 votes = votingPower[msg.sender];

        if (_support) {
            proposal.votesFor = proposal.votesFor.add(votes);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(votes);
        }

        emit Voted(_proposalId, msg.sender, _support, votes);
    }

    // Yield farming functions
    function createYieldFarmingPool(
        address _stakingToken,
        uint256 _rewardRate
    ) external onlyOwner {
        yieldPoolCounter = yieldPoolCounter.add(1);
        YieldFarmingPool storage pool = yieldPools[yieldPoolCounter];
        
        pool.stakingToken = IERC20(_stakingToken);
        pool.rewardRate = _rewardRate;
        pool.lastUpdateTime = block.timestamp;

        emit YieldFarmingPoolCreated(yieldPoolCounter, _stakingToken);
    }

    function stakeInYieldPool(uint256 _poolId, uint256 _amount) external nonReentrant {
        require(yieldFarmingEnabled, "Yield farming disabled");
        YieldFarmingPool storage pool = yieldPools[_poolId];
        require(address(pool.stakingToken) != address(0), "Pool doesn't exist");

        _updateYieldPoolRewards(_poolId, msg.sender);

        pool.stakingToken.transferFrom(msg.sender, address(this), _amount);
        pool.userStaked[msg.sender] = pool.userStaked[msg.sender].add(_amount);
        pool.totalStaked = pool.totalStaked.add(_amount);

        emit Staked(_poolId, msg.sender, _amount);
    }

    function unstakeFromYieldPool(uint256 _poolId, uint256 _amount) external nonReentrant {
        YieldFarmingPool storage pool = yieldPools[_poolId];
        require(pool.userStaked[msg.sender] >= _amount, "Insufficient staked amount");

        _updateYieldPoolRewards(_poolId, msg.sender);

        pool.userStaked[msg.sender] = pool.userStaked[msg.sender].sub(_amount);
        pool.totalStaked = pool.totalStaked.sub(_amount);

        pool.stakingToken.transfer(msg.sender, _amount);

        emit Unstaked(_poolId, msg.sender, _amount);
    }

    function claimYieldRewards(uint256 _poolId) external nonReentrant {
        YieldFarmingPool storage pool = yieldPools[_poolId];
        _updateYieldPoolRewards(_poolId, msg.sender);

        uint256 reward = pool.rewards[msg.sender];
        require(reward > 0, "No rewards available");

        pool.rewards[msg.sender] = 0;
        lendingToken.transfer(msg.sender, reward);

        emit RewardsClaimed(msg.sender, reward);
    }

    // Insurance functions
    function buyInsurance(uint256 _coverageAmount) external payable {
        require(insuranceEnabled, "Insurance disabled");
        require(_coverageAmount > 0, "Coverage amount must be greater than 0");

        uint256 premium = _coverageAmount.mul(insurance.premiumRate).div(10000);
        require(msg.value >= premium, "Insufficient premium");

        insurance.userCoverage[msg.sender] = insurance.userCoverage[msg.sender].add(_coverageAmount);
        insurance.premiumsPaid[msg.sender] = insurance.premiumsPaid[msg.sender].add(premium);
        insurance.isCovered[msg.sender] = true;
        insurance.totalCoverage = insurance.totalCoverage.add(_coverageAmount);
        insuranceFund = insuranceFund.add(premium);
    }

    function claimInsurance(uint256 _claimAmount) external {
        require(insurance.isCovered[msg.sender], "Not covered");
        require(_claimAmount <= insurance.userCoverage[msg.sender], "Claim exceeds coverage");
        require(_claimAmount <= insuranceFund, "Insufficient insurance fund");

        insurance.userCoverage[msg.sender] = insurance.userCoverage[msg.sender].sub(_claimAmount);
        insuranceFund = insuranceFund.sub(_claimAmount);

        payable(msg.sender).transfer(_claimAmount);

        emit InsuranceClaimed(msg.sender, _claimAmount);
    }

    // Credit scoring system
    function _updateCreditScore(address _user) internal {
        BorrowerInfo storage borrower = borrowers[_user];
        uint256 timeBorrowing = block.timestamp.sub(borrower.lastUpdateTime);
        
        if (timeBorrowing > 30 days && borrower.borrowedAmount > 0) {
            borrower.creditScore = borrower.creditScore.add(10);
        }
        
        // Max credit score of 1000
        if (borrower.creditScore > 1000) {
            borrower.creditScore = 1000;
        }
    }

    // Tier system for lenders
    function _updateTier(address _user) internal {
        LenderInfo storage lender = lenders[_user];
        uint256 stakingDuration = block.timestamp.sub(lender.stakingTime);
        
        uint8 newTier = 0;
        if (stakingDuration >= TIER_THRESHOLD.mul(12)) { // 1 year
            newTier = 3;
        } else if (stakingDuration >= TIER_THRESHOLD.mul(6)) { // 6 months
            newTier = 2;
        } else if (stakingDuration >= TIER_THRESHOLD) { // 1 month
            newTier = 1;
        }
        
        if (newTier > lender.tierLevel) {
            lender.tierLevel = newTier;
            emit TierUpgraded(_user, newTier);
        }
    }

    // Add new collateral token
    function addCollateralToken(address _token, uint256 _factor) external onlyOwner {
        require(_token != address(0), "Invalid token address");
        require(_factor >= 100, "Factor must be at least 100%");
        
        collateralFactors[_token] = _factor;
        whitelistedTokens[_token] = true;
        supportedCollaterals.push(_token);
        
        emit CollateralAdded(_token, _factor);
    }

    // Emergency withdraw (only for lenders, with penalty)
    function emergencyWithdraw() external nonReentrant {
        LenderInfo storage lender = lenders[msg.sender];
        require(lender.depositedAmount > 0, "No deposits found");

        uint256 withdrawAmount = lender.depositedAmount.mul(95).div(100); // 5% penalty
        uint256 penalty = lender.depositedAmount.sub(withdrawAmount);

        lender.depositedAmount = 0;
        lender.accruedInterest = 0;
        lender.rewardTokens = 0;

        totalDeposits = totalDeposits.sub(withdrawAmount.add(penalty));
        availableLiquidity = availableLiquidity.sub(withdrawAmount);
        totalReserves = totalReserves.add(penalty);

        _updateInterestRates();

        require(lendingToken.transfer(msg.sender, withdrawAmount), "Transfer failed");

        emit EmergencyWithdraw(msg.sender, withdrawAmount);
    }

    // Auto-compound function
    function autoCompound() external nonReentrant {
        LenderInfo storage lender = lenders[msg.sender];
        _updateLenderInterest(msg.sender);

        uint256 interest = lender.accruedInterest;
        require(interest > 0, "No interest to compound");

        lender.accruedInterest = 0;
        lender.depositedAmount = lender.depositedAmount.add(interest);

        emit Deposit(msg.sender, interest);
    }

    // Helper functions for interest calculation
    function _updateLenderInterest(address _user) internal {
        LenderInfo storage lender = lenders[_user];
        if (lender.depositedAmount > 0) {
            uint256 timeElapsed = block.timestamp.sub(lender.lastUpdateTime);
            uint256 currentRate = getCurrentLendingRate();
            
            // Apply tier bonus
            uint256 tierBonus = lender.tierLevel.mul(25); // 0.25% per tier
            uint256 adjustedRate = currentRate.add(tierBonus);
            
            uint256 interest = lender.depositedAmount.mul(adjustedRate).mul(timeElapsed).div(100).div(SECONDS_PER_YEAR);
            lender.accruedInterest = lender.accruedInterest.add(interest);
            lender.lastUpdateTime = block.timestamp;
        }
    }

    function _updateLenderRewards(address _user) internal {
        LenderInfo storage lender = lenders[_user];
        if (lender.depositedAmount > 0) {
            uint256 timeElapsed = block.timestamp.sub(lender.lastUpdateTime);
            uint256 rewards = timeElapsed.mul(rewardTokensPerSecond).mul(lender.depositedAmount).div(totalDeposits);
            lender.rewardTokens = lender.rewardTokens.add(rewards);
        }
    }

    function _updateBorrowerInterest(address _user) internal {
        BorrowerInfo storage borrower = borrowers[_user];
        if (borrower.borrowedAmount > 0) {
            uint256 timeElapsed = block.timestamp.sub(borrower.lastUpdateTime);
            uint256 currentRate = getCurrentBorrowingRate();
            
            // Apply credit score discount
            uint256 discount = borrower.creditScore.div(100); // Max 10% discount
            uint256 adjustedRate = currentRate > discount ? currentRate.sub(discount) : currentRate;
            
            uint256 interest = borrower.borrowedAmount.mul(adjustedRate).mul(timeElapsed).div(100).div(SECONDS_PER_YEAR);
            borrower.accruedInterest = borrower.accruedInterest.add(interest);
            borrower.lastUpdateTime = block.timestamp;
        }
    }

    function _updateYieldPoolRewards(uint256 _poolId, address _user) internal {
        YieldFarmingPool storage pool = yieldPools[_poolId];
        
        if (pool.totalStaked > 0) {
            uint256 timeElapsed = block.timestamp.sub(pool.lastUpdateTime);
            uint256 rewardPerToken = timeElapsed.mul(pool.rewardRate).mul(1e18).div(pool.totalStaked);
            pool.rewardPerTokenStored = pool.rewardPerTokenStored.add(rewardPerToken);
        }

        if (pool.userStaked[_user] > 0) {
            uint256 earned = pool.userStaked[_user]
                .mul(pool.rewardPerTokenStored.sub(pool.userRewardPerTokenPaid[_user]))
                .div(1e18);
            pool.rewards[_user] = pool.rewards[_user].add(earned);
        }

        pool.userRewardPerTokenPaid[_user] = pool.rewardPerTokenStored;
        pool.lastUpdateTime = block.timestamp;
    }

    function _updateInterestRates() internal {
        uint256 utilizationRate = totalDeposits > 0 ? totalBorrows.mul(100).div(totalDeposits) : 0;
        
        PoolInfo memory pool;
        pool.utilizationRate = utilizationRate;
        
        if (utilizationRate <= OPTIMAL_UTILIZATION) {
            pool.currentLendingRate = BASE_LENDING_RATE.add(utilizationRate.mul(RATE_MULTIPLIER).div(OPTIMAL_UTILIZATION));
            pool.currentBorrowingRate = BASE_BORROWING_RATE.add(utilizationRate.mul(RATE_MULTIPLIER).div(OPTIMAL_UTILIZATION));
        } else {
            uint256 excessUtilization = utilizationRate.sub(OPTIMAL_UTILIZATION);
            pool.currentLendingRate = BASE_LENDING_RATE.add(RATE_MULTIPLIER).add(excessUtilization.mul(RATE_MULTIPLIER).div(100 - OPTIMAL_UTILIZATION));
            pool.currentBorrowingRate = BASE_BORROWING_RATE.add(RATE_MULTIPLIER).add(excessUtilization.mul(RATE_MULTIPLIER).div(100 - OPTIMAL_UTILIZATION));
        }

        emit InterestRatesUpdated(pool.currentLendingRate, pool.currentBorrowingRate);
    }

    // View functions
    function getCurrentLendingRate() public view returns (uint256) {
        uint256 utilizationRate = totalDeposits > 0 ? totalBorrows.mul(100).div(totalDeposits) : 0;
        
        if (utilizationRate <= OPTIMAL_UTILIZATION) {
            return BASE_LENDING_RATE.add(utilizationRate.mul(RATE_MULTIPLIER).div(OPTIMAL_UTILIZATION));
        } else {
            uint256 excessUtilization = utilizationRate.sub(OPTIMAL_UTILIZATION);
            return BASE_LENDING_RATE.add(RATE_MULTIPLIER).add(excessUtilization.mul(RATE_MULTIPLIER).div(100 - OPTIMAL_UTILIZATION));
        }
    }

    function getCurrentBorrowingRate() public view returns (uint256) {
        uint256 utilizationRate = totalDeposits > 0 ? totalBorrows.mul(100).div(totalDeposits) : 0;
        
        if (utilizationRate <= OPTIMAL_UTILIZATION) {
            return BASE_BORROWING_RATE.add(utilizationRate.mul(RATE_MULTIPLIER).div(OPTIMAL_UTILIZATION));
        } else {
            uint256 excessUtilization = utilizationRate.sub(OPTIMAL_UTILIZATION);
            return BASE_BORROWING_RATE.add(RATE_MULTIPLIER).add(excessUtilization.mul(RATE_MULTIPLIER).div(100 - OPTIMAL_UTILIZATION));
        }
    }

    function getUserHealth(address _user) external view returns (uint256) {
        BorrowerInfo storage borrower = borrowers[_user];
        if (borrower.borrowedAmount == 0) return 0;
        
        uint256 totalCollateralValue = 0;
        for (uint256 i = 0; i < supportedCollaterals.length; i++) {
            address token = supportedCollaterals[i];
            uint256 amount = userCollaterals[_user][token];
            if (amount > 0) {
                totalCollateralValue = totalCollateralValue.add(
                    amount.mul(100).div(collateralFactors[token])
                );
            }
        }
        
        return totalCollateralValue.mul(100).div(borrower.borrowedAmount.add(borrower.accruedInterest));
    }

    function getPoolInfo() external view returns (PoolInfo memory) {
        PoolInfo memory pool;
        pool.totalSupply = totalDeposits;
        pool.totalBorrows = totalBorrows;
        pool.utilizationRate = totalDeposits > 0 ? totalBorrows.mul(100).div(totalDeposits) : 0;
        pool.currentLendingRate = getCurrentLendingRate();
        pool.currentBorrowingRate = getCurrentBorrowingRate();
        pool.lastUpdateTime = block.timestamp;
        return pool;
    }

    // Admin functions
    function setFlashLoanFee(uint256 _fee) external onlyOwner {
        require(_fee <= 100, "Fee too high"); // Max 1%
        flashLoanFee = _fee;
    }

    function toggleFeature(string memory _feature, bool _enabled) external onlyOwner {
        bytes32 featureHash = keccak256(abi.encodePacked(_feature));
        
        if (featureHash == keccak256("flashLoans")) {
            flashLoansEnabled = _enabled;
        } else if (featureHash == keccak256("borrowing")) {
            borrowingEnabled = _enabled;
        } else if (featureHash == keccak256("deposits")) {
            depositsEnabled = _enabled;
        } else if (featureHash == keccak256("yieldFarming")) {
            yieldFarmingEnabled = _enabled;
        } else if (featureHash == keccak256("governance")) {
            governanceEnabled = _enabled;
        } else if (featureHash == keccak256("insurance")) {
            insuranceEnabled = _enabled;
        }
    }

    function withdrawReserves(uint256 _amount) external onlyOwner {
        require(_amount <= totalReserves, "Insufficient reserves");
        totalReserves = totalReserves.sub(_amount);
        require(lendingToken.transfer(owner(), _amount), "Transfer failed");
        emit ReservesWithdrawn(_amount);
    }

    // Placeholder for flash loan receiver interface
    function flashLoan(uint256 _amount, bytes calldata _data) external nonReentrant whenNotPause
        

    
       
       
            
       

       
            

        
           
        
        
