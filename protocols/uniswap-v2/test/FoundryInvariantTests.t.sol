pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "./Setup.sol";
import "./FoundryTester.sol";

contract FoundryInvariantTests is Test, Setup {
    FoundryTester private tester;

    function setUp() public {
        _deploy();
        tester = new FoundryTester(token1, token2, pair, factory, router);
        bytes4[] memory selectors = new bytes4[](4);
        selectors[0] = Tester.provideLiquidityInvariants.selector;
        selectors[1] = Tester.swapTokens.selector;
        selectors[2] = Tester.removeLiquidityInvariants.selector;
        selectors[3] = Tester.pathIndependenceForSwaps.selector;
        targetContract(address(tester));
        targetSelector(
            FuzzSelector({addr: address(tester), selectors: selectors})
        );
    }

    function invariant() public {
        assertFalse(tester.invariantFailed());
    }
}
