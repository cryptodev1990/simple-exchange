const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");

describe("Lock", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  it("Deploy & Deposit", async function () {
    // const [owner] = await ethers.getSigner();
     const Contract = await ethers.getContractFactory("GSwap");
     const contract = await Contract.deploy();
     //test deposit function  
    //  const result = await contract.createSwap(
    //   "0x20775d300BdE943Ac260995E977fb915fB01f399",
    //   "0x20775d300BdE943Ac260995E977fb915fB01f399",
    //   1,
    //   2,
    //   2,
    //  );
    const result = await contract.getFee();
     console.log(result)
     //expect(await ethers.provider.getBalance(roiContract.address)).to.equal(ethers.utils.parseEther("30"));
   });
});
