import { Wallet } from "zksync-ethers";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { Deployer } from "@matterlabs/hardhat-zksync";
import { vars } from "hardhat/config";

export default async function (hre: HardhatRuntimeEnvironment) {
  console.log("🚀 Deploying TrillionGame to Abstract Mainnet...");

  const wallet = new Wallet(vars.get("DEPLOYER_PRIVATE_KEY"));
  const deployer = new Deployer(hre, wallet);

  const artifact = await deployer.loadArtifact("TrillionGame");

  const routerMainnet = "0xad1eCa41E6F772bE3cb5A48A6141f9bcc1AF9F7c"; // Abstract mainnet router
  const devWallet = "0x82802d0ADb6105819C2ce7904132A68efD326494";   // Dev fee wallet

  const tokenContract = await deployer.deploy(artifact, [routerMainnet, devWallet]);

  console.log(`✅ ${artifact.contractName} deployed at: ${await tokenContract.getAddress()}`);
  console.log("⚠️ Trading NOT enabled. Token is safe and non-transferable until `enableTrading()` is called.");
}
