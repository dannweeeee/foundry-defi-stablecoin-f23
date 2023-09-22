// SPDX-License-Identifier: MIT

// Have our invariant aka properties hold true for all time

// What are our Invariants?
// 1. The total supply of DSC should be less than the total value of collateral
// 2. Getter view functions should never revert <- evergreen invariant

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralisedStableCoin} from "../../src/DecentralisedStableCoin.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Handler} from "./Handler.t.sol";

contract InvariantsTest is StdInvariant, Test {
    DeployDSC deployer;
    DSCEngine dsce;
    DecentralisedStableCoin dsc;
    HelperConfig config;
    address weth;
    address wbtc;
    Handler handler;

    function setUp() external {
        deployer = new DeployDSC();
        (dsc, dsce, config) = deployer.run();
        (,, weth, wbtc,) = config.activeNetworkConfig();
        // targetContract(address(dsce)); // set the target contract
        // Call the target contract sensibly - for example, don't call redeemcollateral unless there is collateral to redeem
        handler = new Handler(dsce, dsc);
        targetContract(address(handler));
    }

    function invariant_protocolMustHaveMoreValueThanTotalSupplyHandlerBasedTesting() public view {
        // get the value of all the collateral in the protocol
        // compare it to all the debt (dsc)
        uint256 totalSupply = dsc.totalSupply();
        uint256 totalWethDeposited = IERC20(weth).balanceOf(address(dsce));
        uint256 totalWbtcDeposited = IERC20(wbtc).balanceOf(address(dsce));

        uint256 wethValue = dsce.getUsdValue(weth, totalWethDeposited);
        uint256 wbtcValue = dsce.getUsdValue(wbtc, totalWbtcDeposited);

        console.log("weth value ", wethValue);
        console.log("wbtc value ", wbtcValue);
        console.log("total supply ", totalSupply);
        console.log("times mint called: ", handler.timesMintIsCalled());

        assert(wethValue + wbtcValue >= totalSupply);
    }

    function invariant_allGetterFunctionsShouldNotRevert() public view {
        dsce.getHealthFactor(msg.sender);
        dsce.getCollateralTokenPriceFeed(address(dsc));
        dsce.getDsc();
        dsce.getCollateralTokens();
        dsce.getMinHealthFactor();
        dsce.getLiquidationPrecision();
        dsce.getLiquidationBonus();
        dsce.getLiquidationThreshold();
        dsce.getAdditionalFeedPrecision();
        dsce.getPrecision();
        dsce.getCollateralBalanceOfUser(weth, address(this));
        dsce.getAccountInformation(msg.sender);
        dsce.getUsdValue(weth, 1);
        dsce.getAccountCollateralValue(msg.sender);
        dsce.getTokenAmountFromUsd(weth, 1);
    }
}
