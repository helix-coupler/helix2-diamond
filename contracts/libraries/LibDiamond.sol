// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {iDiamondCut} from "../interfaces/iDiamondCut.sol";

error InitializationFunctionReverted(address _initializationContractAddress, bytes _calldata);

/**
 * @dev EIP-2535 Diamond Cut Facet
 */
library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    /// @notice Diamond Storage
    struct DiamondStorage {
        mapping(bytes4 => bytes32) facets; // function selectors → facets
        mapping(uint256 => bytes32) selectorSlots; // slots → facets
        uint16 selectorCount; // number of function selectors in selectorSlots
        mapping(bytes4 => bool) supportedInterfaces;
        address Dev;
        /// @dev : set custom variables here
        // Helix2 Core Variables
        string[4] illegalBlocks; // forbidden characters
        uint256[2][4] sizes; // label sizes for each struct in order [<name>, <bond>, <molecule>, <polycule>]
        uint256[4] lifespans; // default lifespans in seconds for each struct in order [<name>, <bond>, <molecule>, <polycule>]
        bytes32[4] roothash; // Root identifier
        address ensRegistry; // ENS Registry
        address[4] helix2Registry; // Helix2 Registries
        address[4] helix2Registrar; // Helix2 Registrars
        bool active; // pause/resume contract
    }

    /// @dev : Storage access function
    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    /// @dev : Events
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event NewLives(uint256[4] newLives);
    event NewLife(uint256 index, uint256 newLife);
    event NewRegisteries(address[4] newReg);
    event NewRegistry(uint256 index, address newReg);
    event NewRegistrars(address[4] newReg);
    event NewRegistrar(uint256 index, address newReg);
    event NewENSRegistry(address newReg);

    /// @notice Diamond External Functions
    /// @dev : Modifier to allow only dev
    function onlyDev() internal view {
        require(msg.sender == diamondStorage().Dev, "NOT_DEV");
    }

    /**
     * @dev transfer contract ownership to new Dev
     * @param _newDev : new Dev
     */
    function setDev(address _newDev) internal {
        address previousOwner = diamondStorage().Dev;
        diamondStorage().Dev = _newDev;
        emit OwnershipTransferred(previousOwner, _newDev);
    }

    /**
     * @dev sets new list of lifespans
     * @param _newLives : list of new lifespans
     */
    function setLives(uint256[4] calldata _newLives) internal {
        diamondStorage().lifespans = _newLives;
        emit NewLives(_newLives);
    }

    /**
     * @dev replace single lifespan value
     * @param index : index to replace (starts from 0)
     * @param _newLife : new lifespan for index
     */
    function setLife(uint256 index, uint256 _newLife) internal {
        diamondStorage().lifespans[index] = _newLife;
        emit NewLife(index, _newLife);
    }

    /**
     * @dev migrate all Helix2 Registeries
     * @param newReg : new Registry array
     */
    function setRegisteries(address[4] calldata newReg) internal {
        diamondStorage().helix2Registry = newReg;
        emit NewRegisteries(newReg);
    }

    /**
     * @dev replace one index of Helix2 Register
     * @param index : index to replace (starts from 0)
     * @param newReg : new Register for index
     */
    function setRegistry(uint256 index, address newReg) internal {
        diamondStorage().helix2Registry[index] = newReg;
        emit NewRegistry(index, newReg);
    }

    /**
     * @dev migrate all Helix2 Registrars
     * @param newReg : new Registrar array
     */
    function setRegistrars(address[4] calldata newReg) internal {
        diamondStorage().helix2Registrar = newReg;
        emit NewRegistrars(newReg);
    }

    /**
     * @dev replace one index of Helix2 Registrar
     * @param index : index to replace (starts from 0)
     * @param newReg : new Registrar for index
     */
    function setRegistrar(uint256 index, address newReg) internal {
        diamondStorage().helix2Registrar[index] = newReg;
        emit NewRegistrar(index, newReg);
    }

    /**
     * @dev sets ENS Registry if it migrates
     * @param newReg : new Register for index
     */
    function setENSRegistry(address newReg) internal {
        diamondStorage().ensRegistry = newReg;
        emit NewENSRegistry(newReg);
    }

    /// @dev returns owner of contract
    function Dev() internal view returns (address) {
        return diamondStorage().Dev;
    }

    /// @dev checks if an interface is supported
    function checkInterface(bytes4 sig) internal view returns (bool) {
        return diamondStorage().supportedInterfaces[sig];
    }

    /// @dev checks if an interface is supported
    function _setInterface(bytes4 sig, bool value) internal {
        diamondStorage().supportedInterfaces[sig] = value;
    }

    /// @dev returns illegal blocks list
    function illegalBlocks() internal view returns (string[4] memory) {
        return diamondStorage().illegalBlocks;
    }

    /// @dev returns illegal sizes list
    function sizes() internal view returns (uint256[2][4] memory) {
        return diamondStorage().sizes;
    }

    /// @dev returns lifespans array
    function lifespans() internal view returns (uint256[4] memory) {
        return diamondStorage().lifespans;
    }

    /// @dev returns Registeries
    function registries() internal view returns (address[4] memory) {
        return diamondStorage().helix2Registry;
    }

    /// @dev returns Registrars
    function registrars() internal view returns (address[4] memory) {
        return diamondStorage().helix2Registrar;
    }

    /// @dev returns hashes of root labels
    function roothash() internal view returns (bytes32[4] memory) {
        return diamondStorage().roothash;
    }

    /// @dev returns ENS Registry address
    function ensRegistry() internal view returns (address) {
        return diamondStorage().ensRegistry;
    }

    /// @notice Diamond Section
    event DiamondCut(iDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    bytes32 constant CLEAR_ADDRESS_MASK = bytes32(uint256(0xffffffffffffffffffffffff));
    bytes32 constant CLEAR_SELECTOR_MASK = bytes32(uint256(0xffffffff << 224));

    /// @dev : Internal function version of diamondCut
    function diamondCut(iDiamondCut.FacetCut[] memory _diamondCut, address _init, bytes memory _calldata) internal {
        DiamondStorage storage ds = diamondStorage();
        uint256 originalSelectorCount = ds.selectorCount;
        uint256 selectorCount = originalSelectorCount;
        bytes32 selectorSlot;
        // Check if last selector slot is not full
        // "selectorCount & 7" is a gas efficient modulo by eight "selectorCount % 8"
        if (selectorCount & 7 > 0) {
            // get last selectorSlot
            // "selectorSlot >> 3" is a gas efficient division by 8 "selectorSlot / 8"
            selectorSlot = ds.selectorSlots[selectorCount >> 3];
        }
        // loop through diamond cut
        for (uint256 facetIndex; facetIndex < _diamondCut.length; ) {
            (selectorCount, selectorSlot) = addReplaceRemoveFacetSelectors(
                selectorCount,
                selectorSlot,
                _diamondCut[facetIndex].facetAddress,
                _diamondCut[facetIndex].action,
                _diamondCut[facetIndex].functionSelectors
            );

            unchecked {
                facetIndex++;
            }
        }
        if (selectorCount != originalSelectorCount) {
            ds.selectorCount = uint16(selectorCount);
        }
        // If last selector slot is not full
        // "selectorCount & 7" is a gas efficient modulo by eight "selectorCount % 8"
        if (selectorCount & 7 > 0) {
            // "selectorSlot >> 3" is a gas efficient division by 8 "selectorSlot / 8"
            ds.selectorSlots[selectorCount >> 3] = selectorSlot;
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addReplaceRemoveFacetSelectors(
        uint256 _selectorCount,
        bytes32 _selectorSlot,
        address _newFacetAddress,
        iDiamondCut.FacetCutAction _action,
        bytes4[] memory _selectors
    ) internal returns (uint256, bytes32) {
        DiamondStorage storage ds = diamondStorage();
        require(_selectors.length > 0, "NO_SELECTORS");
        if (_action == iDiamondCut.FacetCutAction.Add) {
            enforceHasContractCode(_newFacetAddress, "EMPTY_FACET");
            for (uint256 selectorIndex; selectorIndex < _selectors.length; ) {
                bytes4 selector = _selectors[selectorIndex];
                bytes32 oldFacet = ds.facets[selector];
                require(address(bytes20(oldFacet)) == address(0), "DUPLICATE_FUNCTION");
                // add facet for selector
                ds.facets[selector] = bytes20(_newFacetAddress) | bytes32(_selectorCount);
                // "_selectorCount & 7" is a gas efficient modulo by eight "_selectorCount % 8"
                // " << 5 is the same as multiplying by 32 ( * 32)
                uint256 selectorInSlotPosition = (_selectorCount & 7) << 5;
                // clear selector position in slot and add selector
                _selectorSlot = (_selectorSlot & ~(CLEAR_SELECTOR_MASK >> selectorInSlotPosition)) | (bytes32(selector) >> selectorInSlotPosition);
                // if slot is full then write it to storage
                if (selectorInSlotPosition == 224) {
                    // "_selectorSlot >> 3" is a gas efficient division by 8 "_selectorSlot / 8"
                    ds.selectorSlots[_selectorCount >> 3] = _selectorSlot;
                    _selectorSlot = 0;
                }
                _selectorCount++;

                unchecked {
                    selectorIndex++;
                }
            }
        } else if (_action == iDiamondCut.FacetCutAction.Replace) {
            enforceHasContractCode(_newFacetAddress, "EMPTY_FACET");
            for (uint256 selectorIndex; selectorIndex < _selectors.length; ) {
                bytes4 selector = _selectors[selectorIndex];
                bytes32 oldFacet = ds.facets[selector];
                address oldFacetAddress = address(bytes20(oldFacet));
                // only useful if immutable functions exist
                require(oldFacetAddress != address(this), "NOT_ALLOWED");
                /// @notice : useful for immutable functions only
                /// disabled since Helix2 doesn't have immutable functions
                /// this allows replacing a function with itself
                require(oldFacetAddress != _newFacetAddress, "DUPLICATE_FUNCTION");
                require(oldFacetAddress != address(0), "NOT_FOUND");
                // replace old facet address
                ds.facets[selector] = (oldFacet & CLEAR_ADDRESS_MASK) | bytes20(_newFacetAddress);

                unchecked {
                    selectorIndex++;
                }
            }
        } else if (_action == iDiamondCut.FacetCutAction.Remove) {
            require(_newFacetAddress == address(0), "CANNOT_REPLACE");
            // "_selectorCount >> 3" is a gas efficient division by 8 "_selectorCount / 8"
            uint256 selectorSlotCount = _selectorCount >> 3;
            // "_selectorCount & 7" is a gas efficient modulo by eight "_selectorCount % 8"
            uint256 selectorInSlotIndex = _selectorCount & 7;
            for (uint256 selectorIndex; selectorIndex < _selectors.length; ) {
                if (_selectorSlot == 0) {
                    // get last selectorSlot
                    selectorSlotCount--;
                    _selectorSlot = ds.selectorSlots[selectorSlotCount];
                    selectorInSlotIndex = 7;
                } else {
                    selectorInSlotIndex--;
                }
                bytes4 lastSelector;
                uint256 oldSelectorsSlotCount;
                uint256 oldSelectorInSlotPosition;
                // adding a block here prevents stack too deep error
                {
                    bytes4 selector = _selectors[selectorIndex];
                    bytes32 oldFacet = ds.facets[selector];
                    require(address(bytes20(oldFacet)) != address(0), "NOT_FOUND");
                    // only useful if immutable functions exist
                    require(address(bytes20(oldFacet)) != address(this), "NOT_ALLOWED");
                    // replace selector with last selector in ds.facets
                    // gets the last selector
                    // " << 5 is the same as multiplying by 32 ( * 32)
                    lastSelector = bytes4(_selectorSlot << (selectorInSlotIndex << 5));
                    if (lastSelector != selector) {
                        // update last selector slot position info
                        ds.facets[lastSelector] = (oldFacet & CLEAR_ADDRESS_MASK) | bytes20(ds.facets[lastSelector]);
                    }
                    delete ds.facets[selector];
                    uint256 oldSelectorCount = uint16(uint256(oldFacet));
                    // "oldSelectorCount >> 3" is a gas efficient division by 8 "oldSelectorCount / 8"
                    oldSelectorsSlotCount = oldSelectorCount >> 3;
                    // "oldSelectorCount & 7" is a gas efficient modulo by eight "oldSelectorCount % 8"
                    // " << 5 is the same as multiplying by 32 ( * 32)
                    oldSelectorInSlotPosition = (oldSelectorCount & 7) << 5;
                }
                if (oldSelectorsSlotCount != selectorSlotCount) {
                    bytes32 oldSelectorSlot = ds.selectorSlots[oldSelectorsSlotCount];
                    // clears the selector we are deleting and puts the last selector in its place.
                    oldSelectorSlot =
                        (oldSelectorSlot & ~(CLEAR_SELECTOR_MASK >> oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);
                    // update storage with the modified slot
                    ds.selectorSlots[oldSelectorsSlotCount] = oldSelectorSlot;
                } else {
                    // clears the selector we are deleting and puts the last selector in its place.
                    _selectorSlot =
                        (_selectorSlot & ~(CLEAR_SELECTOR_MASK >> oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);
                }
                if (selectorInSlotIndex == 0) {
                    delete ds.selectorSlots[selectorSlotCount];
                    _selectorSlot = 0;
                }

                unchecked {
                    selectorIndex++;
                }
            }
            _selectorCount = selectorSlotCount * 8 + selectorInSlotIndex;
        } else {
            revert("BAD_ACTION");
        }
        return (_selectorCount, _selectorSlot);
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            return;
        }
        enforceHasContractCode(_init, "EMPTY_INIT");
        (bool success, bytes memory error) = _init.delegatecall(_calldata);
        if (!success) {
            if (error.length > 0) {
                // bubble up error
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(error)
                    revert(add(32, error), returndata_size)
                }
            } else {
                revert InitializationFunctionReverted(_init, _calldata);
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}
