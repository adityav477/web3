// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Simplestorage} from "./Simplestorage.sol";

contract StorageFactory {

    Simplestorage[] public listofSimplestorageContracts;

    function createSimplestorage() public   {
        listofSimplestorageContracts.push(new Simplestorage());
    }

    function sfStore(uint256 _simplostorageIndex,uint256 _newSimpleStorageNumber) public {
        Simplestorage mySimplestorage = listofSimplestorageContracts[_simplostorageIndex];
        mySimplestorage.store(_newSimpleStorageNumber);
        //listofSimplestorageContracts[_simplestorageIndex].store(_newSimpleStorageNumber);
    }

    function sfGet(uint _simplestorageIndex) public view returns(uint256){
        // Simplestorage mySimplestorage = listofSimplestorageContracts[_simplestorageIndex];
        // return mySimplestorage.retrieve();
        return listofSimplestorageContracts[_simplestorageIndex].retrieve();
        
    }
}

 
