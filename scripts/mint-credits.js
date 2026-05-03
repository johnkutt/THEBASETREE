const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  
  const GreenToken = await hre.ethers.getContractFactory("GreenToken");
  const token = await GreenToken.attach(process.env.TOKEN_ADDRESS);
  
  // Mint test credits
  await token.mintWithMetadata(
    deployer.address,
    10000,
    "PROJ-TEST-001",
    "Test Forest Project",
    "Malaysia",
    "REDD+",
    2024,
    "Verra"
  );
  
  console.log("Minted 10,000 test credits");
}

main();
