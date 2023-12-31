# Foundry DeFi Stablecoin

A Foundry DeFi Stablecoin Project that is part of Cyfrin Solidity Blockchain Course.

1. [DSCEngine on Sepolia Testnet](https://sepolia.etherscan.io/address/0x54fd0af9bf45935aa69ecb95cd725b18a0b0a26f#code)
2. [Dann Stablecoin on Sepolia Testnet](https://sepolia.etherscan.io/address/0x6b09db0dfc4c45f731a6dff1487bc495b026385c#code)

## About

This project is meant to be a stablecoin where users can deposit WETH and WBTC in exchange for a token that will be pegged to the USD.

1. Relative Stability: Anchored or Pegged -> $1.00
    * Chainlink Price Feed
    * Set a function to exchange ETH & BTC -> $$$
2. Stability Mechanism (Minting): Algorithmic (Decentralised)
    * People can only mint Stablecoin with enough collateral (coded)
3. Collateral: Exogenous (Crypto)
    * wETH (Wrapped ETH - ERC20 Version)
    * wBTC (Wrapped BTC - ERC20 Version)

**General Mechanism of the DSC System:**
* Threshold set to let's say 150%
    * User gives $100 ETH Collateral
    * $50 DSC Minted
    * Collateral Tanks to $74 ETH (20%) due to Market --> UNDERCOLLATERALISED !!!
    * Some other user will see this undercollateralised and say I'll pay you back the $50 DSC -> In return, the other user will get all your collateral!
    * So the User will have to suffer for being undercollateralised, while the other user will get a good deal of paying $50 DSC and earning $74 ETH!

## Getting Started

### Requirements

- [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
  - You'll know you did it right if you can run `git --version` and you see a response like `git version x.x.x`
- [foundry](https://getfoundry.sh/)
  - You'll know you did it right if you can run `forge --version` and you see a response like `forge 0.2.0 (816e00b 2023-03-16T00:05:26.396218Z)`

### Quickstart

```
git clone https://github.com/dannweeeee/foundry-defi-stablecoin-f23
cd foundry-defi-stablecoin-f23
forge build
```

## Updates
- The latest version of openzeppelin-contracts has changes in the ERC20Mock file. To follow along with the course, you need to install version 4.8.3 which can be done by ```forge install openzeppelin/openzeppelin-contracts@v4.8.3 --no-commit``` instead of ```forge install openzeppelin/openzeppelin-contracts --no-commit```

## Usage

### Start a local node

```
make anvil
```

### Deploy

This will default to your local node. You need to have it running in another terminal in order for it to deploy.

```
make deploy
```

### Deploy - Other Network

[See below](#deployment-to-a-testnet-or-mainnet)

### Testing

1. Unit Testing
2. Fuzz Testing

In this repo we cover #1 and Fuzzing. 

```
forge test
```

#### Test Coverage

```
forge coverage
```

and for coverage based testing: 

```
forge coverage --report debug
```


## Deployment to a Testnet or Mainnet

1. Setup environment variables

You'll want to set your `SEPOLIA_RPC_URL` and `PRIVATE_KEY` as environment variables. You can add them to a `.env` file, similar to what you see in `.env.example`.

- `PRIVATE_KEY`: The private key of your account (like from [metamask](https://metamask.io/)). **NOTE:** FOR DEVELOPMENT, PLEASE USE A KEY THAT DOESN'T HAVE ANY REAL FUNDS ASSOCIATED WITH IT.
  - You can [learn how to export it here](https://metamask.zendesk.com/hc/en-us/articles/360015289632-How-to-Export-an-Account-Private-Key).
- `SEPOLIA_RPC_URL`: This is url of the sepolia testnet node you're working with. You can get setup with one for free from [Alchemy](https://alchemy.com/?a=673c802981)

Optionally, add your `ETHERSCAN_API_KEY` if you want to verify your contract on [Etherscan](https://etherscan.io/).

1. Get testnet ETH

Head over to [faucets.chain.link](https://faucets.chain.link/) and get some testnet ETH. You should see the ETH show up in your metamask.

2. Deploy

```
make deploy ARGS="--network sepolia"
```

### Scripts

Instead of scripts, we can directly use the `cast` command to interact with the contract. 

For example, on Sepolia:

1. Get some WETH 

```
cast send 0xdd13E55209Fd76AfE204dBda4007C227904f0a81 "deposit()" --value 0.1ether --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY
```

2. Approve the WETH

```
cast send 0xdd13E55209Fd76AfE204dBda4007C227904f0a81 "approve(address,uint256)" 0x54FD0AF9bF45935aA69Ecb95Cd725b18a0b0A26F 1000000000000000000 --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY
```

3. Deposit and Mint DSC

```
cast send 0x54FD0AF9bF45935aA69Ecb95Cd725b18a0b0A26F "depositCollateralAndMintDsc(address,uint256,uint256)" 0xdd13E55209Fd76AfE204dBda4007C227904f0a81 100000000000000000 10000000000000000 --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY
```


### Estimate Gas

You can estimate how much gas things cost by running:

```
forge snapshot
```

And you'll see an output file called `.gas-snapshot`


## Formatting


To run code formatting:
```
forge fmt
```