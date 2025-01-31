# Bitcoin-Backed Stablecoin (BBS) System

A decentralized, overcollateralized stablecoin system powered by Bitcoin on the Stacks blockchain.

## Overview

The Bitcoin-Backed Stablecoin (BBS) system is a smart contract that enables users to mint stablecoins using Bitcoin (BTC) as collateral. The system maintains stability through robust overcollateralization mechanisms and automated liquidation processes.

## Key Features

- **Bitcoin Collateralization**: Users can deposit BTC as collateral to mint stablecoins
- **Overcollateralization**: Maintains a minimum collateralization ratio of 150%
- **Liquidation Protection**: Automated liquidation at 120% collateral ratio
- **Price Oracle Integration**: Real-time BTC price feeds with validity checks
- **Flexible Position Management**: Users can deposit, withdraw, mint, and repay at will

## System Parameters

| Parameter                | Value                | Description                                  |
| ------------------------ | -------------------- | -------------------------------------------- |
| Minimum Collateral Ratio | 150%                 | Required collateralization level for minting |
| Liquidation Threshold    | 120%                 | Positions below this ratio can be liquidated |
| Minimum Deposit          | 1,000,000 sats       | Minimum required BTC deposit                 |
| Price Validity Period    | 144 blocks           | Maximum age of price data (~1 day)           |
| Maximum Deposit          | 100,000,000,000 sats | Maximum single deposit amount                |
| Maximum BTC Price        | 1,000,000 USD        | Upper limit for BTC price updates            |

## Core Functions

### User Operations

#### `deposit-collateral`

Deposit BTC as collateral into the system.

```clarity
(deposit-collateral (amount uint))
```

#### `mint-stablecoin`

Mint stablecoins against deposited collateral.

```clarity
(mint-stablecoin (amount uint))
```

#### `repay-stablecoin`

Repay outstanding stablecoin debt.

```clarity
(repay-stablecoin (amount uint))
```

#### `withdraw-collateral`

Withdraw BTC collateral if position remains healthy.

```clarity
(withdraw-collateral (amount uint))
```

### System Operations

#### `liquidate-position`

Liquidate undercollateralized positions.

```clarity
(liquidate-position (user principal))
```

#### `set-price`

Update the BTC price (oracle only).

```clarity
(set-price (new-price uint))
```

#### `set-price-oracle`

Update the price oracle address (owner only).

```clarity
(set-price-oracle (new-oracle principal))
```

### Read-Only Functions

#### `get-position`

Retrieve user position details.

```clarity
(get-position (user principal))
```

#### `get-collateral-ratio`

Calculate current collateralization ratio.

```clarity
(get-collateral-ratio (user principal))
```

#### `get-current-price`

Get the current BTC price.

```clarity
(get-current-price)
```

## Error Codes

| Code  | Description               |
| ----- | ------------------------- |
| u1000 | Not authorized            |
| u1001 | Insufficient collateral   |
| u1002 | Below minimum requirement |
| u1003 | Invalid amount            |
| u1004 | Position not found        |
| u1005 | Already liquidated        |
| u1006 | Position is healthy       |
| u1007 | Price data expired        |

## Security Features

1. **Overcollateralization**: Maintains system solvency through required 150% collateral ratio
2. **Price Validity Checks**: Ensures price data is recent and within acceptable bounds
3. **Liquidation Mechanism**: Protects system stability through timely position liquidation
4. **Access Controls**: Restricted functions for owner and oracle operations
5. **Principal Validation**: Ensures valid addresses for critical operations
6. **Arithmetic Overflow Protection**: Guards against numerical overflows in calculations

## Data Storage

### Maps

- `user-positions`: Tracks user collateral, debt, and updates
- `liquidation-history`: Records liquidation events and details

### Variables

- `contract-owner`: System administrator address
- `price-oracle`: Authorized price feed provider
- `total-supply`: Current stablecoin circulation
- `btc-price`: Current BTC price
- `last-price-update`: Timestamp of last price update

## Best Practices for Users

1. **Monitor Collateral Ratio**: Keep positions well above 150% to avoid liquidation
2. **Regular Position Updates**: Check position health during market volatility
3. **Gradual Operations**: Make incremental changes to large positions
4. **Price Awareness**: Verify current BTC price before major operations
5. **Emergency Planning**: Maintain additional collateral for market downturns

## System Limitations

1. Maximum single deposit of 100B satoshis
2. BTC price capped at $1M USD
3. Price updates required within 144 blocks
4. Minimum deposit requirement of 1M satoshis

## Technical Requirements

- Stacks blockchain compatibility
- Access to reliable BTC price feed
- Sufficient BTC for collateral deposits
- Understanding of Clarity smart contract interactions

## Risk Considerations

1. **Market Risk**: BTC price volatility affects collateral value
2. **Liquidation Risk**: Positions below 120% ratio face liquidation
3. **Oracle Risk**: Dependency on accurate price feeds
4. **Smart Contract Risk**: Standard contract execution risks
5. **Network Risk**: Stacks blockchain operational considerations

## Contributing

The BBS system is designed for reliability and security. Contributions should focus on:

- Enhanced security measures
- Improved price oracle mechanisms
- Additional user safeguards
- Performance optimizations
- Documentation improvements
