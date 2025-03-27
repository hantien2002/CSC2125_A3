// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {TicketNFT} from "./TicketNFT.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TicketMarketplace is Ownable {
    struct Event {
        uint256 nextTicketToSell;
        uint256 maxTickets;
        uint256 pricePerTicket;
        uint256 pricePerTicketERC20;
    }

    TicketNFT public ticketNFT;
    IERC20 public erc20Token;
    uint256 public currentEventId;
    mapping(uint256 => Event) public events;

    event EventCreated(uint256 indexed eventId, uint256 maxTickets, uint256 pricePerTicket, uint256 pricePerTicketERC20);
    event MaxTicketsUpdated(uint256 indexed eventId, uint256 newMaxTickets);
    event PriceUpdated(uint256 indexed eventId, uint256 newPrice);
    event TicketsBought(uint256 indexed eventId, address indexed buyer, uint256 ticketCount, uint256 startSeatNumber);
    event TicketsBoughtERC20(uint256 indexed eventId, address indexed buyer, uint256 ticketCount, uint256 startSeatNumber);

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

    function createEvent(uint256 maxTickets, uint256 pricePerTicket, uint256 pricePerTicketERC20) external {
        require(msg.sender == owner(), "Unauthorized access");
        require(maxTickets > 0, "Max tickets must be greater than 0");
        require(pricePerTicket > 0, "Price per ticket must be greater than 0");
        require(pricePerTicketERC20 > 0, "Price per ticket in ERC20 must be greater than 0");
        
        events[currentEventId] = Event({
            nextTicketToSell: 0,
            maxTickets: maxTickets,
            pricePerTicket: pricePerTicket,
            pricePerTicketERC20: pricePerTicketERC20
        });

        emit EventCreated(currentEventId, maxTickets, pricePerTicket, pricePerTicketERC20);
        currentEventId++;
    }

    function setMaxTicketsForEvent(uint256 eventId, uint256 newMaxTickets) external {
        require(msg.sender == owner(), "Unauthorized access");
        require(events[eventId].maxTickets > 0, "Event does not exist");
        require(newMaxTickets > 0, "Max tickets must be greater than 0");
        require(newMaxTickets >= events[eventId].nextTicketToSell, "The new number of max tickets is too small!");
        require(newMaxTickets >= events[eventId].maxTickets, "The new number of max tickets is too small!");

        events[eventId].maxTickets = newMaxTickets;
        emit MaxTicketsUpdated(eventId, newMaxTickets);
    }

    function setPriceForTicketETH(uint256 eventId, uint256 newPrice) external {
        require(msg.sender == owner(), "Unauthorized access");
        require(events[eventId].maxTickets > 0, "Event does not exist");
        require(newPrice > 0, "Price must be greater than 0");

        events[eventId].pricePerTicket = newPrice;
        emit PriceUpdated(eventId, newPrice);
    }

    function setPriceForTicketERC20(uint256 eventId, uint256 newPrice) external {
        require(msg.sender == owner(), "Unauthorized access");
        require(events[eventId].maxTickets > 0, "Event does not exist");
        require(newPrice > 0, "Price must be greater than 0");

        events[eventId].pricePerTicketERC20 = newPrice;
        emit PriceUpdated(eventId, newPrice);
    }

    function buyTickets(uint256 eventId, uint256 ticketCount) external payable {
        require(events[eventId].maxTickets > 0, "Event does not exist");
        require(ticketCount > 0 && ticketCount <= events[eventId].maxTickets - events[eventId].nextTicketToSell, "Not enough tickets available");
        require(events[eventId].nextTicketToSell + ticketCount <= events[eventId].maxTickets, "Seat number too large");
        require(msg.value >= events[eventId].pricePerTicket * ticketCount, "Insufficient payment");

        for (uint256 i = 0; i < ticketCount; i++) {
            uint256 ticketId = (uint256(eventId) << 128) + (events[eventId].nextTicketToSell + i);
            ticketNFT.mintFromMarketPlace(msg.sender, ticketId);
        }

        events[eventId].nextTicketToSell += ticketCount;
        emit TicketsBought(eventId, msg.sender, ticketCount, events[eventId].nextTicketToSell - ticketCount);
    }

    function buyTicketsERC20(uint256 eventId, uint256 ticketCount) external {
        require(events[eventId].maxTickets > 0, "Event does not exist");
        require(ticketCount > 0 && ticketCount <= events[eventId].maxTickets - events[eventId].nextTicketToSell, "Not enough tickets available");
        require(events[eventId].nextTicketToSell + ticketCount <= events[eventId].maxTickets, "Seat number too large");
        require(erc20Token.transferFrom(msg.sender, address(this), events[eventId].pricePerTicketERC20 * ticketCount), "Insufficient payment");

        for (uint256 i = 0; i < ticketCount; i++) {
            uint256 ticketId = (uint256(eventId) << 128) + (events[eventId].nextTicketToSell + i);
            ticketNFT.mintFromMarketPlace(msg.sender, ticketId);
        }

        events[eventId].nextTicketToSell += ticketCount;
        emit TicketsBoughtERC20(eventId, msg.sender, ticketCount, events[eventId].nextTicketToSell - ticketCount);
    }

    function setERC20Address(address _erc20Token) external {
        require(msg.sender == owner(), "Unauthorized access");
        require(_erc20Token != address(0), "Invalid ERC20 address");
        erc20Token = IERC20(_erc20Token);
    }
}
