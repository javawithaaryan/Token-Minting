# 🏦 Time-Locked Inheritance Vault Smart Contract

A comprehensive Solidity smart contract for managing digital asset inheritance with advanced features including time-locks, beneficiary tokens, multi-beneficiary support, and heartbeat mechanisms.

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
- [Contract Functions](#contract-functions)
- [Security Considerations](#security-considerations)
- [Testing](#testing)
- [Deployment](#deployment)
- [Contributing](#contributing)
- [License](#license)

## 🎯 Overview

The **Inheritance Vault** smart contract provides a secure and transparent way to manage digital asset inheritance on the Ethereum blockchain. It allows users to create time-locked vaults that can only be accessed by designated beneficiaries after a specified unlock time or when certain conditions are met.

### Key Concepts

- **Vault**: A secure container holding ETH/tokens with time-lock protection
- **Inheritance Token**: NFT-like proof of beneficiary rights
- **Heartbeat Mechanism**: Proof-of-life system to ensure owner activity
- **Multi-Beneficiary Support**: Split inheritance among multiple parties

## ✨ Features

### Core Features
- ✅ **Time-Locked Vaults**: Create vaults that unlock at specific timestamps
- ✅ **Beneficiary Tokens**: Mint inheritance tokens as proof of rights
- ✅ **Emergency Withdrawal**: Owner can withdraw before unlock time
- ✅ **Secure Claiming**: Beneficiaries claim with token verification

### New Enhanced Features
- 🆕 **Multi-Beneficiary Vaults**: Split inheritance among multiple beneficiaries with custom percentages
- 🆕 **Heartbeat Mechanism**: Proof-of-life system with configurable intervals (30-365 days)
- 🆕 **Vault Extension**: Extend unlock time for existing vaults
- 🆕 **Beneficiary Updates**: Change beneficiary address before claiming
- 🆕 **Add Funds**: Top up existing vaults with additional ETH
- 🆕 **Personal Messages**: Leave messages for beneficiaries
- 🆕 **Query Functions**: Get all vaults by owner or beneficiary
- 🆕 **Contract Statistics**: View total vaults, tokens, and balance

## 🚀 Installation

### Prerequisites

- Node.js v16+
- Hardhat or Truffle
- MetaMask or similar Web3 wallet

### Setup

```bash
# Clone the repository
git clone https://github.com/yourusername/inheritance-vault.git
cd inheritance-vault

# Install dependencies
npm install

# Compile the contract
npx hardhat compile
```

## 💻 Usage

### Creating a Single Beneficiary Vault

```javascript
// Connect to contract
const vault = await InheritanceVault.deployed();

// Create vault with 1 ETH, unlocking in 1 year
const beneficiaryAddress = "0x...";
const unlockTime = Math.floor(Date.now() / 1000) + (365 * 24 * 60 * 60);

await vault.createVault(beneficiaryAddress, unlockTime, {
  value: ethers.utils.parseEther("1.0")
});
```

### Creating a Multi-Beneficiary Vault

```javascript
const beneficiaries = [
  "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb",
  "0x123...",
  "0x456..."
];

const percentages = [50, 30, 20]; // Must sum to 100

await vault.createMultiBeneficiaryVault(
  beneficiaries,
  percentages,
  unlockTime,
  { value: ethers.utils.parseEther("10.0") }
);
```

### Enabling Heartbeat Mechanism

```javascript
const vaultId = 1;
const interval = 90 * 24 * 60 * 60; // 90 days

await vault.enableHeartbeat(vaultId, interval);

// Record heartbeat periodically
await vault.recordHeartbeat(vaultId);
```

### Claiming Inheritance

```javascript
// For single beneficiary
await vault.claimVault(vaultId, tokenId);

// For multi-beneficiary (any beneficiary can trigger)
await vault.claimMultiBeneficiaryVault(vaultId);
```

## 📚 Contract Functions

### Vault Management

| Function | Description | Access |
|----------|-------------|--------|
| `createVault()` | Create a new single-beneficiary vault | Public |
| `createMultiBeneficiaryVault()` | Create vault with multiple beneficiaries | Public |
| `addFunds()` | Add more ETH to existing vault | Owner |
| `extendVaultTime()` | Extend the unlock time | Owner |
| `updateBeneficiary()` | Change beneficiary address | Owner |
| `setMessage()` | Set message for beneficiary | Owner |

### Token Management

| Function | Description | Access |
|----------|-------------|--------|
| `mintInheritanceToken()` | Mint inheritance token for vault | Owner |

### Claiming & Withdrawal

| Function | Description | Access |
|----------|-------------|--------|
| `claimVault()` | Claim single-beneficiary vault | Beneficiary |
| `claimMultiBeneficiaryVault()` | Claim multi-beneficiary vault | Any Beneficiary |
| `emergencyWithdraw()` | Emergency withdrawal before unlock | Owner |

### Heartbeat System

| Function | Description | Access |
|----------|-------------|--------|
| `enableHeartbeat()` | Enable proof-of-life system | Owner |
| `recordHeartbeat()` | Record activity timestamp | Owner |
| `isHeartbeatOverdue()` | Check if heartbeat is overdue | Public View |

### Query Functions

| Function | Description | Access |
|----------|-------------|--------|
| `getVaultDetails()` | Get complete vault information | Public View |
| `getOwnerVaults()` | Get all vaults owned by address | Public View |
| `getBeneficiaryVaults()` | Get all vaults for beneficiary | Public View |
| `getVaultBeneficiaries()` | Get multi-beneficiary shares | Public View |
| `getTokenDetails()` | Get inheritance token info | Public View |
| `getContractStats()` | Get contract statistics | Public View |

## 🔒 Security Considerations

### Best Practices

1. **Secure Key Management**: Store private keys securely
2. **Test Thoroughly**: Test all functions on testnet first
3. **Verify Addresses**: Double-check beneficiary addresses
4. **Time Validation**: Ensure unlock times are correctly set
5. **Heartbeat Monitoring**: Set reminders for heartbeat intervals

### Potential Risks

- ⚠️ **Lost Keys**: Beneficiaries must secure their private keys
- ⚠️ **Missed Heartbeats**: Owner must record heartbeats regularly
- ⚠️ **Timestamp Dependence**: Blockchain timestamps can vary slightly
- ⚠️ **Reentrancy**: Contract uses CEI pattern for protection

### Audit Status

⚠️ **Not Yet Audited** - This contract has not undergone a professional security audit. Use at your own risk.

## 🧪 Testing

```bash
# Run all tests
npx hardhat test

# Run specific test file
npx hardhat test test/InheritanceVault.test.js

# Check test coverage
npx hardhat coverage
```

### Example Test Cases

```javascript
describe("InheritanceVault", function() {
  it("Should create a vault successfully", async function() {
    // Test implementation
  });
  
  it("Should mint inheritance token", async function() {
    // Test implementation
  });
  
  it("Should allow beneficiary to claim after unlock", async function() {
    // Test implementation
  });
});
```

## 🌐 Deployment

### Testnet Deployment

```bash
# Deploy to Sepolia testnet
npx hardhat run scripts/deploy.js --network sepolia

# Verify contract on Etherscan
npx hardhat verify --network sepolia DEPLOYED_CONTRACT_ADDRESS
```

### Mainnet Deployment

```bash
# Deploy to Ethereum mainnet
npx hardhat run scripts/deploy.js --network mainnet

# Verify contract
npx hardhat verify --network mainnet DEPLOYED_CONTRACT_ADDRESS
```

### Environment Variables

Create a `.env` file:

```env
PRIVATE_KEY=your_private_key_here
INFURA_API_KEY=your_infura_key
ETHERSCAN_API_KEY=your_etherscan_key
```

## 📊 Gas Estimates

| Function | Estimated Gas |
|----------|---------------|
| createVault | ~150,000 |
| createMultiBeneficiaryVault | ~200,000+ |
| mintInheritanceToken | ~100,000 |
| claimVault | ~80,000 |
| emergencyWithdraw | ~75,000 |
| recordHeartbeat | ~45,000 |

*Note: Actual gas costs may vary based on network conditions*

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Development Guidelines

- Follow Solidity style guide
- Add tests for new features
- Update documentation
- Ensure all tests pass

## 🙏 Acknowledgments

- OpenZeppelin for security patterns
- Ethereum community for best practices
- Contributors and testers

## 📈 Roadmap

- [ ] ERC-721 compliance for inheritance tokens
- [ ] Support for ERC-20 tokens
- [ ] Multi-signature support
- [ ] Governance mechanism
- [ ] Mobile app interface
- [ ] Professional security audit

---

**⚠️ Disclaimer**: This smart contract is provided as-is without any guarantees. Users should conduct their own security review before using in production. Always test thoroughly on testnets before mainnet deployment.

**Made with ❤️ for the Ethereum community**
