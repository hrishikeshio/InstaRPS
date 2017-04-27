var CryptoRPS = artifacts.require('./Crypto_RPS.sol')

module.exports = function (deployer) {
  deployer.deploy(CryptoRPS)
}
