import { ethers } from "ethers";
import dotenv from "dotenv";
import path from "path";
import fs from "fs";

// Load environment variables
dotenv.config();

const MOCK_TOKEN_ADDRESS = "0x4eAC1d777438602D869968371e2fFD6e72F17228";

async function submitIntent() {
  const provider = new ethers.JsonRpcProvider(process.env.SOURCE_CHAIN_RPC_URL);
  const wallet = new ethers.Wallet(process.env.USER_PRIVATE_KEY!, provider);

  const intentSenderABI = JSON.parse(
    fs.readFileSync(path.resolve(__dirname, "../contract/IntentSender.json"), "utf-8")
  ).abi;

  const mockTokenABI = JSON.parse(
    fs.readFileSync(path.resolve(__dirname, "../contract/MockERC20.json"), "utf-8")
  ).abi;

  const intentSender = new ethers.Contract(
    process.env.INTENT_SENDER_CONTRACT_ADDRESS!,
    intentSenderABI,
    wallet
  );

  const mockToken = new ethers.Contract(
    MOCK_TOKEN_ADDRESS,
    mockTokenABI,
    wallet
  );

  const token = MOCK_TOKEN_ADDRESS;
  const amount = ethers.parseEther("10"); // 18 decimals
  const originChain = 421614;
  const destinationChainId = 1614990;
  const deadline = Math.floor(Date.now() / 1000) + 3600; // 1 hour from now
  const minReceived = ethers.parseEther("9.5"); // Minimum 9.5 tokens to receive

  try {
    console.log("Approving IntentSender to spend tokens...");

    const approveTx = await mockToken.approve(intentSender.target, amount);
    await approveTx.wait();
    console.log("Token approved successfully!");

    console.log("Submitting intent...");

    // Submit intent
    const tx = await intentSender.submitIntent(
      token,
      amount,
      originChain,
      destinationChainId,
      deadline,
      minReceived
    );

    const receipt = await tx.wait();
    console.log("Intent submitted successfully!");
    console.log("Transaction hash:", tx.hash);

    // Find and log the IntentSubmitted event
    const event = receipt.logs.find(
      (log: any) =>
        log.topics[0] ===
        ethers.id(
          "IntentSubmitted(bytes32,address,address,uint256,uint256,uint32,uint256,uint256)"
        )
    );

    if (event) {
      const decoded = intentSender.interface.parseLog(event);

      console.log("Intent details:", {
        intentId: decoded?.args.intentId,
        user: decoded?.args.user,
        token: decoded?.args.token,
        amount: decoded?.args.amount?.toString(),
        sourceChainId: decoded?.args.sourceChainId?.toString(),
        destinationChainId: decoded?.args.destinationChainId?.toString(),
        deadline: decoded?.args.deadline?.toString(),
        minReceived: decoded?.args.minReceived?.toString(),
      });

      const contractBalance = await mockToken.balanceOf(intentSender.target);
      console.log(`Contract now holds ${ethers.formatEther(contractBalance)} MOCK tokens`);
    }
  } catch (error) {
    console.error("Error submitting intent:", error);
  }
}

submitIntent().catch(console.error);