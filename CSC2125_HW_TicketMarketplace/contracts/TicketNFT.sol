// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ITicketNFT} from "./interfaces/ITicketNFT.sol";

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract TicketNFT is ERC1155, Ownable, ITicketNFT {
    address public marketplace;

    constructor() ERC1155("") Ownable(msg.sender) {}

    function setMarketplace(address _marketplace) external onlyOwner {
        require(_marketplace != address(0), "Invalid marketplace address");
        marketplace = _marketplace;
        _transferOwnership(_marketplace);
    }

    function mintFromMarketPlace(address to, uint256 nftId) external {
        require(msg.sender == marketplace, "Not authorized");
        _mint(to, nftId, 1, "");
    }
}