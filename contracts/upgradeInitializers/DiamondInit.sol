// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibDiamond} from "../libraries/LibDiamond.sol";
import {iDiamondLoupe} from "../interfaces/iDiamondLoupe.sol";
import {iDiamondCut} from "../interfaces/iDiamondCut.sol";
import {iERC173} from "../interfaces/iERC173.sol";
import {iERC165} from "../interfaces/iERC165.sol";

/**
 * @dev EIP-2535 Diamond Init
 */
contract DiamondInit {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @dev : Set state variables
    function init() external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.supportedInterfaces[type(iERC165).interfaceId] = true;
        ds.supportedInterfaces[type(iDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(iDiamondLoupe).interfaceId] = true;
        ds.supportedInterfaces[type(iERC173).interfaceId] = true;
        // add more state variables here
    }
}
