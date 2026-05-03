const hre = require("hardhat");

async function main() {
  const [buyer] = await hre.ethers.getSigners();
  
  const Marketplace = await hre.ethers.getContractFactory("GreenMarketplace");
  const marketplace = await Marketplace.attach(process.env.MARKETPLACE_ADDRESS);
  
  // Buy credits from listing #1
  await marketplace.buyCredits(1, 100, {
    value: ethers.parseEther("1"),
  });
  
  console.log("Bought 100 credits");
}

main();
