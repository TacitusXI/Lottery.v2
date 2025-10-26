# ♠ Decentralized Lottery ♣

> Provably fair lottery contract powered by Chainlink VRF V2.5 & Automation

> This lottery contract uses **Chainlink VRF V2.5** for verifiable random number generation and **Chainlink Automation** for time-based triggers. 
> The system automatically creates VRF subscriptions, funds them with LINK, and registers the contract as a consumer during deployment.

[![Solidity](https://img.shields.io/badge/Solidity-0.8.19-e6e6e6?style=for-the-badge&logo=solidity&logoColor=black)](https://docs.soliditylang.org/)
[![Foundry](https://img.shields.io/badge/Foundry-000000?style=for-the-badge&logo=ethereum&logoColor=white)](https://book.getfoundry.sh/)
[![Chainlink](https://img.shields.io/badge/Chainlink-375BD2?style=for-the-badge&logo=chainlink&logoColor=white)](https://chain.link/)
[![Coverage](https://img.shields.io/badge/Coverage-100%25-brightgreen?style=for-the-badge)](https://github.com/TacitusXI/Lottery.v2)
[![Tests](https://img.shields.io/badge/Tests-47%20Passing-success?style=for-the-badge)](https://github.com/TacitusXI/Lottery.v2)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

---

## 📁 Table of Contents
* [General Info](#-general-information)
* [Technologies Used](#-technologies-used)
* [Features](#-features)
* [Architecture](#-architecture)
* [Requirements](#-requirements-for-initial-setup)
* [Setup](#-setup)
* [Testing](#-testing)
* [Deployment](#-deployment)
* [Security](#-security)
* [License](#-license)
* [Contact](#-contact)

---

## 🚩 General Information

A fully decentralized lottery system built with Foundry that ensures:
- **Provably Fair**: Chainlink VRF V2.5 provides verifiable randomness
- **Fully Automated**: Chainlink Automation triggers winner selection automatically
- **Multi-Network**: Supports Ethereum Sepolia, Polygon Amoy, and local Anvil
- **Gas Optimized**: Uses custom errors and optimized storage patterns
- **Extensively Tested**: 100% test coverage with unit, fuzz, invariant, and staging tests

### How It Works

1. 🎫 **Enter Lottery**: Users pay entrance fee (0.01 ETH) to participate
2. ⏰ **Wait for Interval**: Lottery runs for configurable time period (default: 30 seconds)
3. 🤖 **Automated Trigger**: Chainlink Automation checks conditions and triggers draw
4. 🎲 **Random Winner**: Chainlink VRF provides verifiable random number
5. 💰 **Winner Paid**: Smart contract automatically transfers prize to winner
6. 🔄 **Restart**: Lottery resets and begins new round

---

## 💻 Technologies Used

| Technology | Version | Purpose |
|------------|---------|---------|
| **Solidity** | ^0.8.19 | Smart contract language |
| **Foundry** | Latest | Development framework |
| **Chainlink VRF V2.5** | Latest | Verifiable randomness |
| **Chainlink Automation** | Latest | Automated upkeep triggers |
| **OpenZeppelin** | Via Chainlink | Security standards |
| **Foundry DevOps** | 0.2.2 | Deployment utilities |

---

## 🌟 Features

✅ **Verifiably Random** - Uses Chainlink VRF V2.5 for tamper-proof randomness  
✅ **Fully Automated** - Chainlink Automation handles lottery draws automatically  
✅ **Gas Optimized** - Custom errors, immutable variables, efficient storage  
✅ **Multi-Network Support** - Ethereum, Polygon Amoy, Local Anvil  
✅ **Automated Deployment** - Scripts handle VRF subscription creation and funding  
✅ **Secure Key Management** - Supports encrypted keystores (no plain text keys)  
✅ **Comprehensive Tests** - Unit, fuzz, invariant, staging tests, 100% coverage  
✅ **Professional CI/CD Ready** - Structured for GitHub Actions integration  

---

## 🏗 Architecture

```
┌─────────────────────────────────────────────────┐
│           Lottery Smart Contract                │
│                                                 │
│  ┌───────────────────────────────────────────┐ │
│  │  Players Array                            │ │
│  │  - Store player addresses                 │ │
│  │  - Reset after each draw                  │ │
│  └───────────────────────────────────────────┘ │
│                                                 │
│  ┌───────────────────────────────────────────┐ │
│  │  Chainlink VRF V2.5                       │ │
│  │  - Request random words                   │ │
│  │  - Receive callback with randomness       │ │
│  │  - Pick winner from players array         │ │
│  └───────────────────────────────────────────┘ │
│                                                 │
│  ┌───────────────────────────────────────────┐ │
│  │  Chainlink Automation                     │ │
│  │  - checkUpkeep() validates conditions     │ │
│  │  - performUpkeep() triggers VRF request   │ │
│  └───────────────────────────────────────────┘ │
└─────────────────────────────────────────────────┘
```

### Smart Contract Functions

**Public Functions:**
- `enterLottery()` - Enter lottery by paying entrance fee
- `checkUpkeep()` - View function for Automation to check if upkeep needed
- `performUpkeep()` - Trigger lottery draw (called by Automation)

**Getter Functions:**
- `getLotteryState()` - Returns OPEN or CALCULATING
- `getPlayer(uint256 index)` - Get player address by index
- `getRecentWinner()` - Get last winner address
- `getEntranceFee()` - Get current entrance fee
- `getNumberOfPlayers()` - Get current player count
- And more...

---

## 👀 Requirements For Initial Setup

- Install [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
  - Verify: `git --version`
- Install [Foundry](https://getfoundry.sh/)
  - Verify: `forge --version`
- [Optional] Install [Make](https://www.gnu.org/software/make/) (usually pre-installed on Linux/Mac)

---

## 📟 Setup

### 1. 💾 Clone/Download the Repository

```bash
git clone https://github.com/YOUR_USERNAME/lottery
cd lottery
```

### 2. 📦 Install Dependencies

```bash
forge install
```

This will install:
- `forge-std` - Foundry standard library
- `chainlink-brownie-contracts` - Chainlink smart contracts
- `foundry-devops` - Deployment utilities
- `solmate` - Gas-optimized contracts

### 3. 🔍 Environment Variables Setup

You have two options for key management:

#### Option A: Encrypted Keystore (Recommended ✅)

```bash
# Create encrypted keystore
cast wallet import myKeystore --interactive

# You'll be prompted for:
# - Your private key
# - A password to encrypt it
```

#### Option B: Environment Variables (.env file)

Create `.env` file in project root:

```bash
# Polygon Amoy (Recommended for testing)
POLYGON_AMOY_RPC_URL=https://rpc-amoy.polygon.technology/
POLYGONSCAN_API_KEY=your_polygonscan_api_key

# Ethereum Sepolia (Alternative)
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_API_KEY
ETHERSCAN_API_KEY=your_etherscan_api_key

# Only if using .env instead of keystore
PRIVATE_KEY=0xYOUR_PRIVATE_KEY_HERE
```

**Where to get:**
- **RPC URLs**: [Alchemy](https://www.alchemy.com/), [Infura](https://www.infura.io/), or public RPCs
- **API Keys**: [PolygonScan](https://polygonscan.com/myapikey), [Etherscan](https://etherscan.io/myapikey)
- **Private Key**: Export from MetaMask (⚠️ **NEVER share or commit this!**)

### 4. 🪙 Get Testnet Tokens

#### For Polygon Amoy (Easiest, No Restrictions):
1. **MATIC**: [Polygon Faucet](https://faucet.polygon.technology/) - Select "Polygon Amoy"
2. **LINK**: [Chainlink Faucet](https://faucets.chain.link/polygon-amoy) - Get 5-10 LINK

#### For Ethereum Sepolia:
1. **ETH**: [Chainlink Faucet](https://faucets.chain.link/sepolia)
2. **LINK**: Same faucet provides LINK

---

## 🧪 Testing

### Test Suite Overview

**47 comprehensive tests** with **100% coverage**:
- ✅ 37 Unit Tests (functional testing)
- ✅ 8 Invariant Tests (property-based testing, 128K calls)
- ✅ 3 Fuzz Tests (256 runs each)
- ✅ 2 Staging Tests (integration testing)

### Run All Tests

```bash
forge test
```

### Run Specific Test Types

```bash
# Unit tests only
forge test --match-path test/unit/LotteryTest.t.sol

# Invariant tests (stateful fuzzing)
forge test --match-path test/unit/LotteryInvariant.t.sol

# Staging tests (testnet integration)
forge test --match-path test/staging/

# Specific test
forge test --match-test testGetEntranceFeeReturnsCorrectValue
```

### Run Tests with Verbosity

```bash
forge test -vv   # Show stack traces on failure
forge test -vvv  # Show stack traces + setup
forge test -vvvv # Full traces
```

### Generate Coverage Report

```bash
forge coverage --report summary
```

### Gas Benchmarking

```bash
forge test --gas-report  # Gas usage per function
forge snapshot           # Save gas snapshot
```

### Test Documentation

See [test/README.md](test/README.md) for detailed test documentation.

**Current Coverage:**
```
src/Lottery.sol:
├── Lines:      100.00% ✅✅✅
├── Statements: 100.00% ✅✅✅
├── Branches:   100.00% ✅✅✅
└── Functions:  100.00% ✅✅✅

PERFECT SCORE! 🎯
```

### Gas Snapshot

```bash
forge snapshot
```

This creates `.gas-snapshot` file with gas usage for all functions.

---

## 🚀 Deployment

### Local Deployment (Anvil)

**Terminal 1** - Start local blockchain:
```bash
make anvil
```

**Terminal 2** - Deploy contract:
```bash
make deploy
```

This automatically:
- ✅ Creates mock VRF Coordinator
- ✅ Deploys LINK token mock
- ✅ Creates VRF subscription
- ✅ Funds subscription with LINK
- ✅ Deploys Lottery contract
- ✅ Adds contract as VRF consumer

### Testnet Deployment

#### Polygon Amoy (Recommended)

```bash
# Load environment variables
source .env

# Deploy with keystore (Recommended)
forge script script/DeployLottery.s.sol:DeployLottery \
  --rpc-url $POLYGON_AMOY_RPC_URL \
  --account myKeystore \
  --sender YOUR_ADDRESS \
  --broadcast \
  --verify \
  -vvvv

# OR deploy with private key
make deploy ARGS="--network polygon-amoy"
```

#### Ethereum Sepolia

```bash
make deploy ARGS="--network sepolia"
```

### What Happens During Deployment:

1. 🔧 **Network Detection**: Automatically configures for target network
2. 🎫 **Subscription Creation**: Creates Chainlink VRF subscription (if needed)
3. 💰 **Funding**: Funds subscription with 3 LINK tokens
4. 📜 **Contract Deploy**: Deploys Lottery contract with configuration
5. ✅ **Consumer Registration**: Adds contract as VRF consumer
6. 🔍 **Verification**: Verifies contract on block explorer

---

## 🔧 Post-Deployment: Setup Chainlink Automation

**Important**: VRF is automatic, but Automation requires manual setup!

### Steps:

1. Go to [automation.chain.link](https://automation.chain.link/)
2. Click **"Register new Upkeep"**
3. Select **"Custom logic"** trigger
4. Enter your **Lottery contract address**
5. Set **upkeep name**: "Lottery Auto Draw"
6. **Fund with LINK** (~5 LINK recommended)
7. Click **"Register Upkeep"**

### Automation Configuration:
- **Check interval**: Every block
- **Gas limit**: 500,000 (default is fine)
- **Starting balance**: 5 LINK

Now your lottery will automatically draw winners every 30 seconds! 🎉

---

## 🛡 Security

### Security Features

✅ **Reentrancy Protection**: External calls at function end  
✅ **Verifiable Randomness**: Chainlink VRF prevents manipulation  
✅ **State Machine**: Clear OPEN → CALCULATING → OPEN transitions  
✅ **Solidity 0.8.19**: Built-in overflow/underflow protection  
✅ **Custom Errors**: Gas efficient error handling  
✅ **Immutable Variables**: Critical params cannot be changed  

### Recommendations for Production

⚠️ Consider adding:
- **Pausable Pattern**: Emergency stop mechanism
- **Access Control**: Owner functions for admin operations
- **Maximum Players**: Cap to prevent DoS via gas limit
- **Upgradeability**: Proxy pattern for bug fixes
- **Multi-sig**: Require multiple signatures for critical operations

### Run Security Analysis

```bash
# Install Slither
pip install slither-analyzer

# Run analysis
slither . --exclude-dependencies
```

---

## 📊 Project Statistics

```
Smart Contracts:     1 (Lottery.sol)
Lines of Code:       ~320 (contract + tests)
Test Coverage:       100% (Lines, Statements, Branches, Functions)
Number of Tests:     47 (37 unit, 8 invariant, 2 staging)
Gas Optimization:    Custom errors, immutables
Deployment Scripts:  Fully automated
Networks Supported:  3 (Anvil, Sepolia, Polygon Amoy)
```

---

## 🎯 Makefile Commands

```bash
make anvil              # Start local blockchain
make deploy             # Deploy to Anvil (default)
make deploy ARGS="--network polygon-amoy"  # Deploy to Polygon Amoy
make deploy ARGS="--network sepolia"       # Deploy to Sepolia
make test               # Run all tests
make coverage           # Generate coverage report
make snapshot           # Gas snapshot
make format             # Format code with forge fmt
make clean              # Clean build artifacts
```

---

## 📖 Additional Documentation

- **[PORTFOLIO_IMPROVEMENT_PLAN.md](./PORTFOLIO_IMPROVEMENT_PLAN.md)** - Roadmap for enhancements
- **[PROJECT_AUDIT.md](./PROJECT_AUDIT.md)** - Code quality assessment
- **Contract NatSpec** - Inline documentation in `src/Lottery.sol`
- **[Chainlink VRF Docs](https://docs.chain.link/vrf/v2/introduction)** - VRF documentation
- **[Chainlink Automation Docs](https://docs.chain.link/chainlink-automation/introduction)** - Automation guide
- **[Foundry Book](https://book.getfoundry.sh/)** - Foundry framework docs

---

## 🐛 Troubleshooting

### "Subscription not funded"
**Solution**: Make sure you have at least 3 LINK in your wallet before deployment.

### "Gas estimation failed"
**Solution**: Ensure entrance fee is paid: `--value 0.01ether`

### "Upkeep not triggered"
**Solution**: Verify:
- Lottery has players (call `enterLottery()`)
- 30 seconds have passed since last draw
- Contract has balance
- Automation is registered and funded

### "VRF request failed"
**Solution**: Check:
- Subscription is funded with LINK
- Contract is added as consumer
- Gas limit is sufficient (500,000)

---

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 💬 Contact

**Created by TacitusXI**

- 🔗 GitHub: [@TacitusXI](https://github.com/TacitusXI)
- 📂 Project: [Lottery.v2](https://github.com/TacitusXI/Lottery.v2)

---

## 🙏 Acknowledgments

- [Chainlink](https://chain.link/) - VRF and Automation infrastructure
- [Foundry](https://getfoundry.sh/) - Fast, portable, modular smart contract development toolkit
