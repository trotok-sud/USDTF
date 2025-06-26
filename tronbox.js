require('dotenv').config();

module.exports = {
  networks: {
    shasta: {
      privateKey: process.env.PRIVATE_KEY,
      userFeePercentage: 30,
      feeLimit: 1000000000,
      fullHost: 'https://api.shasta.trongrid.io',
      network_id: '*',
    },
    nile: {
      privateKey: process.env.PRIVATE_KEY,
      userFeePercentage: 30,
      feeLimit: 1000000000,
      fullHost: 'https://api.nileex.io',
      network_id: '*',
    },
    mainnet: {
      privateKey: process.env.PRIVATE_KEY,
      userFeePercentage: 30,
      feeLimit: 1000000000,
      fullHost: 'https://api.trongrid.io',
      network_id: '*',
    }
  },
  compilers: {
    solc: {
      version: '0.5.10'
    }
  }
};




