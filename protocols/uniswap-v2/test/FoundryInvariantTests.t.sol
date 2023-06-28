pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "./Setup.sol";
import "./InvariantTester.sol";

contract FoundryInvariantTests is Test, Setup {
    InvariantTester private tester;

    function setUp() public {
        _deploy();
        tester = new InvariantTester(token1, token2, pair, factory, router);
        targetContract(address(tester));
    }

    function invariant_AlwaysTrue() public {
        assertTrue(true);
    }
}
