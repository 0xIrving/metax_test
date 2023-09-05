// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract $MetaX is ERC20 {

    uint256 public immutable Max = 20000000000 ether;

    constructor() ERC20("MetaX", "MetaX") {
        for (uint256 i=0; i<Vaults.length; i++) {
            _mint(Vaults[i], Allocation[i]);
        }
    }

    address[] public Vaults = [
        0x5B38Da6a701c568545dCfcB03FcB875f56beddC4, /* #0 Social Mining 40% */
        0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2, /* #1 Builder Incentives 5% */
        0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db, /* #2 Marketing Expense 10% */
        0x38cB7800C3Fddb8dda074C1c650A155154924C73, /* #3 Treasure 10% */
        0xEf9f1ACE83dfbB8f559Da621f4aEA72C6EB10eBf, /* #4 Team Reserved 15% */
        0x688c0611a5691B7c1F09a694bf4ADfb456a58Cf7, /* #5 Advisors 5% */
        0x4815A8Ba613a3eB21A920739dE4cA7C439c7e1b1  /* #6 Investors 15% */
    ];

    uint256[] public Allocation = [
        8000000000 ether, /* #0 Social Mining 40% */
        1000000000 ether, /* #1 Builder Incentives 5% */
        2000000000 ether, /* #2 Marketing Expense 10% */
        2000000000 ether, /* #3 Treasure 10% */
        3000000000 ether, /* #4 Team Reserved 15% */
        1000000000 ether, /* #5 Advisors 5% */
        3000000000 ether  /* #6 Investors 15% */
    ];
}