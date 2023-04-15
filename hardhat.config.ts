import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import "@typechain/hardhat";
import "solidity-coverage";

// import * as dotenv from "dotenv";

import { HardhatUserConfig } from "hardhat/config";

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.9",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1000000,
      },
      metadata: {
        bytecodeHash: "none",
      },
    },
  },
  networks : {
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
