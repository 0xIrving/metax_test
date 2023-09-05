// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Investors_Vault is AccessControl, Ownable {

    bytes32 public constant Investor = keccak256("Investor");

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    address public MetaX_addr;

    IERC20 public MX;

    function setMetaX (address _MetaX_addr) public onlyOwner {
        require(!frozen, "Investors_Vault: $MetaX Tokens Address is frozen.");
        MetaX_addr = _MetaX_addr;
        MX = IERC20(_MetaX_addr);
    }

    bool public frozen;

    function setFrozen () public onlyOwner {
        frozen = true;
    }
    
    uint256 public immutable T0 = 1696118400; /* Oct 1st 2023 */

    uint256 public immutable Max = 3000000000 ether; /* 15% of $MetaX */

    uint256 public immutable maxClaim = 24; /* 24 months linear release */

    uint256 public immutable intervals = 30 days; /* 24 months linear release */

    function Balance () public view returns (uint256) {
        return MX.balanceOf(address(this));
    }

    uint256 public accumAllocated;

    uint256 public accumClaimed;

    struct _Investors {
        bool isInvestor;
        uint256 nextRelease;
        uint256 max;
        uint256 release;
        uint256 alreadyClaimed;
        uint256 numClaimed;
    }

    mapping (address => _Investors) public Investors;

    function setInvestors (address newInvestors_addr, uint256 _nextRelease, uint256 tokenMax) public onlyOwner {
        _Investors storage Inv = Investors[newInvestors_addr];
        require(!Inv.isInvestor, "Investors_Vault: This address is already an investor.");
        require(accumAllocated + tokenMax <= Max, "Investors_Vault: All the tokens have been allocated");
        uint256 _release = tokenMax / maxClaim;
        Inv.isInvestor = true;
        Inv.nextRelease = _nextRelease;
        Inv.max = tokenMax;
        Inv.release = _release;
        accumAllocated += tokenMax;
    }

    function updateInvestors (address oldInvestors_addr, address newInvestors_addr) public onlyRole(Investor) {
        require(oldInvestors_addr == msg.sender, "Investors_Vault: Incorrect investor identity.");
        require(Investors[msg.sender].isInvestor, "Investors_Vault: You are not an investor.");
        require(Investors[msg.sender].alreadyClaimed + Investors[msg.sender].release <= Investors[msg.sender].max, "Investors_Vault: You have claimed all your investor tokens.");
        Investors[newInvestors_addr].isInvestor = true;
        Investors[newInvestors_addr].nextRelease = Investors[oldInvestors_addr].nextRelease;
        Investors[newInvestors_addr].max = Investors[oldInvestors_addr].max;
        Investors[newInvestors_addr].release = Investors[oldInvestors_addr].release;
        Investors[newInvestors_addr].alreadyClaimed = Investors[oldInvestors_addr].alreadyClaimed;
        Investors[newInvestors_addr].numClaimed = Investors[oldInvestors_addr].numClaimed;
        delete Investors[oldInvestors_addr];
    }

    function Claim () public {
        _Investors storage Inv = Investors[msg.sender];
        require(Inv.isInvestor, "Investors_Vault: You are not an investor");
        require(block.timestamp > Inv.nextRelease && block.timestamp > T0, "Investors_Vault: Please wait for the next release.");
        require(Inv.alreadyClaimed + Inv.release <= Inv.max && Inv.numClaimed < maxClaim, "Investors_Vault: You have claimed all your investors tokens");
        Inv.nextRelease = block.timestamp + intervals;
        Inv.alreadyClaimed += Inv.release;
        Inv.numClaimed ++;
        accumClaimed += Inv.release;
        MX.transfer(msg.sender, Inv.release);

        emit claimRecord(msg.sender, Inv.release, block.timestamp);
    }

    event claimRecord(address _investor, uint256 amount, uint256 time);
}