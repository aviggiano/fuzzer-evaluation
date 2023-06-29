pragma solidity ^0.8.0;

/// @title Foundry/Echidna compatible handler contract
/// @author Justin Jacob <@technovision99>, Antonio Viggiano <@agfviggiano>
/// @notice Serves as a compatible user/handler contract to compare foundry and echidna. This contract was largely inspired by @technovision99's work on the `crytic/echidna-streaming-series` repository.
/// @dev Can proxy requests to an arbitrary target and calldata.
contract User {
    function proxy(
        address _target,
        bytes memory _calldata
    ) public returns (bool success, bytes memory returnData) {
        (success, returnData) = address(_target).call(_calldata);
    }
}
