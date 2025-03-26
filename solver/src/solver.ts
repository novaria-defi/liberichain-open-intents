import { ethers } from 'ethers';
import dotenv from 'dotenv';
import fs from 'fs';
import path from 'path';

// Load environment variables
dotenv.config();

interface Intent {
  intentId: string;
  user: string;
  token: string;
  amount: bigint;
  sourceChainId: bigint;
  destinationChainId: bigint;
  deadline: bigint;
  minReceived: bigint;
}

class CrossChainIntentSolver {
  private sourceProvider: ethers.JsonRpcProvider;
  private destProvider: ethers.JsonRpcProvider;
  private intentSenderContract: ethers.Contract;
  private sourceWallet: ethers.Wallet;
  private destWallet: ethers.Wallet;
  private processedIntents: Set<string> = new Set();
  private scanInterval: NodeJS.Timeout | null = null;
  private lastScannedBlock: number = 0;
  private currentProcessingIntent: string | null = null;
  private processingLock: boolean = false;

  // Chain IDs
  private readonly ARBITRUM_SEPOLIA = 421614;
  private readonly LIBERICHAIN = 1614990;

  // Token mapping (Arbitrum Sepolia -> Liberichain)
  private readonly TOKEN_MAPPING: Record<string, string> = {
    "0x4eAC1d777438602D869968371e2fFD6e72F17228": "0x66674b815dEF43A3A32DB2aA0abc26E5603C15ED"
  };

  constructor() {
    // Setup providers
    this.sourceProvider = new ethers.JsonRpcProvider(process.env.SOURCE_CHAIN_RPC_URL!);
    this.destProvider = new ethers.JsonRpcProvider(process.env.DEST_CHAIN_RPC_URL!);

    // Setup wallets
    this.sourceWallet = new ethers.Wallet(process.env.SOLVER_PRIVATE_KEY!, this.sourceProvider);
    this.destWallet = new ethers.Wallet(process.env.SOLVER_PRIVATE_KEY!, this.destProvider);

    // Load IntentSender ABI
    const intentSenderABI = JSON.parse(
      fs.readFileSync(path.resolve(__dirname, "../contract/IntentSender.json"), "utf-8")
    ).abi;

    // Create contract instance
    this.intentSenderContract = new ethers.Contract(
      process.env.INTENT_SENDER_CONTRACT_ADDRESS!,
      intentSenderABI,
      this.sourceWallet
    );
  }

  async start() {
    console.log("🚀 Cross-Chain Intent Solver started!");
    console.log(`🔗 Monitoring IntentSender at ${this.intentSenderContract.target} on Arbitrum Sepolia`);
    console.log(`💸 Will send tokens on Liberichain (${this.LIBERICHAIN})`);
    console.log("⏱️ Scanning every 2 seconds");

    // Get initial block number
    this.lastScannedBlock = await this.sourceProvider.getBlockNumber() - 1;
    console.log(`🔍 Starting scan from block ${this.lastScannedBlock}`);

    // Start polling
    this.startPolling();
  }

  private startPolling() {
    this.scanInterval = setInterval(async () => {
      if (this.processingLock) {
        console.log("⏸️ Solver is processing an intent, skipping scan...");
        return;
      }

      try {
        await this.pollNewBlocks();
      } catch (error) {
        console.error("⚠️ Error during polling:", error);
      }
    }, 2000);
  }

  stop() {
    if (this.scanInterval) {
      clearInterval(this.scanInterval);
      console.log("🛑 Solver stopped");
    }
  }

  private async pollNewBlocks() {
    const currentBlock = await this.sourceProvider.getBlockNumber();
    
    if (currentBlock <= this.lastScannedBlock) {
      console.log("⏭️ No new blocks since last scan");
      return;
    }

    console.log(`🔍 Scanning blocks ${this.lastScannedBlock + 1}-${currentBlock}`);
    await this.checkIntents(this.lastScannedBlock + 1, currentBlock);
    this.lastScannedBlock = currentBlock;
  }

