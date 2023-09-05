// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import { DefaultOperatorFilterer } from "./Opensea/DefaultOperatorFilterer.sol";

contract PlanetPass is ERC721, AccessControl, Ownable, ERC2981, DefaultOperatorFilterer {

/** Roles **/
    bytes32 public constant Admin = keccak256("Admin");

    constructor(
        string[] memory _baseURI,
        address receiver,
        uint96 feeNumerator
    ) ERC721 ("PlanetPass", "PlanetPass") {
        baseURI = _baseURI;
        _setDefaultRoyalty(receiver, feeNumerator);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(Admin, msg.sender);
    }

/** Metadata **/
    string[] public baseURI;

    function setBaseURI(uint256 batch, string memory newBaseURI) public onlyRole(Admin) {
        baseURI[batch] = newBaseURI;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "BlackHole: Token not exist.");
        uint256 type_ = Pass[_tokenId]._type;
        return baseURI[type_];
    }

/** Whitelist **/
    bool public WLRequired;

    function setWLRequired(bool _WLRequired) public onlyRole(Admin) {
        WLRequired = _WLRequired;
    }

    bytes32 public merkleRoot;

    function setWhitelist(bytes32 _merkleRoot) public onlyRole(Admin) {
        merkleRoot = _merkleRoot;
    }

    function verify(bytes32[] calldata merkleProof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(merkleProof, merkleRoot, leaf);
    }

/** POSW Subscription **/
    
    /* Duration */
    struct _Pass {
        uint256 _type; /* 0=>Lifetime | 1=>Daily | 2=>Weekly | 3=>Monthly | 4=>Quaterly | 5=>Semi-Annually | 6=>Annually */
        uint256 beginTime;
        uint256 endTime;
    }

    mapping (uint256 => _Pass) public Pass;

    function getBeginTime (uint256 _tokenId) external view returns (uint256) {
        return Pass[_tokenId].beginTime;
    }

    function getEndTime (uint256 _tokenId) external view returns (uint256) {
        return Pass[_tokenId].endTime;
    }

    function Type (uint256 _duration) public pure returns (uint256 _type) {
        uint256 duration = _duration * 1 days;
        if (duration == 0) {
            _type = 0;
        }
        if (0 < duration && duration < 7 days) {
            _type = 1;
        }
        if (7 days <= duration && duration < 30 days) {
            _type = 2;
        }
        if (30 days <= duration && duration < 90 days) {
            _type = 3;
        }
        if (90 days <= duration && duration < 180 days) {
            _type = 4;
        }
        if (180 days <= duration && duration < 365 days) {
            _type = 5;
        }
        if (365 days <= duration) {
            _type = 6;
        }
    }

    /* Price */
    uint256 public Max_Lifetime = 1000;

    uint256[] public unitPrice = [ 1 ether, 0.01 ether, 0.0075 ether, 0.004 ether, 0.0025 ether, 0.0015 ether, 0.001 ether];
    /* 0=>Lifetime | 1=>Daily | 2=>Weekly | 3=>Monthly | 4=>Quaterly | 5=>Semi-Annually | 6=>Annually */

    function updateUnitPrice (uint256 batch, uint256 newPrice) public onlyOwner {
        unitPrice[batch] = newPrice;
    }

    function Price (uint256 _duration) public view returns (uint256 price) {
        uint256 duration = _duration * 1 days;
        if (duration == 0) {
            price = unitPrice[0];
        }
        if (0 < duration && duration < 7 days) {
            price = duration * unitPrice[1];
        }
        if (7 days <= duration && duration < 30 days) {
            price = duration * unitPrice[2];
        }
        if (30 days <= duration && duration < 90 days) {
            price = duration * unitPrice[3];
        }
        if (90 days <= duration && duration < 180 days) {
            price = duration * unitPrice[4];
        }
        if (180 days <= duration && duration < 365 days) {
            price = duration * unitPrice[5];
        }
        if (365 days <= duration) {
            price = duration * unitPrice[6];
        }
    }

/** Mint **/
    uint256 private tokenId_Lifetime;

    uint256 private tokenId_Subscription = 1000;

    function totalSupply () public view returns (uint256 _Lifetime, uint256 _Subscription, uint256 _Total) {
        _Lifetime = tokenId_Lifetime;
        _Subscription = tokenId_Subscription - 1000;
        _Total = _Lifetime + _Subscription;
    }

    function Mint(address User, uint256 _duration) public payable {
        uint256 duration = _duration * 1 days;
        uint256 price = Price(_duration);
        uint256 type_ = Type(_duration);
        uint256 tokenId;
        if (duration == 0) {
            require(tokenId_Lifetime < Max_Lifetime, "PlanetPass: Lifetime Pass is limited to 1000 pieces.");
            tokenId_Lifetime++;
            tokenId = tokenId_Lifetime;
        } else {
            tokenId_Subscription++;
            tokenId = tokenId_Subscription;
            Pass[tokenId].beginTime = block.timestamp;
            Pass[tokenId].endTime = block.timestamp + duration;
        }
        require(msg.value >= price, "PlanetPass: Not enough payment.");
        Pass[tokenId]._type = type_;
        _safeMint(User, tokenId);
    }

/** Binding Tokens With Wallet Address **/
    mapping (address => uint256[]) public wallet_token;

    function getAllTokens(address owner) public view returns (uint256[] memory) {
        return wallet_token[owner];
    }

    function addToken(address user, uint256 tokenId) internal {
        wallet_token[user].push(tokenId);
    }

    function removeToken(address user, uint256 tokenId) internal {
        uint256[] storage token = wallet_token[user];
        for (uint256 i=0; i<token.length; i++) {
            if(token[i] == tokenId) {
                token[i] = token[token.length - 1];
                token.pop();
                break;
            }
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal virtual override {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
        for (uint256 i=0; i<batchSize; i++) {
            uint256 tokenId = firstTokenId + i;
            if (from != address(0)) {
                removeToken(from, tokenId);
            }
            if (to != address(0)) {
                addToken(to, tokenId);
            }
        }
    }

/** Royalty **/
    function setRoyaltyInfo(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) external onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

/** Withdraw **/
    function Withdraw(address recipient) public payable onlyOwner {
        payable(recipient).transfer(address(this).balance);
    }
}