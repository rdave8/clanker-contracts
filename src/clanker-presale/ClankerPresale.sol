// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ClankerPresale is ERC721, Ownable, ReentrancyGuard {
    using Strings for uint256;

    struct PresaleConfig {
        uint256 price;
        uint256 maxSupply;
        uint256 maxPerWallet;
    }

    // Presale configuration
    PresaleConfig public config;
    
    // State variables
    uint256 public totalSupply;
    bool public isPresaleActive;
    uint256 public totalRaised;
    
    // Tracking
    mapping(address => uint256) public contributions;
    mapping(address => uint256) public mintCount;
    address[] private contributors;

    // Metadata
    string public baseTokenURI;
    
    // Events
    event PresaleStarted(uint256 startTime, uint256 endTime);
    event PresaleEnded(uint256 totalRaised);
    event TokenPurchased(address indexed buyer, uint256 tokenId, uint256 amount);
    event PresaleConfigUpdated(PresaleConfig config);
    event BaseURIUpdated(string baseURI);
    event FundsWithdrawn(address indexed to, uint256 amount);
    
    // Errors
    error PresaleNotActive();
    error PresaleAlreadyEnded();
    error PresaleNotEnded();
    error MaxSupplyReached();
    error MaxPerWalletReached();
    error InsufficientPayment();
    error InvalidTimestamp();
    error InvalidPrice();
    error InvalidMaxSupply();
    error InvalidMaxPerWallet();

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 price_,
        uint256 maxSupply_,
        uint256 maxPerWallet_,
        string memory baseTokenURI_,
        address owner_
    ) ERC721(name_, symbol_) Ownable(owner_) {
        if (price_ == 0) revert InvalidPrice();
        if (maxSupply_ == 0) revert InvalidMaxSupply();
        if (maxPerWallet_ == 0) revert InvalidMaxPerWallet();

        config = PresaleConfig({
            price: price_,
            maxSupply: maxSupply_,
            maxPerWallet: maxPerWallet_
        });

        baseTokenURI = baseTokenURI_;
        isPresaleActive = true;
        
        emit PresaleConfigUpdated(config);
        emit BaseURIUpdated(baseTokenURI_);
    }

    function purchase(uint256 quantity) external payable nonReentrant {
        // Validate presale state
        if (!isPresaleActive) revert PresaleNotActive();
        
        // Validate purchase
        if (totalSupply + quantity > config.maxSupply) revert MaxSupplyReached();
        if (mintCount[msg.sender] + quantity > config.maxPerWallet) revert MaxPerWalletReached();
        if (msg.value < config.price * quantity) revert InsufficientPayment();

        // Update state
        if (contributions[msg.sender] == 0) {
            contributors.push(msg.sender);
        }
        
        contributions[msg.sender] += msg.value;
        mintCount[msg.sender] += quantity;
        totalRaised += msg.value;

        // Mint tokens
        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = totalSupply + 1;
            _mint(msg.sender, tokenId);
            totalSupply++;
            
            emit TokenPurchased(msg.sender, tokenId, config.price);
        }
    }

    function endPresale() external onlyOwner {
        if (!isPresaleActive) revert PresaleAlreadyEnded();
        
        isPresaleActive = false;
        emit PresaleEnded(totalRaised);
    }

    function withdrawFunds() external onlyOwner {
        if (isPresaleActive) revert PresaleNotEnded();
        
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
        
        emit FundsWithdrawn(owner(), balance);
    }

    function updateConfig(PresaleConfig calldata newConfig) external onlyOwner {
        if (newConfig.price == 0) revert InvalidPrice();
        if (newConfig.maxSupply == 0) revert InvalidMaxSupply();
        if (newConfig.maxPerWallet == 0) revert InvalidMaxPerWallet();

        config = newConfig;
        emit PresaleConfigUpdated(newConfig);
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseTokenURI = newBaseURI;
        emit BaseURIUpdated(newBaseURI);
    }

    // View functions
    function getContributors() external view returns (address[] memory) {
        return contributors;
    }

    function getContribution(address contributor) external view returns (uint256) {
        return contributions[contributor];
    }

    function getTotalRaised() external view returns (uint256) {
        return totalRaised;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        // _requireMinted(tokenId);
        return string(abi.encodePacked(baseTokenURI, tokenId.toString()));
    }
}