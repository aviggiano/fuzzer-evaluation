pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "./Setup.sol";
import "./FoundryTester.sol";

/// @title Foundry-specific tester contract
/// @author Antonio Viggiano <@agfviggiano>
/// @notice Serves as a foundry-especific `Test` contract to be fuzzed
/// @dev Deploys the foundry-specific `FoundryTester` contract and cherry-picks relevant functions to be fuzzed. Calls `_deploy` to deploy the dependent contracts and exposes the tester as the target contract.
contract FoundryInvariantTests is Test, Setup {
    FoundryTester private tester;

    function setUp() public {
        _deploy();
        tester = new FoundryTester(token1, token2, pair, factory, router);
        bytes4[] memory selectors = new bytes4[](3);
        selectors[0] = Tester.addLiquidity.selector;
        selectors[1] = Tester.removeLiquidity.selector;
        selectors[2] = Tester.swapExactTokensForTokens.selector;
        targetContract(address(tester));
        targetSelector(
            FuzzSelector({addr: address(tester), selectors: selectors})
        );
    }

    function invariant() public {
        assertFalse(tester.failed(), tester.message());
    }
}
