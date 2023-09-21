# Foundry DeFi Stablecoin

1. Relative Stability: Anchored or Pegged -> $1.00
    * Chainlink Price Feed
    * Set a function to exchange ETH & BTC -> $$$
2. Stability Mechanism (Minting): Algorithmic (Decentralised)
    * People can only mint Stablecoin with enough collateral (coded)
3. Collateral: Exogenous (Crypto)
    * wETH (Wrapped ETH - ERC20 Version)
    * wBTC (Wrapped BTC - ERC20 Version)

General Mechanism of the DSC System:
* Threshold set to let's say 150%
    * User gives $100 ETH Collateral
    * $50 DSC Minted
    * Collateral Tanks to $74 ETH (20%) due to Market --> UNDERCOLLATERISED !!!
    * Some other user will see this undercollaterised and say I'll pay you back the $50 DSC -> In return, the other user will get all your collateral!
    * So the User will have to suffer for being undercollaterised, while the other user will get a good deal of paying $50 DSC and earning $74 ETH!