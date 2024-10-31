# BitFutures: Decentralized Bitcoin Price Prediction Market

BitFutures is a decentralized prediction market smart contract built on the Stacks blockchain that allows users to make predictions about Bitcoin price movements. Users can stake STX tokens on their predictions and earn rewards for correct predictions.

## Features

- Create prediction markets with customizable parameters
- Make "up" or "down" predictions with STX stakes
- Automated market resolution and reward distribution
- Configurable minimum stake amounts and fee structure
- Oracle-based price feed integration
- Fair and transparent reward calculation

## Smart Contract Overview

### Core Functions

#### For Users
- `make-prediction`: Place a prediction with a stake on a market
- `claim-winnings`: Claim rewards for correct predictions
- `get-market`: View details of a specific market
- `get-user-prediction`: Check prediction details for a specific user
- `get-contract-balance`: View the current contract balance

#### For Administrators
- `create-market`: Create a new prediction market
- `resolve-market`: Resolve a market with final price data
- `set-oracle-address`: Update the oracle address
- `set-minimum-stake`: Modify the minimum stake requirement
- `set-fee-percentage`: Adjust the platform fee percentage
- `withdraw-fees`: Withdraw accumulated platform fees

### Market Lifecycle

1. **Market Creation**: Admin creates a market with start price and timeframe
2. **Active Period**: Users make predictions by staking STX
3. **Resolution**: Oracle provides final price and market is resolved
4. **Claims**: Winners can claim their rewards

## Technical Details

### Constants
- Minimum stake: 1 STX (1,000,000 microSTX)
- Default fee: 2%
- Error codes: 100-106 for various error conditions

### Data Structures

```clarity
;; Market Structure
{
  start-price: uint,
  end-price: uint,
  total-up-stake: uint,
  total-down-stake: uint,
  start-block: uint,
  end-block: uint,
  resolved: bool
}

;; Prediction Structure
{
  prediction: (string-ascii 4),
  stake: uint,
  claimed: bool
}
```

## Usage Examples

### Making a Prediction

```clarity
;; Stake 5 STX on an upward price movement
(contract-call? .bitfutures make-prediction u1 "up" u5000000)
```

### Claiming Winnings

```clarity
;; Claim winnings from market #1
(contract-call? .bitfutures claim-winnings u1)
```

## Security Considerations

- Oracle-dependent for price feeds
- Time-locked predictions based on block height
- Owner-only administrative functions
- Built-in checks for:
  - Minimum stake amounts
  - Valid prediction values
  - Market timing
  - Double-claiming prevention
  - Balance verification

## Installation

1. Deploy the contract to the Stacks blockchain
2. Initialize oracle address
3. Configure minimum stake and fee parameters
4. Create first market

## Development

To modify or extend the contract:

1. Clone the repository
2. Make changes to the Clarity smart contract
3. Test thoroughly using Clarinet
4. Deploy updated contract

