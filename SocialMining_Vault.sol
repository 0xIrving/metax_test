// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SocialMining_Vault is AccessControl, Ownable {

    bytes32 public constant Admin = keccak256("Admin");

    address public MetaX_addr;

    IERC20 public MX;

    function setMetaX (address _MetaX_addr) public onlyOwner {
        require(!frozen, "SocialMining_Vault: $MetaX Tokens Address is frozen.");
        MetaX_addr = _MetaX_addr;
        MX = IERC20(_MetaX_addr);
    }

    address public SocialMining_addr;

    function setSocialMining (address newSocialMining_addr) public onlyOwner {
        require(!frozen, "SocialMining_Vault: SocialMining Address is frozen.");
        SocialMining_addr = newSocialMining_addr;
    }

    uint256 public T0 = 1676332800; /* Feb 14th 2023 */

    uint256[] public release = [5479452 ether, 38356164 ether, 164383560 ether, 986301360 ether, 2000000000 ether];

    uint256 public accumRelease;

    uint256 public intervals;

    uint256[] public time = [1 days, 7 days, 30 days, 180 days, 365 days];

    uint256 public nextRelease = 1693526400; /* Sept 1st 2023 */

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(Admin, msg.sender);
    }

    function Balance () public view returns (uint256) {
        return MX.balanceOf(address(this));
    }

    function setIntervals (uint256 _intervals) public onlyOwner {
        require(!frozen, "SocialMining_Vault: Release intervals is frozen.");
        intervals = _intervals;
    }

    function Release () public onlyRole(Admin) {
        require(block.timestamp > nextRelease, "SocialMining_Vault: Please wait for the next release.");
        MX.transfer(SocialMining_addr, release[intervals]);
        accumRelease += release[intervals];
        nextRelease += time[intervals];
    }

    function Halve () public onlyOwner {
        require(block.timestamp > T0 + 730 days, "SocialMining_Vault: Please wait till the next halving.");
        for (uint256 i=0; i<release.length; i++) {
            release[i] /= 2;
        }
        T0 += 730 days;
    }

    bool public frozen;

    function setFrozen () public onlyOwner {
        frozen = true;
    }
}