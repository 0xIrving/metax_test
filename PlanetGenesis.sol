// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import { DefaultOperatorFilterer } from "./Opensea/DefaultOperatorFilterer.sol";

contract PlanetGenesis is ERC721, Ownable, ERC2981, DefaultOperatorFilterer {

    constructor(
        string memory _baseURI,
        uint256 _roundLtd,
        address receiver,
        uint96 feeNumerator
    ) ERC721("PlanetGenesis", "PlanetGenesis") {
        baseURI = _baseURI;
        roundLtd = _roundLtd;
        _setDefaultRoyalty(receiver, feeNumerator);
    }

/** Status **/
    enum Status {
        Close,
        Whitelist,
        Open
    }

    function setStatus(Status _status) public onlyOwner {
        status = _status;
    }

    Status public status;

/** Metadata **/
    string public baseURI;

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    bool public revealed;

    function _reveal() public onlyOwner {
        revealed = true;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "PlanetGenesis: Token not exist.");
        if (revealed) {
            return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, Strings.toString(tokenId), ".json")) : "";
        } else {
            return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, "Mystery.json")) : "";
        }
    }

/** Whitelist **/
    bytes32 public merkleRoot;

    function setWhitelist(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function verify(address owner, uint256 _airdrop, bytes32[] calldata merkleProof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(owner, _airdrop));
        return MerkleProof.verify(merkleProof, merkleRoot, leaf);
    }

/** Mint **/
    uint256 public immutable Max = 2222;

    uint256 public _tokenId;

    function totalSupply() public view returns (uint256) {
        return _tokenId;
    }

    uint256 public roundLtd;

    function setRoundLtd(uint256 newRoundLtd) public onlyOwner {
        roundLtd = newRoundLtd;
    }

    uint256 public Price = 0.2 ether;

    function setPrice(uint256 newPrice) public onlyOwner {
        Price = newPrice;
    }

    mapping (address => bool) public alreadyMinted;

    function Mint(address owner, uint256 _airdrop, bytes32[] calldata merkleProof) public payable {
        require(status != Status.Close, "PlanetGenesis: Mint is not open.");
        require(tx.origin == msg.sender, "PlanetGenesis: Contract not allowed.");
        require(totalSupply() < Max, "PlanetGenesis: Sold out.");
        require(totalSupply() < roundLtd, "PlanetGenesis: Exceed this round's limit.");
        require(!alreadyMinted[owner], "PlanetGenesis: Limited to 1 per wallet.");
        if (status == Status.Whitelist) {
            require(verify(owner, _airdrop, merkleProof), "PlanetGenesis: You are not whitelisted.");
        }
        if (_airdrop != 1) {
            require(msg.value >= Price, "PlanetGenesis: Not enough payment.");
        }
        _tokenId++;
        _safeMint(owner, _tokenId);

        alreadyMinted[owner] = true;

        emit mintRecord(owner, _tokenId, block.timestamp);
    }

    event mintRecord(address indexed owner, uint256 indexed _tokenId, uint256 indexed time);

    uint256 public immutable reservedLtd = 22;

    bool public reserveMinted;

    function Reserve(address[] calldata team) public onlyOwner {
        require(!reserveMinted, "PlanetGenesis: Reserved NFTs have been minted.");
        require(totalSupply() + reservedLtd <= Max, "PlanetGenesis: Sold out.");
        for (uint256 i=0; i<team.length; i++) {
            _tokenId++;
            _safeMint(team[i], _tokenId);
            alreadyMinted[team[i]] = true;
        }
        reserveMinted = true;
    }

/** Stake **/
    mapping (uint256 => bool) public Staked;

    function Stake(uint256 tokenId) public {
        require(ownerOf(tokenId) == msg.sender, "PlanetGenesis: You are not the owner.");
        if (Staked[tokenId]) {
            Staked[tokenId] = false;
        } else {
            Staked[tokenId] = true;
        }
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

/** Lock **/
    bool public Liquidity;

    function setLiquidity() public onlyOwner {
        Liquidity = true;
    }

    function _beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal virtual override {
        for (uint256 i=0; i<batchSize; i++) {
            uint256 tokenId = firstTokenId + i;
            if (from != address(0) && to != address(0)) {
                require(Liquidity, "PlanetGenesis: Locked until 100 communities deployed.");
                require(!Staked[tokenId], "PlanetGenesis: Staked NFT can not be transfered.");
            }
            if (from != address(0)) {
                removeToken(from, tokenId);
            }
            if (to != address(0)) {
                addToken(to, tokenId);
            }
        }
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
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

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

/** Withdraw **/
    function withdraw(address recipient) public onlyOwner {
        payable(recipient).transfer(address(this).balance);
    }
}