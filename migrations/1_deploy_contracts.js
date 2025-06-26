// migrations/1_deploy_contracts.js
const Migrations = artifacts.require("Migrations");
const USDTF = artifacts.require("USDTF");

module.exports = function (deployer) {
  deployer.deploy(Migrations);
  deployer.deploy(USDTF);
};
