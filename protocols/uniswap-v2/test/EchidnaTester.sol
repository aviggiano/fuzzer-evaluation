pragma solidity ^0.8.0;
import "./Tester.sol";
import "./Asserts.sol";

/// @title Echidna-specific tester contract
/// @author Antonio Viggiano <@agfviggiano>
/// @notice Serves as a echidna-especific tester contract to be fuzzed
/// @dev Inherits from a base `Tester` contract that exposes all functions to be fuzzed. In assertion mode, echidna requires all target contracts to be deployed on the tested constructor, which is why `_deploy` is called here.
contract EchidnaTester is Asserts, Tester {
    constructor() {
        _deploy();
    }

    function gt(uint256 a, uint256 b, string memory reason) internal override {
        assertGt(a, b, reason);
    }

    function gte(uint256 a, uint256 b, string memory reason) internal override {
        assertGte(a, b, reason);
    }

    function lt(uint256 a, uint256 b, string memory reason) internal override {
        assertLt(a, b, reason);
    }

    function lte(uint256 a, uint256 b, string memory reason) internal override {
        assertLte(a, b, reason);
    }

    function eq(uint256 a, uint256 b, string memory reason) internal override {
        assertEq(a, b, reason);
    }

    function t(bool b, string memory reason) internal override {
        assertWithMsg(b, reason);
    }
}
