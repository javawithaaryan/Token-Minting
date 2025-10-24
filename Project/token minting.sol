// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Time-Locked Inheritance Vault
 * @dev A smart contract for managing digital asset inheritance with time-locks and beneficiary tokens
 */
contract Project {
    
    // Struct to store vault information
    struct Vault {
        address owner;
        address beneficiary;
        uint256 amount;
        uint256 unlockTime;
        bool claimed;
        bool exists;
    }
    
    // Struct for Inheritance Tokens
    struct InheritanceToken {
        uint256 tokenId;
        address beneficiary;
        uint256 vaultId;
        bool active;
    }
    
    // State variables
    mapping(uint256 => Vault) public vaults;
    mapping(uint256 => InheritanceToken) public inheritanceTokens;
    mapping(address => uint256[]) public ownerVaults;
    
    uint256 public vaultCounter;
    uint256 public tokenCounter;
    
    // Events
    event VaultCreated(uint256 indexed vaultId, address indexed owner, address indexed beneficiary, uint256 amount, uint256 unlockTime);
    event TokenMinted(uint256 indexed tokenId, address indexed beneficiary, uint256 indexed vaultId);
    event VaultClaimed(uint256 indexed vaultId, address indexed beneficiary, uint256 amount);
    event EmergencyWithdraw(uint256 indexed vaultId, address indexed owner, uint256 amount);
    
    /**
     * @dev Core Function 1: Create a time-locked vault and deposit funds
     * @param _beneficiary Address of the beneficiary who will inherit
     * @param _unlockTime Unix timestamp when vault can be unlocked
     */
    function createVault(address _beneficiary, uint256 _unlockTime) public payable {
        require(msg.value > 0, "Must deposit funds");
        require(_beneficiary != address(0), "Invalid beneficiary address");
        require(_unlockTime > block.timestamp, "Unlock time must be in future");
        
        vaultCounter++;
        
        vaults[vaultCounter] = Vault({
            owner: msg.sender,
            beneficiary: _beneficiary,
            amount: msg.value,
            unlockTime: _unlockTime,
            claimed: false,
            exists: true
        });
        
        ownerVaults[msg.sender].push(vaultCounter);
        
        emit VaultCreated(vaultCounter, msg.sender, _beneficiary, msg.value, _unlockTime);
    }
    
    /**
     * @dev Core Function 2: Mint an Inheritance Token for beneficiary
     * @param _vaultId ID of the vault to mint token for
     */
    function mintInheritanceToken(uint256 _vaultId) public {
        require(vaults[_vaultId].exists, "Vault does not exist");
        require(msg.sender == vaults[_vaultId].owner, "Only vault owner can mint token");
        require(!vaults[_vaultId].claimed, "Vault already claimed");
        
        tokenCounter++;
        
        inheritanceTokens[tokenCounter] = InheritanceToken({
            tokenId: tokenCounter,
            beneficiary: vaults[_vaultId].beneficiary,
            vaultId: _vaultId,
            active: true
        });
        
        emit TokenMinted(tokenCounter, vaults[_vaultId].beneficiary, _vaultId);
    }
    
    /**
     * @dev Core Function 3: Claim vault funds after unlock time
     * @param _vaultId ID of the vault to claim
     * @param _tokenId Inheritance token ID proving beneficiary rights
     */
    function claimVault(uint256 _vaultId, uint256 _tokenId) public {
        Vault storage vault = vaults[_vaultId];
        InheritanceToken storage token = inheritanceTokens[_tokenId];
        
        require(vault.exists, "Vault does not exist");
        require(!vault.claimed, "Vault already claimed");
        require(block.timestamp >= vault.unlockTime, "Vault is still locked");
        require(msg.sender == vault.beneficiary, "Only beneficiary can claim");
        require(token.active, "Token is not active");
        require(token.vaultId == _vaultId, "Token does not match vault");
        require(token.beneficiary == msg.sender, "Token not owned by caller");
        
        vault.claimed = true;
        token.active = false;
        
        uint256 amount = vault.amount;
        vault.amount = 0;
        
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");
        
        emit VaultClaimed(_vaultId, msg.sender, amount);
    }
    
    /**
     * @dev Emergency withdraw by owner before unlock time (with conditions)
     * @param _vaultId ID of the vault to withdraw from
     */
    function emergencyWithdraw(uint256 _vaultId) public {
        Vault storage vault = vaults[_vaultId];
        
        require(vault.exists, "Vault does not exist");
        require(msg.sender == vault.owner, "Only owner can emergency withdraw");
        require(!vault.claimed, "Vault already claimed");
        require(block.timestamp < vault.unlockTime, "Use claim function after unlock time");
        
        vault.claimed = true;
        uint256 amount = vault.amount;
        vault.amount = 0;
        
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");
        
        emit EmergencyWithdraw(_vaultId, msg.sender, amount);
    }
    
    /**
     * @dev Get vault details
     * @param _vaultId ID of the vault
     */
    function getVaultDetails(uint256 _vaultId) public view returns (
        address owner,
        address beneficiary,
        uint256 amount,
        uint256 unlockTime,
        bool claimed
    ) {
        Vault memory vault = vaults[_vaultId];
        return (vault.owner, vault.beneficiary, vault.amount, vault.unlockTime, vault.claimed);
    }
