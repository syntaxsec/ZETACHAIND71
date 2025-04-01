const hre = require("hardhat");
const fs = require("fs");
const path = require("path");

// for testing in localnet:
// npx hardhat run scripts/deploy_all.js --network localhost

// npx hardhat compile --force ; npx hardhat run scripts/deploy_all.js --network localhost    
// npx hardhat callBaseSepolia --network localhost --nftreceiver 0xF93EfaF39040BA4C32271E3256B8847fD94386DF

async function main() {
  console.log("Starting deployment process...");
  
  // more details: https://www.zetachain.com/docs/reference/network/contracts/
  // const GATEWAY_ADDRESSES = {
  //   baseSepolia: "0x0c487a766110c85d301d96e33579c5b317fa4995",
  //   zetachain: "0x6c533f7fe93fae114d0954697069df33c9b74fd7", 
  //   sepolia: "0x0c487a766110c85d301d96e33579c5b317fa4995"  
  // };
  GATEWAY_ADDRESSES = {
    baseSepolia: "0xA51c1fc2f0D1a1b8494Ed1FE312d7C3a78Ed91C0",
    zetachain: "0x5FC8d32690cc91D4c39d9d3abcBD16989F875707", 
    sepolia: "0xA51c1fc2f0D1a1b8494Ed1FE312d7C3a78Ed91C0"  
  };
  
  const deploymentInfo = {};

  const [signer] = await hre.ethers.getSigners();
  if (signer === undefined) {
    throw new Error(
      `Wallet not found. Please, run "npx hardhat account --save" or set PRIVATE_KEY env variable (for example, in a .env file)`
    );
  }
  
  
  console.log("Deploying Sepolia contract...");
  const sepoliaFactory = await hre.ethers.getContractFactory("SepoliaContract");
  const sepoliaContract = await sepoliaFactory.deploy(GATEWAY_ADDRESSES.sepolia);
  await sepoliaContract.deployed();
  console.log(`Sepolia contract deployed to: ${sepoliaContract.address}`);
  deploymentInfo.sepolia = sepoliaContract.address;
  
  console.log("Deploying ZetaChain contract...");
  const zetaChainFactory = await hre.ethers.getContractFactory("ZetaChainContract");
  const zetaChainContract = await zetaChainFactory.deploy(
    GATEWAY_ADDRESSES.zetachain,
    deploymentInfo.sepolia
  );
  await zetaChainContract.deployed();
  console.log(`ZetaChain contract deployed to: ${zetaChainContract.address}`);
  deploymentInfo.zetachain = zetaChainContract.address;
  
  console.log("Deploying Base Sepolia contract...");
  const baseSepoliaFactory = await hre.ethers.getContractFactory("BaseSepoliaContract");
  const baseSepoliaContract = await baseSepoliaFactory.deploy(
    GATEWAY_ADDRESSES.baseSepolia,
    deploymentInfo.zetachain
  );
  await baseSepoliaContract.deployed();
  console.log(`Base Sepolia contract deployed to: ${baseSepoliaContract.address}`);
  deploymentInfo.baseSepolia = baseSepoliaContract.address;
  
  // Save deployment info to a file
  const deploymentPath = path.join(__dirname, "../deployment-info.json");
  fs.writeFileSync(
    deploymentPath,
    JSON.stringify(deploymentInfo, null, 2)
  );
  console.log(`Deployment information saved to ${deploymentPath}`);
  
  console.log("All contracts deployed successfully!");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });