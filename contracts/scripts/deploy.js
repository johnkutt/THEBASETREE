const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying with account:", deployer.address);

  const paymentToken = process.env.PAYMENT_TOKEN || deployer.address;
  const admin = process.env.ADMIN_ADDRESS || deployer.address;
  const feeRecipient = process.env.FEE_RECIPIENT || deployer.address;
  const platformFeeBps = process.env.PLATFORM_FEE_BPS || 100;

  console.log("\n=== Deploying TheBaseTree Core ===");

  const GreenToken = await hre.ethers.getContractFactory("GreenToken");
  const greenToken = await GreenToken.deploy("BaseTree Green Credit", "BTGC", admin);
  await greenToken.waitForDeployment();
  console.log("GreenToken deployed:", await greenToken.getAddress());

  const RetirementProofNFT = await hre.ethers.getContractFactory("RetirementProofNFT");
  const proofNFT = await RetirementProofNFT.deploy(admin);
  await proofNFT.waitForDeployment();
  console.log("RetirementProofNFT deployed:", await proofNFT.getAddress());

  const RetirementRegistry = await hre.ethers.getContractFactory("RetirementRegistry");
  const registry = await RetirementRegistry.deploy(
    await greenToken.getAddress(),
    await proofNFT.getAddress(),
    admin
  );
  await registry.waitForDeployment();
  console.log("RetirementRegistry deployed:", await registry.getAddress());

  const GreenMarketplace = await hre.ethers.getContractFactory("GreenMarketplace");
  const marketplace = await GreenMarketplace.deploy(
    paymentToken,
    await greenToken.getAddress(),
    admin,
    platformFeeBps,
    feeRecipient
  );
  await marketplace.waitForDeployment();
  console.log("GreenMarketplace deployed:", await marketplace.getAddress());

  const GreenAgent = await hre.ethers.getContractFactory("GreenAgent");
  const greenAgent = await GreenAgent.deploy(
    await marketplace.getAddress(),
    paymentToken,
    admin
  );
  await greenAgent.waitForDeployment();
  console.log("GreenAgent deployed:", await greenAgent.getAddress());

  console.log("\n=== Setup Roles ===");
  
  await (await greenToken.connect(deployer).grantRole(
    await greenToken.MINTER_ROLE(),
    admin
  )).wait();
  console.log("Granted MINTER_ROLE to admin on GreenToken");

  await (await greenToken.connect(deployer).grantRole(
    await greenToken.RETIRER_ROLE(),
    await marketplace.getAddress()
  )).wait();
  await (await greenToken.connect(deployer).grantRole(
    await greenToken.RETIRER_ROLE(),
    await registry.getAddress()
  )).wait();
  console.log("Granted RETIRER_ROLE to Marketplace and Registry");

  await (await proofNFT.connect(deployer).grantRole(
    await proofNFT.MINTER_ROLE(),
    await registry.getAddress()
  )).wait();
  console.log("Granted MINTER_ROLE to Registry on ProofNFT");

  await (await registry.connect(deployer).grantRole(
    await registry.REGISTRAR_ROLE(),
    admin
  )).wait();
  console.log("Granted REGISTRAR_ROLE to admin on Registry");

  console.log("\n=== Deployment Complete ===");
  console.log("{");
  console.log(`  "greenToken": "${await greenToken.getAddress()}",`);
  console.log(`  "marketplace": "${await marketplace.getAddress()}",`);
  console.log(`  "registry": "${await registry.getAddress()}",`);
  console.log(`  "proofNFT": "${await proofNFT.getAddress()}",`);
  console.log(`  "greenAgent": "${await greenAgent.getAddress()}"`);
  console.log("}");

  if (hre.network.name !== "hardhat") {
    console.log("\nWaiting for block confirmations...");
    await new Promise(r => setTimeout(r, 30000));
    
    try {
      await hre.run("verify:verify", {
        address: await greenToken.getAddress(),
        constructorArguments: ["BaseTree Green Credit", "BTGC", admin],
      });
      console.log("Verified GreenToken");
    } catch (e) {
      console.log("GreenToken verification failed:", e.message);
    }
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
