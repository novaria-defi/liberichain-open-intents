import { ethers } from "ethers";
import dotenv from "dotenv";
import * as fs from "fs";
import * as path from "path";

dotenv.config();

// Load environment variables
const providerUrl = process.env.Arbitrum_SEPOLIA_RPC;
const privateKey = process.env.USER_PRIVATE_KEY;

if (!providerUrl || !privateKey) {
  throw new Error("Missing environment variables. Check .env file.");
}

// Initialize provider & wallet
async function createProvider() {
  try {
    const provider = new ethers.JsonRpcProvider(providerUrl as string);
    await provider.getBlockNumber(); // Cek koneksi RPC
    console.log("✅ Connected to Arbitrum Sepolia RPC successfully.");
    return provider;
  } catch (error) {
    console.error("❌ Failed to connect to RPC:", error);
    process.exit(1);
  }
}

async function main() {
  let intentSenderABI: any;
  
  // Load ABI
  try {
    const abiPath = path.resolve(__dirname, "./contract/IntentSender.json");
    if (!fs.existsSync(abiPath)) {
      throw new Error(`ABI file not found at: ${abiPath}`);
    }
    intentSenderABI = JSON.parse(fs.readFileSync(abiPath, "utf8")).abi;
    console.log("✅ Loaded IntentSender ABI successfully.");
  } catch (error) {
    console.error("❌ Failed to load IntentSender ABI:", error);
    process.exit(1);
  }

  // Setup Provider & Wallet
  const provider = await createProvider();
  const wallet = new ethers.Wallet(privateKey as string, provider);

  // Contract details
  const intentSenderAddress = "0x6d4Df94BF28E5355c6558e2E1C9f9dDAF6Aa5324";
  const intentSenderContract = new ethers.Contract(intentSenderAddress, intentSenderABI, wallet);

  async function submitIntent() {
    try {
      console.log("🚀 Submitting intent transaction...");

      const user = wallet.address;
      const token = "0xcc7C5B8957943659608d3d6116dee8fE18333120"; // Contoh token address
      const amount = ethers.toBigInt(ethers.parseUnits("1", 18));
      const sourceChainId = 421614;
      const destinationChainId = 1614990;
      const deadline = Math.floor(Date.now() / 1000) + 3600;
      const minReceived = ethers.toBigInt(ethers.parseUnits("0.98", 18));

      // Estimasi gas secara dinamis
      const gasLimit = await intentSenderContract.submitIntent.estimateGas([
        user, token, amount, sourceChainId, destinationChainId, deadline, minReceived
      ]);

      // Penyesuaian gas limit dengan operator `bigint`
      const adjustedGasLimit = gasLimit * BigInt(12) / BigInt(10); // Sebelumnya `.mul(1.2)`

      // Ambil harga gas terbaru dari jaringan
      const gasPrice = await provider.getFeeData();
      const maxGasPrice = gasPrice.gasPrice ? gasPrice.gasPrice : ethers.parseUnits("10", "gwei");

      console.log(`⏳ Estimated Gas Limit: ${gasLimit.toString()}`);
      console.log(`⏳ Adjusted Gas Limit: ${adjustedGasLimit.toString()}`);
      console.log(`⛽ Current Gas Price: ${ethers.formatUnits(maxGasPrice, "gwei")} gwei`);

      const tx = await intentSenderContract.submitIntent(
        [user, token, amount, sourceChainId, destinationChainId, deadline, minReceived], 
        { gasLimit: adjustedGasLimit, gasPrice: maxGasPrice }
      );

      console.log("✅ Transaction submitted. Hash:", tx.hash);
      await tx.wait();
      console.log("🎉 Intent successfully submitted!");
    } catch (err) {
      console.error("❌ Failed to submit intent:", err);
    }
  }

  await submitIntent();
}

main();
