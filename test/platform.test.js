const { sig } = require("./utils");
const TokenBucket = artifacts.require("TokenBucket.sol");
const MustToken = artifacts.require("MustToken.sol");
const Burner = artifacts.require("Burner.sol");

contract("Platform", ([owner, minter, buyer, agent]) => {
  let token, bucket, burner;
  before(async () => {
    token = await MustToken.deployed();
    bucket = await TokenBucket.deployed();
    burner = await Burner.deployed();
  });
  describe("Setup", () => {
    it("should have proper rights", async () => {
      assert.isTrue(await token.isOwner(owner));
      assert.isTrue(await bucket.isOwner(owner));
      assert.isTrue(await bucket.isMinter(minter));
    });

    it("should mint tokens to buyer", async () => {
      const available = await bucket.availableRate();
      await bucket.mint(buyer, available, sig(minter));
      assert.equal(available.toNumber(), await token.balanceOf(buyer));
    });

    it("should finalize contracts", async () => {
      await token.saneIt(sig(owner));
    });

    it("should transfer to agent", async () => {
      const balance = await token.balanceOf(buyer);
      await token.transfer(agent, balance.div(2), sig(buyer));
    });
  });
});
