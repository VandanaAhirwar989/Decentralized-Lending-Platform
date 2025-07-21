// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Decentralized Lending Platform
 * @dev A simple lending platform where users can deposit tokens to earn interest and borrow against collateral
 */
contract Project is ReentrancyGuard, Ownable {
    // Structs
    struct LenderInfo {
        uint256 depositedAmount;
        uint256 lastUpdateTime;
        uint256 accruedInterest;
    }

    struct BorrowerInfo {
        uint256 borrowedAmount;
        uint256 collateralAmount;
        uint256 lastUpdateTime;
        uint256 accruedInterest;
    }

    // Hardcoded token addresses (replace with real ones before deployment)
    address constant LENDING_TOKEN_ADDRESS = 0x0000000000000000000000000000000000000001;
    address constant COLLATERAL_TOKEN_ADDRESS = 0x0000000000000000000000000000000000000002;

    // Tokens
    IERC20 public lendingToken;
    IERC20 public collateralToken;

    // Constants
    uint256 public constant LENDING_INTEREST_RATE = 5;
    uint256 public constant BORROWING_INTEREST_RATE = 8;
    uint256 public constant COLLATERAL_RATIO = 150;
    uint256 public constant SECONDS_PER_YEAR = 365 days;

    uint256 public totalDeposits;
    uint256 public totalBorrows;
    uint256 public availableLiquidity;

    // Mappings
    mapping(address => LenderInfo) public lenders;
    mapping(address => BorrowerInfo) public borrowers;

    // Events
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount, uint256 interest);
    event Borrow(address indexed user, uint256 borrowAmount, uint256 collateralAmount);
    event Repay(address indexed user, uint256 amount, uint256 interest);
    event Liquidation(address indexed borrower, address indexed liquidator, uint256 collateralSeized);

    // Constructor with hardcoded tokens
    constructor() Ownable(msg.sender) {
        lendingToken = IERC20(LENDING_TOKEN_ADDRESS);
        collateralToken = IERC20(COLLATERAL_TOKEN_ADDRESS);
    }

    function deposit(uint256 _amount) external nonReentrant {
        require(_amount > 0, "Amount must be greater than 0");
        require(lendingToken.transferFrom(msg.sender, address(this), _amount), "Transfer failed");

        LenderInfo storage lender = lenders[msg.sender];
        _updateLenderInterest(msg.sender);

        lender.depositedAmount += _amount;
        lender.lastUpdateTime = block.timestamp;

        totalDeposits += _amount;
        availableLiquidity += _amount;

        emit Deposit(msg.sender, _amount);
    }

    function borrow(uint256 _borrowAmount, uint256 _collateralAmount) external nonReentrant {
        require(_borrowAmount > 0, "Borrow amount must be greater than 0");
        require(_collateralAmount > 0, "Collateral amount must be greater than 0");
        require(availableLiquidity >= _borrowAmount, "Insufficient liquidity");

        require(_collateralAmount * 100 >= _borrowAmount * COLLATERAL_RATIO, "Insufficient collateral");

        require(collateralToken.transferFrom(msg.sender, address(this), _collateralAmount), "Collateral transfer failed");

        BorrowerInfo storage borrower = borrowers[msg.sender];
        _updateBorrowerInterest(msg.sender);

        borrower.borrowedAmount += _borrowAmount;
        borrower.collateralAmount += _collateralAmount;
        borrower.lastUpdateTime = block.timestamp;

        totalBorrows += _borrowAmount;
        availableLiquidity -= _borrowAmount;

        require(lendingToken.transfer(msg.sender, _borrowAmount), "Borrow transfer failed");

        emit Borrow(msg.sender, _borrowAmount, _collateralAmount);
    }

    function repay(uint256 _repayAmount) external nonReentrant {
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

        uint256 collateralToReturn = 0;
        if (principalRepaid > 0 && borrower.borrowedAmount == 0) {
            collateralToReturn = borrower.collateralAmount;
            borrower.collateralAmount = 0;
        } else if (principalRepaid > 0) {
            collateralToReturn = (borrower.collateralAmount * principalRepaid) / (borrower.borrowedAmount + principalRepaid);
            borrower.collateralAmount -= collateralToReturn;
        }

        totalBorrows -= principalRepaid;
        availableLiquidity += _repayAmount;

        if (collateralToReturn > 0) {
            require(collateralToken.transfer(msg.sender, collateralToReturn), "Collateral return failed");
        }

        emit Repay(msg.sender, _repayAmount, interestRepaid);
    }

    function _updateLenderInterest(address _lender) internal {
        LenderInfo storage lender = lenders[_lender];
        if (lender.depositedAmount > 0 && lender.lastUpdateTime > 0) {
            uint256 timeElapsed = block.timestamp - lender.lastUpdateTime;
            uint256 interest = (lender.depositedAmount * LENDING_INTEREST_RATE * timeElapsed) / (100 * SECONDS_PER_YEAR);
            lender.accruedInterest += interest;
        }
        lender.lastUpdateTime = block.timestamp;
    }

    function _updateBorrowerInterest(address _borrower) internal {
        BorrowerInfo storage borrower = borrowers[_borrower];
        if (borrower.borrowedAmount > 0 && borrower.lastUpdateTime > 0) {
            uint256 timeElapsed = block.timestamp - borrower.lastUpdateTime;
            uint256 interest = (borrower.borrowedAmount * BORROWING_INTEREST_RATE * timeElapsed) / (100 * SECONDS_PER_YEAR);
            borrower.accruedInterest += interest;
        }
        borrower.lastUpdateTime = block.timestamp;
    }

    function getLenderInfo(address _lender) external view returns (
        uint256 depositedAmount,
        uint256 currentInterest,
        uint256 totalBalance
    ) {
        LenderInfo storage lender = lenders[_lender];
        depositedAmount = lender.depositedAmount;

        if (lender.depositedAmount > 0 && lender.lastUpdateTime > 0) {
            uint256 timeElapsed = block.timestamp - lender.lastUpdateTime;
            uint256 newInterest = (lender.depositedAmount * LENDING_INTEREST_RATE * timeElapsed) / (100 * SECONDS_PER_YEAR);
            currentInterest = lender.accruedInterest + newInterest;
        } else {
            currentInterest = lender.accruedInterest;
        }

        totalBalance = depositedAmount + currentInterest;
    }

    function getBorrowerInfo(address _borrower) external view returns (
        uint256 borrowedAmount,
        uint256 currentInterest,
        uint256 totalDebt,
        uint256 collateralAmount
    ) {
        BorrowerInfo storage borrower = borrowers[_borrower];
        borrowedAmount = borrower.borrowedAmount;
        collateralAmount = borrower.collateralAmount;

        if (borrower.borrowedAmount > 0 && borrower.lastUpdateTime > 0) {
            uint256 timeElapsed = block.timestamp - borrower.lastUpdateTime;
            uint256 newInterest = (borrower.borrowedAmount * BORROWING_INTEREST_RATE * timeElapsed) / (100 * SECONDS_PER_YEAR);
            currentInterest = borrower.accruedInterest + newInterest;
        } else {
            currentInterest = borrower.accruedInterest;
        }

        totalDebt = borrowedAmount + currentInterest;
    }
}
