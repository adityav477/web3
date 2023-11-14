
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract Simplestorage{

    uint256 public myfavouritenumber;

    function store(uint256 _favouritenumber) public virtual {
        myfavouritenumber = _favouritenumber;
    }

    //structure 
    struct Person {
        uint256 favouritenumber;
        string name;
    }

    //view - allows you to only read and not write
    //pure - doesn't allws to either read or update
    function retrieve() public view returns(uint256) {
        return myfavouritenumber ;
    }

    //declaring one person
    // Person public persone1 = Person(23,"adi");
    // Person public perosne2 = Person({favouritenumber:23, name:"adity"});


    //array of persons to store the persons info
    //static array : Person[3] public listofperson;

    //dynamic array
    Person[] public listofperson;

    function  addPerson (uint256 favouriteNumber,string memory name) public {
        listofperson.push(Person(favouriteNumber,name));
        nametofavouritenumber[name] = favouriteNumber;
    }

    //calldata and memory
    // string passed as parameter in a function is stored in temporary variable like call data and memory
    //calldata - temporary storage variable which cannot be updated
    //memory - temporaty storage variable which can be updated or changed inside the function which they have been called
    //whenever use the string(which is array of bits),array,mapping etc to pass as a parameter through a function declare the
    //storage as memory, calldate.

    //mapping 
    mapping(string => uint256) public nametofavouritenumber;




}
