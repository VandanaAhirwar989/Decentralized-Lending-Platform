// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title Enhanced Decentralized Lending Platform
 * @dev A comprehensive lending platform with advanced features for DeFi
 */
contract Project is ReentrancyGuard, Ownable, Pausable {
    // Structs
    struct LenderInfo {
        uint256 depositedAmount;
        uint256 lastUpdateTime;
        uint256 accruedInterest;
        uint256 rewardTokens;
    }

    struct BorrowerInfo {
        uint256 borrowedAmount;
        uint256 collateralAmount;
        uint256 lastUpdateTime;
        uint256 accruedInterest;
        uint256 liquidationThreshold;
    }

    struct PoolInfo {
        uint256 totalSupply;
        uint256 totalBorrows;
        uint256 reserveFactor;
        uint256 utilizationRate;
        uint256 currentLendingRate;
        uint256 currentBorrowingRate;
    }

    // Token addresses (replace with real ones before deployment)
    address constant LENDING_TOKEN_ADDRESS = 0x0000000000000000000000000000000000000001;
    address constant COLLATERAL_TOKEN_ADDRESS = 0x0000000000000000000000000000000000000002;

    // Tokens
    IERC20 public lendingToken;
    IERC20 public collateralToken;

    // Enhanced Constants
    uint256 public constant BASE_LENDING_RATE = 2; // 2% base rate
    uint256 public constant BASE_BORROWING_RATE = 5; // 5% base rate
    uint256 public constant RATE_MULTIPLIER = 20; // Rate increases with utilization
    uint256 public constant OPTIMAL_UTILIZATION = 80; // 80% optimal utilization
    uint256 public constant COLLATERAL_RATIO = 150;
    uint256 public constant LIQUIDATION_THRESHOLD = 120; // 120% liquidation threshold
    uint256 public constant LIQUIDATION_PENALTY = 10; // 10% liquidation penalty
    uint256 public constant RESERVE_FACTOR = 10; // 10% goes to reserves
    uint256 public constant SECONDS_PER_YEAR = 365 days;
    uint256 public constant MAX_BORROW_LIMIT = 1000000 * 10**18; // 1M token limit per user

    // State variables
    uint256 public totalDeposits;
    uint256 public totalBorrows;
    uint256 public availableLiquidity;
    uint256 public totalReserves;
    uint256 public flashLoanFee = 9; // 0.09% flash loan fee
    uint256 public rewardTokensPerSecond = 1 * 10**15; // Reward rate
    
    bool public flashLoansEnabled = true;
    bool public borrowingEnabled = true;
    bool public depositsEnabled = true;

    // Mappings
    mapping(address => LenderInfo) public lenders;
    mapping(address => BorrowerInfo) public borrowers;
    mapping(address => bool) public authorizedLiquidators;
    mapping(address => uint256) public userBorrowLimits;

    // Arrays for iteration
    address[] public lendersList;
    address[] public borrowersList;

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

    constructor() Ownable(msg.sender) {
        lendingToken = IERC20(LENDING_TOKEN_ADDRESS);
        collateralToken = IERC20(COLLATERAL_TOKEN_ADDRESS);
        authorizedLiquidators[msg.sender] = true;
    }

    // Enhanced deposit function with rewards
    function deposit(uint256 _amount) external nonReentrant whenNotPaused whenDepositsEnabled {
        require(_amount > 0, "Amount must be greater than 0");
        require(lendingToken.transferFrom(msg.sender, address(this), _amount), "Transfer failed");

        LenderInfo storage lender = lenders[msg.sender];
        
        // Add to lenders list if new lender
        if (lender.depositedAmount == 0) {
            lendersList.push(msg.sender);
        }

        _updateLenderInterest(msg.sender);
        _updateLenderRewards(msg.sender);

        lender.depositedAmount += _amount;
        lender.lastUpdateTime = block.timestamp;

        totalDeposits += _amount;
        availableLiquidity += _amount;

        _updateInterestRates();

        emit Deposit(msg.sender, _amount);
    }

    // Enhanced withdraw function
    function withdraw(uint256 _amount) external nonReentrant whenNotPaused {
        LenderInfo storage lender = lenders[msg.sender];
        require(lender.depositedAmount > 0, "No deposits found");

        _updateLenderInterest(msg.sender);
        _updateLenderRewards(msg.sender);

        uint256 totalBalance = lender.depositedAmount + lender.accruedInterest;
        require(_amount <= totalBalance, "Insufficient balance");
        require(_amount <= availableLiquidity, "Insufficient liquidity in pool");

        uint256 principalWithdraw;
        uint256 interestWithdraw;

        if (_amount <= lender.accruedInterest) {
            interestWithdraw = _amount;
            lender.accruedInterest -= _amount;
        } else {
            interestWithdraw = lender.accruedInterest;
            principalWithdraw = _amount - lender.accruedInterest;
            lender.accruedInterest = 0;
            lender.depositedAmount -= principalWithdraw;
        }

        totalDeposits -= principalWithdraw;
        availableLiquidity -= _amount;

        _updateInterestRates();

        require(lendingToken.transfer(msg.sender, _amount), "Transfer failed");

        emit Withdraw(msg.sender, _amount, interestWithdraw);
    }

    // Enhanced borrow function with dynamic rates
    function borrow(uint256 _borrowAmount, uint256 _collateralAmount) external nonReentrant whenNotPaused whenBorrowingEnabled {
        require(_borrowAmount > 0, "Borrow amount must be greater than 0");
        require(_collateralAmount > 0, "Collateral amount must be greater than 0");
        require(availableLiquidity >= _borrowAmount, "Insufficient liquidity");

        // Check borrow limits
        uint256 userLimit = userBorrowLimits[msg.sender];
        if (userLimit == 0) userLimit = MAX_BORROW_LIMIT;
        require(_borrowAmount <= userLimit, "Exceeds borrow limit");

        require(_collateralAmount * 100 >= _borrowAmount * COLLATERAL_RATIO, "Insufficient collateral");

        require(collateralToken.transferFrom(msg.sender, address(this), _collateralAmount), "Collateral transfer failed");

        BorrowerInfo storage borrower = borrowers[msg.sender];
        
        // Add to borrowers list if new borrower
        if (borrower.borrowedAmount == 0) {
            borrowersList.push(msg.sender);
        }

        _updateBorrowerInterest(msg.sender);

        borrower.borrowedAmount += _borrowAmount;
        borrower.collateralAmount += _collateralAmount;
        borrower.lastUpdateTime = block.timestamp;
        borrower.liquidationThreshold = LIQUIDATION_THRESHOLD;

        totalBorrows += _borrowAmount;
        availableLiquidity -= _borrowAmount;

        _updateInterestRates();

        require(lendingToken.transfer(msg.sender, _borrowAmount), "Borrow transfer failed");

        emit Borrow(msg.sender, _borrowAmount, _collateralAmount);
    }

    // Enhanced repay function
    function repay(uint256 _repayAmount) external nonReentrant whenNotPaused {
        BorrowerInfo storage borrower = borrowers[msg.sender];
        require(borrower.borrowedAmount > 0, "No outstanding loan");

        _updateBorrowerInterest(msg.sender);

        uint256 totalOwed = borrower.borrowedAmount + borrower.accruedInterest;
        require(_repayAmount <= totalOwed, "Repay amount exceeds debt");

        require(lendingToken.transferFrom(msg.sender, address(this), _repayAmount), "Repay transfer failed");

        uint256 principalRepaid;
        uint256 interestRepaid;

        if (_repayAmount <= borrower.accruedInterest) {
            interestRepaid = _repayAmount;
            borrower.accruedInterest -= _repayAmount;
        } else {
            interestRepaid = borrower.accruedInterest;
            principalRepaid = _repayAmount - borrower.accruedInterest;
            borrower.accruedInterest = 0;
            borrower.borrowedAmount -= principalRepaid;
        }

        // Calculate reserves from interest
        uint256 reserveAmount = (interestRepaid * RESERVE_FACTOR) / 100;
        totalReserves += reserveAmount;

        uint256 collateralToReturn = 0;
        if (principalRepaid > 0 && borrower.borrowedAmount == 0) {
            collateralToReturn = borrower.collateralAmount;
            borrower.collateralAmount = 0;
        } else if (principalRepaid > 0) {
            collateralToReturn = (borrower.collateralAmount * principalRepaid) / (borrower.borrowedAmount + principalRepaid);
            borrower.collateralAmount -= collateralToReturn;
        }

        totalBorrows -= principalRepaid;
        availableLiquidity += _repayAmount - reserveAmount;

        _updateInterestRates();

        if (collateralToReturn > 0) {
            require(collateralToken.transfer(msg.sender, collateralToReturn), "Collateral return failed");
        }

        emit Repay(msg.sender, _repayAmount, interestRepaid);
    }

    // Liquidation function
    function liquidate(address _borrower) external nonReentrant whenNotPaused onlyAuthorizedLiquidator {
        BorrowerInfo storage borrower = borrowers[_borrower];
        require(borrower.borrowedAmount > 0, "No outstanding loan");

        _updateBorrowerInterest(_borrower);

        uint256 totalDebt = borrower.borrowedAmount + borrower.accruedInterest;
        uint256 collateralValue = borrower.collateralAmount; // Assuming 1:1 for simplicity
        
        // Check if position is undercollateralized
        require(collateralValue * 100 < totalDebt * borrower.liquidationThreshold, "Position is healthy");

        // Calculate liquidation amounts
        uint256 maxLiquidation = totalDebt / 2; // Can liquidate up to 50% of debt
        uint256 collateralToSeize = (maxLiquidation * borrower.liquidationThreshold * (100 + LIQUIDATION_PENALTY)) / 10000;
        
        if (collateralToSeize > borrower.collateralAmount) {
            collateralToSeize = borrower.collateralAmount;
            maxLiquidation = (borrower.collateralAmount * 10000) / (borrower.liquidationThreshold * (100 + LIQUIDATION_PENALTY));
        }

        require(lendingToken.transferFrom(msg.sender, address(this), maxLiquidation), "Liquidation payment failed");

        // Update borrower's position
        borrower.borrowedAmount -= maxLiquidation;
        borrower.collateralAmount -= collateralToSeize;
        totalBorrows -= maxLiquidation;
        availableLiquidity += maxLiquidation;

        _updateInterestRates();

        // Transfer seized collateral to liquidator
        require(collateralToken.transfer(msg.sender, collateralToSeize), "Collateral transfer failed");

        emit Liquidation(_borrower, msg.sender, collateralToSeize, maxLiquidation);
    }

    // Flash loan function
    function flashLoan(uint256 _amount, bytes calldata _data) external nonReentrant whenNotPaused {
        require(flashLoansEnabled, "Flash loans disabled");
        require(_amount <= availableLiquidity, "Insufficient liquidity");
        require(_amount > 0, "Amount must be greater than 0");

        uint256 fee = (_amount * flashLoanFee) / 10000;
        uint256 balanceBefore = lendingToken.balanceOf(address(this));

        require(lendingToken.transfer(msg.sender, _amount), "Flash loan transfer failed");

        // Call the borrower's callback function
        IFlashLoanReceiver(msg.sender).executeOperation(_amount, fee, _data);

        uint256 balanceAfter = lendingToken.balanceOf(address(this));
        require(balanceAfter >= balanceBefore + fee, "Flash loan not repaid");

        totalReserves += fee;

        emit FlashLoan(msg.sender, _amount, fee);
    }

    // Reward claiming function
    function claimRewards() external nonReentrant whenNotPaused {
        LenderInfo storage lender = lenders[msg.sender];
        _updateLenderRewards(msg.sender);

        uint256 rewards = lender.rewardTokens;
        require(rewards > 0, "No rewards to claim");

        lender.rewardTokens = 0;
        // Assuming reward tokens are the same as lending tokens for simplicity
        require(lendingToken.transfer(msg.sender, rewards), "Reward transfer failed");

        emit RewardsClaimed(msg.sender, rewards);
    }

    // Emergency withdraw (only for lenders, with penalty)
    function emergencyWithdraw() external nonReentrant {
        LenderInfo storage lender = lenders[msg.sender];
        require(lender.depositedAmount > 0, "No deposits found");

        uint256 withdrawAmount = (lender.depositedAmount * 95) / 100; // 5% penalty
        uint256 penalty = l
    
    
    
    
       
