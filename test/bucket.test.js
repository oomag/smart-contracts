import { sig } from "./utils";
import expectThrow from "zeppelin-solidity/test/helpers/expectThrow";
import increaseTime, {
  duration
} from "zeppelin-solidity/test/helpers/increaseTime";
const SolidityCoder = require("web3/lib/solidity/coder.js");
const TokenBucket = artifacts.require("TokenBucket.sol");
const MustToken = artifacts.require("MustToken.sol");

contract("TokenBucket", ([owner, minter, first, second, third, fourth]) => {
  let bucket, token, size, rate;
  before(async () => {
    // 5k tokens per second
    rate = 5000 * 10e8;
    // 300k tokens per second (1 minute to fullfil)
    size = 300000 * 10e8;
    token = await MustToken.new();
    bucket = await TokenBucket.new(token.address, size, rate);
    await token.addMinter(bucket.address);
    await bucket.addMinter(minter);
  });

  describe("Calculation", () => {
    it("should have full size at start", async () => {
      assert.equal(
        size.toString(),
        (await bucket.availableRate()).toString(10)
      );
    });

    it("should decrease available after mint", async () => {
      await bucket.mint(first, 1000000);
      const available = await bucket.availableRate();
      assert.isAbove(size, available.toNumber());
    });

    it("should return available after time", async () => {
      const availableAtBegin = await bucket.availableRate();
      await bucket.mint(second, availableAtBegin);
      const availableAfterMint = await bucket.availableRate();
      assert.equal(
        0,
        availableAfterMint,
        "Available amount to mint isn't zero after mint"
      );
      await increaseTime(duration.hours(1));
      const availableAfterTime = await bucket.availableRate();
      assert.equal(
        size,
        availableAfterTime,
        "After minute available hasn't achived size"
      );
    });
  });

  describe("Administration", () => {
    it("should reject changes from strangers", async () => {
      await Promise.all(
        [first, second].map(async account => {
          await expectThrow(bucket.setSize(size + size, sig(account)));
          await expectThrow(bucket.setRate(rate + rate, sig(account)));
          await expectThrow(
            bucket.setSizeAndRate(size + size, rate + rate, sig(account))
          );
        })
      );
    });

    it("should reject changes from minter", async () => {
      await expectThrow(bucket.setSize(size + size, sig(minter)));
      await expectThrow(bucket.setRate(rate + rate, sig(minter)));
      await expectThrow(
        bucket.setSizeAndRate(size + size, rate + rate, sig(minter))
      );
    });

    it("should allow owner to change settings", async () => {
      await bucket.setRate(rate + rate, sig(owner));
      await bucket.setSize(size + size, sig(owner));
      await bucket.setSizeAndRate(size + size, rate + rate, sig(owner));
    });

    it("reject minting from strangers", async () => {
      await Promise.all(
        [first, second].map(async account => {
          const available = await bucket.availableRate();
          assert.isBelow(0, available, "Bucket is dry");
          await expectThrow(bucket.mint(account, available, sig(account)));
        })
      );
    });

    it("allow minter to mint", async () => {
      await bucket.mint(first, 1, sig(minter));
    });
  });

  describe("Minting", () => {
    before(async () => {
      // remove side effects
      // 5k tokens per second
      rate = 5000 * 10e8;
      // 300k tokens per second (1 minute to fullfil)
      size = 300000 * 10e8;
      token = await MustToken.new();
      bucket = await TokenBucket.new(token.address, size, rate);
      await token.addMinter(bucket.address);
      await bucket.addMinter(minter);
    });

    it("should fire Mint in token", async () => {
      const tx = await bucket.mint(first, 1000, sig(minter));

      var abis = MustToken.abi;

      const knownEvents = abis.reduce((acc, abi) => {
        if (abi.type == "event") {
          var signature =
            abi.name + "(" + _.map(abi.inputs, "type").join(",") + ")";
          acc[web3.sha3(signature)] = {
            signature: signature,
            abi_entry: abi
          };
        }
        return acc;
      }, {});

      const parsedLogs = tx.receipt.logs.map(rawLog => {
        const event = knownEvents[rawLog.topics[0]];

        if (typeof event === "undefined") {
          return null;
        }

        const types = event.abi_entry.inputs
          .map(function(input) {
            return input.indexed == true ? null : input.type;
          })
          .filter(function(type) {
            return type != null;
          });

        const values = SolidityCoder.decodeParams(
          types,
          rawLog.data.replace("0x", "")
        );

        let index = 0;

        return {
          event: event.abi_entry.name,
          args: event.abi_entry.inputs.reduce((acc, input) => {
            acc[input.name] = input.indexed ? "indexed" : values[index++];
            return acc;
          }, {})
        };
      });

      const mintEvents = parsedLogs.filter(log => log.event === "Mint");
      assert.isBelow(0, mintEvents.length, "Mint event not found");
      assert.equal(1000, mintEvents[0].args.amount, "Mint value isn't same");
    });

    it("should increase total supply", async () => {
      const totalBefore = await token.totalSupply();
      await bucket.mint(first, 1000, sig(minter));
      const totalAfter = await token.totalSupply();

      assert.equal(
        1000,
        totalAfter.sub(totalBefore),
        "Total isn't same as minter amount"
      );
    });

    it("should increase balance of beneficiar", async () => {
      const balanceBefore = await token.balanceOf(first);
      await bucket.mint(first, 1000, sig(minter));
      const balanceAfter = await token.balanceOf(first);

      assert.equal(
        1000,
        balanceAfter.sub(balanceBefore),
        "Balance has increased on incorrect amount"
      );
    });
  });
});
