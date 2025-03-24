import { ethers } from "ethers";
import * as dotenv from "dotenv";
import * as fs from "fs";

dotenv.config();

// Load environment variables
const sepoliaRpc = process.env.Arbitrum_SEPOLIA_RPC;
const liberichainRpc = process.env.LIBERICHAIN_RPC;
const userPrivateKey = process.env.SOLVER_PRIVATE_KEY;
const intentSenderAddress = process.env.INTENT_SENDER_ADDRESS;
const liberichainTokenAddress = process.env.MTK_TOKEN_ADDRESS;

if (!sepoliaRpc || !liberichainRpc || !userPrivateKey || !intentSenderAddress || !liberichainTokenAddress) {
    throw new Error("Missing required environment variables.");
}

// Setup providers and wallets
const sepoliaProvider = new ethers.JsonRpcProvider(sepoliaRpc);
const liberichainProvider = new ethers.JsonRpcProvider(liberichainRpc);
const wallet = new ethers.Wallet(userPrivateKey);
const sepoliaWallet = wallet.connect(sepoliaProvider);
const liberichainWallet = wallet.connect(liberichainProvider);

// Load ABI for IntentSender contract
const intentSenderABI = JSON.parse(fs.readFileSync("contract/IntentSender.json", "utf8")).abi;
const intentSenderContract = new ethers.Contract(intentSenderAddress, intentSenderABI, sepoliaWallet);

// Load ERC20 ABI
const erc20ABI = [
    "function transfer(address to, uint256 amount) external returns (bool)",
    "function balanceOf(address account) external view returns (uint256)"
];

const tokenContract = new ethers.Contract(liberichainTokenAddress, erc20ABI, liberichainWallet);

// Function to send tokens on LiberiChain
async function sendTokens(user: string, amount: bigint) {
    try {
        const balance = await tokenContract.balanceOf(liberichainWallet.address);
        if (balance < amount) {
            console.error("Insufficient balance in solver wallet on LiberiChain.");
            return;
        }

        console.log(`Sending ${amount} tokens to ${user} on LiberiChain...`);
        const tx = await tokenContract.transfer(user, amount);
        await tx.wait();
        console.log(`Tokens sent successfully: ${tx.hash}`);
    } catch (error) {
        console.error("Error sending tokens:", error);
    }
}

// Function to listen for intents with polling
async function listenForIntents() {
    console.log("Bot solver is running and listening for intents...");

    let lastBlock = await sepoliaProvider.getBlockNumber();

    setInterval(async () => {
        try {
            const latestBlock = await sepoliaProvider.getBlockNumber();
            if (latestBlock > lastBlock) {
                const events = await sepoliaProvider.getLogs({
                    address: intentSenderAddress,
                    fromBlock: lastBlock + 1,
                    toBlock: latestBlock,
                    topics: [ethers.id("IntentSubmitted(uint256,tuple)")],
                });

                for (const event of events) {
                    const decodedEvent = intentSenderContract.interface.parseLog(event);
                    if (!decodedEvent) {
                        console.error("Failed to decode event log.");
                        return;
                    }
                    const intent = decodedEvent.args[1]; // Sekarang aman                    

                    console.log("New intent detected:", intent);

                    if (intent.destinationChainId !== BigInt(1614990)) {
                        console.log("Intent is not for LiberiChain, ignoring...");
                        continue;
                    }

                    // Execute token transfer on LiberiChain
                    await sendTokens(intent.user, intent.minReceived);
                }

                lastBlock = latestBlock;
            }
        } catch (error) {
            console.error("Error fetching events:", error);
        }
    }, 5000); // Polling setiap 5 detik
}

// Start bot solver
listenForIntents();
