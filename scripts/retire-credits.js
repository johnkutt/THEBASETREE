const hre = require("hardhat");

async function main() {
  const [holder] = await hre.ethers.getSigners();
  
  const GreenToken = await hre.ethers.getContractFactory("GreenToken");
  const token = await GreenToken.attach(process.env.TOKEN_ADDRESS);
  
  // Retire credits
  await token.retire(1, 100, "ipfs://retirement-proof-001");
  
  console.log("Retired 100 credits with proof NFT");
}

main();
