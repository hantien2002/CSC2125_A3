// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ITicketNFT} from "./interfaces/ITicketNFT.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {TicketNFT} from "./TicketNFT.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol"; 
import {ITicketMarketplace} from "./interfaces/ITicketMarketplace.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract TicketMarketplace is ITicketMarketplace, Ownable {
    struct Event {
        uint128 maxTickets;
        uint256 pricePerTicket;
        uint256 pricePerTicketERC20;
        uint128 ticketsSold;
        uint128 nextTicketToSell;
    }

    TicketNFT public immutable ticketNFT;
    IERC20 public erc20Token;
    mapping(uint128 => Event) public events;
    uint128 public nextEventId;

    constructor(address _ticketNFT, address _erc20Token) Ownable(msg.sender) {
        ticketNFT = TicketNFT(_ticketNFT);
        erc20Token = IERC20(_erc20Token);
    }

    function nftContract() external view returns (address) {
        return address(ticketNFT);
    }

    function ERC20Address() external view returns (address) {
        return address(erc20Token);
    }

    function currentEventId() external view returns (uint128) {
        return nextEventId;
    }

    function createEvent(uint128 maxTickets, uint256 pricePerTicket, uint256 pricePerTicketERC20) external override onlyOwner {
        require(maxTickets > 0, "Max tickets must be greater than 0");
        require(pricePerTicket > 0, "ETH price must be greater than 0");
        require(pricePerTicketERC20 > 0, "ERC20 price must be greater than 0");
        
        events[nextEventId] = Event({
            maxTickets: maxTickets,
            pricePerTicket: pricePerTicket,
            pricePerTicketERC20: pricePerTicketERC20,
            ticketsSold: 0,
            nextTicketToSell: 0
        });

        emit EventCreated(nextEventId, maxTickets, pricePerTicket, pricePerTicketERC20);
        nextEventId++;
    }

    function setMaxTicketsForEvent(uint128 eventId, uint128 newMaxTickets) external override onlyOwner {
        require(newMaxTickets > 0, "Max tickets must be greater than 0");
        require(newMaxTickets >= events[eventId].ticketsSold, "The new number of max tickets is too small!");
        
        events[eventId].maxTickets = newMaxTickets;
        emit MaxTicketsUpdate(eventId, newMaxTickets);
    }

    function setPriceForTicketETH(uint128 eventId, uint256 price) external override onlyOwner {
        require(price > 0, "Price must be greater than 0");
        
        events[eventId].pricePerTicket = price;
        emit PriceUpdate(eventId, price, "ETH");
    }

    function setPriceForTicketERC20(uint128 eventId, uint256 price) external override onlyOwner {
        require(price > 0, "Price must be greater than 0");
        
        events[eventId].pricePerTicketERC20 = price;
        emit PriceUpdate(eventId, price, "ERC20");
    }

    function buyTickets(uint128 eventId, uint128 ticketCount) external payable override {
        Event storage event_ = events[eventId];
        require(event_.maxTickets > 0, "Event does not exist");
        require(event_.ticketsSold + ticketCount <= event_.maxTickets, "We don't have that many tickets left to sell!");
        
        uint256 totalCost = event_.pricePerTicket * ticketCount;
        require(totalCost <= msg.value, "Not enough funds supplied to buy the specified number of tickets.");

        uint256 startSeatNumber = event_.ticketsSold + 1;
        for (uint128 i = 0; i < ticketCount; i++) {
            uint256 ticketId = (uint256(eventId) << 128) + startSeatNumber + i;
            ticketNFT.mintFromMarketPlace(msg.sender, ticketId);
        }

        event_.ticketsSold += ticketCount;
        emit TicketsBought(eventId, ticketCount, "ETH");
    }

    function buyTicketsERC20(uint128 eventId, uint128 ticketCount) external override {
        Event storage event_ = events[eventId];
        require(event_.maxTickets > 0, "Event does not exist");
        require(event_.ticketsSold + ticketCount <= event_.maxTickets, "We don't have that many tickets left to sell!");
        require(erc20Token != IERC20(address(0)), "ERC20 token not set");
        
        uint256 totalCost = event_.pricePerTicketERC20 * ticketCount;
        require(erc20Token.transferFrom(msg.sender, address(this), totalCost), "ERC20 transfer failed");

        uint256 startSeatNumber = event_.ticketsSold + 1;
        for (uint128 i = 0; i < ticketCount; i++) {
            uint256 ticketId = (uint256(eventId) << 128) + startSeatNumber + i;
            ticketNFT.mintFromMarketPlace(msg.sender, ticketId);
        }

        event_.ticketsSold += ticketCount;
        emit TicketsBought(eventId, ticketCount, "ERC20");
    }

    function setERC20Address(address newERC20Address) external override onlyOwner {
        require(newERC20Address != address(0), "Invalid ERC20 address");
        erc20Token = IERC20(newERC20Address);
        emit ERC20AddressUpdate(newERC20Address);
    }
}