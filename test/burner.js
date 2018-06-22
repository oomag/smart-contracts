import { sig } from "./utils";
import { timeTravelTo } from "./utils";
const Burner = artifacts.require("Burner.sol");
const ERC223TokenBurnerMock = artifacts.require("ERC223TokenBurnerMock.sol");

contract("Burner", function ([owner, stranger, another]) {
  let burner, token;
  let blockNumber = 0;

  before(async () => {
    burner = await Burner.new(sig(owner));
    token = await ERC223TokenBurnerMock.new(sig(owner));
    await token.setReceiver(burner.address);
  });

  async function verifyDiscount(date, expectedDiscount) {
    await timeTravelTo(date);
    let tx = await token.triggerFallback(stranger, 42, 0);
    let burnEvent = burner.Burn({}, {fromBlock: blockNumber, toBlock: 'latest'});
    async function filterEvents() {
      return new Promise(function (resolve, reject) {
        burnEvent.get((error, logs) => {
            if (error) {
                reject(error);
            } else {
                resolve(logs);
            }
          })
      })
    }
    let txs = await filterEvents();
    assert.equal(txs[0].args.discount.toNumber(), expectedDiscount, "discount should be equal");
    blockNumber = web3.eth.blockNumber + 1;
  }

  it("in October 2018 discount should be 50", async () => {
      await verifyDiscount("2018-10-07", 50);
  });

  it("in November 2019 discount should be 75", async () => {
      await verifyDiscount("2019-11-07", 75);
  });

  it("in August 2020 discount should be 80", async () => {
      await verifyDiscount("2020-08-07", 80);
  });

  it("in July 2021 discount should be 90", async () => {
      await verifyDiscount("2021-08-07", 90);
  });

  it("in Decemember 2022 discount should be 95", async () => {
      await verifyDiscount("2022-08-07", 95);
  });

});
