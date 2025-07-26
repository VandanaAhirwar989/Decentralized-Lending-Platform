// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title Enhanced Decentralized Lending Platform with Advanced Features
 * @dev A comprehensive lending platform with cutting-edge DeFi features
 */
contract EnhancedProject is ReentrancyGuard, Ownable, Pausable {
    using SafeMath for uint256;

    // NEW ADDITIONAL FEATURES - Flash Loans
    struct FlashLoan {
        uint256 id;
        address borrower;
        address token;
        uint256 amount;
        uint256 fee;
        uint256 timestamp;
        bool isRepaid;
    }

    // Cross-Chain Bridge Support
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

    // NFT Collateral System
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

    // Vault System for Automated Yield Generation
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

    // Advanced Order Book for DEX functionality
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

    // Liquidity Bootstrapping Pool
    struct LiquidityBootstrapPool {
        uint256 id;
        string name;
        address tokenA;
        address tokenB;
        uint256 initialWeightA;
        uint256 initialWeightB;
        uint256 finalWeightA;
        uint256 finalWeightB;
        uint256 startTime;
        uint256 endTime;
        uint256 totalLiquidity;
        bool isActive;
        mapping(address => uint256) userContributions;
    }

    // Credit Delegation System
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

    // Options Trading
    struct OptionsContract {
        uint256 id;
        address underlying;
        uint256 strikePrice;
        uint256 premium;
        uint256 expiry;
        bool isCall; // true for call, false for put
        address writer;
        address buyer;
        bool isExercised;
        bool isActive;
        uint256 collateralAmount;
    }

    // EXISTING STRUCTURES (keeping all your original structures)
    struct DerivativesPool {
        uint256 id;
        string name;
        address underlyingAsset;
        uint256 totalLiquidity;
        uint256 totalShorts;
        uint256 totalLongs;
        uint256 fundingRate;
        uint256 maxLeverage;
        bool isActive;
        mapping(address => uint256) userLongPositions;
        mapping(address => uint256) userShortPositions;
        mapping(address => uint256) userMargin;
    }

    struct PredictionMarket {
        uint256 id;
        string question;
        string category;
        uint256 endTime;
        uint256 totalYesShares;
        uint256 totalNoShares;
        uint256 resolutionTime;
        bool isResolved;
        bool outcome;
        address oracle;
        mapping(address => uint256) yesShares;
        mapping(address => uint256) noShares;
        uint256 totalVolume;
        uint256 creatorFee;
    }

    struct YieldStrategy {
        uint256 id;
        string name;
        address targetToken;
        uint256 totalDeposited;
        uint256 expectedAPY;
        uint256 riskLevel;
        bool autoRebalance;
        bool isActive;
        address strategyContract;
        uint256 managementFee;
        uint256 performanceFee;
        mapping(address => uint256) userDeposits;
        mapping(address => uint256) userRewards;
    }

    // STATE VARIABLES FOR NEW FEATURES
    uint256 public flashLoanCounter;
    uint256 public crossChainBridgeCounter;
    uint256 public nftCollateralCounter;
    uint256 public yieldVaultCounter;
    uint256 public orderBookCounter;
    uint256 public lbpCounter;
    uint256 public creditDelegationCounter;
    uint256 public optionsCounter;

    // Flash loan parameters
    uint256 public flashLoanFeeRate = 9; // 0.09% fee
    uint256 public constant FLASH_LOAN_FEE_PRECISION = 10000;

    // Mappings for new features
    mapping(uint256 => FlashLoan) public flashLoans;
    mapping(uint256 => CrossChainBridge) public crossChainBridges;
    mapping(uint256 => NFTCollateral) public nftCollaterals;
    mapping(uint256 => YieldVault) public yieldVaults;
    mapping(uint256 => OrderBook) public orderBooks;
    mapping(uint256 => LiquidityBootstrapPool) public lbpPools;
    mapping(uint256 => CreditDelegation) public creditDelegations;
    mapping(uint256 => OptionsContract) public optionsContracts;
    
    // Additional mappings
    mapping(address => uint256[]) public userFlashLoans;
    mapping(address => uint256[]) public userNFTCollaterals;
    mapping(address => uint256[]) public userOrders;
    mapping(address => bool) public authorizedNFTContracts;
    mapping(address => address) public nftPriceOracles;

    // ORIGINAL STATE VARIABLES (keeping all your existing ones)
    uint256 public derivativesPoolCounter;
    uint256 public predictionMarketCounter;
    uint256 public yieldStrategyCounter;
    uint256 public liquidityMiningCounter;
    uint256 public syntheticAssetCounter;
    uint256 public insurancePoolCounter;
    uint256 public stakingPoolCounter;
    uint256 public automatedStrategyCounter;
    uint256 public rebaseTokenCounter;

    bool public derivativesEnabled = true;
    bool public predictionMarketsEnabled = true;
    bool public yieldStrategiesEnabled = true;
    bool public liquidityMiningEnabled = true;
    bool public syntheticAssetsEnabled = true;
    bool public advancedInsuranceEnabled = true;
    bool public automatedStrategiesEnabled = true;
    bool public rebaseTokensEnabled = true;
    bool public daoEnabled = true;
    
    // New feature flags
    bool public flashLoansEnabled = true;
    bool public crossChainEnabled = true;
    bool public nftCollateralEnabled = true;
    bool public yieldVaultsEnabled = true;
    bool public orderBookEnabled = true;
    bool public lbpEnabled = true;
    bool public creditDelegationEnabled = true;
    bool public optionsEnabled = true;

    // Mappings for existing features
    mapping(uint256 => DerivativesPool) public derivativesPools;
    mapping(uint256 => PredictionMarket) public predictionMarkets;
    mapping(uint256 => YieldStrategy) public yieldStrategies;
    mapping(address => uint256[]) public userStrategies;
    mapping(address => uint256) public reputationScores;
    mapping(address => bool) public strategists;
    mapping(address => uint256) public totalFeesEarned;

    // Additional variables
    IERC20 public lendingToken;
    uint256 public availableLiquidity;
    mapping(address => bool) public whitelistedTokens;
    mapping(address => uint256) public lastActivity;
    mapping(address => uint256) public loyaltyPoints;

    // NEW EVENTS
    event FlashLoanInitiated(uint256 indexed loanId, address indexed borrower, address token, uint256 amount, uint256 fee);
    event FlashLoanRepaid(uint256 indexed loanId, address indexed borrower, uint256 totalAmount);
    event CrossChainTransferInitiated(uint256 indexed bridgeId, address indexed user, string destinationChain, uint256 amount);
    event NFTCollateralDeposited(uint256 indexed collateralId, address indexed user, address nftContract, uint256 tokenId, uint256 loanAmount);
    event NFTCollateralLiquidated(uint256 indexed collateralId, address indexed user, uint256 liquidationAmount);
    event YieldVaultDeposit(uint256 indexed vaultId, address indexed user, uint256 amount);
    event YieldVaultWithdraw(uint256 indexed vaultId, address indexed user, uint256 amount, uint256 yield);
    event OrderPlaced(uint256 indexed orderId, address indexed maker, address tokenA, address tokenB, uint256 amountA, uint256 price);
    event OrderFilled(uint256 indexed orderId, address indexed taker, uint256 filledAmount);
    event LBPCreated(uint256 indexed poolId, string name, address tokenA, address tokenB);
    event CreditDelegated(address indexed delegator, address indexed delegatee, address asset, uint256 creditLimit);
    event OptionsContractCreated(uint256 indexed optionId, address indexed writer, address underlying, uint256 strikePrice, bool isCall);
    event OptionsExercised(uint256 indexed optionId, address indexed buyer, uint256 payout);

    // EXISTING EVENTS (keeping your original events)
    event DerivativesPoolCreated(uint256 indexed poolId, string name, address underlyingAsset);
    event PositionOpened(uint256 indexed poolId, address indexed user, bool isLong, uint256 amount, uint256 leverage);
    event PositionClosed(uint256 indexed poolId, address indexed user, uint256 pnl);
    event PredictionMarketCreated(uint256 indexed marketId, string question, uint256 endTime);
    event SharesPurchased(uint256 indexed marketId, address indexed user, bool isYes, uint256 shares);
    event MarketResolved(uint256 indexed marketId, bool outcome);
    
    // Modifiers
    modifier onlyStrategist() {
        require(strategists[msg.sender] || owner() == msg.sender, "Not authorized strategist");
        _;
    }

    modifier updateActivity() {
        lastActivity[msg.sender] = block.timestamp;
        _;
    }

    constructor() Ownable(msg.sender) {
        strategists[msg.sender] = true;
    }

    // NEW FEATURE 1: Flash Loans
    function initiateFlashLoan(
        address _token,
        uint256 _amount,
        bytes calldata _data
    ) external nonReentrant {
        require(flashLoansEnabled, "Flash loans disabled");
        require(whitelistedTokens[_token], "Token not supported");
        require(_amount > 0, "Invalid amount");
        
        IERC20 token = IERC20(_token);
        require(token.balanceOf(address(this)) >= _amount, "Insufficient liquidity");
        
        flashLoanCounter = flashLoanCounter.add(1);
        uint256 fee = _amount.mul(flashLoanFeeRate).div(FLASH_LOAN_FEE_PRECISION);
        
        FlashLoan storage loan = flashLoans[flashLoanCounter];
        loan.id = flashLoanCounter;
        loan.borrower = msg.sender;
        loan.token = _token;
        loan.amount = _amount;
        loan.fee = fee;
        loan.timestamp = block.timestamp;
        
        userFlashLoans[msg.sender].push(flashLoanCounter);
        
        // Transfer tokens to borrower
        require(token.transfer(msg.sender, _amount), "Transfer failed");
        
        emit FlashLoanInitiated(flashLoanCounter, msg.sender, _token, _amount, fee);
        
        // Execute borrower's logic
        IFlashLoanReceiver(msg.sender).receiveFlashLoan(_token, _amount, fee, _data);
        
        // Check repayment
        uint256 totalRepayment = _amount.add(fee);
        require(token.balanceOf(address(this)) >= totalRepayment, "Flash loan not repaid");
        
        loan.isRepaid = true;
        emit FlashLoanRepaid(flashLoanCounter, msg.sender, totalRepayment);
    }

    // NEW FEATURE 2: Cross-Chain Bridge
    function createCrossChainBridge(
        string memory _destinationChain,
        address _destinationContract,
        uint256 _minAmount,
        uint256 _maxAmount,
        uint256 _bridgeFee
    ) external onlyOwner {
        require(crossChainEnabled, "Cross-chain disabled");
        
        crossChainBridgeCounter = crossChainBridgeCounter.add(1);
        
        CrossChainBridge storage bridge = crossChainBridges[crossChainBridgeCounter];
        bridge.id = crossChainBridgeCounter;
        bridge.destinationChain = _destinationChain;
        bridge.destinationContract = _destinationContract;
        bridge.minAmount = _minAmount;
        bridge.maxAmount = _maxAmount;
        bridge.bridgeFee = _bridgeFee;
        bridge.isActive = true;
    }

    function initiateCrossChainTransfer(
        uint256 _bridgeId,
        uint256 _amount,
        string memory _destinationAddress
    ) external nonReentrant updateActivity {
        require(_bridgeId > 0 && _bridgeId <= crossChainBridgeCounter, "Invalid bridge");
        CrossChainBridge storage bridge = crossChainBridges[_bridgeId];
        require(bridge.isActive, "Bridge not active");
        require(_amount >= bridge.minAmount && _amount <= bridge.maxAmount, "Amount out of range");
        
        uint256 totalAmount = _amount.add(bridge.bridgeFee);
        require(lendingToken.transferFrom(msg.sender, address(this), totalAmount), "Transfer failed");
        
        // Generate unique transaction hash
        bytes32 txHash = keccak256(abi.encodePacked(msg.sender, _amount, block.timestamp, _destinationAddress));
        bridge.processedTransactions[txHash] = true;
        
        emit CrossChainTransferInitiated(_bridgeId, msg.sender, bridge.destinationChain, _amount);
    }

    // NEW FEATURE 3: NFT Collateral System
    function authorizeNFTContract(address _nftContract, address _priceOracle) external onlyOwner {
        authorizedNFTContracts[_nftContract] = true;
        nftPriceOracles[_nftContract] = _priceOracle;
    }

    function depositNFTCollateral(
        address _nftContract,
        uint256 _tokenId,
        uint256 _loanAmount,
        uint256 _loanDuration
    ) external nonReentrant updateActivity {
        require(nftCollateralEnabled, "NFT collateral disabled");
        require(authorizedNFTContracts[_nftContract], "NFT contract not authorized");
        require(_loanDuration >= 7 days && _loanDuration <= 365 days, "Invalid loan duration");
        
        // Get NFT valuation
        uint256 nftValue = _getNFTValuation(_nftContract, _tokenId);
        require(_loanAmount <= nftValue.mul(75).div(100), "Loan amount too high"); // Max 75% LTV
        
        nftCollateralCounter = nftCollateralCounter.add(1);
        
        NFTCollateral storage collateral = nftCollaterals[nftCollateralCounter];
        collateral.tokenId = _tokenId;
        collateral.nftContract = _nftContract;
        collateral.owner = msg.sender;
        collateral.valuationAmount = nftValue;
        collateral.loanAmount = _loanAmount;
        collateral.interestRate = 1000; // 10% annual rate
        collateral.loanDuration = _loanDuration;
        collateral.startTime = block.timestamp;
        collateral.isActive = true;
        collateral.valuationOracle = nftPriceOracles[_nftContract];
        
        userNFTCollaterals[msg.sender].push(nftCollateralCounter);
        
        // Transfer NFT to contract (assuming ERC721)
        IERC721(_nftContract).transferFrom(msg.sender, address(this), _tokenId);
        
        // Transfer loan amount to user
        require(lendingToken.transfer(msg.sender, _loanAmount), "Loan transfer failed");
        
        emit NFTCollateralDeposited(nftCollateralCounter, msg.sender, _nftContract, _tokenId, _loanAmount);
    }

    function repayNFTLoan(uint256 _collateralId) external nonReentrant updateActivity {
        require(_collateralId > 0 && _collateralId <= nftCollateralCounter, "Invalid collateral");
        NFTCollateral storage collateral = nftCollaterals[_collateralId];
        require(collateral.owner == msg.sender, "Not the owner");
        require(collateral.isActive, "Collateral not active");
        
        uint256 interest = _calculateNFTLoanInterest(_collateralId);
        uint256 totalRepayment = collateral.loanAmount.add(interest);
        
        require(lendingToken.transferFrom(msg.sender, address(this), totalRepayment), "Repayment failed");
        
        // Return NFT to owner
        IERC721(collateral.nftContract).transferFrom(address(this), msg.sender, collateral.tokenId);
        
        collateral.isActive = false;
    }

    // NEW FEATURE 4: Yield Vaults
    function createYieldVault(
        string memory _name,
        address _depositToken,
        uint256 _lockPeriod,
        uint256 _managementFee,
        uint256 _withdrawalFee,
        address[] memory _strategyContracts
    ) external onlyOwner {
        require(yieldVaultsEnabled, "Yield vaults disabled");
        require(_managementFee <= 300, "Management fee too high"); // Max 3%
        require(_withdrawalFee <= 100, "Withdrawal fee too high"); // Max 1%
        
        yieldVaultCounter = yieldVaultCounter.add(1);
        
        YieldVault storage vault = yieldVaults[yieldVaultCounter];
        vault.id = yieldVaultCounter;
        vault.name = _name;
        vault.depositToken = _depositToken;
        vault.lockPeriod = _lockPeriod;
        vault.managementFee = _managementFee;
        vault.withdrawalFee = _withdrawalFee;
        vault.isActive = true;
        vault.strategyContracts = _strategyContracts;
    }

    function depositToVault(uint256 _vaultId, uint256 _amount) external nonReentrant updateActivity {
        require(_vaultId > 0 && _vaultId <= yieldVaultCounter, "Invalid vault");
        YieldVault storage vault = yieldVaults[_vaultId];
        require(vault.isActive, "Vault not active");
        require(_amount > 0, "Invalid amount");
        
        require(IERC20(vault.depositToken).transferFrom(msg.sender, address(this), _amount), "Deposit failed");
        
        vault.userDeposits[msg.sender] = vault.userDeposits[msg.sender].add(_amount);
        vault.depositTime[msg.sender] = block.timestamp;
        vault.totalDeposits = vault.totalDeposits.add(_amount);
        
        emit YieldVaultDeposit(_vaultId, msg.sender, _amount);
    }

    function withdrawFromVault(uint256 _vaultId, uint256 _amount) external nonReentrant updateActivity {
        require(_vaultId > 0 && _vaultId <= yieldVaultCounter, "Invalid vault");
        YieldVault storage vault = yieldVaults[_vaultId];
        require(vault.userDeposits[msg.sender] >= _amount, "Insufficient balance");
        
        uint256 withdrawalFee = 0;
        if (block.timestamp < vault.depositTime[msg.sender].add(vault.lockPeriod)) {
            withdrawalFee = _amount.mul(vault.withdrawalFee).div(10000);
        }
        
        uint256 netAmount = _amount.sub(withdrawalFee);
        uint256 yieldEarned = vault.earnedYield[msg.sender];
        
        vault.userDeposits[msg.sender] = vault.userDeposits[msg.sender].sub(_amount);
        vault.earnedYield[msg.sender] = 0;
        vault.totalDeposits = vault.totalDeposits.sub(_amount);
        
        require(IERC20(vault.depositToken).transfer(msg.sender, netAmount.add(yieldEarned)), "Withdrawal failed");
        
        emit YieldVaultWithdraw(_vaultId, msg.sender, netAmount, yieldEarned);
    }

    // NEW FEATURE 5: Advanced Order Book (DEX functionality)
    function placeOrder(
        address _tokenA,
        address _tokenB,
        uint256 _amountA,
        uint256 _amountB,
        uint256 _price,
        uint256 _expiry,
        OrderType _orderType
    ) external nonReentrant updateActivity {
        require(orderBookEnabled, "Order book disabled");
        require(whitelistedTokens[_tokenA] && whitelistedTokens[_tokenB], "Tokens not supported");
        require(_amountA > 0 && _amountB > 0, "Invalid amounts");
        require(_expiry > block.timestamp, "Invalid expiry");
        
        orderBookCounter = orderBookCounter.add(1);
        
        OrderBook storage order = orderBooks[orderBookCounter];
        order.orderId = orderBookCounter;
        order.maker = msg.sender;
        order.tokenA = _tokenA;
        order.tokenB = _tokenB;
        order.amountA = _amountA;
        order.amountB = _amountB;
        order.price = _price;
        order.expiry = _expiry;
        order.orderType = _orderType;
        order.isActive = true;
        
        userOrders[msg.sender].push(orderBookCounter);
        
        // Lock tokens for the order
        require(IERC20(_tokenA).transferFrom(msg.sender, address(this), _amountA), "Token lock failed");
        
        emit OrderPlaced(orderBookCounter, msg.sender, _tokenA, _tokenB, _amountA, _price);
    }

    function fillOrder(uint256 _orderId, uint256 _fillAmount) external nonReentrant updateActivity {
        require(_orderId > 0 && _orderId <= orderBookCounter, "Invalid order");
        OrderBook storage order = orderBooks[_orderId];
        require(order.isActive, "Order not active");
        require(block.timestamp <= order.expiry, "Order expired");
        require(_fillAmount <= order.amountA, "Fill amount too high");
        
        uint256 tokenBAmount = _fillAmount.mul(order.amountB).div(order.amountA);
        
        // Transfer tokens
        require(IERC20(order.tokenB).transferFrom(msg.sender, order.maker, tokenBAmount), "Payment failed");
        require(IERC20(order.tokenA).transfer(msg.sender, _fillAmount), "Token transfer failed");
        
        // Update order
        order.amountA = order.amountA.sub(_fillAmount);
        order.amountB = order.amountB.sub(tokenBAmount);
        
        if (order.amountA == 0) {
            order.isActive = false;
            order.isFilled = true;
        }
        
        emit OrderFilled(_orderId, msg.sender, _fillAmount);
    }

    // NEW FEATURE 6: Credit Delegation
    function delegateCredit(
        address _delegatee,
        address _asset,
        uint256 _creditLimit,
        uint256 _interestRate,
        uint256 _duration
    ) external nonReentrant updateActivity {
        require(creditDelegationEnabled, "Credit delegation disabled");
        require(whitelistedTokens[_asset], "Asset not supported");
        require(_creditLimit > 0, "Invalid credit limit");
        require(_duration >= 1 days && _duration <= 365 days, "Invalid duration");
        
        creditDelegationCounter = creditDelegationCounter.add(1);
        
        CreditDelegation storage delegation = creditDelegations[creditDelegationCounter];
        delegation.delegator = msg.sender;
        delegation.delegatee = _delegatee;
        delegation.asset = _asset;
        delegation.creditLimit = _creditLimit;
        delegation.interestRate = _interestRate;
        delegation.expiryTime = block.timestamp.add(_duration);
        delegation.isActive = true;
        
        emit CreditDelegated(msg.sender, _delegatee, _asset, _creditLimit);
    }

    function borrowOnCredit(uint256 _delegationId, uint256 _amount) external nonReentrant updateActivity {
        require(_delegationId > 0 && _delegationId <= creditDelegationCounter, "Invalid delegation");
        CreditDelegation storage delegation = creditDelegations[_delegationId];
        require(delegation.delegatee == msg.sender, "Not authorized");
        require(delegation.isActive, "Delegation not active");
        require(block.timestamp <= delegation.expiryTime, "Delegation expired");
        require(delegation.usedCredit.add(_amount) <= delegation.creditLimit, "Exceeds credit limit");
        
        delegation.usedCredit = delegation.usedCredit.add(_amount);
        
        require(IERC20(delegation.asset).transfer(msg.sender, _amount), "Borrow transfer failed");
    }

    // Helper Functions
    function _getNFTValuation(address _nftContract, uint256 _tokenId) internal view returns (uint256) {
        // This would integrate with NFT price oracles like OpenSea API or floor price feeds
        // For now, returning a placeholder value
        return 1000 * 10**18; // $1000 placeholder
    }

    function _calculateNFTLoanInterest(uint256 _collateralId) internal view returns (uint256) {
        NFTCollateral storage collateral = nftCollaterals[_collateralId];
        uint256 timeElapsed = block.timestamp.sub(collateral.startTime);
        uint256 annualInterest = collateral.loanAmount.mul(collateral.interestRate).div(10000);
        return annualInterest.mul(timeElapsed).div(365 days);
    }

    // Administrative Functions
    function setFlashLoanFee(uint256 _newFeeRate) external onlyOwner {
        require(_newFeeRate <= 100, "Fee too high"); // Max 1%
        flashLoanFeeRate = _newFeeRate;
    }

    function toggleFlashLoans() external onlyOwner {
        flashLoansEnabled = !flashLoansEnabled;
    }

    function toggleCrossChain() external onlyOwner {
        crossChainEnabled = !crossChainEnabled;
    }

    function toggleNFTCollateral() external onlyOwner {
        nftCollateralEnabled = !nftCollateralEnabled;
    }

    function toggleYieldVaults() external onlyOwner {
        yieldVaultsEnabled = !yieldVaultsEnabled;
    }

    function toggleOrderBook() external onlyOwner {
        orderBookEnabled = !orderBookEnabled;
    }

    function addWhitelistedToken(address _token) external onlyOwner {
        whitelistedTokens[_token] = true;
    }

    function removeWhitelistedToken(address _token) external onlyOwner {
        whitelistedTokens[_token] = false;
    }

    // View Functions
    function getUserFlashLoans(address _user) external view returns (uint256[] memory) {
        return userFlashLoans[_user];
    }

    function getUserNFTCollaterals(address _user) external view returns (uint256[] memory) {
        return userNFTCollaterals[_user];
    }

    function getUserOrders(address _user) external view returns (uint256[] memory) {
        return userOrders[_user];
    }

    function getFlashLoanInfo(uint256 _loanId) external view returns (
        address borrower,
        address token,
        uint256 amount,
        uint256 fee,
        bool isRepaid
    ) {
        FlashLoan storage loan = flashLoans[_loanId];
        return (loan.borrower, loan.token, loan.amount, loan.fee, loan.isRepaid);
    }

    function getVaultInfo(uint256 _vaultId) external view returns (
        string memory name,
        address depositToken,
        uint256 totalDeposits,
        uint256 currentAPY,
        bool isActive
    ) {
        YieldVault storage vault = yieldVaults[_vaultId];
        return (vault.name, vault.depositToken, vault.totalDeposits, vault.currentAPY, vault.isActive);
    }

    // Emergency Functions
    function emergencyPause() external onlyOwner {
        _pause();
    }

    function emergencyUnpause() external onlyOwner {
       
        
       
       
        
        
       
    
   
        
        
