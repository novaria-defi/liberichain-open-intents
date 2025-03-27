```markdown
# Liberichain Solver (Cross-Chain Open Intents)

Minimal solver for Liberichain’s Open Intents system, supporting cross-chain swaps via Hyperlane and settlement on Arbitrum Nitro & Espresso Systems.

## 📂 Folder Structure
```
solver/
├── abis/
│   ├── ERC20.json
│   ├── IntentSender.json       # For cross-chain intent submission
│   └── IntentSettlement.json   # For final settlement
├── src/
│   ├── config.ts              # Chain configurations
│   ├── index.ts               # Main solver logic
│   └── types.ts
├── .env.example
└── package.json
```

## 🌉 Cross-Chain Workflow
1. **User Submits Intent**  
   - Calls `IntentSender.sendIntent()` on source chain (e.g., Arbitrum Sepolia).
2. **Solver Monitors**  
   - Polls `IntentSender` contract every second for new intents.
3. **Token Bridging**  
   - Solver sends equivalent tokens to user on destination chain via Hyperlane-wrapped assets.
4. **User Receives Funds**  
   - Tokens arrive on destination chain (gas paid by solver).
5. **Settlement**  
   - Solver calls `IntentSettlement.settle()` on destination chain to finalize net balances.

```mermaid
sequenceDiagram
    User->>IntentSender: sendIntent(destChain, amount)
    loop Every 1 sec
        Solver->>IntentSender: checkNewIntents()
    end
    Solver->>DestinationChain: sendTokens(user, amount)
    User->>DestinationChain: receives tokens
    Solver->>IntentSettlement: settleNetTransactions()
```

## ⚙️ Pre-Requirements
1. **Token Deployment**  
   - ERC20 tokens must be deployed on all chains and wrapped via Hyperlane.
2. **Chain Setup**  
   - Hyperlane configured for:
     - Arbitrum Nitro (Sepolia)
     - Espresso Systems (Testnet)
3. **Tech Stack**  
   ```bash
   yarn add typescript ts-node ethers viem dotenv
   ```

## 🔄 Open Intents Logic
- **Single Transaction**:  
  ```ts
  // User intent example
  await IntentSender.sendIntent({
    destChain: '1614990', //liberichain chain id
    token: 'USDC',
    amount: '100'
  });
  ```
- **Net Settlement**:  
  If 2 users swap USDC between chains:
  - Only the **difference** is settled on-chain (e.g., 100 USDC in → 80 USDC out = 20 USDC net transfer).

## 🛠️ Setup
1. Configure `.env`:
   ```ini
  SOURCE_CHAIN_RPC_URL = 
  DEST_CHAIN_RPC_URL = 
  SOLVER_PRIVATE_KEY = 
  INTENT_SENDER_CONTRACT_ADDRESS =
  USER_PRIVATE_KEY = 
  USER_ADDRESS =
  SOURCE_TOKEN_ADDRESS =
  DESTINATION_TOKEN_ADDRESS =
   ```
2. Run:
   ```bash
   yarn install
   yarn ts-node src/solver.ts
   yarn ts-node src/transaction.ts
   ```
3. Debugging

## ⚠️ Limitations
- Requires pre-funded solver wallets on all chains.
- Has a testnet balance

---
[Liberichain Contracts](https://github.com/novaria-defi/liberichain-open-intents) | [Hyperlane Docs](https://docs.hyperlane.xyz)
```
