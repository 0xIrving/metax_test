// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Marketing_Vault is Ownable {

    address public MetaX_addr;

    IERC20 public MX;

    function setMetaX (address _MetaX_addr) public onlyOwner {
        require(!frozen, "Marketing_Vault: $MetaX Tokens Address is frozen.");
        MetaX_addr = _MetaX_addr;
        MX = IERC20(_MetaX_addr);
    }

    bool public frozen;

    function setFrozen () public onlyOwner {
        frozen = true;
    }

    uint256 public T0 = 1693526400; /* Sept 1st 2023 */

    uint256 public immutable Max = 2000000000 ether; /* 10% of $MetaX */

    uint256 public accumReleased;

    uint256 public numReleased;

    struct _releaseRecord {
        address receiver;
        uint256 timeReleased;
        uint256 amountReleased;
    }

    mapping (uint256 => _releaseRecord) public releaseRecord;

    function Balance () public view returns (uint256) {
        return MX.balanceOf(address(this));
    }

    function Release (address Receiver, uint256 Amount) public onlyOwner {
        require(block.timestamp > T0, "Marketing_Vault: Please wait for open release.");
        require(accumReleased + Amount <= Max, "Marketing_Vault: All the tokens have been released");
        numReleased ++;
        _releaseRecord storage record = releaseRecord[numReleased];
        accumReleased += Amount;
        record.receiver = Receiver;
        record.timeReleased = block.timestamp;
        record.amountReleased = Amount;
        MX.transfer(Receiver, Amount);
        emit marketingRecord(Receiver, Amount, block.timestamp);
    }

    event marketingRecord(address receiver, uint256 amount, uint256 time);
}