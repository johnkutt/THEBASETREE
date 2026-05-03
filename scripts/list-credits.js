const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  
  const Marketplace = await hre.ethers.getContractFactory("GreenMarketplace");
  const marketplace = await Marketplace.attach(process.env.MARKETPLACE_ADDRESS);
  
  // List credits
  await marketplace.listCredits(1, 1000, ethers.parseEther("0.01"));
  
  console.log("Listed 1000 credits for sale");
}

main();
