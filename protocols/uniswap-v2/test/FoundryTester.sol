pragma solidity ^0.8.0;
import "./Tester.sol";

/// @title Foundry-specific tester contract
/// @author Antonio Viggiano <@agfviggiano>
/// @notice Serves as a foundry-especific tester contract to be fuzzed
/// @dev Inherits from a base `Tester` contract that exposes all functions to be fuzzed. In invariant tests, foundry requires all target contracts to be deployed on the `setUp` function inherited from the `Test` contract from `forge-std`, which is why `_deploy` is called there, and the foundry-specific `FoundryTester` tester contract receives the target contracts as constructor arguments. In addition, it exposes a `invariantFailed` public view method that will be checked against in order to validate if any assertion failed from the `Asserts` contract.
contract FoundryTester is Tester {
    constructor(
        UniswapV2ERC20 _token1,
        UniswapV2ERC20 _token2,
        UniswapV2Pair _pair,
        UniswapV2Factory _factory,
        UniswapV2Router01 _router
    ) {
        token1 = _token1;
        token2 = _token2;
        pair = _pair;
        factory = _factory;
        router = _router;
    }

    function invariantFailed() public view returns (bool) {
        return fail;
    }
}
