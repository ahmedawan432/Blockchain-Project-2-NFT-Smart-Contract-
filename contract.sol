// SPDX-License-Identifier: MIT
pragma solidity >= 0.7.0 < 0.9.0;

/*Importing contracts from openzeppelin*/

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFT is ERC721, ERC721URIStorage, Pausable, Ownable {

    /*
    * State variables:
    * baseURI store base uri for every token
    * totalLimit store total minting limit
    * whiteListedLimit store whitelisted minting limit
    * publicLimit store public minting limit
    * adminLimit store admin minting limit
    * publicSale store status of public sale
    * mintedNFTs find number of total minted NFTs
    * whitelistedMintedNFTs find number of whitelisted minted NFTs
    * publicMintedNFTs find number of publicaly minted NFTs
    * adminMintedNFTs find number of NFTs minted by admins
    */

    string public baseURI;
    uint public totalLimit;
    uint public whiteListedLimit;
    uint public publicLimit;
    uint public adminLimit;
    bool public publicSale;
    uint public mintedNFTs;
    uint public whitelistedMintedNFTs;
    uint public publicMintedNFTs;
    uint public adminMintedNFTs;

    /*
    * Constructor Token name PKSPECIAL and symbol PKS
    */

    constructor() ERC721("PKSPECIAL", "PKS") {}

    /*
    * Struct store data every nft with id, name and metadata hash
    */
    struct nftData {
        uint Id;
        string Name;
        string MetadataHash;
    }

    /*
    * Mappings
    */
    mapping(address => bool) public whiteListedUsers;
    mapping(address => uint) public perAddressMinting;
    mapping(address => bool) public whiteListedAdmins;
    mapping(uint => nftData) public NFTs;

    /*
    * Events
    */

   
    event withdrawBalance(address _address,uint _balance);
    event publicSaleEvent(address _sender, bool _status);
    event addAdminEvent(address _admin, bool _status);
    event setMintingLimit(uint _total, uint _whitelisted, uint _admin, uint _public);
    event updateUri(address _sender, string _uri);
    event updateWhitelistedUser(address _sender, address _user, bool _status);

    /*
    * Errors
    */

    error perAddressLimit(string);
    error totalMintLimit(string);
    error notWhitelistedAdmin(string);
    error notWhitelistedUser(string);
    error whitelistedUserLimit(string);
    error publicSaleStatus(string);
    error publicMintLimit(string);
    error adminMintLimit(string);

    
    /*
    * pause function set paused status to true.
    */

    function pause() public onlyOwner {
        _pause();
    }

    /*
    * unpause function sets the paused status to false.
    */
    
    function unpause() public onlyOwner {
        _unpause();
    }

    /*
    * safeMint mints ERC721 Token.
    * to Will be address of receiver of minted token.
    * name Will be name of NFT.
    * uri Will be metadata hash of minted token.
    */

    function safeMint(address to, uint _id, string memory name, string memory uri) private {
        if(mintedNFTs < totalLimit) {
            if (perAddressMinting[msg.sender] < 5) {
                _safeMint(to, _id);
                _setTokenURI(_id, string(abi.encode(baseURI, uri)));
                NFTs[_id] = nftData(_id, name, uri);
                perAddressMinting[msg.sender] += 1;
                mintedNFTs += 1;
            }
            else {
                revert perAddressLimit("Minting limit of 5 NFTs per address is reached");
            }
        }
        else {
            revert totalMintLimit("Total minting limit is reached");
        }
    }

    /*
    * setPuclicSale sets the status of public sale.
    * _status - Will be the status of the public sale, either true or false.
    */

    function setPuclicSale(bool _status) public onlyOwner{
        require(!paused(), "Pausable: paused");
        publicSale = _status;
        emit publicSaleEvent(msg.sender, _status);
    }

    /*
    * addAdmin adds admin.
    * _address will be address of the admin.
    * _status Will be status of the admin.
    */

    function addAdmin(address _address, bool _status) public onlyOwner {
        require(!paused(), "Pausable: paused");
        whiteListedAdmins[_address] = _status;
        emit addAdminEvent(_address, _status);
    }

    /*
    * setMIntingLimit sets minting limit for types of minting.
    * _totalMinting will be the total minting limit.
    * _whitelistedMinting will be the whitelisted user minting limit.
    * _adminMinting - Will be the admin minting limit.
    */

    function setNFTMintingLimit(
        uint _totalMinting,
        uint _whitelistedMinting,
        uint _adminMinting
    )
        public
        onlyOwner
    {
        require(!paused(), "Pausable: paused");
        totalLimit = _totalMinting;
        whiteListedLimit = _whitelistedMinting;
        publicLimit = _totalMinting - (_whitelistedMinting + _adminMinting);
        adminLimit = _adminMinting;
        emit setMintingLimit(totalLimit, whiteListedLimit, _adminMinting, publicLimit);
    }

    /*
    * @dev updateBaseUri updates the base URI for all the NFTs.
    * @param _uri will be the base URI.
    */

    function updateBaseUri(string memory _uri) public {
        require(!paused(), "Pausable: paused");
        if(whiteListedAdmins[msg.sender]) {
            baseURI = _uri;
            emit updateUri(msg.sender, _uri);
        }
        else {
            revert notWhitelistedAdmin("Not a whitelisted admin");
        }
    }

    /*
    * addWhitelistedUser adds or updated the whitelisted users.
    * _address will be the address of the user.
    * _status will be the status of the user, either whitelisted or not.
    */

    function addWhitelistedUser(address _address, bool _status) public {
        require(!paused(), "Pausable: paused");
        if(whiteListedAdmins[msg.sender]) {
            whiteListedUsers[_address] = _status;
            emit updateWhitelistedUser(msg.sender, _address, _status);
        }
        else {
            revert notWhitelistedAdmin("Not a whitelisted admin");
        }
    }
    
    /*
    * whitelistUserMinting mints the ERC721 Token for whitelisted users only.
    * _to - Will be the address of the receiver of minted token.
    * _name - Will be the name of the NFT.
    * _uri - Will be the metadata hash of the minted token.
    */

    function whitelistUserMinting(address _to, uint _id, string memory _name, string memory _uri) public {
        require(!publicSale, "Can't mint when public sale is active");
        if (whitelistedMintedNFTs < whiteListedLimit) {
            if (whiteListedUsers[msg.sender]) {
                safeMint(_to, _id, _name, _uri);
                whitelistedMintedNFTs += 1;
            }
            else {
                revert notWhitelistedUser("Not a whitelisted user");
            }
        }
        else {
            revert whitelistedUserLimit("Whitelisted user minting limit is reached");
        }
    }

    /*
    * publicMinting mints the ERC721 Token for public users.
    * _to - Will be the address of the receiver of minted token.
    * _name - Will be the name of the NFT.
    * _uri - Will be the metadata hash of the minted token.
    */

    function publicMinting(address _to, uint _id, string memory _name, string memory _uri) public {
        if (publicMintedNFTs < publicLimit) {
            if (publicSale) {
                safeMint(_to, _id, _name, _uri);
                publicMintedNFTs += 1;
            }
            else {
                revert publicSaleStatus("Public sale is not active");
            }
        }
        else {
            revert publicMintLimit("Public minting limit is reached");
        }
    }

    /*
    * adminMinting mints the ERC721 Token for admins.
    * _to - Will be the address of the receiver of minted token.
    * _name - Will be the name of the NFT.
    * _uri - Will be the metadata hash of the minted token.
    */

    function adminMinting(address _to, uint _id, string memory _name, string memory _uri) public {
        if(adminMintedNFTs < adminLimit) {
            if(whiteListedAdmins[msg.sender]) {
                safeMint(_to, _id, _name, _uri);
                adminMintedNFTs += 1;
            }
            else {
                revert notWhitelistedAdmin("Not a whitelisted admin");
            }
        }
        else {
            revert adminMintLimit("admin minting limit is reached");
        }
    }

    /*
    * @dev _beforeTokenTransfer checks for pauseed status before token transfer.
    * @param from - Will be the address of the sender of minted token.
    * @param to - Will be the address of the rceiver.
    * @param tokenId - Will be the token id of NFT.
    */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.
    /**
    * @dev _burn burns the ERC721 Token for at given id.
    * @param tokenId - Will be the token id.
    */
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    /**
    * @dev tokenURI returns the token uri at the given id.
    * @param tokenId - Will be the token id.
    */
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return string(abi.encodePacked(baseURI, NFTs[tokenId].MetadataHash));
    }
}
