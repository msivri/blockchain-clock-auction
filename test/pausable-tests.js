const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Pausable Tests", function () {
  it("Owner should be able to pause/unpause", async function () {
    const Pausable = await ethers.getContractFactory("Pausable");
    const pausable = await Pausable.deploy();
    await pausable.deployed();

    const txPause = await pausable.pause();
    await txPause.wait();

    expect(await pausable.isPaused()).to.equal(true);

    const txUnpause = await pausable.unpause();
    await txUnpause.wait();

    expect(await pausable.isPaused()).to.equal(false);
  });

  it("Should revert if non-owner is trying to pause/unpause", async function () {
    const Pausable = await ethers.getContractFactory("Pausable");
    const pausable = await Pausable.deploy();
    await pausable.deployed();

    const [, addr1] = await ethers.getSigners();

    // eslint-disable-next-line no-unused-expressions
    expect(pausable.connect(addr1).pause()).to.be.reverted;
    // eslint-disable-next-line no-unused-expressions
    expect(pausable.connect(addr1).unpause()).to.be.reverted;
  });
});
