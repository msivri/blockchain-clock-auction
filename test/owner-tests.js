const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Owner Test", function () {
  it("Should transfer ownership if owner contract", async function () {
    const Ownable = await ethers.getContractFactory("Ownable");
    const ownable = await Ownable.deploy();
    await ownable.deployed();

    const [owner, addr1] = await ethers.getSigners();

    const tx = await ownable.transferOwnership(addr1.address);

    // wait until the transaction is mined
    await tx.wait();

    expect(await ownable.getOwner()).to.equal(addr1.address);
    expect(await ownable.getOwner()).to.not.equal(owner.address);
  });

  it("Should not transfer ownership if owner is not contract", async function () {
    const Ownable = await ethers.getContractFactory("Ownable");
    const ownable = await Ownable.deploy();
    await ownable.deployed();

    const [, addr1] = await ethers.getSigners();

    // eslint-disable-next-line no-unused-expressions
    expect(ownable.connect(addr1).transferOwnership(addr1.address)).to.be
      .reverted;
  });
});
