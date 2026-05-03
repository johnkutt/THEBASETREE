const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("GreenToken", function () {
  let GreenToken;
  let token;
  let owner;
  let addr1;
  let addr2;

  beforeEach(async function () {
    [owner, addr1, addr2] = await ethers.getSigners();
    GreenToken = await ethers.getContractFactory("GreenToken");
    token = await GreenToken.deploy("GreenToken", "GREEN");
    await token.waitForDeployment();
  });

  describe("Deployment", function () {
    it("Should set the right name and symbol", async function () {
      expect(await token.name()).to.equal("GreenToken");
      expect(await token.symbol()).to.equal("GREEN");
    });

    it("Should assign the total supply to owner", async function () {
      const ownerBalance = await token.balanceOf(owner.address);
      expect(await token.totalSupply()).to.equal(ownerBalance);
    });
  });

  describe("Minting", function () {
    it("Should mint with metadata", async function () {
      await token.mintWithMetadata(
        addr1.address,
        1000,
        "PROJ-001",
        "Forest Project",
        "Malaysia",
        "REDD+",
        2024,
        "VCS"
      );
      
      expect(await token.balanceOf(addr1.address)).to.equal(1000);
    });
  });
});
