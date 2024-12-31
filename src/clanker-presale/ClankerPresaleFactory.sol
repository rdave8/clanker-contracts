// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ClankerPresale.sol";

contract ClankerPresaleFactory is Ownable {
    error PresaleNotFound();
    error PresaleAlreadyExists();
    error InvalidPrice();
    error InvalidMaxSupply();

    event PresaleCreated(
        address indexed presaleContract,
        address indexed creator,
        string name,
        string symbol,
        uint256 price,
        uint256 maxSupply
    );

    struct PresaleInfo {
        address presaleContract;
        string name;
        string symbol;
        uint256 price;
        uint256 maxSupply;
        uint256 createdAt;
        bool exists;
    }

    mapping(address => PresaleInfo[]) public presalesByCreator;
    mapping(address => PresaleInfo) public presaleInfo;
    mapping(address => bool) public admins;

    constructor(address owner_) Ownable(owner_) {}

    modifier onlyOwnerOrAdmin() {
        require(msg.sender == owner() || admins[msg.sender], "Not authorized");
        _;
    }

    function setAdmin(address admin, bool status) external onlyOwner {
        admins[admin] = status;
    }

    function createPresale(
        string memory name,
        string memory symbol,
        uint256 price,
        uint256 maxSupply,
        uint256 maxPerWallet,
        string memory baseTokenURI,
        address creator
    ) external onlyOwnerOrAdmin returns (address) {
        if (price == 0) revert InvalidPrice();
        if (maxSupply == 0) revert InvalidMaxSupply();

        // Deploy new presale contract
        ClankerPresale presale = new ClankerPresale(
            name,
            symbol,
            price,
            maxSupply,
            maxPerWallet,
            baseTokenURI,
            creator // Set the creator as the owner of the presale
        );

        // Store presale information
        PresaleInfo memory info = PresaleInfo({
            presaleContract: address(presale),
            name: name,
            symbol: symbol,
            price: price,
            maxSupply: maxSupply,
            createdAt: block.timestamp,
            exists: true
        });

        presalesByCreator[creator].push(info);
        presaleInfo[address(presale)] = info;

        emit PresaleCreated(
            address(presale),
            creator,
            name,
            symbol,
            price,
            maxSupply
        );

        return address(presale);
    }

    function getPresalesByCreator(address creator) 
        external 
        view 
        returns (PresaleInfo[] memory) 
    {
        return presalesByCreator[creator];
    }

    function getPresaleInfo(address presaleContract) 
        external 
        view 
        returns (PresaleInfo memory) 
    {
        PresaleInfo memory info = presaleInfo[presaleContract];
        if (!info.exists) revert PresaleNotFound();
        return info;
    }

    function isValidPresale(address presaleContract) 
        external 
        view 
        returns (bool) 
    {
        return presaleInfo[presaleContract].exists;
    }

    // Helper function to get presale stats
    function getPresaleStats(address presaleContract) 
        external 
        view 
        returns (
            uint256 totalSupply,
            uint256 totalRaised,
            bool isActive
        ) 
    {
        if (!presaleInfo[presaleContract].exists) revert PresaleNotFound();
        
        ClankerPresale presale = ClankerPresale(presaleContract);
        return (
            presale.totalSupply(),
            presale.getTotalRaised(),
            presale.isPresaleActive()
        );
    }
}