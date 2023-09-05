// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "../Interface/IMetaX.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract POSWRequest is AccessControl, Ownable {

/** Roles **/
    bytes32 public constant Admin = keccak256("Admin");

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(Admin, msg.sender);
    }

/** Smart Contracts Preset **/
    /* User POSW */
    address public POSW_Addr;

    IMetaX public POSW;

    function setPOSW(address _POSW_Addr) public onlyOwner {
        POSW_Addr = _POSW_Addr;
        POSW = IMetaX(_POSW_Addr);
    }

    /* Builder POSW */
    address public BlackHole_Addr;

    IMetaX public BH;

    function setBlackHole(address _BlackHole_Addr) public onlyOwner {
        BlackHole_Addr = _BlackHole_Addr;
        BH = IMetaX(_BlackHole_Addr);
    }

    /* PlanetPass */
    address public PP_Addr;

    IERC721 public PP_NFT;

    IMetaX public PP;

    function setPlanetPass(address _PP_Addr) public onlyOwner {
        PP_Addr = _PP_Addr;
        PP_NFT = IERC721(_PP_Addr);
        PP = IMetaX(_PP_Addr);
    }

/*** User POSW Request ***/
    /* Subscription Verification */
    function Verify (uint256 _tokenId) public view returns (bool) {
        require(PP_NFT.ownerOf(_tokenId) == msg.sender, "POSW Request: You are not the owner of that PlanetPass NFT.");
        uint256 endTime = PP.getEndTime(_tokenId);
        if (endTime == 0 || endTime > block.timestamp) {
            return true;
        } else {
            return false;
        }
    }

  /** User POSW Request **/
    /* User POSW Overall */
    function getPOSW (address user, uint256 _tokenId) public view returns (uint256) {
        require(Verify(_tokenId), "POSW Request: You don't have a valid PlanetPass NFT.");
        return POSW.getPOSW(user);
    }

    /* User POSW by Version */
    function getPOSW_Version (address user, uint256 _version, uint256 _tokenId) public view returns (uint256) {
        require(Verify(_tokenId), "POSW Request: You don't have a valid PlanetPass NFT.");
        return POSW.getPOSW_Version(user, _version);
    }

    /* User POSW by Social Platform */
    function getPOSW_SocialPlatform (address user, uint256 _socialPlatform, uint256 _tokenId) public view returns (uint256) {
        require(Verify(_tokenId), "POSW Request: You don't have a valid PlanetPass NFT.");
        return POSW.getPOSW_SocialPlatform(user, _socialPlatform);
    }

    /* User POSW by Community */
    function getPOSW_Community (address user, uint256 _community, uint256 _tokenId) public view returns (uint256) {
        require(Verify(_tokenId), "POSW Request: You don't have a valid PlanetPass NFT.");
        return POSW.getPOSW_Community(user, _community);
    }

    /* User POSW by Version & Social Platform */
    function getPOSW_Version_SocialPlatform (address user, uint256 _version, uint256 _socialPlatform, uint256 _tokenId) public view returns (uint256) {
        require(Verify(_tokenId), "POSW Request: You don't have a valid PlanetPass NFT.");
        return POSW.getPOSW_Version_SocialPlatform(user, _version, _socialPlatform);
    }

    /* User POSW by Version & Community */
    function getPOSW_Version_Community (address user, uint256 _version, uint256 _community, uint256 _tokenId) public view returns (uint256) {
        require(Verify(_tokenId), "POSW Request: You don't have a valid PlanetPass NFT.");
        return POSW.getPOSW_Version_Community(user, _version, _community);
    }

    /* User POSW by Social Platform & Community */
    function getPOSW_SocialPlatform_Community (address user, uint256 _socialPlatform, uint256 _community, uint256 _tokenId) public view returns (uint256) {
        require(Verify(_tokenId), "POSW Request: You don't have a valid PlanetPass NFT.");
        return POSW.getPOSW_SocialPlatform_Community(user, _socialPlatform, _community);
    }

    /* User POSW by Version & Social Platform & Community */
    function getPOSW_Version_SocialPlatform_Community (address user, uint256 _version, uint256 _socialPlatform, uint256 _community, uint256 _tokenId) public view returns (uint256) {
        require(Verify(_tokenId), "POSW Request: You don't have a valid PlanetPass NFT.");
        return POSW.getPOSW_Version_SocialPlatform_Community(user, _version, _socialPlatform, _community);
    }

  /** Global User POSW Request **/
    /* Global POSW Overall */
    function getGlobalPOSW_Overall () public view returns (uint256) {
        return POSW.getGlobalPOSW_Overall();
    }

    /* Global POSW by Version */
    function getGlobalPOSW_Version (uint256 _version) public view returns (uint256) {
        return POSW.getGlobalPOSW_Version(_version);
    }

    /* Global POSW by Social Platform */
    function getGlobalPOSW_SocialPlatform (uint256 _socialPlatform) public view returns (uint256) {
        return POSW.getGlobalPOSW_SocialPlatform(_socialPlatform);
    }

    /* Global POSW by Community */
    function getGlobalPOSW_Community (uint256 _community, uint256 _tokenId) public view returns (uint256) {
        require(Verify(_tokenId), "POSW Request: You don't have a valid PlanetPass NFT.");
        return POSW.getGlobalPOSW_Community(_community);
    }

    /* Global POSW by Version & Social Platform */
    function getGlobalPOSW_Version_SocialPlatform (uint256 _version, uint256 _socialPlatform) public view returns (uint256) {
        return POSW.getGlobalPOSW_Version_SocialPlatform(_version, _socialPlatform);
    }

    /* Global POSW by Version & Community */
    function getGlobalPOSW_Version_Community (uint256 _version, uint256 _community, uint256 _tokenId) public view returns (uint256) {
        require(Verify(_tokenId), "POSW Request: You don't have a valid PlanetPass NFT.");
        return POSW.getGlobalPOSW_Version_Community(_version, _community);
    }

    /* Global POSW by Social Platform & Community */
    function getGlobalPOSW_SocialPlatform_Community (uint256 _socialPlatform, uint256 _community, uint256 _tokenId) public view returns (uint256) {
        require(Verify(_tokenId), "POSW Request: You don't have a valid PlanetPass NFT.");
        return POSW.getGlobalPOSW_SocialPlatform_Community(_socialPlatform, _community);
    }

    /* Global POSW by Version & Social Platform & Community */
    function getGlobalPOSW_Version_SocialPlatform_Community (uint256 _version, uint256 _socialPlatform, uint256 _community, uint256 _tokenId) public view returns (uint256) {
        require(Verify(_tokenId), "POSW Request: You don't have a valid PlanetPass NFT.");
        return POSW.getGlobalPOSW_Version_SocialPlatform_Community(_version, _socialPlatform, _community);
    }

/*** Builder POSW Request ***/
    function getPOSW_Builder (uint256 _tokenId) public view returns (uint256) {
        return BH.getPOSW_Builder(_tokenId);
    }

    function getPOSW_Builder_Owner (uint256 _tokenId) public view returns (uint256) {
        return BH.getPOSW_Builder_Owner(_tokenId);
    }

    function getPOSW_Builder_SocialPlatform (uint256 _tokenId, uint256 _socialPlatform) public view returns (uint256) {
        return BH.getPOSW_Builder_SocialPlatform(_tokenId, _socialPlatform);
    }

    function getPOSW_Builder_SocialPlatform_Owner (uint256 _tokenId, uint256 _socialPlatform) public view returns (uint256) {
        return BH.getPOSW_Builder_SocialPlatform_Owner(_tokenId, _socialPlatform);
    }
}