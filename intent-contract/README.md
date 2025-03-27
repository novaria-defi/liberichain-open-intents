## ⚠️ Important Package Manager Notice
**Important:** We no longer support the use of Yarn for smart contract development.

```markdown
# Open Intent Smart Contracts 🔗

[![Foundry][foundry-badge]][foundry]
[![License: MIT][license-badge]][license]

Smart contracts implementing Open Intent protocol for cross-chain transactions, built with Foundry.

## 📜 Contracts

### Core Contracts
- `IntentSender.sol`: Entry point for users to submit intents

## 🛠️ Development

### Prerequisites
- [Foundry](https://getfoundry.sh)
- Node.js ≥ 18
- [Hyperlane](https://www.hyperlane.xyz/) configured chains

### Setup
```bash
git clone https://github.com/novaria-defi/liberichain-open-intents.git
cd intent-contract
forge install
```

### Build
```bash
forge build
```

### Test
```bash
forge test -vvv # Run tests with verbose output
```

### Environment Setup
Create `.env` file:
```ini
PRIVATE_KEY=0x...
```

## 📊 Deployment

### Deploy to Arbitrum Sepolia
```bash
forge script script/Deploy.s.sol:DeployScript \
--rpc-url $RPC_URL_ARBITRUM \
--private-key $PRIVATE_KEY \
--broadcast \
--verify \
--etherscan-api-key $ARBISCAN_KEY \
-s "run()"
```

### Verify Contracts
```bash
forge verify-contract \
--chain-id 42161 \
--constructor-args $(cast abi-encode "constructor()" "") \
--etherscan-api-key $ARBISCAN_KEY \
<CONTRACT_ADDRESS> \
src/IntentSender.sol:IntentSender
```

## 🌉 Cross-Chain Workflow

1. **User Submission**:
   ```solidity
   // Submit intent to send 100 USDC from Arbitrum to Liberichain
   IntentSender.submitIntent(
       destChainId: 1614990, // Liberichain
       token: 0xA0b869... // USDC
       amount: 100e6,
       minOut: 99e6
   );
   ```

## 📚 Documentation

- [Foundry Book](https://book.getfoundry.sh)
- [Hyperlane Docs](https://docs.hyperlane.xyz)
- [Open Intent Spec](./docs/SPEC.md)
- [Liberichain](https://github.com/novaria-defi/liberichain-open-intents?tab=readme-ov-file#liberichain-open-intents)

## ⚠️ Security

```bash
# Run slither analysis
slither . --config-file slither.config.json
```

## 📄 License
MIT

[foundry]: https://getfoundry.sh
[foundry-badge]: https://img.shields.io/badge/Built%20with-Foundry-FFDB1C.svg
[license]: https://opensource.org/licenses/MIT
[license-badge]: https://img.shields.io/badge/License-MIT-blue.svg
```
