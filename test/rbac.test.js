import { sig } from "./utils";
import expectThrow from "zeppelin-solidity/test/helpers/expectThrow";
const RBACMixin = artifacts.require("RBACMixin.sol");

contract("RBAC Mixin", ([owner, stranger, another]) => {
  describe("RBAC", () => {
    let rbac;
    before(async () => {
      rbac = await RBACMixin.new(sig(owner));
    });

    it("creator should have exclusive roles", async () => {
      assert.isTrue(
        await rbac.isOwner(owner),
        "Creator have no exclusive rights after creation"
      );
    });

    it("stranger should haven't any roles", async () => {
      assert.isFalse(
        await rbac.isOwner(stranger),
        "Stranger have owner rights"
      );
      assert.isFalse(
        await rbac.isMinter(stranger),
        "Stranger have owner rights"
      );
    });

    it("creator should have a rights to grant mint role", async () => {
      await rbac.addMinter(stranger, sig(owner));
      assert.isTrue(await rbac.isMinter(stranger));
      assert.isFalse(await rbac.isOwner(stranger));
    });

    it("stranger should haven't access to grant roles", async () => {
      await expectThrow(rbac.addMinter(another, sig(another)));
      await expectThrow(rbac.addOwner(another, sig(another)));
    });

    it("minter should haven't access to grant roles", async () => {
      await expectThrow(rbac.addMinter(another, sig(stranger)));
      await expectThrow(rbac.addOwner(another, sig(stranger)));
    });

    it("owner should have access to grant owner role", async () => {
      await rbac.addOwner(another, sig(owner));
      assert.isTrue(await rbac.isOwner(another));
    });

    it("new admin should have rights to remove previous", async () => {
      await rbac.removeOwner(owner, sig(another));
      assert.isFalse(await rbac.isOwner(owner), "Owner still has some roles");
    });

    it("admin should have right to remove minter", async () => {
      assert.isTrue(await rbac.isOwner(another));
      assert.isTrue(await rbac.isMinter(stranger));
      await rbac.removeMinter(stranger, sig(another));
    });
  });
});
