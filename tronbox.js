require('dotenv').config();

module.exports = {
  networks: {
    development: {
      privateKey: process.env.PRIVATE_KEY,
      userFeePercentage: 30,
      feeLimit: 1e9,
      fullHost: "http://127.0.0.1:9090",
      network_id: "*"
    },
    nile: {
      privateKey: process.env.PRIVATE_KEY,
      userFeePercentage: 30,
      feeLimit: 1e9,
      fullHost:"https://nile.trongrid.io",
      network_id: "*"
    }
  },
  compilers: {
    solc: {
      version: "0.5.10"
    }
  }
};
