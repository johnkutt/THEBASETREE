const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  
  // Fund test wallets
  const testWallets = [
    "0x...",
    "0x...",
  ];
  
  for (const wallet of testWallets) {
    await deployer.sendTransaction({
      to: wallet,
      value: hre.ethers.parseEther("0.1"),
    });
    console.log(`Funded ${wallet}`);
  }
}

main();
