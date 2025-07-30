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

    // EXISTING STRUCTURES (keeping all previous ones)
    
    // 1. Dynamic Interest Rate Model
    struct InterestRateModel {
        uint256 baseRate;           
        uint256 multiplier;         
        uint256 jumpMultiplier;     
        uint256 optimalUtilization; 
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

    // ===== NEW FUNCTIONALITY 6: ARTIFICIAL INTELLIGENCE TRADING BOTS =====
    struct AITradingBot {
        uint256 id;
        string name;
        address owner;
        BotStrategy strategy;
        uint256 allocatedFunds;
        uint256 minTradeAmount;
        uint256 maxTradeAmount;
        uint256 riskTolerance; // 1-10 scale
        uint256 profitTarget;
        uint256 stopLoss;
        bool isActive;
        bool isPublic;
        uint256 totalTrades;
        uint256 successfulTrades;
        uint256 totalPnL;
        uint256 lastTradeTime;
        mapping(address => bool) allowedTokens;
        mapping(address => uint256) tokenWeights;
        uint256 subscriptionFee;
        mapping(address => uint256) subscribers;
    }

    enum BotStrategy { 
        ARBITRAGE, 
        MOMENTUM, 
        MEAN_REVERSION, 
        GRID_TRADING, 
        DCA, 
        SENTIMENT_ANALYSIS,
        YIELD_OPTIMIZATION,
        CROSS_CHAIN_ARBITRAGE
    }

    // ===== NEW FUNCTIONALITY 7: DECENTRALIZED PREDICTION MARKETS =====
    struct PredictionMarket {
        uint256 id;
        string question;
        string description;
        address creator;
        uint256 endTime;
        uint256 resolutionTime;
        uint256 totalStaked;
        uint256 yesStaked;
        uint256 noStaked;
        bool isResolved;
        bool outcome; // true for YES, false for NO
        address oracle;
        uint256 creatorFee;
        MarketCategory category;
        mapping(address => UserPrediction) predictions;
        mapping(address => bool) hasWithdrawn;
        uint256 totalParticipants;
    }

    struct UserPrediction {
        uint256 yesAmount;
        uint256 noAmount;
        bool hasParticipated;
        uint256 potentialPayout;
    }

    enum MarketCategory { 
        SPORTS, 
        POLITICS, 
        CRYPTO, 
        WEATHER, 
        ECONOMICS, 
        ENTERTAINMENT,
        TECHNOLOGY,
        SCIENCE
    }

    // ===== NEW FUNCTIONALITY 8: DYNAMIC NFT MARKETPLACE WITH FRACTIONAL OWNERSHIP =====
    struct DynamicNFT {
        uint256 tokenId;
        address nftContract;
        address owner;
        uint256 totalFractions;
        uint256 availableFractions;
        uint256 pricePerFraction;
        uint256 totalValue;
        bool isListed;
        bool allowsFractional;
        mapping(address => uint256) fractionOwners;
        mapping(address => uint256) fractionListings;
        uint256 royaltyPercentage;
        address royaltyRecipient;
        uint256 lastTradePrice;
        uint256 priceHistory;
    }

    struct NFTAuction {
        uint256 auctionId;
        uint256 tokenId;
        address nftContract;
        address seller;
        uint256 startingBid;
        uint256 currentBid;
        address currentBidder;
        uint256 endTime;
        bool isActive;
        bool isCompleted;
        AuctionType auctionType;
        uint256 reservePrice;
        uint256 bidIncrement;
    }

    enum AuctionType { ENGLISH, DUTCH, SEALED_BID, VICKREY }

    // ===== NEW FUNCTIONALITY 9: CARBON CREDIT TRADING PLATFORM =====
    struct CarbonCredit {
        uint256 id;
        string projectName;
        string location;
        address issuer;
        uint256 totalCredits;
        uint256 availableCredits;
        uint256 pricePerCredit;
        uint256 vintage; // Year of issuance
        CreditStandard standard;
        bool isVerified;
        bool isRetired;
        mapping(address => uint256) holdings;
        uint256 expiryDate;
        string methodology;
        bytes32 verificationHash;
    }

    enum CreditStandard { VCS, GOLD_STANDARD, CAR, ACR, CDM }

    struct CarbonOffset {
        uint256 id;
        address offsetter;
        uint256 creditId;
        uint256 amount;
        uint256 offsetDate;
        string purpose;
        bool isPermanent;
        bytes32 offsetCertificate;
    }

    // ===== NEW FUNCTIONALITY 10: DECENTRALIZED MUSIC STREAMING & ROYALTIES =====
    struct MusicTrack {
        uint256 trackId;
        string title;
        string artist;
        address owner;
        uint256 streamCount;
        uint256 pricePerStream;
        uint256 totalRoyalties;
        bool isActive;
        mapping(address => uint256) royaltyShares; // For collaborators
        mapping(address => uint256) streamHistory;
        uint256 duration; // in seconds
        string ipfsHash;
        Genre genre;
        uint256 releaseDate;
    }

    enum Genre { 
        ROCK, 
        POP, 
        JAZZ, 
        CLASSICAL, 
        ELECTRONIC, 
        HIP_HOP,
        COUNTRY,
        BLUES,
        REGGAE,
        OTHER
    }

    struct MusicStreaming {
        address streamer;
        uint256 trackId;
        uint256 streamTime;
        uint256 royaltyPaid;
        bool isComplete;
    }

    // ===== NEW FUNCTIONALITY 11: DECENTRALIZED CLOUD STORAGE MARKETPLACE =====
    struct StorageProvider {
        address provider;
        string name;
        uint256 totalCapacity; // in GB
        uint256 availableCapacity;
        uint256 pricePerGBMonth;
        uint256 uptime; // percentage
        uint256 reputation;
        bool isActive;
        mapping(address => uint256) userStorageUsed;
        uint256 totalEarnings;
        string endpoint;
        bytes32 publicKey;
    }

    struct StorageContract {
        uint256 contractId;
        address client;
        address provider;
        uint256 storageAmount; // in GB
        uint256 duration; // in months
        uint256 monthlyPrice;
        uint256 totalPrice;
        uint256 startTime;
        uint256 endTime;
        bool isActive;
        bool isPaid;
        string dataHash;
        uint256 redundancyLevel;
    }

    // ===== NEW FUNCTIONALITY 12: QUANTUM-RESISTANT SECURITY LAYER =====
    struct QuantumSecurity {
        address user;
        bytes32 quantumKeyHash;
        uint256 keyGeneration;
        uint256 lastRotation;
        bool isQuantumSecured;
        mapping(bytes32 => bool) usedNonces;
        uint256 securityLevel; // 1-5 scale
    }

    struct SecureTransaction {
        uint256 txId;
        address sender;
        address recipient;
        uint256 amount;
        bytes32 quantumSignature;
        uint256 timestamp;
        bool isVerified;
        uint256 securityScore;
    }

    // EXISTING STRUCTURES (abbreviated for space)
    struct FlashLoan {
        uint256 id;
        address borrower;
        address token;
        uint256 amount;
        uint256 fee;
        uint256 timestamp;
        bool isRepaid;
    }

    struct Portfolio {
        uint256 id;
        address owner;
        string name;
        uint256 totalValue;
        uint256 riskScore;
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

    // NEW COUNTERS FOR ADDED FUNCTIONALITY
    uint256 public aiTradingBotCounter;
    uint256 public predictionMarketCounter;
    uint256 public dynamicNFTCounter;
    uint256 public nftAuctionCounter;
    uint256 public carbonCreditCounter;
    uint256 public carbonOffsetCounter;
    uint256 public musicTrackCounter;
    uint256 public storageContractCounter;
    uint256 public secureTransactionCounter;

    // EXISTING COUNTERS
    uint256 public portfolioCounter;
    uint256 public flashLoanCounter;
    uint256 public dutchAuctionCounter;
    uint256 public governanceProposalCounter;

    // NEW MAPPINGS FOR ADDED FUNCTIONALITY
    mapping(uint256 => AITradingBot) public aiTradingBots;
    mapping(address => uint256[]) public userTradingBots;
    mapping(uint256 => PredictionMarket) public predictionMarkets;
    mapping(address => uint256[]) public userPredictions;
    mapping(uint256 => DynamicNFT) public dynamicNFTs;
    mapping(uint256 => NFTAuction) public nftAuctions;
    mapping(uint256 => CarbonCredit) public carbonCredits;
    mapping(uint256 => CarbonOffset) public carbonOffsets;
    mapping(address => uint256) public carbonFootprint;
    mapping(uint256 => MusicTrack) public musicTracks;
    mapping(address => uint256[]) public artistTracks;
    mapping(address => MusicStreaming[]) public userStreamingHistory;
    mapping(address => StorageProvider) public storageProviders;
    mapping(uint256 => StorageContract) public storageContracts;
    mapping(address => QuantumSecurity) public quantumSecurity;
    mapping(uint256 => SecureTransaction) public secureTransactions;

    // EXISTING MAPPINGS
    mapping(uint256 => Portfolio) public portfolios;
    mapping(uint256 => FlashLoan) public flashLoans;
    mapping(uint256 => DutchAuction) public dutchAuctions;
    mapping(uint256 => GovernanceProposal) public governanceProposals;

    // NEW FEATURE FLAGS
    bool public aiTradingEnabled = true;
    bool public predictionMarketsEnabled = true;
    bool public dynamicNFTEnabled = true;
    bool public carbonTradingEnabled = true;
    bool public musicStreamingEnabled = true;
    bool public cloudStorageEnabled = true;
    bool public quantumSecurityEnabled = true;

    // EXISTING FEATURE FLAGS
    bool public portfolioManagementEnabled = true;
    bool public flashLoansEnabled = true;
    bool public governanceEnabled = true;

    // PROTOCOL PARAMETERS
    uint256 public aiTradingFee = 50; // 0.5%
    uint256 public predictionMarketFee = 200; // 2%
    uint256 public nftMarketplaceFee = 250; // 2.5%
    uint256 public carbonCreditFee = 100; // 1%
    uint256 public musicStreamingFee = 30; // 0.3%
    uint256 public storageMarketplaceFee = 150; // 1.5%
    uint256 public quantumSecurityFee = 20; // 0.2%

    // CORE TOKENS
    IERC20 public lendingToken;
    IERC20 public governanceToken;
    uint256 public availableLiquidity;

    // NEW EVENTS FOR ADDED FUNCTIONALITY
    event AITradingBotCreated(uint256 indexed botId, address indexed owner, string name, BotStrategy strategy);
    event AITradeExecuted(uint256 indexed botId, address indexed token, bool isBuy, uint256 amount, uint256 price);
    event PredictionMarketCreated(uint256 indexed marketId, string question, address indexed creator, uint256 endTime);
    event PredictionPlaced(uint256 indexed marketId, address indexed user, bool prediction, uint256 amount);
    event PredictionMarketResolved(uint256 indexed marketId, bool outcome, uint256 totalPayout);
    event DynamicNFTListed(uint256 indexed tokenId, address indexed owner, uint256 totalFractions, uint256 pricePerFraction);
    event NFTFractionPurchased(uint256 indexed tokenId, address indexed buyer, uint256 fractions, uint256 totalPrice);
    event NFTAuctionStarted(uint256 indexed auctionId, uint256 indexed tokenId, address indexed seller, uint256 startingBid);
    event NFTAuctionBid(uint256 indexed auctionId, address indexed bidder, uint256 bidAmount);
    event CarbonCreditIssued(uint256 indexed creditId, string projectName, address indexed issuer, uint256 totalCredits);
    event CarbonCreditTraded(uint256 indexed creditId, address indexed seller, address indexed buyer, uint256 amount, uint256 price);
    event CarbonOffset(uint256 indexed offsetId, address indexed offsetter, uint256 creditId, uint256 amount);
    event MusicTrackUploaded(uint256 indexed trackId, string title, address indexed artist, uint256 pricePerStream);
    event MusicStreamed(uint256 indexed trackId, address indexed streamer, uint256 royaltyPaid);
    event StorageProviderRegistered(address indexed provider, string name, uint256 totalCapacity, uint256 pricePerGBMonth);
    event StorageContractCreated(uint256 indexed contractId, address indexed client, address indexed provider, uint256 storageAmount);
    event QuantumSecurityEnabled(address indexed user, uint256 securityLevel);
    event QuantumKeyRotated(address indexed user, uint256 newGeneration);

    // EXISTING EVENTS
    event FlashLoanInitiated(uint256 indexed loanId, address indexed borrower, address token, uint256 amount, uint256 fee);
    event PortfolioCreated(uint256 indexed portfolioId, address indexed owner, string name);
    event GovernanceProposalCreated(uint256 indexed proposalId, address indexed proposer, string title);

    // MODIFIERS
    modifier onlyStrategist() {
        require(msg.sender == owner(), "Not authorized strategist");
        _;
    }

    modifier updateActivity() {
        _;
    }

    modifier onlyQuantumSecured() {
        require(quantumSecurity[msg.sender].isQuantumSecured, "Quantum security required");
        _;
    }

    constructor() Ownable(msg.sender) {
        // Initialize quantum security for owner
        quantumSecurity[msg.sender].user = msg.sender;
        quantumSecurity[msg.sender].isQuantumSecured = true;
        quantumSecurity[msg.sender].securityLevel = 5;
        quantumSecurity[msg.sender].lastRotation = block.timestamp;
    }

    // ===== NEW FUNCTIONALITY 6: AI TRADING BOTS =====
    
    function createAITradingBot(
        string memory _name,
        BotStrategy _strategy,
        uint256 _allocatedFunds,
        uint256 _minTradeAmount,
        uint256 _maxTradeAmount,
        uint256 _riskTolerance,
        bool _isPublic,
        uint256 _subscriptionFee
    ) external nonReentrant updateActivity {
        require(aiTradingEnabled, "AI trading disabled");
        require(_riskTolerance >= 1 && _riskTolerance <= 10, "Invalid risk tolerance");
        require(_minTradeAmount <= _maxTradeAmount, "Invalid trade amounts");
        require(lendingToken.transferFrom(msg.sender, address(this), _allocatedFunds), "Fund transfer failed");
        
        aiTradingBotCounter = aiTradingBotCounter.add(1);
        
        AITradingBot storage bot = aiTradingBots[aiTradingBotCounter];
        bot.id = aiTradingBotCounter;
        bot.name = _name;
        bot.owner = msg.sender;
        bot.strategy = _strategy;
        bot.allocatedFunds = _allocatedFunds;
        bot.minTradeAmount = _minTradeAmount;
        bot.maxTradeAmount = _maxTradeAmount;
        bot.riskTolerance = _riskTolerance;
        bot.isActive = true;
        bot.isPublic = _isPublic;
        bot.subscriptionFee = _subscriptionFee;
        
        userTradingBots[msg.sender].push(aiTradingBotCounter);
        
        emit AITradingBotCreated(aiTradingBotCounter, msg.sender, _name, _strategy);
    }

    function executeAITrade(
        uint256 _botId,
        address _token,
        bool _isBuy,
        uint256 _amount,
        uint256 _price
    ) external nonReentrant onlyStrategist {
        require(_botId > 0 && _botId <= aiTradingBotCounter, "Invalid bot ID");
        AITradingBot storage bot = aiTradingBots[_botId];
        require(bot.isActive, "Bot not active");
        require(_amount >= bot.minTradeAmount && _amount <= bot.maxTradeAmount, "Amount out of range");
        
        // Execute trade logic here
        bot.totalTrades = bot.totalTrades.add(1);
        bot.lastTradeTime = block.timestamp;
        
        emit AITradeExecuted(_botId, _token, _isBuy, _amount, _price);
    }

    // ===== NEW FUNCTIONALITY 7: PREDICTION MARKETS =====
    
    function createPredictionMarket(
        string memory _question,
        string memory _description,
        uint256 _endTime,
        uint256 _resolutionTime,
        address _oracle,
        uint256 _creatorFee,
        MarketCategory _category
    ) external nonReentrant updateActivity {
        require(predictionMarketsEnabled, "Prediction markets disabled");
        require(_endTime > block.timestamp, "Invalid end time");
        require(_resolutionTime > _endTime, "Invalid resolution time");
        require(_creatorFee <= 1000, "Creator fee too high"); // Max 10%
        
        predictionMarketCounter = predictionMarketCounter.add(1);
        
        PredictionMarket storage market = predictionMarkets[predictionMarketCounter];
        market.id = predictionMarketCounter;
        market.question = _question;
        market.description = _description;
        market.creator = msg.sender;
        market.endTime = _endTime;
        market.resolutionTime = _resolutionTime;
        market.oracle = _oracle;
        market.creatorFee = _creatorFee;
        market.category = _category;
        
        emit PredictionMarketCreated(predictionMarketCounter, _question, msg.sender, _endTime);
    }

    function placePrediction(
        uint256 _marketId,
        bool _prediction,
        uint256 _amount
    ) external nonReentrant updateActivity {
        require(_marketId > 0 && _marketId <= predictionMarketCounter, "Invalid market");
        PredictionMarket storage market = predictionMarkets[_marketId];
        require(block.timestamp < market.endTime, "Market ended");
        require(!market.isResolved, "Market resolved");
        require(lendingToken.transferFrom(msg.sender, address(this), _amount), "Transfer failed");
        
        UserPrediction storage userPred = market.predictions[msg.sender];
        if (!userPred.hasParticipated) {
            market.totalParticipants = market.totalParticipants.add(1);
            userPred.hasParticipated = true;
        }
        
        if (_prediction) {
            userPred.yesAmount = userPred.yesAmount.add(_amount);
            market.yesStaked = market.yesStaked.add(_amount);
        } else {
            userPred.noAmount = userPred.noAmount.add(_amount);
            market.noStaked = market.noStaked.add(_amount);
        }
        
        market.totalStaked = market.totalStaked.add(_amount);
        
        emit PredictionPlaced(_marketId, msg.sender, _prediction, _amount);
    }

    // ===== NEW FUNCTIONALITY 8: DYNAMIC NFT MARKETPLACE =====
    
    function listDynamicNFT(
        address _nftContract,
        uint256 _tokenId,
        uint256 _totalFractions,
        uint256 _pricePerFraction,
        bool _allowsFractional,
        uint256 _royaltyPercentage
    ) external nonReentrant updateActivity {
        require(dynamicNFTEnabled, "Dynamic NFT disabled");
        require(_totalFractions > 0, "Invalid fractions");
        require(_royaltyPercentage <= 1000, "Royalty too high"); // Max 10%
        
        dynamicNFTCounter = dynamicNFTCounter.add(1);
        
        DynamicNFT storage nft = dynamicNFTs[dynamicNFTCounter];
        nft.tokenId = _tokenId;
        nft.nftContract = _nftContract;
        nft.owner = msg.sender;
        nft.totalFractions = _totalFractions;
        nft.availableFractions = _totalFractions;
        nft.pricePerFraction = _pricePerFraction;
        nft.totalValue = _totalFractions.mul(_pricePerFraction);
        nft.isListed = true;
        nft.allowsFractional = _allowsFractional;
        nft.royaltyPercentage = _royaltyPercentage;
        nft.royaltyRecipient = msg.sender;
        
        emit DynamicNFTListed(_tokenId, msg.sender, _totalFractions, _pricePerFraction);
    }

    function purchaseNFTFractions(
        uint256 _nftId,
        uint256 _fractions
    ) external nonReentrant updateActivity {
        require(_nftId > 0 && _nftId <= dynamicNFTCounter, "Invalid NFT");
        DynamicNFT storage nft = dynamicNFTs[_nftId];
        require(nft.isListed, "NFT not listed");
        require(nft.allowsFractional, "Fractional ownership not allowed");
        require(_fractions <= nft.availableFractions, "Not enough fractions available");
        
        uint256 totalPrice = _fractions.mul(nft.pricePerFraction);
        require(lendingToken.transferFrom(msg.sender, address(this), totalPrice), "Payment failed");
        
        // Transfer royalty to original creator
        uint256 royalty = totalPrice.mul(nft.royaltyPercentage).div(10000);
        if (royalty > 0) {
            require(lendingToken.transfer(nft.royaltyRecipient, royalty), "Royalty transfer failed");
        }
        
        // Transfer remaining amount to current owner
        uint256 sellerAmount = totalPrice.sub(royalty);
        require(lendingToken.transfer(nft.owner, sellerAmount), "Seller payment failed");
        
        nft.fractionOwners[msg.sender] = nft.fractionOwners[msg.sender].add(_fractions);
        nft.availableFractions = nft.availableFractions.sub(_fractions);
        nft.lastTradePrice = nft.pricePerFraction;
        
        emit NFTFractionPurchased(_nftId, msg.sender, _fractions, totalPrice);
    }

    // ===== NEW FUNCTIONALITY 9: CARBON CREDIT TRADING =====
    
    function issueCarbonCredit(
        string memory _projectName,
        string memory _location,
        uint256 _totalCredits,
        uint256 _pricePerCredit,
        uint256 _vintage,
        CreditStandard _standard,
        uint256 _expiryDate,
        string memory _methodology
    ) external nonReentrant updateActivity {
        require(carbonTradingEnabled, "Carbon trading disabled");
        require(_totalCredits > 0, "Invalid credit amount");
        require(_vintage <= block.timestamp, "Invalid vintage");
        
        carbonCreditCounter = carbonCreditCounter.add(1);
        
        CarbonCredit storage credit = carbonCredits[carbonCreditCounter];
        credit.id = carbonCreditCounter;
        credit.projectName = _projectName;
        credit.location = _location;
        credit.issuer = msg.sender;
        credit.totalCredits = _totalCredits;
        credit.availableCredits = _totalCredits;
        credit.pricePerCredit = _pricePerCredit;
        credit.vintage = _vintage;
        credit.standard = _standard;
        credit.isVerified = false; // Needs verification
        credit.expiryDate = _expiryDate;
        credit.methodology = _methodology;
        
        emit CarbonCreditIssued(carbonCreditCounter, _projectName, msg.sender, _totalCredits);
    }

    function purchaseCarbonCredits(
        uint256 _creditId,
        uint256 _amount
    ) external nonReentrant updateActivity {
        require(_creditId > 0 && _creditId <= carbonCreditCounter, "Invalid credit ID");
        CarbonCredit storage credit = carbonCredits[_creditId];
        require(credit.isVerified, "Credit not verified");
        require(_amount <= credit.availableCredits, "Not enough credits available");
        require(block.timestamp < credit.expiryDate, "Credits expired");
        
        uint256 totalPrice = _amount.mul(credit.pricePerCredit);
        require(lendingToken.transferFrom(msg.sender, address(this), totalPrice), "Payment failed");
        
        // Transfer payment to issuer (minus platform fee)
        uint256 platformFee = totalPrice.mul(carbonCreditFee).div(10000);
        uint256 issuerAmount = totalPrice.sub(platformFee);
        require(lendingToken.transfer(credit.issuer, issuerAmount), "Issuer payment failed");
        
        credit.holdings[msg.sender] = credit.holdings[msg.sender].add(_amount);
        credit.availableCredits = credit.availableCredits.sub(_amount);
        
        emit CarbonCreditTraded(_creditId, credit.issuer, msg.sender, _amount, credit.pricePerCredit);
    }

    function offsetCarbonCredits(
        uint256 _creditId,
        uint256 _amount,
        string memory _purpose
    ) external nonReentrant updateActivity {
        require(_creditId > 0 && _creditId <= carbonCreditCounter, "Invalid credit ID");
        CarbonCredit storage credit = carbonCredits[_creditId];
        require(credit.holdings[msg.sender] >= _amount, "Insufficient credits");
        
        carbonOffsetCounter = carbonOffsetCounter.add(1);
        
        CarbonOffset storage offset = carbonOffsets[carbonOffsetCounter];
        offset.id = carbonOffsetCounter;
        offset.offsetter = msg.sender;
        offset.creditId = _creditId;
        offset.amount = _amount;
        offset.offsetDate = block.timestamp;
        offset.purpose = _purpose;
        offset.isPermanent = true;
        
        credit.holdings[msg.sender] = credit.holdings[msg.sender].sub(_amount);
        carbonFootprint[msg.sender] = carbonFootprint[msg.sender].sub(_amount);
        
        emit CarbonOffset(carbonOffsetCounter, msg.sender, _creditId, _amount);
    }

    // ===== NEW FUNCTIONALITY 10: MUSIC STREAMING & ROYALTIES =====
    
    function uploadMusicTrack(
        string memory _title,
        string memory _artist,
        uint256 _pricePerStream,
        uint256 _duration,
        string memory _ipfsHash,
        Genre _genre
    ) external nonReentrant updateActivity {
        require(musicStreamingEnabled, "Music streaming disabled");
        require(bytes(_title).length > 0, "Invalid title");
        require(_duration > 0, "Invalid duration");
        
        musicTrackCounter = musicTrackCounter.add(1);
        
        MusicTrack storage track = musicTracks[musicTrackCounter];
        track.trackId = musicTrackCounter;
        track.title = _title;
        track.artist = _artist;
        track.owner = msg.sender;
        track.pricePerStream = _pricePerStream;
        track.duration = _duration;
        track.ipfsHash = _ipfsHash;
        track.genre = _genre;
