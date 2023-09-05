// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Treasure_Vault is Ownable {

    address public MetaX_addr;

    IERC20 public MX;

    function setMetaX (address _MetaX_addr) public onlyOwner {
        require(!frozen, "Treasure_Vault: $MetaX Tokens Address is frozen.");
        MetaX_addr = _MetaX_addr;
        MX = IERC20(_MetaX_addr);
    }

    bool public frozen;

    function setFrozen () public onlyOwner {
        frozen = true;
    }

    uint256 public T0 = 1704067200; /* Jan 1st 2024 */

    uint256 public immutable Max = 2000000000 ether; /* 10% of $MetaX */

    uint256 public accumReleased;

    uint256 public numReleased;

    struct _releaseRecord {
        address receiver;
        uint256 timeReleased;
        uint256 amountReleased;
        string reason;
    }

    mapping (uint256 => _releaseRecord) public releaseRecord;

    function Balance () public view returns (uint256) {
        return MX.balanceOf(address(this));
    }

    function Release (address[] memory Receiver, uint256[] memory Amount, string[] memory Reason) public onlyOwner {
        require(block.timestamp > T0, "Treasure_Vault: Please wait for open release.");
        for (uint256 i=0; i<Receiver.length; i++) {
            require(accumReleased + Amount[i] <= Max, "Treasure_Vault: All the tokens have been released");
            numReleased ++;
            _releaseRecord storage record = releaseRecord[numReleased];
            accumReleased += Amount[i];
            record.receiver = Receiver[i];
            record.timeReleased = block.timestamp;
            record.amountReleased = Amount[i];
            record.reason = Reason[i];
            MX.transfer(Receiver[i], Amount[i]);
            emit treasureRecord(Receiver[i], Amount[i], Reason[i], block.timestamp);
        }
    }

    event treasureRecord(address receiver, uint256 amount, string reason, uint256 time);
}