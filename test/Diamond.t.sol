// SPDX-License-Identifier: UNLICENSED
pragma solidity >0.8.0;

import "forge-std/Test.sol";
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

import "contracts/interfaces/iDiamondCut.sol";

/**
 * @author sshmatrix (BeenSick Labs)
 * @title Helix2 Diamond Tests
 * @notice Tests Helix2 Manager Diamond Wrapper
 */
contract Helix2DiamondTest is Test {
    address public Dev;
    Diamond public DIAMOND;
    DiamondCutFacet public CUT_FACET;
    DiamondInit public INIT;
    ERCFacet public ERC_FACET;
    DiamondLoupeFacet public LOUPE_FACET;
    ViewFacet public VIEW_FACET;
    WriteFacet public WRITE_FACET;

    iDiamondCut public iCUT;

    constructor() {
        Dev = msg.sender;
        /// @dev : deploy DiamondCutFacet
        CUT_FACET = new DiamondCutFacet();
        /// @dev : deploy Diamond
        DIAMOND = new Diamond(address(CUT_FACET), Dev);
        /// @dev : deploy DiamondInit
        INIT = new DiamondInit();
        /// @dev : deploy Diamond facets
        ERC_FACET = new ERCFacet();
        LOUPE_FACET = new DiamondLoupeFacet();
        VIEW_FACET = new ViewFacet();
        WRITE_FACET = new WriteFacet();
        /// @dev : Cut Diamond facets
        iCUT = iDiamondCut(address(DIAMOND));
        /// @notice :
    }
}