  private async checkIntents(fromBlock: number, toBlock: number) {
    const eventFilter = this.intentSenderContract.filters.IntentSubmitted();
    const events = await this.intentSenderContract.queryFilter(eventFilter, fromBlock, toBlock);

    if (events.length === 0) {
      console.log("⏭️ No new intents found");
      return;
    }

    for (const event of events) {
      if (!(event instanceof ethers.EventLog)) continue;

      const intent = event.args as unknown as Intent;
      
      // Validate chain IDs and check processing status
      if (intent.sourceChainId !== BigInt(this.ARBITRUM_SEPOLIA) || 
          intent.destinationChainId !== BigInt(this.LIBERICHAIN) ||
          this.processedIntents.has(intent.intentId) ||
          this.currentProcessingIntent === intent.intentId) {
        console.log(`⏭️ Skipping intent ${intent.intentId}`);
        continue;
      }

      console.log("\n🎯 New Cross-Chain Intent Detected:");
      console.log(`🆔 Intent ID: ${intent.intentId}`);
      console.log(`👤 User: ${intent.user}`);
      console.log(`💰 Amount: ${ethers.formatEther(intent.amount)} tokens`);
      console.log(`⏱️ Deadline: ${new Date(Number(intent.deadline) * 1000)}`);
      console.log(`📝 Tx hash: ${event.transactionHash}`);

      // Lock processing
      this.currentProcessingIntent = intent.intentId;
      this.processingLock = true;

      try {
        await this.processCrossChainIntent(intent);
        this.processedIntents.add(intent.intentId);
      } catch (error) {
        console.error("⚠️ Error processing intent:", error);
        // Remove from processed if failed
        this.processedIntents.delete(intent.intentId);
      } finally {
        // Release lock
        this.currentProcessingIntent = null;
        this.processingLock = false;
        console.log("🔄 Resuming scanning...");
      }
    }
  }

  private async processCrossChainIntent(intent: Intent) {
    // Double check processing status
    if (this.processingLock && this.currentProcessingIntent !== intent.intentId) {
      console.log("⏭️ Another intent is being processed, skipping...");
      return;
    }

    // Check deadline
    const currentTime = BigInt(Math.floor(Date.now() / 1000));
    if (currentTime > intent.deadline) {
      console.log("❌ Intent expired");
      return;
    }

    // Get corresponding token address on destination chain
    const destToken = this.TOKEN_MAPPING[intent.token];
    if (!destToken) {
      console.log(`❌ No token mapping found for ${intent.token}`);
      return;
    }

    // Create token contract on destination chain
    const tokenAbi = [
      "function balanceOf(address) view returns (uint)",
      "function transfer(address, uint) returns (bool)",
      "function decimals() view returns (uint8)",
      "function symbol() view returns (string)"
    ];
    
    const destTokenContract = new ethers.Contract(
      destToken,
      tokenAbi,
      this.destWallet
    );

    // Check solver balance on destination chain
    const [symbol, decimals, balance] = await Promise.all([
      destTokenContract.symbol(),
      destTokenContract.decimals(),
      destTokenContract.balanceOf(this.destWallet.address)
    ]);

    console.log(`💰 Solver balance on Liberichain: ${ethers.formatUnits(balance, decimals)} ${symbol}`);

    if (balance < intent.amount) {
      console.log("❌ Insufficient balance on destination chain");
      return;
    }

    // Execute cross-chain transfer
    console.log(`🔄 Sending ${ethers.formatUnits(intent.amount, decimals)} ${symbol} to ${intent.user} on Liberichain...`);
    
    const tx = await destTokenContract.transfer(intent.user, intent.amount);
    console.log(`📤 Transaction sent: ${tx.hash}`);

    const receipt = await tx.wait();
    console.log("✅ Transfer completed!");
    console.log(`📝 Tx hash: ${tx.hash}`);
    console.log(`⛽ Gas used: ${receipt?.gasUsed.toString()}`);
    console.log(`🔗 Explorer: https://liberichain.blockscout.com/tx/${tx.hash}`);
  }
}

// Start the solver
const solver = new CrossChainIntentSolver();
solver.start().catch(console.error);

// Graceful shutdown
process.on('SIGINT', () => {
  solver.stop();
  process.exit();
});