pragma solidity ^0.8.0;
import "./Setup.sol";

/// @title Foundry/Echidna compatible assertion contract
/// @author Antonio Viggiano <@agfviggiano>
/// @notice Serves as a compatible assertion contract to compare foundry and echidna
/// @dev Due to how invariant testing works in foundry, each specific tester contract must implement these assertion functions. See https://github.com/foundry-rs/foundry/issues/5259
abstract contract Asserts {
    function gt(uint256 a, uint256 b, string memory reason) internal virtual;

    function gte(uint256 a, uint256 b, string memory reason) internal virtual;

    function lt(uint256 a, uint256 b, string memory reason) internal virtual;

    function lte(uint256 a, uint256 b, string memory reason) internal virtual;

    function eq(uint256 a, uint256 b, string memory reason) internal virtual;

    function t(bool b, string memory reason) internal virtual;
}
