// SPDX-License-Identifier: UNLICENSED
pragma solidity >0.8.0;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
// Diamond
import "contracts/Diamond.sol";
import "contracts/facets/DiamondCutFacet.sol";
import "contracts/facets/DiamondLoupeFacet.sol";
import "contracts/facets/ERCFacet.sol";
import "contracts/facets/ViewFacet.sol";
import "contracts/facets/WriteFacet.sol";
import "contracts/libraries/LibDiamond.sol";
import "contracts/upgradeInitializers/DiamondInit.sol";

/**
 * @author sshmatrix (BeenSick Labs)
 * @title Helix2 Diamond Tests
 * @notice Tests Helix2 Manager Diamond Wrapper
 */
contract Helix2Diamond is Script {
    function run() external {
        vm.startBroadcast();
        vm.stopBroadcast();
    }
}
