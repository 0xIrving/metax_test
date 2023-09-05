// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TeamReserve_Vault is Ownable {

    address public MetaX_addr;

    IERC20 public MX;

    function setMetaX (address _MetaX_addr) public onlyOwner {
        require(!frozen, "TeamReserve_Vault: $MetaX Tokens Address is frozen.");
        MetaX_addr = _MetaX_addr;
        MX = IERC20(_MetaX_addr);
    }

    bool public frozen;

    function setFrozen () public onlyOwner {
        frozen = true;
    }
    
    uint256 public immutable T0 = 1696118400; /* Oct 1st 2023 */

    uint256 public nextRelease = 1696118400; /* Oct 1st 2023 */

    uint256 public immutable Max = 3000000000 ether; /* 15% of $MetaX */

    uint256 public immutable release = 83333333 ether; /* 36 months linear release */ 

    uint256 public immutable intervals = 30 days;

    uint256 public accumRelease;

    function Balance () public view returns (uint256) {
        return MX.balanceOf(address(this));
    }

    address public teamReserve;

    function setTeamReserve (address _teamReserve) public onlyOwner {
        require(!frozen, "TeamReserve_Vault: $MetaX Tokens Address is frozen.");
        teamReserve = _teamReserve;
    }

    function Release () public onlyOwner {
        require(block.timestamp > nextRelease, "TeamReserve_Vault: Please wait for the next release.");
        require(accumRelease + release <= Max, "TeamReserve_Vault: All the tokens have been released.");
        require(teamReserve != address(0), "TeamReserve_Vault: Can't release to address(0).");
        MX.transfer(teamReserve, release);
        nextRelease += intervals;
        accumRelease += release;
    }
}