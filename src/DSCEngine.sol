// SPDX-License-Identifier: MIT

// Layout of Contract:
// version
// imports
// interfaces, libraries, contracts
// errors
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

pragma solidity ^0.8.18;

import {DecentralisedStableCoin} from "./DecentralisedStableCoin.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title DSCEngine
 * @author Dann Wee
 *
 * The system is designed to be as minimal as possible, and have the tokens maintain a 1 token == $1 peg
 * This stablecoin has the properties:
 * - Exogenous Collateral
 * - Dollar Pegged
 * - Algorithmically Stable
 *
 * It is similar to MakerDAO's DAI if DAI had no governance, no fees, and was only backed by WETH and WBTC
 *
 * Our DSC system should always be "overcollaterised". At no point should the value of all the collateral be <= the $ backed value of all the DSC tokens.
 *
 * @notice This contract is the core of the DSC System. It handles all the logical for mining and redeeming DSC, as well as depositing & withdrawing collateral.
 * @notice This contract is VERY loosely based on the MakerDAO DSS (DAI) System.
 */
contract DSCEngine is ReentrancyGuard {
    /////////////////////////////////
    //////////// Errors /////////////
    /////////////////////////////////
    error DSCEngine__NeedsMoreThanZero();
    error DSCEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength();
    error DSCEngine__NotAllowedToken();
    error DSCEngine__TransferFailed();
    error DSCEngine__BreaksHealthFactor(uint256 healthFactor);
    error DSCEngine__MintFailed();

    /////////////////////////////////
    //////// State Variables ////////
    /////////////////////////////////
    uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10;
    uint256 private constant PRECISION = 1e18;
    uint256 private constant LIQUIDATION_THRESHOLD = 50; // 200% overcollaterised
    uint256 private constant LIQUIDATION_PRECISION = 100;
    uint256 private constant MINT_HEALTH_FACTOR = 1;

    mapping(address token => address priceFeed) private s_priceFeeds; // mapping of token address to price feed address
    mapping(address user => mapping(address token => uint256 amount)) private s_collateralDeposited; // mapping of user address to mapping of token address to amount of token that they have deposited
    mapping(address user => uint256 amountDscMinted) private s_DSCMinted;
    address[] private s_collateralTokens; // array of collateral tokens

    DecentralisedStableCoin private immutable i_dsc;

    /////////////////////////////////
    //////////// Events /////////////
    /////////////////////////////////
    event CollateralDeposited(address indexed user, address indexed token, uint256 amount);

    /////////////////////////////////
    /////////// Modifiers ///////////
    /////////////////////////////////
    modifier moreThanZero(uint256 amount) {
        if (amount == 0) {
            revert DSCEngine__NeedsMoreThanZero();
        }
        _;
    }

    modifier isAllowedToken(address token) {
        // if token is not allowed, then revert
        if (s_priceFeeds[token] == address(0)) {
            revert DSCEngine__NotAllowedToken();
        }
        _;
    }

    /////////////////////////////////
    /////////// Functions ///////////
    /////////////////////////////////
    constructor(
        // these are the allowed tokens and allowed price feeds
        address[] memory tokenAddresses,
        address[] memory priceFeedAddresses,
        address dscAddress
    ) {
        // USD Price Feeds
        if (tokenAddresses.length != priceFeedAddresses.length) {
            revert DSCEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength();
        }
        // For example ETH / USD, BTC / USD, etc
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            // token i = price feed i
            // to set up what tokens are allowed on our platform
            s_priceFeeds[tokenAddresses[i]] = priceFeedAddresses[i];
            s_collateralTokens.push(tokenAddresses[i]); // adding the token to the array of collateral tokens
        }
        i_dsc = DecentralisedStableCoin(dscAddress);
    }

    /////////////////////////////////
    ////// External Functions ///////
    /////////////////////////////////
    function depositCollateralAndMintDsc() external {}

    /**
     * @notice Follows CEI (Checks, Effects, Interactions) pattern
     * @param tokenCollateralAddress The address of the token to deposit as collateral
     * @param amountCollateral The amount of collateral to deposit
     */
    function depositCollateral(address tokenCollateralAddress, uint256 amountCollateral)
        external
        moreThanZero(amountCollateral)
        isAllowedToken(tokenCollateralAddress)
        nonReentrant // reentrancies are one of the most common attack vectors in solidity especially when you work with external contracts (more gas intensive)
    {
        s_collateralDeposited[msg.sender][tokenCollateralAddress] += amountCollateral; // updating the collateral and internal record keeping
        emit CollateralDeposited(msg.sender, tokenCollateralAddress, amountCollateral); // emitting events
        bool success = IERC20(tokenCollateralAddress).transferFrom(msg.sender, address(this), amountCollateral); // transferring the collateral from the user to the contract
        if (!success) {
            revert DSCEngine__TransferFailed();
        }
    }

    function redeemCollateralForDsc() external {}

    function redeemCollateral() external {}

    /**
     * @notice Follows CEI (Checks, Effects, Interactions) pattern
     * @param amountDscToMint The amount of decentralised stablecoin to mint
     * @notice They must have more collateral value than the minimum threshold
     * Check if the collateral value > DSC amount. Involves Price Feeds and Checking Values etc.
     */
    function mintDsc(uint256 amountDscToMint) external moreThanZero(amountDscToMint) nonReentrant {
        s_DSCMinted[msg.sender] += amountDscToMint; // updating the internal record keeping
        // if they mint too much ($150 DSC Minted with only $100 ETH Collateral)
        _revertIfHealthFactorIsBroken(msg.sender);
        bool minted = i_dsc.mint(msg.sender, amountDscToMint); // minting the DSC
        if (!minted) {
            revert DSCEngine__MintFailed();
        }
    }

    function burnDsc() external {}

    function liquidate() external {}

    function getHealthFactor() external view {}

    /////////////////////////////////////////
    /// Private & Internal View Functions ///
    /////////////////////////////////////////
    function _getAccountInformation(address user)
        private
        view
        returns (uint256 totalDscMinted, uint256 collateralValueInUsd)
    {
        totalDscMinted = s_DSCMinted[user]; // get the total DSC minted by the user
        collateralValueInUsd = getAccountCollateralValue(user); // get the total collateral value in USD
    }

    /**
     * Returns how close to liquidation the user is
     * If a user goes below 1, then they can get liquidated
     * @param user Address of the user
     */
    function _healthFactor(address user) private view returns (uint256) {
        // total DSC minted
        // total collateral VALUE
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = _getAccountInformation(user);
        uint256 collateralAdjustedForThreshold = (collateralValueInUsd * LIQUIDATION_THRESHOLD) / LIQUIDATION_PRECISION;

        // 1000 ETH Deposited * 50 = 50,000 / 100 = 500 Health Factor
        return (collateralAdjustedForThreshold * PRECISION) / totalDscMinted;
    }

    // 1. Check Health Factor (Do they have enough collateral)
    // 2. Revert if they don't have enough collateral
    function _revertIfHealthFactorIsBroken(address user) internal view {
        uint256 userhealthFactor = _healthFactor(user);
        if (userhealthFactor < MINT_HEALTH_FACTOR) {
            revert DSCEngine__BreaksHealthFactor(userhealthFactor);
        }
    }

    /////////////////////////////////////////
    /// Public & External View Functions ////
    /////////////////////////////////////////
    function getAccountCollateralValue(address user) public view returns (uint256 totalCollateralValueInUsd) {
        // loop through each collateral token, get the amount they deposited and map it to the price, to get the USD value
        for (uint256 i = 0; i < s_collateralTokens.length; i++) {
            address token = s_collateralTokens[i];
            uint256 amount = s_collateralDeposited[user][token];
            totalCollateralValueInUsd += getUsdValue(token, amount);
        }
        return totalCollateralValueInUsd;
    }

    function getUsdValue(address token, uint256 amount) public view returns (uint256) {
        // get the price feed for the token * price
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[token]);
        (, int256 price,,,) = priceFeed.latestRoundData(); // get the price by calling priceFeed.latestRoundData()
        // 1 ETH = $1000
        // The returned value from CL will be 1000 * 1e8
        return ((uint256(price) * ADDITIONAL_FEED_PRECISION) * amount) / PRECISION; // ((1000 * 1e8) * (1e10)) * 1000 / 1e18
    }
}
