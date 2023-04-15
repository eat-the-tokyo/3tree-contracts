import { expect } from "chai";
import { ethers } from "hardhat";
import { Escrow } from "../typechain-types";

import { Escrow__factory } from "../typechain-types";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

describe("Escrow",  function () {
  let escrow: Escrow;
  // eslint-disable-next-line camelcase
  let Escrow: Escrow__factory;

  let admin: SignerWithAddress;
  let addr1: SignerWithAddress;
  let addr2: SignerWithAddress;

  before("Deploy", async function () {
    [admin, addr1, addr2] = await ethers.getSigners();

    Escrow = await ethers.getContractFactory("Escrow");

    //
    escrow = await Escrow.deploy();

    await escrow.deployed();
  });

  describe("Deployment", function () {
    it("Should be deployed with right roles", async function () {
      const roleTx = await escrow.hasRole((await escrow.RELAYER_ROLE()), admin.address);
      expect(roleTx).to.be.true;
    });
  });

  // Test createEscrowFromHotWallet
  describe("createEscrowFromHotWallet", function () {
    it("Should create a new escrow", async function () {
      const initialBalance = await addr1.getBalance();
      const amount = ethers.utils.parseEther("1");
      const expiration = Date.now() + 60 * 60 * 1000; // 1 hour from now

      const tx = await escrow.connect(addr1).createEscrowFromHotWallet("senderSnsId", "hash", ethers.constants.AddressZero, amount, expiration, "wrapperType", { value: amount });

      const escrowData = await escrow.escrows(0);

      expect(escrowData.sender).to.equal(addr1.address);
      expect(escrowData.senderSnsId).to.equal("senderSnsId");
      expect(escrowData.receiver).to.equal(ethers.constants.AddressZero);
      expect(escrowData.receiverSnsId).to.equal("");
      expect(escrowData.hash).to.equal("hash");
      expect(escrowData.amount).to.equal(amount);
      expect(escrowData.tokenAddress).to.equal(ethers.constants.AddressZero);
      expect(escrowData.expiration).to.equal(expiration);
      expect(escrowData.isActive).to.equal(true);
      expect(escrowData.isClaimed).to.equal(false);
      expect(escrowData.wrapperType).to.equal("wrapperType");
      expect(escrowData.transactionType).to.equal(0); // FROM_HOTWALLET

      const newBalance = await addr1.getBalance();
      expect(newBalance).to.be.closeTo(initialBalance.sub(amount),  ethers.utils.parseEther("0.01"));
    });
  });


  // more tests for 1.0 coverage

});
