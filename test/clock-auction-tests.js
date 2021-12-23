const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Clock Auction", function () {
  const transactionCut = 1000;
  const mockAuction = {
    tokenId: 1,
    startingPrice: 2,
    endingPrice: 1,
    duration: 1000,
  };

  async function getNFTContract() {
    const NFToken = await ethers.getContractFactory("MockNFToken");
    const nftoken = await NFToken.deploy();

    const txMint = await nftoken.mint(mockAuction.tokenId);
    await txMint.wait();

    return nftoken;
  }

  async function getAuctionContract() {
    const nftoken = await getNFTContract();
    const ClockAuction = await ethers.getContractFactory("ClockAuction");
    const auction = await ClockAuction.deploy(nftoken.address, transactionCut);
    await auction.deployed();
    await nftoken.setAuctionaddress(auction.address);
    return auction;
  }

  it("Auction should be created", async function () {
    const auction = await getAuctionContract();
    const [, addr1] = await ethers.getSigners();
    const txCreateAuction = await auction.createAuction(
      mockAuction.tokenId,
      mockAuction.startingPrice,
      mockAuction.endingPrice,
      mockAuction.duration,
      addr1.address
    );
    await txCreateAuction.wait();

    expect(await auction.hasAuction(1)).to.equals(true);
  });

  it("Auction should be canceled", async function () {
    const auction = await getAuctionContract();
    const [, addr1] = await ethers.getSigners();

    const txCreateAuction = await auction.createAuction(
      mockAuction.tokenId,
      mockAuction.startingPrice,
      mockAuction.endingPrice,
      mockAuction.duration,
      addr1.address
    );
    await txCreateAuction.wait();

    expect(await auction.hasAuction(1)).to.equals(true);
    const txCancel = await auction
      .connect(addr1)
      .cancelAuction(mockAuction.tokenId);
    await txCancel.wait();

    expect(await auction.hasAuction(1)).to.equals(false);
  });

  it("Auction should be bid", async function () {
    const auction = await getAuctionContract();
    const [, addr1, addr2] = await ethers.getSigners();

    const txCreateAuction = await auction.createAuction(
      mockAuction.tokenId,
      mockAuction.startingPrice,
      mockAuction.endingPrice,
      mockAuction.duration,
      addr1.address
    );
    await txCreateAuction.wait();

    expect(await auction.hasAuction(1)).to.equals(true);

    const txBid = await auction
      .connect(addr2)
      .bid(mockAuction.tokenId, { value: ethers.utils.parseEther("1.5") });

    await txBid.wait();

    expect(await auction.hasAuction(1)).to.equals(false);
  });
});
