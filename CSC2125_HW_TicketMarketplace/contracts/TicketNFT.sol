// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {ITicketNFT} from "./interfaces/ITicketNFT.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract TicketNFT is ERC1155, ITicketNFT, Ownable {
    constructor() ERC1155("https://api.example.com/token/{id}") Ownable(msg.sender) {}

    function mintFromMarketPlace(address to, uint256 nftId) external override onlyOwner {
        _mint(to, nftId, 1, "");
    }
}