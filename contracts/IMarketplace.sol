// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMarketplace {
    function getListedNfts() external view returns (uint256[] memory);

    function getMintedNFTs(address user) external view returns (uint256[] memory);

    function getUserOwnedNFTs(address user) external view returns (uint256[] memory);

    function getEveryPhaseMinted() external view returns(uint256[3] memory);

    function getBaseURI() external view returns (string memory);

    function addToWhitelist(address _address) external;

    function addToWhitelistBatch(address[] memory addresses) external;

    function removeFromWhitelist(address _address) external;

    function listNFT(uint256 tokenId, uint256 price) external;

    function unlistNFT(uint256 tokenId) external;

    function buyNFT(uint256 tokenId) external payable;

    function withdrawBalance() external;

    function addToSuperWhitelistBatch(address[] memory addresses) external;
}
