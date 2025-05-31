# 🎭 VelvetVault - Premium Royalty Distribution Protocol

[![Clarity](https://img.shields.io/badge/Clarity-Smart%20Contract-purple)](https://clarity-lang.org/)
[![Stacks](https://img.shields.io/badge/Stacks-Blockchain-orange)](https://stacks.co/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

VelvetVault is a sophisticated, gas-optimized smart contract system built on the Stacks blockchain for automated royalty distribution. Designed for creators, artists, and content platforms who need transparent, efficient, and fair revenue sharing among multiple stakeholders.

## ✨ Key Features

### 🎯 **Smart Distribution Engine**
- **Percentage-based allocation**: Configure custom royalty percentages for each stakeholder
- **Automated payouts**: Set recurring distribution intervals with block-based timing
- **Batch processing**: Gas-efficient mass distributions to all stakeholders
- **Individual payouts**: Targeted distributions to specific stakeholders

### 🛡️ **Enterprise-Grade Security**
- **Owner-only controls**: Administrative functions restricted to vault owner
- **Input validation**: Comprehensive checks for all parameters and amounts
- **Emergency controls**: Pause/resume vault operations when needed
- **Error handling**: Detailed error codes for debugging and monitoring

### 📊 **Advanced Analytics**
- **Lifetime earnings tracking**: Monitor total earnings per stakeholder
- **Distribution history**: Block-by-block payout records
- **Vault statistics**: Comprehensive system metrics and status
- **Real-time queries**: Instant access to all vault data

## 🏗️ Architecture Overview

```
VelvetVault Smart Contract
├── Stakeholder Management
│   ├── configure-stakeholder()     // Add/update stakeholders
│   ├── get-stakeholder-share()     // Query share percentages
│   └── get-stakeholder-earnings()  // Track lifetime earnings
├── Distribution Engine
│   ├── execute-payout()            // Individual payouts
│   ├── execute-mass-payout()       // Batch distributions
│   └── trigger-scheduled-payout()  // Automated recurring payouts
├── Vault Controls
│   ├── toggle-vault-status()       // Emergency pause/resume
│   ├── update-payout-frequency()   // Configure timing
│   └── get-vault-stats()          // System overview
└── Analytics & Queries
    ├── get-stakeholder-count()     // Total stakeholders
    ├── get-current-block-distribution() // Current payouts
    └── get-vault-status()          // Operational status
```

## 🚀 Quick Start

### Prerequisites
- Stacks wallet with STX tokens
- Clarity development environment
- Node.js (for testing utilities)

### Deployment

1. **Clone the repository**
```bash
git clone https://github.com/favoureze17/velvet-vault.git
cd velvet-vault
```

2. **Deploy the contract**
```bash
# Using Clarinet
clarinet deploy --testnet

# Or deploy to mainnet
clarinet deploy --mainnet
```

3. **Configure your first stakeholder**
```clarity
;; Add a stakeholder with 25% royalty share
(contract-call? .velvet-vault configure-stakeholder 'SP1ABC...DEF 25)
```

## 📖 Usage Examples

### Adding Multiple Stakeholders
```clarity
;; Artist gets 40%
(contract-call? .velvet-vault configure-stakeholder 'SP1ARTIST...ABC u40)

;; Producer gets 30%
(contract-call? .velvet-vault configure-stakeholder 'SP1PRODUCER...DEF u30)

;; Label gets 20%
(contract-call? .velvet-vault configure-stakeholder 'SP1LABEL...GHI u20)

;; Manager gets 10%
(contract-call? .velvet-vault configure-stakeholder 'SP1MANAGER...JKL u10)
```

### Executing Distributions
```clarity
;; Distribute 1000 STX to all stakeholders
(contract-call? .velvet-vault execute-mass-payout u1000000000) ;; 1000 STX in microSTX

;; Set up automated weekly payouts (10080 blocks ≈ 1 week)
(contract-call? .velvet-vault update-payout-frequency u10080)

;; Trigger scheduled payout
(contract-call? .velvet-vault trigger-scheduled-payout u500000000) ;; 500 STX
```

### Monitoring and Analytics
```clarity
;; Check stakeholder's lifetime earnings
(contract-call? .velvet-vault get-stakeholder-earnings 'SP1ARTIST...ABC)

;; Get comprehensive vault statistics  
(contract-call? .velvet-vault get-vault-stats)

;; Monitor current block distributions
(contract-call? .velvet-vault get-current-block-distribution)
```

## 🔧 Configuration Options

### Distribution Frequency Settings
- **Daily**: `u1440` blocks (~24 hours)
- **Weekly**: `u10080` blocks (~7 days)  
- **Monthly**: `u43200` blocks (~30 days)
- **Custom**: Any positive integer representing blocks

### Emergency Controls
```clarity
;; Pause vault operations
(contract-call? .velvet-vault toggle-vault-status)

;; Resume operations (call again)
(contract-call? .velvet-vault toggle-vault-status)
```

## 🛠️ Development

### Running Tests
```bash
clarinet test
```

### Local Development
```bash
clarinet console
```

### Contract Verification
```bash
clarinet check
```

## 🎯 Use Cases

VelvetVault is perfect for:

- **Music Industry**: Distribute streaming royalties to artists, producers, writers
- **Content Creation**: Share ad revenue among video creators and collaborators
- **Gaming**: Distribute in-game purchase revenue to developers and designers
- **NFT Projects**: Automate royalty splits for digital art collections
- **Publishing**: Distribute book sales among authors, editors, and publishers

## 🔐 Security Considerations

- All administrative functions require owner authorization
- Input validation prevents invalid percentages and amounts
- Emergency pause functionality for critical situations
- Comprehensive error handling with specific error codes
- Gas-optimized operations to prevent out-of-gas issues

## 📊 Error Codes Reference

| Code | Error | Description |
|------|-------|-------------|
| u100 | ERR_UNAUTHORIZED | Caller is not the vault owner |
| u101 | ERR_INVALID_PERCENTAGE | Percentage exceeds 100% |
| u102 | ERR_NO_STAKEHOLDERS | No stakeholders configured |
| u103 | ERR_INVALID_STAKEHOLDER | Stakeholder index out of range |
| u104 | ERR_PAYMENT_FAILED | STX transfer failed |
| u105 | ERR_STAKEHOLDER_NOT_FOUND | Stakeholder not in registry |
| u106 | ERR_DISTRIBUTION_FAILED | Batch distribution failed |
| u107 | ERR_TOO_EARLY | Insufficient time since last payout |
| u108 | ERR_INVALID_INTERVAL | Invalid time interval |
| u109 | ERR_INVALID_AMOUNT | Invalid distribution amount |

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License



**Built with ❤️ on the Stacks blockchain**

*VelvetVault - Where royalties flow as smooth as velvet*