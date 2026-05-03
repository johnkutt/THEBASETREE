const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying Inception Framework with account:", deployer.address);

  const thebasetree = process.env.THEBASETREE_ADDRESS || deployer.address;

  console.log("\n=== Phase 1: Deploy Core Modules ===");

  // Deploy InceptionMemory
  const InceptionMemory = await hre.ethers.getContractFactory("InceptionMemory");
  const inceptionMemory = await InceptionMemory.deploy();
  await inceptionMemory.waitForDeployment();
  console.log("✓ InceptionMemory deployed:", await inceptionMemory.getAddress());

  // Deploy AtomicBlonde
  const AtomicBlonde = await hre.ethers.getContractFactory("AtomicBlonde");
  const atomicBlonde = await AtomicBlonde.deploy();
  await atomicBlonde.waitForDeployment();
  console.log("✓ AtomicBlonde deployed:", await atomicBlonde.getAddress());

  // Deploy NuclearFission
  const NuclearFission = await hre.ethers.getContractFactory("NuclearFission");
  const nuclearFission = await NuclearFission.deploy();
  await nuclearFission.waitForDeployment();
  console.log("✓ NuclearFission deployed:", await nuclearFission.getAddress());

  // Deploy DreamWeaver
  const DreamWeaver = await hre.ethers.getContractFactory("DreamWeaver");
  const dreamWeaver = await DreamWeaver.deploy();
  await dreamWeaver.waitForDeployment();
  console.log("✓ DreamWeaver deployed:", await dreamWeaver.getAddress());

  // Deploy ConnectionMatrix
  const ConnectionMatrix = await hre.ethers.getContractFactory("ConnectionMatrix");
  const connectionMatrix = await ConnectionMatrix.deploy();
  await connectionMatrix.waitForDeployment();
  console.log("✓ ConnectionMatrix deployed:", await connectionMatrix.getAddress());

  console.log("\n=== Phase 2: Deploy Orchestrator ===");

  // Deploy Orchestrator
  const InceptionOrchestrator = await hre.ethers.getContractFactory("InceptionOrchestrator");
  const orchestrator = await InceptionOrchestrator.deploy(
    await inceptionMemory.getAddress(),
    await atomicBlonde.getAddress(),
    await nuclearFission.getAddress(),
    await dreamWeaver.getAddress(),
    await connectionMatrix.getAddress(),
    thebasetree
  );
  await orchestrator.waitForDeployment();
  console.log("✓ InceptionOrchestrator deployed:", await orchestrator.getAddress());

  console.log("\n=== Phase 3: Initialize Inception Session ===");

  // Launch initial inception session
  const targetIdea = hre.ethers.keccak256(hre.ethers.toUtf8Bytes("TheBaseTree Green Credit Expansion"));
  const tx = await orchestrator.launchInception(targetIdea, 3, 2000);
  const receipt = await tx.wait();
  
  // Parse event to get session ID
  const event = receipt.logs.find(
    log => {
      try {
        const parsed = orchestrator.interface.parseLog(log);
        return parsed && parsed.name === "InceptionLaunched";
      } catch { return false; }
    }
  );
  
  if (event) {
    const parsed = orchestrator.interface.parseLog(event);
    console.log("✓ Initial Inception Session launched:", parsed.args.sessionId.toString());
    console.log("  - Dream Level:", parsed.args.dreamLevel.toString());
    console.log("  - Target Idea:", parsed.args.targetIdea);
  }

  console.log("\n=== Inception Framework Deployment Complete ===");
  console.log("{");
  console.log(`  "inceptionMemory": "${await inceptionMemory.getAddress()}",`);
  console.log(`  "atomicBlonde": "${await atomicBlonde.getAddress()}",`);
  console.log(`  "nuclearFission": "${await nuclearFission.getAddress()}",`);
  console.log(`  "dreamWeaver": "${await dreamWeaver.getAddress()}",`);
  console.log(`  "connectionMatrix": "${await connectionMatrix.getAddress()}",`);
  console.log(`  "orchestrator": "${await orchestrator.getAddress()}"`);
  console.log("}");

  // Verify contracts if on testnet/mainnet
  if (hre.network.name !== "hardhat") {
    console.log("\nWaiting for block confirmations...");
    await new Promise(r => setTimeout(r, 30000));
    
    const contracts = [
      { name: "InceptionMemory", address: await inceptionMemory.getAddress() },
      { name: "AtomicBlonde", address: await atomicBlonde.getAddress() },
      { name: "NuclearFission", address: await nuclearFission.getAddress() },
      { name: "DreamWeaver", address: await dreamWeaver.getAddress() },
      { name: "ConnectionMatrix", address: await connectionMatrix.getAddress() },
      { name: "InceptionOrchestrator", address: await orchestrator.getAddress(), 
        args: [await inceptionMemory.getAddress(), await atomicBlonde.getAddress(), 
               await nuclearFission.getAddress(), await dreamWeaver.getAddress(),
               await connectionMatrix.getAddress(), thebasetree] },
    ];

    for (const contract of contracts) {
      try {
        await hre.run("verify:verify", {
          address: contract.address,
          constructorArguments: contract.args || [],
        });
        console.log(`✓ Verified ${contract.name}`);
      } catch (e) {
        console.log(`✗ Failed to verify ${contract.name}:`, e.message);
      }
    }
  }

  console.log("\n=== Next Steps ===");
  console.log("1. Fund the fission cores with energy");
  console.log("2. Dreamify existing credits through the orchestrator");
  console.log("3. Trigger cascades for exponential growth");
  console.log("4. Monitor matrix connections and resonances");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
