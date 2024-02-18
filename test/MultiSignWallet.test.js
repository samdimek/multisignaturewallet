// scripts/multisig-test.js
const { expect } = require("chai");

describe("OurWallet", function () {
  let OurWallet;
  let ourWallet;
  let owner1;
  let owner2;
  let owner3;
  let addr1;
  let addr2;
  let addr3;

  // Before each test, deploy a new instance of the contract && set up owners.
  beforeEach(async function () {
    [owner1, owner2, owner3, addr1, addr2, addr3] = await ethers.getSigners();

    const OurWalletFactory = await ethers.getContractFactory("OurWallet");
    OurWallet = await OurWalletFactory.deploy([owner1.address, owner2.address, owner3.address], 2);
    await OurWallet.deployed();

    ourWallet = OurWallet.connect(owner1);
  });

  // Tests owners can submit transactions.
  

  // Tests owners can approve transactions.
  it("should allow owners to approve transactions", async function () {
    await ourWallet.submit(addr1.address, 100, "0x");
    const tx = await ourWallet.connect(owner2).approve(0);

    await expect(tx).to.emit(OurWallet, "Approve").withArgs(owner2.address, 0);
  });

  // Tests owners can revoke approval
  it("should allow owners to revoke approval", async function () {
    await ourWallet.submit(addr1.address, 100, "0x");
    await ourWallet.connect(owner2).approve(0);
    const tx = await ourWallet.connect(owner2).revoke(0);

    await expect(tx).to.emit(OurWallet, "Revoke").withArgs(owner2.address, 0);
  });

  // Tests that transaction is executed when required number is reached.
  it("should execute transaction when approved by required number of owners", async function () {
    await ourWallet.submit(addr1.address, 100, "0x");
    await ourWallet.connect(owner2).approve(0);

    const tx = await ourWallet.execute(0);

    await expect(tx).to.emit(OurWallet, "Execute").withArgs(0);
  });

  // Tests that non-owners cannot submit transactions
  it("should not allow non-owners to submit transactions", async function () {
    await expect(OurWallet.connect(adrr1).submit(addr2.address, 100, "0x")).to.be.revertedWith("not owner");
  });

  // Test that non-owners cannot approve transaction
  it("should not allow no-owners to approve transactions", async function () {
    await ourWallet.submit(addr1.address, 100, "0x");
    await expect(OurWallet.connect(addr1).approve(0)).to.be.revertedWith("not owner");
  });

  // Test that non-owners cannot revoke approvals
  it("should not allow non-owners to revoke approvals", async function () {
    await ourWallet.submit(addr1.address, 100, "0x");
    await ourWallet.connect(owner2).approve(0);
    await expect(ourWallet.connect(addr1).revoke(0)).to.be.revertedWith("not owner");
  });

  // Tests that double approval from the same owner is not allowed.
  it("should not allow double approval from a single owner", async function () {
    await ourWallet.submit(addr1.address, 100, "0x");
    await ourWallet.connect(owner2).approve(0);
    await expect(ourWallet.connect(owner2).approve(0)).to.be.revertedWith("Txt already approved");
  });

  // Tests that execution of already executed transaction is not allowed.
  it("should not allow execution of an already executed transaction", async function () {
    await ourWallet.submit(addr1, 100, "0x");
    await ourWallet.connect(owner2).approve(0);
    await ourWallet.execute(0);
    await expect(ourWallet.execute(0)).to.be.revertedWith("Transaction already executed!");
  });

  // Tests for gas optimization.
  it("should optimize gas fees by using minimal approvals", async function () {
    // Submitting transaction
    await ourWallet.submit(addr1.address, 100, "0x");

    // check gas fees for executing 2 approvals
    const txt1 = await ourWallet.connect(owner2).approve(0);
    const receipt1 = await txt.wait();
    const gasCost1 = receipt1.gasUsed;

    // check gas fees for executing 3 approvals
    const txt2 = await ourWallet.connect(owner3).approve(0);
    const receipt2 = await txt.wait();
    const gasCost2 = receipt2.gasUsed;

    // ansures gas fees on 2 approvals is lower than with 3 approvals
    expect(gasCost1).to.be.lessThan(gasCost2);
  });
});
