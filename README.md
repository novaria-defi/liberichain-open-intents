# Liberichain Open Intents Integration  

**A gasless intent-based transaction system integrated with Arbitrum (Nitro) Sepolia and Espresso Systems**  

##  ██╗     ██╗██████╗ ███████╗██████╗ ██╗ ██████╗██╗  ██╗ █████╗ ██╗███╗   ██╗
##  ██║     ██║██╔══██╗██╔════╝██╔══██╗██║██╔════╝██║  ██║██╔══██╗██║████╗  ██║
##  ██║     ██║██████╔╝█████╗  ██████╔╝██║██║     ███████║███████║██║██╔██╗ ██║
##  ██║     ██║██╔══██╗██╔══╝  ██╔══██╗██║██║     ██╔══██║██╔══██║██║██║╚██╗██║
##  ███████╗██║███████║███████╗██║  ██║██║╚██████╗██║  ██║██║  ██║██║██║ ╚████║
##  ╚══════╝╚═╝╚══════╝╚══════╝╚═╝  ╚═╝╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝
##  
##  Decentralized Intent-Based Cross-Chain Protocol

## Overview  

Liberichain Open Intents is a framework that enables users to submit **gasless, intent-driven transactions** (e.g., transfers, cross-chain actions) without directly paying gas fees. Instead, **solvers** (relayers or third-party executors) fulfill these intents on supported chains, including:  
- **Arbitrum Nitro (Sepolia Testnet)**  
- **Espresso Systems (for fast sequencing & privacy-enhanced intents)**  

This system improves UX by abstracting gas management while maintaining decentralization and security.  

---

## How It Works  

### Core Workflow  
1. **User Declares an Intent**  
   - Example: *"I want to move my 100 USDC from arbitrum to liberichain"*  
   - Signed off-chain and submitted to Liberichain’s intent mempool.  

2. **Solvers Compete to Fulfill**  
   - Solvers (bots/relayers) monitor the mempool, simulate intent execution, and submit the best-fulfilled transaction on-chain.  
   - Gas fees are paid by the solver (reimbursed via transaction surplus or fees).  

3. **On-Chain Execution**  
   - Solvers broadcast the transaction to **Arbitrum Sepolia** (for low-cost settlement) or **Espresso Systems** (for privacy/rollup sequencing).  
   - Users receive their desired outcome without managing gas or complex interactions.  

---

## Key Features  
✅ **Gasless UX** – No need for users to hold native tokens for gas.  
✅ **Multi-Chain Support** – Arbitrum Nitro (Sepolia) for scalability + Espresso for privacy/sequencing.  
✅ **Solver Incentives** – Solvers earn fees via MEV or intent-based rewards.  
✅ **Composable Intents** – Combine swaps, bridges, and approvals in a single intent.  

---

## Integration Targets  
| Component          | Role                                  | Supported Networks                |  
|--------------------|---------------------------------------|-----------------------------------|  
| **Intent Mempool** | Off-chain intent aggregation          | Liberichain P2P Network           |  
| **Solver Layer**   | Intent execution & gas subsidization  | Arbitrum Sepolia, Espresso Testnet|

---

## Getting Started (For Developers)  

### 1. Submit an Intent  
```typescript  
// Example: Move fund intent via Liberichain interface  
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

// Sign and submit to the mempool  
const signedIntent = await wallet.signIntent(intent);  
await liberichain.submitIntent(signedIntent);  
```  

### 2. Run a Solver  
```bash  
# Clone the solver template (Don't forget to configure the chain on number 3)
git clone https://github.com/novaria-defi/liberichain-open-intents  
cd intent-contract

deploy contract using forge

# Configure solver bot
cd ..
cd solver  
yarn install  
cp .env.example .env  

# Start the solver  
yarn ts-node src/solver.ts

# Start testing transaction
yarn ts-node src/transaction.ts
```  

### 3. Test on Arbitrum Sepolia  
- **RPC Endpoint**: `https://sepolia-rollup.arbitrum.io/rpc`  
- **Chain ID**: `421614`  
- **Test Tokens**: Use [Arbitrum Sepolia Faucet](https://faucet.triangleplatform.com/arbitrum/sepolia).  

---

## Why Open Intents?  
- **User-Friendly**: No gas headaches; intents are declarative.  
- **Modular**: Plug into Arbitrum for scaling or Espresso for privacy.  
- **Efficient**: Solvers optimize execution (e.g., batching, MEV capture).  

---

## Resources  
- [Smart Contracts (GitHub)](https://github.com/novaria-defi/liberichain-open-intents)  
- [Arbitrum Sepolia Docs](https://docs.arbitrum.io/for-devs/concepts/nitro)  
- [Espresso Systems](https://www.espressosys.com/)  

---  
`🚀 Powered by Liberichain | Gasless Future`  

---  

### Notes for Developers:  
- **Espresso Integration**: Intents routed through Espresso benefit from fast sequencing and optional privacy.  
- **Solver Economics**: Design your solver to profit from intent arbitrage or fee subsidies.  
