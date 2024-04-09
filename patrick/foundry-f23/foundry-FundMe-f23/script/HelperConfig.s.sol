// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
//no we need Mock Aggregator to deploy on local chain for getting it's interfaces like version and pricefeed
import {MockV3Aggregator} from "../test/mock/MockV3Aggregator.sol";

contract HelperConfig is Script{
  //to save the network address and other infromation related to a blockchain that can be neded in future
  // that's why we make it as struct instead of simple address
  struct NetworkDetails {
    address priceFeed;
  }

  //to store the actual network 
  NetworkDetails public actualNetworkAddress;

  constructor() {
  uint256 chainId = block.chainid;
  if(chainId == 11155111){
    actualNetworkAddress = getSepolia();
  }else {
       actualNetworkAddress = getGanache();
  }
  }

  //to return sepolica address
  function getSepolia() public pure returns(NetworkDetails memory){
    return NetworkDetails({priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306});
  }

  //to return local ganache address 

  function getGanache() public returns (NetworkDetails memory){
    if(actualNetworkAddress.priceFeed != address(0)){
      return actualNetworkAddress;
    }

    vm.startBroadcast();
    MockV3Aggregator mockV3Aggregator = new MockV3Aggregator(8,2000e8);
    vm.stopBroadcast();

    return NetworkDetails({priceFeed: address(mockV3Aggregator) });
  }

}
