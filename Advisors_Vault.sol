// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Advisors_Vault is AccessControl, Ownable {

    bytes32 public constant Advisor = keccak256("Advisor");

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    address public MetaX_addr;

    IERC20 public MX;

    function setMetaX (address _MetaX_addr) public onlyOwner {
        require(!frozen, "Advisors_Vault: $MetaX Tokens Address is frozen.");
        MetaX_addr = _MetaX_addr;
        MX = IERC20(_MetaX_addr);
    }

    bool public frozen;

    function setFrozen () public onlyOwner {
        frozen = true;
    }
    
    uint256 public immutable T0 = 1693526400;//1696118400; /* Oct 1st 2023 */

    uint256 public immutable Max = 1000000000 ether; /* 5% of $MetaX */

    uint256 public immutable maxClaim = 36; /* 36 months linear release */

    uint256 public immutable intervals = 1 minutes;//30 days; /* 36 months linear release */

    function Balance () public view returns (uint256) {
        return MX.balanceOf(address(this));
    }

    uint256 public accumAllocated;

    uint256 public accumClaimed;

    struct _Advisors {
        bool isAdvisor;
        uint256 nextRelease;
        uint256 max;
        uint256 release;
        uint256 alreadyClaimed;
        uint256 numClaimed;
    }

    mapping (address => _Advisors) public Advisors;

    function setAdvisors (address newAdvisors_addr, uint256 _nextRelease, uint256 tokenMax) public onlyOwner {
        _Advisors storage Adv = Advisors[newAdvisors_addr];
        require(!Adv.isAdvisor, "Advisors_Vault: This address is already an Advisor.");
        require(accumAllocated + tokenMax <= Max, "Advisors_Vault: All the tokens have been allocated");
        uint256 _release = tokenMax / maxClaim;
        Adv.isAdvisor = true;
        Adv.nextRelease = _nextRelease;
        Adv.max = tokenMax;
        Adv.release = _release;
        accumAllocated += tokenMax;
    }

    function updateAdvisors (address oldAdvisors_addr, address newAdvisors_addr) public onlyRole(Advisor) {
        require(oldAdvisors_addr == msg.sender, "Advisors_Vault: Incorrect Advisor identity.");
        require(Advisors[msg.sender].isAdvisor, "Advisors_Vault: You are not an Advisor.");
        require(Advisors[msg.sender].alreadyClaimed + Advisors[msg.sender].release <= Advisors[msg.sender].max, "Advisors_Vault: You have claimed all your Advisor tokens.");
        Advisors[newAdvisors_addr].isAdvisor = Advisors[oldAdvisors_addr].isAdvisor;
        Advisors[newAdvisors_addr].nextRelease = Advisors[oldAdvisors_addr].nextRelease;
        Advisors[newAdvisors_addr].max = Advisors[oldAdvisors_addr].max;
        Advisors[newAdvisors_addr].release = Advisors[oldAdvisors_addr].release;
        Advisors[newAdvisors_addr].alreadyClaimed = Advisors[oldAdvisors_addr].alreadyClaimed;
        Advisors[newAdvisors_addr].numClaimed = Advisors[oldAdvisors_addr].numClaimed;
        delete Advisors[oldAdvisors_addr];
    }

    function Claim () public {
        _Advisors storage Adv = Advisors[msg.sender];
        require(Adv.isAdvisor, "Advisors_Vault: You are not an Advisor");
        require(block.timestamp > Adv.nextRelease && block.timestamp > T0, "Advisors_Vault: Please wait for the next release.");
        require(Adv.alreadyClaimed + Adv.release <= Adv.max && Adv.numClaimed < maxClaim, "Advisors_Vault: You have claimed all your Advisors tokens");
        Adv.nextRelease = block.timestamp + intervals;
        Adv.alreadyClaimed += Adv.release;
        Adv.numClaimed ++;
        accumClaimed += Adv.release;
        MX.transfer(msg.sender, Adv.release);

        emit claimRecord(msg.sender, Adv.release, block.timestamp);
    }

    event claimRecord(address _Advisor, uint256 amount, uint256 time);
}