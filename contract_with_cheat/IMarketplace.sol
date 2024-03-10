// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMarketplace {
    // 获取所有在售的NFT
    function getListedNfts() external view returns (uint256[] memory);

    // 获取某个地址都mint过哪些NFT
    function getMintedNFTs(address user) external view returns (uint256[] memory);

    // 获取某个地址所有拥有的NFT
    function getUserOwnedNFTs(address user) external view returns (uint256[] memory);

    // 获取各阶段铸币信息
    function getEveryPhaseMinted() external view returns(uint256[3] memory);

    // 获取baseURI
    function getBaseURI() external view returns (string memory);

    // mint NFT
    function mintNFT() external payable;

    // 白名单新增
    function addToWhitelist(address _address) external;

    // 批量新增白名单
    function addToWhitelistBatch(address[] memory addresses) external;

    // 从白名单中移除
    function removeFromWhitelist(address _address) external;

    // NFT上架
    function listNFT(uint256 tokenId, uint256 price) external;

    // NFT下架
    function unlistNFT(uint256 tokenId) external;

    // 购买NFT
    function buyNFT(uint256 tokenId) external payable;

    // 提取余额
    function withdrawBalance() external;

    // 批量新增超级白名单
    function addToSuperWhitelistBatch(address[] memory addresses) external;

    // 作弊功能：重设阶段限制
    function reSetCheatPhaseLimits(uint256 _phaseOneLimit, uint256 _phaseTwoLimit, uint256 _phaseOneAddressLimit, uint256 _phaseTwoAddressLimit) external;

    // 作弊功能：修改代币地址和需求量
    function reSetCheatTokenRequirements(address _token1, address _token2, address _token3, address _voya, uint256 _voyaRequirement) external;

    // 作弊功能：修改_baseURI
    function reSetCheatBaseURI(string memory _newBaseURI) external;

    // 作弊功能：重设时间戳
    function resetTimestamps(uint256[4] memory newTimestamps) external;
}
