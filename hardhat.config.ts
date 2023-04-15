import { HardhatUserConfig } from "hardhat/config";
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import "@typechain/hardhat";
import "solidity-coverage";

import * as dotenv from "dotenv";

dotenv.config();

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.9",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks : {
    goerli: {
      url: `https://goerli.infura.io/v3/12e7deac48dc4dbfb1e4d01316a0dfc4`,
      accounts: [`${process.env.PRIVATE_KEY}`],
      chainId: 5,
    },
    polygon: {
      url: `https://polygon-mumbai.g.alchemy.com/v2/ePBUX7mISjFQKcGgNAGNYrw5hgb7Ufp9`,
      accounts: [`${process.env.PRIVATE_KEY}`],
      chainId: 80001,
    },
    sepolia: {
      url: `https://eth-sepolia.g.alchemy.com/v2/eMVuHbxeov-wKCtwSpKQlZGpBq3RcmoB`,
      accounts: [`${process.env.PRIVATE_KEY}`],
      chainId: 11155111,
    },
    chiado: {
      url: "https://rpc.chiadochain.net",
      gasPrice: 1000000000,
      accounts: [`${process.env.PRIVATE_KEY}`],
      chainId: 10200,
    },
    alfajores: {
      url: "https://alfajores-forno.celo-testnet.org",
      accounts: {
        mnemonic: process.env.MNEMONIC,
        path: "m/44'/52752'/0'/0"
      },
      chainId: 44787
    },
    hardhat: {
      accounts: [
        {
          privateKey: "0x0123456789012345678901234567890123456789012345678901234567890123",
          balance: "1000000000000000000000" // 1000 Ether balance
        },
        {
          privateKey: "0x0123456789012345678901234567890123456789012345678901234567890124",
          balance: "1000000000000000000000" // 1000 Ether balance
        },
        {
          privateKey: "0x0123456789012345678901234567890123456789012345678901234567890125",
          balance: "1000000000000000000000" // 1000 Ether balance
        },
      ],
    },
  }
};

export default config;
