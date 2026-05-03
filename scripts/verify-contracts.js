const hre = require("hardhat");

async function main() {
  const addresses = {
    GreenToken: process.env.GREEN_TOKEN_ADDRESS,
    GreenMarketplace: process.env.MARKETPLACE_ADDRESS,
    RetirementRegistry: process.env.REGISTRY_ADDRESS,
  };

  for (const [name, address] of Object.entries(addresses)) {
    if (address) {
      try {
        await hre.run("verify:verify", {
          address,
          constructorArguments: [],
        });
        console.log(`Verified ${name} at ${address}`);
      } catch (e) {
        console.error(`Failed to verify ${name}:`, e.message);
      }
    }
  }
}

main();
