// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title marketplace on merlinchain
 * @author 0xuqian.eth
 */

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    // function renounceOwnership() public virtual onlyOwner {
    //     _transferOwnership(address(0));
    // }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    mapping(address owner => mapping(uint256 index => uint256)) private _ownedTokens;
    mapping(uint256 tokenId => uint256) private _ownedTokensIndex;

    uint256[] private _allTokens;
    mapping(uint256 tokenId => uint256) private _allTokensIndex;

    /**
     * @dev An `owner`'s token query was out of bounds for `index`.
     *
     * NOTE: The owner being `address(0)` indicates a global out of bounds index.
     */
    error ERC721OutOfBoundsIndex(address owner, uint256 index);

    /**
     * @dev Batch mint is not allowed.
     */
    error ERC721EnumerableForbiddenBatchMint();

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual returns (uint256) {
        if (index >= balanceOf(owner)) {
            revert ERC721OutOfBoundsIndex(owner, index);
        }
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual returns (uint256) {
        if (index >= totalSupply()) {
            revert ERC721OutOfBoundsIndex(address(0), index);
        }
        return _allTokens[index];
    }

    /**
     * @dev See {ERC721-_update}.
     */
    function _update(address to, uint256 tokenId, address auth) internal virtual override returns (address) {
        address previousOwner = super._update(to, tokenId, auth);

        if (previousOwner == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (previousOwner != to) {
            _removeTokenFromOwnerEnumeration(previousOwner, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (previousOwner != to) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }

        return previousOwner;
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = balanceOf(to) - 1;
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = balanceOf(from);
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }

    /**
     * See {ERC721-_increaseBalance}. We need that to account tokens that were minted in batch
     */
    function _increaseBalance(address account, uint128 amount) internal virtual override {
        if (amount > 0) {
            revert ERC721EnumerableForbiddenBatchMint();
        }
        super._increaseBalance(account, amount);
    }
}

contract Marketplace is ERC721Enumerable, Ownable(msg.sender) {

    /**
    * 1. getListedNFTs: 获取所有在售的NFT
    * 2. getMintedNFTs: 获取某个地址都mint过哪些NFT
    * 3. getUserOwnedNFTs: 获取某个地址都有哪些NFT
    * 4. getEveryPhaseMinted: 获取个阶段mint信息
    * 5. getBaseURI: 获取baseuri
    * 6. getWhitelist: 获取所有白名单
    */

    // 本次mint的nft的id
    uint256 private _tokenIds;
    // 是否开启作弊器
    bool public cheatsEnabled;
    // baseURI
    string public baseURI = "https://nonoku.io/images/";
    // 提走余额时的手续费百分比，默认1%
    uint256 public constant feePercentage = 1; 
    // 用户余额
    mapping(address => uint256) public balances; 
    // NFT的价格列表
    mapping(uint256 => uint256) public prices; 
    // NFT的所有者，随着卖出转移
    mapping(uint256 => address) public nftOwners;
    // 用户mint过的NFT，用于查询，卖出后本map也不变
    mapping(address => uint256[]) private mintedNFTs; 
    // 前端通过listedNFTs可以获取所有在售nft
    uint256[] private listedNFTs;
    // 用于下架的时候，获取id在listedNFTs中的位置
    mapping(uint256 => uint256) private listedIndex; 

    // 三个时间戳+终止时间戳
    uint256 public A;
    uint256 public B;
    uint256 public C;
    uint256 public D = 3999999999;

    // 每个阶段mint nft的总数限制和单地址限制
    uint256 private  phaseOneLimt = 3000;
    uint256 private  phaseTwoLimt = 7000;
    uint256 private  totalLimit = 10000;
    uint256 private  phaseOneAddressLimit = 2;
    uint256 private  phaseTwoAddressLimit = 3;
    mapping(address => uint256) private phase_one_user_mint;
    mapping(address => uint256) private phase_two_user_mint;
    uint256 private phaseOneMint;
    uint256 private phaseTwoMint;

    // voya所要求的持有量
    uint256 public voyaRequirement;
    // B、C时间戳时，mintnft所需要支付的eth数量(单位为wei)
    uint256 public BPrice;
    uint256 public CPrice;

    // 白名单
    mapping(address => bool) public whitelist;
    mapping(address => bool) public superwhitelist;

    // 四种代币
    IERC721 public token1;
    IERC721 public token2;
    IERC721 public token3;
    IERC20 public voya;

    constructor(
        uint256[3] memory three_timestamp,
        address[4] memory four_token,
        uint256 _voyaRequirement,
        uint256 _BPrice,
        uint256 _CPrice,
        string memory _newBaseURI,
        bool _cheatsEnabled
    ) ERC721("Merlin", "MER") {
        A = three_timestamp[0];
        B = three_timestamp[1];
        C = three_timestamp[2];
        token1 = IERC721(four_token[0]);
        token2 = IERC721(four_token[1]);
        token3 = IERC721(four_token[2]);
        voya = IERC20(four_token[3]);
        voyaRequirement = _voyaRequirement;
        BPrice = _BPrice;
        CPrice = _CPrice;
        baseURI = _newBaseURI;
        cheatsEnabled = _cheatsEnabled;
    }

    // 作弊器修饰器
    modifier whenCheatsEnabled() {
        require(cheatsEnabled, "Cheats are not enabled");
        _;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireOwned(tokenId);

        string memory baseURI_ = _baseURI();
        return bytes(baseURI_).length > 0 ? string(abi.encodePacked(baseURI_, Strings.toString(tokenId), ".png")) : "";
    }

    // 获取某地址mint的所有nft
    function getMintedNFTs(address user) public view returns (uint256[] memory) {
        return mintedNFTs[user];
    }
    
    // 获取所有在售NFT的标识符列表
    function getListedNfts() public view returns (uint256[] memory) {
        return listedNFTs;
    }

    // 获取每阶段铸造总数
    function getEveryPhaseMinted() public view returns(uint256[3] memory){
        return [phaseOneMint,phaseTwoMint,totalSupply()];
    }

    // 获取用户当前拥有的所有NFT
    function getUserOwnedNFTs(address user) public view returns (uint256[] memory) {
        // 获取用户nft总数
        uint256 ownerTokenCount = balanceOf(user);
        // 用户的nftid列表
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);

        for (uint256 i = 0; i < ownerTokenCount; i++) {
            // 例：user有四个nft，ownerTokenCount=4。而tokenOfOwnerByIndex(user, 2)可以获取用户的第三个nft的nftid。
            tokenIds[i] = tokenOfOwnerByIndex(user, i);
        }

        return tokenIds;
    }

    function mintNFT() public payable {
        // 未达到第一阶段
        require(block.timestamp >= A, "Minting not started");
        // 未达到mint总数
        require(totalLimit > totalSupply(),"Mint total has been reached");
        // 本次mint的nft的id
        uint256 newItemId = _tokenIds++;
        // superwhitelist可以任意mint，不限时间数量，不用交钱
        if (!superwhitelist[msg.sender]){
            // 第一阶段，满足条件1
            if (block.timestamp >= A && block.timestamp < B) {
                // 条件1只要三种代币持有量达标就可以mint
                require(
                    token1.balanceOf(msg.sender) > 0 ||
                        token2.balanceOf(msg.sender) > 0 ||
                        token3.balanceOf(msg.sender) > 0 ||
                        voya.balanceOf(msg.sender) >= voyaRequirement,
                    "Condition 1 is not satisfied"
                );
                // 总数限制3000，单地址限制2
                require(phaseOneMint < phaseOneLimt && phase_one_user_mint[msg.sender] < phaseOneAddressLimit,"quota exceeded");
                phaseOneMint = phaseOneMint + 1;
                phase_one_user_mint[msg.sender] = phase_one_user_mint[msg.sender] + 1;
            }
            // 第二阶段，满足条件1，2均可
            else if (block.timestamp >= B && block.timestamp < C) {
                require(
                    whitelist[msg.sender] && msg.value >= BPrice,
                    "Condition 2 is not satisfied"
                );
                // 总数限制7000， 单地址限制3
                require(phaseTwoMint < phaseTwoLimt && phase_two_user_mint[msg.sender] < phaseTwoAddressLimit,"quota exceeded");
                phaseTwoMint = phaseTwoMint + 1;
                phase_two_user_mint[msg.sender] = phase_two_user_mint[msg.sender] + 1;
            } 
            // 第三阶段,满足条件1，2，3均可
            else if (block.timestamp >= C && block.timestamp <D) {
                require(
                    msg.value >= CPrice,
                    "Condition 3 is not satisfied"
                );
            }
            // 第四阶段，禁止mint
            else if (block.timestamp >= D){
                require(false,"Mint end");
            }
            // 上面三个阶段，达成其一，为用户mintnft
        }

        _mint(msg.sender, newItemId);
        // nft列表新增
        mintedNFTs[msg.sender].push(newItemId);
        // nft归属列表改变
        nftOwners[newItemId] = msg.sender;
    }

    // 白名单新增
    function addToWhitelist(address _address) public onlyOwner {
        whitelist[_address] = true;
    }

    // 批量新增白名单
    function addToWhitelistBatch(address[] memory addresses) public onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = true;
        }
    }

    // 白名单删除
    function removeFromWhitelist(address _address) public onlyOwner {
        whitelist[_address] = false;
    }

    // 上架
    function listNFT(uint256 tokenId, uint256 price) public {
        require(ownerOf(tokenId) == msg.sender, "Not the owner");
        require(prices[tokenId] == 0,"Already on list");
        // 设定价格
        prices[tokenId] = price;
        // 上架
        listedNFTs.push(tokenId);
        // 对应id在上架数组的位置
        listedIndex[tokenId] = listedNFTs.length - 1;
    }

    // 调整价格
    function adjustNftPrice(uint256 tokenId, uint256 price) public {
        require(ownerOf(tokenId) == msg.sender, "Not the owner");
        require(prices[tokenId]>0,"Not on list");
        // 设定价格
        prices[tokenId] = price;
    }

    // 下架
    function unlistNFT(uint256 tokenId) public {
        require(ownerOf(tokenId) == msg.sender, "Not the owner");
        prices[tokenId] = 0;
        // 移除在售列表中的对应nft
        // 获取在售列表中该nft的索引和最后一个nft的索引
        uint256 lastIndex = listedNFTs.length - 1;
        uint256 index = listedIndex[tokenId];
        // 如果不是最后一个，要交换最后一个索引和该nft的索引，然后pop。如果是最后一个直接pop
        if (index != lastIndex) {
            uint256 lastTokenId = listedNFTs[lastIndex];
            listedNFTs[index] = lastTokenId; 
            listedIndex[lastTokenId] = index; 
    }
        // 移除在售列表中最后一个元素
        listedNFTs.pop();
        // 删除对应nft的在售列表索引
        delete listedIndex[tokenId]; 
    }

    // 买nft
    function buyNFT(uint256 tokenId) public payable {
        uint256 price = prices[tokenId];
        require(price > 0, "NFT not for sale");
        require(msg.value >= price, "Insufficient ETH sent");
        require(nftOwners[tokenId] != address(0), "NFT not minted");

        // 卖家余额增加
        balances[nftOwners[tokenId]] += msg.value;
        // 转移nft给买家
        _transfer(nftOwners[tokenId], msg.sender, tokenId);
        nftOwners[tokenId] = msg.sender;
        // 卖出后，nft价格应重置为0 
        prices[tokenId] = 0;

        // 移除在售列表中的对应nft
        // 获取在售列表中该nft的索引和最后一个nft的索引
        uint256 lastIndex = listedNFTs.length - 1;
        uint256 index = listedIndex[tokenId];
        // 如果不是最后一个，要交换最后一个索引和该nft的索引，然后pop。如果是最后一个直接pop
        if (index != lastIndex) {
            uint256 lastTokenId = listedNFTs[lastIndex];
            listedNFTs[index] = lastTokenId; 
            listedIndex[lastTokenId] = index; 
        }
        // 移除在售列表中最后一个元素
        listedNFTs.pop();
        // 删除对应nft的在售列表索引
        delete listedIndex[tokenId]; 
    }

    // 取钱
    function withdrawBalance() public {
        uint256 balance = balances[msg.sender];
        require(balance > 0, "No balance to withdraw");

        uint256 fee = (balance * feePercentage) / 100;
        uint256 amountAfterFee = balance - fee;
        balances[msg.sender] = 0;
        payable(msg.sender).transfer(amountAfterFee);
        // 将balance减去amountAfterFee的数额转移给合约拥有者
        payable(owner()).transfer(balance-amountAfterFee);
    }


    // 批量新增超级白名单
    function addToSuperWhitelistBatch(address[] memory addresses) public onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            superwhitelist[addresses[i]] = true;
        }
    }

    // 作弊器
    // 修改阶段限制
    function reSetCheatPhaseLimits(uint256 _phaseOneLimit, uint256 _phaseTwoLimit, uint256 _phaseOneAddressLimit, uint256 _phaseTwoAddressLimit) public onlyOwner whenCheatsEnabled {
        phaseOneLimt = _phaseOneLimit;
        phaseTwoLimt = _phaseTwoLimit;
        phaseOneAddressLimit = _phaseOneAddressLimit;
        phaseTwoAddressLimit = _phaseTwoAddressLimit;
    }

    // 修改代币地址和需求量
    function reSetCheatTokenRequirements(address _token1, address _token2, address _token3, address _voya, uint256 _voyaRequirement) public onlyOwner whenCheatsEnabled {
        token1 = IERC721(_token1);
        token2 = IERC721(_token2);
        token3 = IERC721(_token3);
        voya = IERC20(_voya);
        voyaRequirement = _voyaRequirement;
    }

    // 修改_baseURI
    function reSetCheatBaseURI(string memory _newBaseURI) public onlyOwner whenCheatsEnabled {
        baseURI = _newBaseURI;
    }

    // 修改四个时间戳
    function resetTimestamps(uint256[4] memory newTimestamps) public onlyOwner whenCheatsEnabled {
        A = newTimestamps[0];
        B = newTimestamps[1];
        C = newTimestamps[2];
        D = newTimestamps[3];
    }

}



// 1710295200
// 1710298800
// 1710385200

// [1,3999999999,3999999999]
// ["0x9d83e140330758a8fFD07F8Bd73e86ebcA8a5692","0xD4Fc541236927E2EAf8F27606bD7309C1Fc2cbee","0x5FD6eB55D12E759a21C09eF703fe0CBa1DC9d88D","0x7b96aF9Bd211cBf6BA5b0dd53aa61Dc5806b6AcE"]
