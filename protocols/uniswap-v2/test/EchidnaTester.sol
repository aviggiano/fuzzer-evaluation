pragma solidity ^0.8.0;
import "./Tester.sol";

/// @title Echidna-specific tester contract
/// @author Antonio Viggiano <@agfviggiano>
/// @notice Serves as a echidna-especific tester contract to be fuzzed
/// @dev Inherits from a base `Tester` contract that exposes all functions to be fuzzed. In assertion mode, echidna requires all target contracts to be deployed on the tested constructor, which is why `_deploy` is called here.
contract EchidnaTester is Tester {
    constructor() {
        _deploy();
    }
}
