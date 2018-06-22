// const web3 = require("web3");
const TokenBucket = artifacts.require("TokenBucket.sol");
const MustToken = artifacts.require("MustToken.sol");
const Burner = artifacts.require("Burner.sol");

module.exports = async function(deployer, network, [owner, minter]) {
  await deployer.then(async () => {
    const rate = 5000 * 10e8;
    const size = 300000 * 10e8;
    await deployer.deploy(MustToken);
    await deployer.deploy(TokenBucket, MustToken.address, size, rate);
    await deployer.deploy(Burner);

    const token = await MustToken.deployed();
    const bucket = await TokenBucket.deployed();

    token.addMinter(bucket.address);
    bucket.addMinter(minter);
  });
};
