const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("GreenMarketplace", function () {
  let marketplace;
  let token;
  let owner;
  let seller;
  let buyer;

  beforeEach(async function () {
    [owner, seller, buyer] = await ethers.getSigners();
    
    const GreenToken = await ethers.getContractFactory("GreenToken");
    token = await GreenToken.deploy("GreenToken", "GREEN");
    
    const Marketplace = await ethers.getContractFactory("GreenMarketplace");
    marketplace = await Marketplace.deploy(await token.getAddress(), owner.address, 100);
    
    // Mint some tokens to seller
    await token.mintWithMetadata(seller.address, 10000, "PROJ-001", "Test", "MY", "VCS", 2024, "Verra");
  });

  describe("Listings", function () {
    it("Should create a listing", async function () {
      await token.connect(seller).approve(await marketplace.getAddress(), 1000);
      
      await marketplace.connect(seller).listCredits(1, 1000, ethers.parseEther("0.1"));
      
      const listing = await marketplace.getListing(1);
      expect(listing.seller).to.equal(seller.address);
      expect(listing.amount).to.equal(1000);
    });
  });
});
