import { ethers } from 'ethers';
import { createPublicClient, http, Address } from 'viem';
import dotenv from 'dotenv';
import fs from 'fs';
import path from 'path';

// Load environment variables
dotenv.config();

// Interface untuk Intent
interface Intent {
  user: string;
  token: string;
  amount: bigint;
  sourceChainId: number;
  destinationChainId: number;
  deadline: bigint;
  minReceived: bigint;
  intentId?: string;
}

class IntentBotSolver {
  private sourceChainProvider: ethers.Provider;
  private destChainProvider: ethers.Provider;
  private sourceChainClient: any;
  private destChainClient: any;
  private intentSenderContract: ethers.Contract;
  private intentSettlementContract: ethers.Contract;
  private processedIntents: Set<string> = new Set();
  private hasActiveListener: boolean = false;

  constructor(
    sourceRpcUrl: string, 
    destRpcUrl: string,
    intentSenderAddress: Address,
    intentSettlementAddress: Address
  ) {
    // Inisialisasi provider
    this.sourceChainProvider = new ethers.JsonRpcProvider(sourceRpcUrl);
    this.destChainProvider = new ethers.JsonRpcProvider(destRpcUrl);

    // Inisialisasi viem clients
    this.sourceChainClient = createPublicClient({
      transport: http(sourceRpcUrl)
    });

    this.destChainClient = createPublicClient({
      transport: http(destRpcUrl)
    });

    // Baca ABI dari file JSON
    const intentSenderABI = JSON.parse(
      fs.readFileSync(path.resolve(__dirname, "../contract/IntentSender.json"), "utf-8")
    ).abi;

    const intentSettlementABI = JSON.parse(
      fs.readFileSync(path.resolve(__dirname, "../contract/IntentSettlement.json"), "utf-8")
    ).abi;

    // Siapkan signer untuk transaksi
    const wallet = new ethers.Wallet(
      process.env.SOLVER_PRIVATE_KEY!, 
      this.destChainProvider
    );

    // Inisialisasi kontrak-kontrak
    this.intentSenderContract = new ethers.Contract(
      intentSenderAddress, 
      intentSenderABI, 
      this.sourceChainProvider
    );

    this.intentSettlementContract = new ethers.Contract(
      intentSettlementAddress, 
      intentSettlementABI, 
      wallet
    );
  }

  // Metode untuk melakukan polling terhadap event IntentSubmitted
  async startPolling(pollInterval: number = 5000) {
    console.log('Starting Intent Bot Solver...');
    
    // Cegah listener ganda
    if (this.hasActiveListener) {
      console.log('Listener already active');
      return;
    }

    let transactionsFound = false;

    // Listen to IntentSubmitted event
    const listener = this.intentSenderContract.on('IntentSubmitted', async (intentId, intent, event) => {
      transactionsFound = true;
      console.log('New Intent Received:', intentId);
      
      // Hindari memproses intent yang sama berulang kali
      if (this.processedIntents.has(intentId)) {
        console.log('Intent already processed:', intentId);
        return;
      }

      try {
        await this.processIntentRequest({
          user: intent.user,
          token: intent.token,
          amount: intent.amount,
          sourceChainId: intent.sourceChainId,
          destinationChainId: intent.destinationChainId,
          deadline: intent.deadline,
          minReceived: intent.minReceived,
          intentId: intentId
        });

        // Tandai intent sebagai sudah diproses
        this.processedIntents.add(intentId);
      } catch (error) {
        console.error('Error processing intent:', error);
      }
    });

    // Set flag listener aktif
    this.hasActiveListener = true;

    // Tambahkan log untuk transaksi yang tidak ditemukan
    setTimeout(() => {
      if (!transactionsFound) {
        console.log('No incoming transactions');
      }
      transactionsFound = false;
    }, pollInterval);

    // Prevent the process from exiting
    await new Promise(() => {});
  }

  // Metode untuk memproses intent request
  private async processIntentRequest(intent: Intent) {
    try {
      console.log('Processing Intent:', intent);

      // Siapkan signer untuk transaksi
      const wallet = new ethers.Wallet(
        process.env.SOLVER_PRIVATE_KEY!, 
        this.destChainProvider
      );

      // Transfer token di chain tujuan
      const tokenContract = new ethers.Contract(
        intent.token, 
        ['function transfer(address to, uint256 amount) public'],
        wallet
      );

      const transferTx = await tokenContract.transfer(
        intent.user, 
        intent.amount
      );
      await transferTx.wait();

      // Lakukan settlement di kontrak tujuan
      const settlementTx = await this.intentSettlementContract.executeSettlement(
        intent.user,
        intent.amount,
        intent.intentId
      );
      await settlementTx.wait();

      console.log(`Intent processed for ${intent.user}`);
    } catch (error) {
      console.error('Error processing intent request:', error);
      throw error;
    }
  }
}

// Contoh penggunaan
async function main() {
  const solver = new IntentBotSolver(
    process.env.SOURCE_CHAIN_RPC_URL!,
    process.env.DEST_CHAIN_RPC_URL!,
    process.env.INTENT_SENDER_CONTRACT_ADDRESS! as Address,
    process.env.INTENT_SETTLEMENT_CONTRACT_ADDRESS! as Address
  );

  solver.startPolling();
}

// Jalankan bot
main().catch(console.error);

export default IntentBotSolver;