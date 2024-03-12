// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMarketplace {
    function getListedNfts() external view returns (uint256[] memory);

    function getMintedNFTs(address user) external view returns (uint256[] memory);

    function getUserOwnedNFTs(address user) external view returns (uint256[] memory);

    function getEveryPhaseMinted() external view returns(uint256[3] memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function mintNFT() external payable;

    function mintMultipleNFTs(uint256 count) external payable;
    
    function canMintNFT() external view returns(bool);

    function addToWhitelist(address _address) external;

    function addToWhitelistBatch(address[] memory addresses) external;

    function removeFromWhitelist(address _address) external;

    function addToWhitelistOneMore(address _address) external;

    function addToWhitelistOneMoreBatch(address[] memory addresses) external;

    function removeFromWhitelistOneMore(address _address) external;
    
    function listMultipleNFTs(uint256[] calldata tokenIds, uint256[] calldata pricesArray) external;

    function unlistNFT(uint256 tokenId) external;

    function buyNFT(uint256 tokenId) external payable;

    function addToSuperWhitelistBatch(address[] memory addresses) external;
}
