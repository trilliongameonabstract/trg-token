import { HardhatUserConfig } from "hardhat/config";
import"@nomicfoundation/hardhat-toolbox";
import "@matterlabs/hardhat-zksync";
import "dotenv/config"; 

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.24",
  },
  zksolc: {
    version: "1.5.15",
    settings: {
      optimizer: {
        enabled: true
      },
      codegen: "evmla" // 🔧 EVM legacy assembly for compatibility
    },
  },
  defaultNetwork: "abstractTestnet",
  networks: {
    abstractTestnet: {
      url: "https://api.testnet.abs.xyz",
      ethNetwork: "sepolia",
      zksync: true,
      chainId: 11124,
      accounts: [process.env.PRIVATE_KEY!],
    },
    abstractMainnet: {
      url: "https://api.mainnet.abs.xyz",
      ethNetwork: "mainnet",
      zksync: true,
      chainId: 2741,
      accounts: [process.env.PRIVATE_KEY!],
    },
  },
  etherscan: {
    apiKey: {
      abstractTestnet: process.env.ABSTRACTSCAN_API_KEY || "",
      abstractMainnet: process.env.ABSTRACTSCAN_API_KEY || "",
    },
    customChains: [
      {
        network: "abstractTestnet",
        chainId: 11124,
        urls: {
          apiURL: "https://api-sepolia.abscan.org/api",
          browserURL: "https://sepolia.abscan.org/",
        },
      },
      {
        network: "abstractMainnet",
        chainId: 2741,
        urls: {
          apiURL: "https://api.abscan.org/api",
          browserURL: "https://abscan.org/",
        },
      },
    ],
  },
};

export default config;
