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

contract NNK is ERC721Enumerable, Ownable(msg.sender) {

    uint256 private _tokenIds;

    string public baseURI = "https://nonoku.io/images/";

    uint256 public constant feePercentage = 3; 
    // mapping(address => uint256) public balances; 
    mapping(uint256 => uint256) public prices; 
    mapping(uint256 => address) public nftOwners;
    mapping(address => uint256[]) private mintedNFTs; 
    uint256[] private listedNFTs;
    mapping(uint256 => uint256) private listedIndex; 

    uint256 public A = 1710327600; // UTC 2024-3-13 11:00 1710327600
    uint256 public B = 1710327600 + 1 hours; // UTC 2024-3-13 12:00 1710331200
    uint256 public C = 1710327600 + 3 hours; // UTC 2024-3-13 14:00 1710338400

    uint256 private  phaseOneLimt = 3000;
    uint256 private  phaseTwoLimt = 7000;
    uint256 private  totalLimit = 10000;
    uint256 private  phaseOneAddressLimit = 2;
    uint256 private  phaseTwoAddressLimit = 3;
    uint256 private  phaseThrAddressLimit = 3;
    mapping(address => uint256) public phase_one_user_mint;
    mapping(address => uint256) public phase_two_user_mint;
    mapping(address => uint256) public phase_thr_user_mint;
    uint256 public phaseOneMint;
    uint256 public phaseTwoMint;

    uint256 public voyaRequirement = 248_000_000_000_000_000_000; // 248
    uint256 public BPrice = 700_000_000_000_000; // 0.0007 BTC
    uint256 public CPrice = 850_000_000_000_000; // 0.00085 BTC

    mapping(address => bool) public whitelist;
    mapping(address => bool) public whitelist_onemore;

    IERC20 public voya = IERC20(address(0x480E158395cC5b41e5584347c495584cA2cAf78d));

    constructor() ERC721("Nonoku", "NNK") {}

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireOwned(tokenId);

        string memory baseURI_ = _baseURI();
        return bytes(baseURI_).length > 0 ? string(abi.encodePacked(baseURI_, Strings.toString(tokenId), ".json")) : "";
    }

    function getMintedNFTs(address user) public view returns (uint256[] memory) {
        return mintedNFTs[user];
    }
    
    function getListedNfts() public view returns (uint256[] memory) {
        return listedNFTs;
    }

    function getEveryPhaseMinted() public view returns(uint256[3] memory){
        return [phaseOneMint,phaseTwoMint,totalSupply()];
    }

    function getUserOwnedNFTs(address user) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(user);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);

        for (uint256 i = 0; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(user, i);
        }

        return tokenIds;
    }

    function mintNFT() public payable {
        require(block.timestamp >= A, "Minting not started");
        require(totalLimit > totalSupply(),"Mint total has been reached");
        uint256 newItemId = _tokenIds++;
        if (block.timestamp >= A && block.timestamp < B) {
            require(
                whitelist_onemore[msg.sender] ||
                voya.balanceOf(msg.sender) >= voyaRequirement,
                "Condition 1 is not satisfied"
            );
            require(phaseOneMint < phaseOneLimt && phase_one_user_mint[msg.sender] < phaseOneAddressLimit,"quota exceeded");
            phaseOneMint = phaseOneMint + 1;
            phase_one_user_mint[msg.sender] = phase_one_user_mint[msg.sender] + 1;
        }
        else if (block.timestamp >= B && block.timestamp < C) {
            require(
                whitelist[msg.sender] && msg.value >= BPrice,
                "Condition 2 is not satisfied"
            );
            require(phaseTwoMint < phaseTwoLimt && phase_two_user_mint[msg.sender] < phaseTwoAddressLimit,"quota exceeded");
            phaseTwoMint = phaseTwoMint + 1;
            phase_two_user_mint[msg.sender] = phase_two_user_mint[msg.sender] + 1;
        } 
        else if (block.timestamp >= C) {
            require(
                msg.value >= CPrice,
                "Condition 3 is not satisfied"
            );
            require(phase_thr_user_mint[msg.sender] < phaseThrAddressLimit,"quota exceeded");
            phase_thr_user_mint[msg.sender] = phase_thr_user_mint[msg.sender] + 1;
        }

        _mint(msg.sender, newItemId);
        payable(owner()).transfer(msg.value);
        mintedNFTs[msg.sender].push(newItemId);
        nftOwners[newItemId] = msg.sender;
    }

    function mintMultipleNFTs(uint256 count) public payable{
        require(count > 0,"Count must be greater than 0");
        require(block.timestamp >= A, "Minting not started");
        require(totalLimit > totalSupply()+ count - 1,"Mint total has been reached");
        if (block.timestamp >= A && block.timestamp < B) {
            require(
                whitelist_onemore[msg.sender] ||
                voya.balanceOf(msg.sender) >= voyaRequirement,
                "Condition 1 is not satisfied"
            );
            require(phaseOneMint + count - 1 < phaseOneLimt && phase_one_user_mint[msg.sender] + count - 1 < phaseOneAddressLimit,"quota exceeded");
            phaseOneMint = phaseOneMint + count;
            phase_one_user_mint[msg.sender] = phase_one_user_mint[msg.sender] + count;
        }
        else if (block.timestamp >= B && block.timestamp < C) {
            require(
                whitelist[msg.sender] && msg.value >= BPrice * count,
                "Condition 2 is not satisfied"
            );
            require(phaseTwoMint + count - 1 < phaseTwoLimt && phase_two_user_mint[msg.sender] + count - 1 < phaseTwoAddressLimit,"quota exceeded");
            phaseTwoMint = phaseTwoMint + count;
            phase_two_user_mint[msg.sender] = phase_two_user_mint[msg.sender] + count;
        } 
        else if (block.timestamp >= C) {
            require(
                msg.value >= CPrice * count,
                "Condition 3 is not satisfied"
            );
        }

        for (uint i = 0; i < count; i++) {
            uint256 newItemId = _tokenIds++;
            _mint(msg.sender, newItemId);
            mintedNFTs[msg.sender].push(newItemId);
            nftOwners[newItemId] = msg.sender;
        }

        payable(owner()).transfer(msg.value);
    }

    function canMintNFT() public view returns(uint256){
        if (totalSupply() >= totalLimit){
            return 0;
        }
        if (block.timestamp >= A && block.timestamp < B){
            if ((whitelist_onemore[msg.sender] ||
                voya.balanceOf(msg.sender) >= voyaRequirement)&&
                (phaseOneMint < phaseOneLimt && 
                phase_one_user_mint[msg.sender] < phaseOneAddressLimit)){
                    return (phaseOneLimt + phaseOneAddressLimit) > (phase_one_user_mint[msg.sender] + phaseOneMint) ?
                     (phaseOneAddressLimit - phase_one_user_mint[msg.sender]):(phaseOneLimt - phaseOneMint);
                }else{
                    return 0;
                }
        }else if (block.timestamp >= B && block.timestamp < C){
            if (whitelist[msg.sender]&&
                (phaseTwoMint < phaseTwoLimt && 
                phase_two_user_mint[msg.sender] < phaseTwoAddressLimit)){
                    return (phaseTwoLimt + phaseTwoAddressLimit) > (phase_two_user_mint[msg.sender] + phaseTwoMint) ?
                     (phaseTwoAddressLimit - phase_two_user_mint[msg.sender]):(phaseTwoLimt - phaseTwoMint);
                }else{
                    return 0;
                }
        }else if (block.timestamp >= C){
            return (totalLimit + phaseThrAddressLimit) > (phase_thr_user_mint[msg.sender] + totalSupply()) ?
                     (phaseOneAddressLimit - phase_one_user_mint[msg.sender]):(totalLimit - totalSupply());
        }else {
            return 0;
        }
    }

    function addToWhitelist(address _address) public onlyOwner {
        whitelist[_address] = true;
    }

    function addToWhitelistBatch(address[] memory addresses) public onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = true;
        }
    } 

    function removeFromWhitelist(address _address) public onlyOwner {
        whitelist[_address] = false;
    }

    function addToWhitelistOneMore(address _address) public onlyOwner {
        whitelist_onemore[_address] = true;
    }

    function addToWhitelistOneMoreBatch(address[] memory addresses) public onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            whitelist_onemore[addresses[i]] = true;
        }
    }

    function removeFromWhitelistOneMore(address _address) public onlyOwner {
        whitelist_onemore[_address] = false;
    }

    // ================================================

    // function listNFT(uint256 tokenId, uint256 price) public {
    //     require(ownerOf(tokenId) == msg.sender, "Not the owner");
    //     require(prices[tokenId] == 0,"Already on list");
    //     prices[tokenId] = price;
    //     listedNFTs.push(tokenId);
    //     listedIndex[tokenId] = listedNFTs.length - 1;
    // }

    function listMultipleNFTs(uint256[] memory tokenIds, uint256[] memory pricesArray) public {
        require(tokenIds.length == pricesArray.length, "Arrays must be of equal length");

        for (uint i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            uint256 price = pricesArray[i];
            require(ownerOf(tokenId) == msg.sender, "Not the owner");
            require(prices[tokenId] == 0, "Already on list");
            prices[tokenId] = price;
            listedNFTs.push(tokenId);
            listedIndex[tokenId] = listedNFTs.length - 1;
        }
    }

    function adjustNftPrice(uint256 tokenId, uint256 price) public {
        require(ownerOf(tokenId) == msg.sender, "Not the owner");
        require(prices[tokenId] > 0,"Not on list");
        prices[tokenId] = price;
    }

    function unlistNFT(uint256 tokenId) public {
        require(ownerOf(tokenId) == msg.sender, "Not the owner");
        prices[tokenId] = 0;
        uint256 lastIndex = listedNFTs.length - 1;
        uint256 index = listedIndex[tokenId];
        if (index != lastIndex) {
            uint256 lastTokenId = listedNFTs[lastIndex];
            listedNFTs[index] = lastTokenId; 
            listedIndex[lastTokenId] = index; 
    }
        listedNFTs.pop();
        delete listedIndex[tokenId]; 
    }

    function buyNFT(uint256 tokenId) public payable {
        uint256 price = prices[tokenId];
        require(price > 0, "NFT not for sale");
        require(msg.value >= price, "Insufficient ETH sent");
        require(nftOwners[tokenId] != address(0), "NFT not minted");

        payable(nftOwners[tokenId]).transfer(msg.value);
        _transfer(nftOwners[tokenId], msg.sender, tokenId);
        nftOwners[tokenId] = msg.sender;
        prices[tokenId] = 0;

        uint256 lastIndex = listedNFTs.length - 1;
        uint256 index = listedIndex[tokenId];
        if (index != lastIndex) {
            uint256 lastTokenId = listedNFTs[lastIndex];
            listedNFTs[index] = lastTokenId; 
            listedIndex[lastTokenId] = index; 
        }
        listedNFTs.pop();
        delete listedIndex[tokenId]; 
    }
}

