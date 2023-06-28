pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "./Setup.sol";
import "./FoundryTester.sol";

contract FoundryInvariantTests is Test, Setup {
    FoundryTester private tester;

    function setUp() public {
        _deploy();
        tester = new FoundryTester(token1, token2, pair, factory, router);
        targetContract(address(tester));
    }

    function invariant_AlwaysTrue() public {
        assertTrue(true);
    }
}
