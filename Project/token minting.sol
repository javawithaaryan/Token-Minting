// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Time-Locked Inheritance Vault
 * @dev A smart contract for managing digital asset inheritance with time-locks and beneficiary tokens
 * @notice Enhanced with multi-beneficiary support, heartbeat mechanism, and vault extensions
 */
contract InheritanceVault {
    
    // Struct to store vault information
    struct Vault {
        address owner;
        address beneficiary;
        uint256 amount;
        uint256 unlockTime;
        bool claimed;
        bool exists;
        uint256 lastHeartbeat;
        bool heartbeatEnabled;
        uint256 heartbeatInterval;
        string message;
    }
    
    // Struct for Inheritance Tokens
    struct InheritanceToken {
        uint256 tokenId;
        address beneficiary;
        uint256 vaultId;
        bool active;
        uint256 mintedAt;
    }
    
    // Struct for multiple beneficiaries
    struct BeneficiaryShare {
        address beneficiary;
        uint256 percentage; // Out of 100
    }
    
    // State variables
    mapping(uint256 => Vault) public vaults;
    mapping(uint256 => InheritanceToken) public inheritanceTokens;
    mapping(address => uint256[]) public ownerVaults;
    mapping(uint256 => BeneficiaryShare[]) public vaultBeneficiaries;
    mapping(address => uint256[]) public beneficiaryVaults;
    
    uint256 public vaultCounter;
    uint256 public tokenCounter;
    uint256 public constant MIN_HEARTBEAT_INTERVAL = 30 days;
    uint256 public constant MAX_HEARTBEAT_INTERVAL = 365 days;
    
    // Events
    event VaultCreated(uint256 indexed vaultId, address indexed owner, address indexed beneficiary, uint256 amount, uint256 unlockTime);
    event TokenMinted(uint256 indexed tokenId, address indexed beneficiary, uint256 indexed vaultId);
    event VaultClaimed(uint256 indexed vaultId, address indexed beneficiary, uint256 amount);
    event EmergencyWithdraw(uint256 indexed vaultId, address indexed owner, uint256 amount);
    event VaultExtended(uint256 indexed vaultId, uint256 newUnlockTime);
    event BeneficiaryUpdated(uint256 indexed vaultId, address indexed oldBeneficiary, address indexed newBeneficiary);
    event HeartbeatRecorded(uint256 indexed vaultId, uint256 timestamp);
    event VaultFunded(uint256 indexed vaultId, uint256 amount);
    event MessageUpdated(uint256 indexed vaultId, string message);
    event MultiBeneficiaryVaultCreated(uint256 indexed vaultId, address indexed owner, uint256 amount);
    
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
            exists: true,
            lastHeartbeat: block.timestamp,
            heartbeatEnabled: false,
            heartbeatInterval: 0,
            message: ""
        });
        
        ownerVaults[msg.sender].push(vaultCounter);
        beneficiaryVaults[_beneficiary].push(vaultCounter);
        
        emit VaultCreated(vaultCounter, msg.sender, _beneficiary, msg.value, _unlockTime);
    }
    
    /**
     * @dev NEW: Create a vault with multiple beneficiaries
     * @param _beneficiaries Array of beneficiary addresses
     * @param _percentages Array of percentage shares (must sum to 100)
     * @param _unlockTime Unix timestamp when vault can be unlocked
     */
    function createMultiBeneficiaryVault(
        address[] memory _beneficiaries,
        uint256[] memory _percentages,
        uint256 _unlockTime
    ) public payable {
        require(msg.value > 0, "Must deposit funds");
        require(_beneficiaries.length == _percentages.length, "Arrays length mismatch");
        require(_beneficiaries.length > 0, "Must have at least one beneficiary");
        require(_unlockTime > block.timestamp, "Unlock time must be in future");
        
        uint256 totalPercentage = 0;
        for (uint256 i = 0; i < _percentages.length; i++) {
            require(_beneficiaries[i] != address(0), "Invalid beneficiary address");
            totalPercentage += _percentages[i];
            vaultBeneficiaries[vaultCounter + 1].push(BeneficiaryShare({
                beneficiary: _beneficiaries[i],
                percentage: _percentages[i]
            }));
            beneficiaryVaults[_beneficiaries[i]].push(vaultCounter + 1);
        }
        
        require(totalPercentage == 100, "Percentages must sum to 100");
        
        vaultCounter++;
        
        vaults[vaultCounter] = Vault({
            owner: msg.sender,
            beneficiary: address(0), // Multi-beneficiary vault
            amount: msg.value,
            unlockTime: _unlockTime,
            claimed: false,
            exists: true,
            lastHeartbeat: block.timestamp,
            heartbeatEnabled: false,
            heartbeatInterval: 0,
            message: ""
        });
        
        ownerVaults[msg.sender].push(vaultCounter);
        
        emit MultiBeneficiaryVaultCreated(vaultCounter, msg.sender, msg.value);
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
            active: true,
            mintedAt: block.timestamp
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
     * @dev NEW: Claim multi-beneficiary vault
     * @param _vaultId ID of the vault to claim
     */
    function claimMultiBeneficiaryVault(uint256 _vaultId) public {
        Vault storage vault = vaults[_vaultId];
        
        require(vault.exists, "Vault does not exist");
        require(!vault.claimed, "Vault already claimed");
        require(block.timestamp >= vault.unlockTime, "Vault is still locked");
        require(vault.beneficiary == address(0), "Not a multi-beneficiary vault");
        
        BeneficiaryShare[] memory beneficiaries = vaultBeneficiaries[_vaultId];
        require(beneficiaries.length > 0, "No beneficiaries found");
        
        vault.claimed = true;
        uint256 totalAmount = vault.amount;
        vault.amount = 0;
        
        for (uint256 i = 0; i < beneficiaries.length; i++) {
            uint256 shareAmount = (totalAmount * beneficiaries[i].percentage) / 100;
            (bool success, ) = payable(beneficiaries[i].beneficiary).call{value: shareAmount}("");
            require(success, "Transfer failed");
            
            emit VaultClaimed(_vaultId, beneficiaries[i].beneficiary, shareAmount);
        }
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
     * @dev NEW: Extend vault unlock time
     * @param _vaultId ID of the vault
     * @param _newUnlockTime New unlock timestamp
     */
    function extendVaultTime(uint256 _vaultId, uint256 _newUnlockTime) public {
        Vault storage vault = vaults[_vaultId];
        
        require(vault.exists, "Vault does not exist");
        require(msg.sender == vault.owner, "Only owner can extend vault");
        require(!vault.claimed, "Vault already claimed");
        require(_newUnlockTime > vault.unlockTime, "New time must be later than current");
        
        vault.unlockTime = _newUnlockTime;
        
        emit VaultExtended(_vaultId, _newUnlockTime);
    }
    
    /**
     * @dev NEW: Update beneficiary address
     * @param _vaultId ID of the vault
     * @param _newBeneficiary New beneficiary address
     */
    function updateBeneficiary(uint256 _vaultId, address _newBeneficiary) public {
        Vault storage vault = vaults[_vaultId];
        
        require(vault.exists, "Vault does not exist");
        require(msg.sender == vault.owner, "Only owner can update beneficiary");
        require(!vault.claimed, "Vault already claimed");
        require(_newBeneficiary != address(0), "Invalid beneficiary address");
        require(vault.beneficiary != address(0), "Cannot update multi-beneficiary vault");
        
        address oldBeneficiary = vault.beneficiary;
        vault.beneficiary = _newBeneficiary;
        
        emit BeneficiaryUpdated(_vaultId, oldBeneficiary, _newBeneficiary);
    }
    
    /**
     * @dev NEW: Enable heartbeat mechanism for vault
     * @param _vaultId ID of the vault
     * @param _interval Heartbeat interval in seconds
     */
    function enableHeartbeat(uint256 _vaultId, uint256 _interval) public {
        Vault storage vault = vaults[_vaultId];
        
        require(vault.exists, "Vault does not exist");
        require(msg.sender == vault.owner, "Only owner can enable heartbeat");
        require(!vault.claimed, "Vault already claimed");
        require(_interval >= MIN_HEARTBEAT_INTERVAL && _interval <= MAX_HEARTBEAT_INTERVAL, 
                "Invalid heartbeat interval");
        
        vault.heartbeatEnabled = true;
        vault.heartbeatInterval = _interval;
        vault.lastHeartbeat = block.timestamp;
    }
    
    /**
     * @dev NEW: Record a heartbeat (proof of life)
     * @param _vaultId ID of the vault
     */
    function recordHeartbeat(uint256 _vaultId) public {
        Vault storage vault = vaults[_vaultId];
        
        require(vault.exists, "Vault does not exist");
        require(msg.sender == vault.owner, "Only owner can record heartbeat");
        require(vault.heartbeatEnabled, "Heartbeat not enabled");
        require(!vault.claimed, "Vault already claimed");
        
        vault.lastHeartbeat = block.timestamp;
        
        emit HeartbeatRecorded(_vaultId, block.timestamp);
    }
    
    /**
     * @dev NEW: Add more funds to existing vault
     * @param _vaultId ID of the vault
     */
    function addFunds(uint256 _vaultId) public payable {
        Vault storage vault = vaults[_vaultId];
        
        require(vault.exists, "Vault does not exist");
        require(msg.sender == vault.owner, "Only owner can add funds");
        require(!vault.claimed, "Vault already claimed");
        require(msg.value > 0, "Must send funds");
        
        vault.amount += msg.value;
        
        emit VaultFunded(_vaultId, msg.value);
    }
    
    /**
     * @dev NEW: Set a message for beneficiary
     * @param _vaultId ID of the vault
     * @param _message Message to beneficiary
     */
    function setMessage(uint256 _vaultId, string memory _message) public {
        Vault storage vault = vaults[_vaultId];
        
        require(vault.exists, "Vault does not exist");
        require(msg.sender == vault.owner, "Only owner can set message");
        require(!vault.claimed, "Vault already claimed");
        
        vault.message = _message;
        
        emit MessageUpdated(_vaultId, _message);
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
        bool claimed,
        bool heartbeatEnabled,
        uint256 lastHeartbeat,
        string memory message
    ) {
        Vault memory vault = vaults[_vaultId];
        return (
            vault.owner, 
            vault.beneficiary, 
            vault.amount, 
            vault.unlockTime, 
            vault.claimed,
            vault.heartbeatEnabled,
            vault.lastHeartbeat,
            vault.message
        );
    }
    
    /**
     * @dev NEW: Get all vaults owned by an address
     * @param _owner Owner address
     */
    function getOwnerVaults(address _owner) public view returns (uint256[] memory) {
        return ownerVaults[_owner];
    }
    
    /**
     * @dev NEW: Get all vaults where address is beneficiary
     * @param _beneficiary Beneficiary address
     */
    function getBeneficiaryVaults(address _beneficiary) public view returns (uint256[] memory) {
        return beneficiaryVaults[_beneficiary];
    }
    
    /**
     * @dev NEW: Get multi-beneficiary vault shares
     * @param _vaultId ID of the vault
     */
    function getVaultBeneficiaries(uint256 _vaultId) public view returns (BeneficiaryShare[] memory) {
        return vaultBeneficiaries[_vaultId];
    }
    
    /**
     * @dev NEW: Check if heartbeat is overdue
     * @param _vaultId ID of the vault
     */
    function isHeartbeatOverdue(uint256 _vaultId) public view returns (bool) {
        Vault memory vault = vaults[_vaultId];
        
        if (!vault.heartbeatEnabled) {
            return false;
        }
        
        return block.timestamp > vault.lastHeartbeat + vault.heartbeatInterval;
    }
    
    /**
     * @dev Get token details
     * @param _tokenId ID of the token
     */
    function getTokenDetails(uint256 _tokenId) public view returns (
        address beneficiary,
        uint256 vaultId,
        bool active,
        uint256 mintedAt
    ) {
        InheritanceToken memory token = inheritanceTokens[_tokenId];
        return (token.beneficiary, token.vaultId, token.active, token.mintedAt);
    }
    
    /**
     * @dev Get contract statistics
     */
    function getContractStats() public view returns (
        uint256 totalVaults,
        uint256 totalTokens,
        uint256 contractBalance
    ) {
        return (vaultCounter, tokenCounter, address(this).balance);
    }
}
