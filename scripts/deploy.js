const { ethers } = require("hardhat");

async function main() {
  console.log("Starting deployment to Core Testnet 2...");
  
  // Get the deployer account
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with account:", deployer.address);
  
  // Check deployer balance
  const balance = await deployer.getBalance();
  console.log("Account balance:", ethers.utils.formatEther(balance), "ETH");
  
  // For demo purposes, we'll need to deploy mock ERC20 tokens first
  // In a real scenario, you would use existing token addresses
  
  console.log("\nDeploying Mock ERC20 tokens...");
  
  // Deploy Mock Lending Token (e.g., USDC)
  const MockToken = await ethers.getContractFactory("MockERC20");
  console.log("Deploying Mock USDC token...");
  
  const mockUSDC = await MockToken.deploy("Mock USDC", "mUSDC", 18, ethers.utils.parseEther("1000000"));
  await mockUSDC.deployed();
  console.log("Mock USDC deployed to:", mockUSDC.address);
  
  // Deploy Mock Collateral Token (e.g., WBTC)
  console.log("Deploying Mock WBTC token...");
  const mockWBTC = await MockToken.deploy("Mock WBTC", "mWBTC", 18, ethers.utils.parseEther("1000000"));
  await mockWBTC.deployed();
  console.log("Mock WBTC deployed to:", mockWBTC.address);
  
  // Now deploy the main lending platform contract
  console.log("\nDeploying Decentralized Lending Platform...");
  const Project = await ethers.getContractFactory("Project");
  
  const project = await Project.deploy(mockUSDC.address, mockWBTC.address);
  await project.deployed();
  
  console.log("Decentralized Lending Platform deployed to:", project.address);
  console.log("Lending Token (Mock USDC):", mockUSDC.address);
  console.log("Collateral Token (Mock WBTC):", mockWBTC.address);
  
  // Verify deployment by checking contract details
  const lendingToken = await project.lendingToken();
  const collateralToken = await project.collateralToken();
  const owner = await project.owner();
  
  console.log("\nContract Verification:");
  console.log("Lending Token Address:", lendingToken);
  console.log("Collateral Token Address:", collateralToken);
  console.log("Contract Owner:", owner);
  
  // Save deployment info
  const deploymentInfo = {
    network: "core_testnet_2",
    chainId: 1115,
    deployer: deployer.address,
    contracts: {
      lendingPlatform: project.address,
      mockUSDC: mockUSDC.address,
      mockWBTC: mockWBTC.address
    },
    deploymentTime: new Date().toISOString()
  };
  
  console.log("\n=== Deployment Summary ===");
  console.log(JSON.stringify(deploymentInfo, null, 2));
  
  console.log("\n=== Next Steps ===");
  console.log("1. Save the contract addresses for frontend integration");
  console.log("2. Fund your account with some mock tokens for testing");
  console.log("3. Interact with the contract using the provided addresses");
  console.log("4. Consider verifying the contracts on block explorer if available");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Deployment failed:", error);
    process.exit(1);
  });
