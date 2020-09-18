pragma solidity ^0.4.24;
pragma experimental ABIEncoderV2;

// solium-disable

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

interface ERC721 {
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    function name() external view returns (string _name);
    function symbol() external view returns (string _symbol);
    function balanceOf(address _owner) external view returns (uint256 _balance);
    function ownerOf(uint256 _tokenId) external view returns (address _owner);
    // function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) external;
    // function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    function approve(address _to, uint256 _tokenId) external;
    function setApprovalForAll(address _to, bool _approved) external;
    function getApprovedAddress(uint256 _tokenId) external view returns (address);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
    function totalSupply() external view returns (uint256);
    function tokenByIndex(uint256 _index) external view returns (uint256);
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}

contract AllowanceAndOwnershipContract is ERC721 {
    using SafeMath for uint256;

    mapping (uint256 => address) internal tokenOwner; // (tokenId => ownerAddress)
    mapping (uint256 => address) internal tokenApprovals; // (tokenId => approvedAddress)
    mapping (address => mapping (address => bool)) internal operatorApprovals; // (ownerAddress => (approvedAddress => bool))

    function ownerOf(uint256 _tokenId) public view returns (address) {
        address owner = tokenOwner[_tokenId];
        require(owner != address(0));
        return owner;
    }

    modifier onlyOwnerOf(uint256 _tokenId) {
        require(ownerOf(_tokenId) == msg.sender);
        _;
    }

    function getApprovedAddress(uint256 _tokenId) public view returns(address) {
        return  tokenApprovals[_tokenId];
    }

    function isSpecificallyApprovedFor(address _asker, uint256 _tokenId) internal view returns (bool) {
        return getApprovedAddress(_tokenId) == _asker;
    }

    function isApprovedForAll(address _owner, address _operator) public view returns (bool)
    {
        return operatorApprovals[_owner][_operator];
    }

    function isSenderApprovedFor(uint256 _tokenId) internal view returns(bool) {
        return
            ownerOf(_tokenId) == msg.sender ||
            isSpecificallyApprovedFor(msg.sender, _tokenId) ||
            isApprovedForAll(ownerOf(_tokenId), msg.sender);
    }

    function approve(address _to, uint256 _tokenId) external onlyOwnerOf(_tokenId)
    {
        address owner = ownerOf(_tokenId);
        require(_to != owner);
        if (getApprovedAddress(_tokenId) != 0 || _to != 0) {
            tokenApprovals[_tokenId] = _to;
            emit Approval(owner, _to, _tokenId);
        }
    }

    function setApprovalForAll(address _to, bool _approved)
        external
    {
        if(_approved) {
            approveAll(_to);
        } else {
            disapproveAll(_to);
        }
    }

    function approveAll(address _to)
        public
    {
        require(_to != msg.sender);
        require(_to != address(0));
        operatorApprovals[msg.sender][_to] = true;
        emit ApprovalForAll(msg.sender, _to, true);
    }

    function disapproveAll(address _to)
    public
    {
        require(_to != msg.sender);
        delete operatorApprovals[msg.sender][_to];
        emit ApprovalForAll(msg.sender, _to, false);
    }
}

contract ERC721BasicTokenContract is AllowanceAndOwnershipContract {
    using SafeMath for uint256;

    mapping (address => uint256[]) internal ownedTokens; // (ownerAddress => [tokenId, .....])
    mapping(uint256 => uint256) internal ownedTokensIndex;
    uint256[] internal allTokens;

    string internal name_;
    string internal symbol_;
    address internal tokenSaleAddress;

    constructor(string _name, string _symbol) public {
        name_ = _name;
        symbol_ = _symbol;
    }

    function name() external view returns (string) {
        return name_;
    }

    function symbol() external view returns (string) {
        return symbol_;
    }

    function totalSupply() public view returns (uint256) {
        return allTokens.length;
    }

    function tokenByIndex(uint256 _index) external view returns (uint256) {
        require(_index < totalSupply());
        return _index;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        require(_owner != address(0));
        return ownedTokens[_owner].length;
    }

    function tokensOf(address _owner) public view returns (uint256[]) {
        require( _owner != address(0));
        return ownedTokens[_owner];
    }

    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256) {
        require(_index < balanceOf(_owner));
        return ownedTokens[_owner][_index];
    }

    function transfer(address _to, uint256 _tokenId)
        external

        onlyOwnerOf(_tokenId)
    {
        _clearApprovalAndTransfer(msg.sender, _to, _tokenId);
    }

    function takeOwnership(uint256 _tokenId)
    external
    {
        require(isSenderApprovedFor(_tokenId));
        _clearApprovalAndTransfer(ownerOf(_tokenId), msg.sender, _tokenId);
    }

    function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
     )
    public
    {
        require(isSenderApprovedFor(_tokenId));
        require(ownerOf(_tokenId) == _from);
        _clearApprovalAndTransfer(ownerOf(_tokenId), _to, _tokenId);
    }

    function getTokenSaleAddress () public view returns (address) {
        return tokenSaleAddress;
    }

    function _mint(address _to, uint256 _tokenId) internal {
        require(_to != address(0));

        _addToken(_to, _tokenId);
        emit Transfer(0x0, _to, _tokenId);
    }

    function _clearApprovalAndTransfer(address _from, address _to, uint256 _tokenId) internal {
        require(_to != address(0));
        require(_to != ownerOf(_tokenId));
        require(ownerOf(_tokenId) == _from);

        _clearApproval(_from, _tokenId);
        _removeToken(_from, _tokenId);
        _addToken(_to, _tokenId);
        emit Transfer(_from, _to, _tokenId);
    }

    function _clearApproval(address _owner, uint256 _tokenId) internal {
        require(ownerOf(_tokenId) ==_owner);
        tokenApprovals[_tokenId] = 0;
        emit Approval(_owner, 0, _tokenId);
    }

    function _addToken(address _to, uint256 _tokenId) internal {
        require(tokenOwner[_tokenId] == address(0));
        tokenOwner[_tokenId] = _to;
        uint256 length = balanceOf(_to);
        ownedTokens[_to].push(_tokenId);
        ownedTokensIndex[_tokenId] = length;
        allTokens.push(_tokenId);
    }

    function _removeToken(address _from, uint256 _tokenId) internal {
        uint256 tokenIndex = ownedTokensIndex[_tokenId];
        uint256 lastTokenIndex = balanceOf(_from).sub(1);
        uint256 lastToken = ownedTokens[_from][lastTokenIndex];

        tokenOwner[_tokenId] = 0;
        ownedTokens[_from][tokenIndex] = lastToken;
        ownedTokens[_from][lastTokenIndex] = 0;

        ownedTokens[_from].length--;
        ownedTokensIndex[_tokenId] = 0;
        ownedTokensIndex[lastToken] = tokenIndex;
        allTokens.push(_tokenId);
    }
}

contract Ownable {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract AnchoringContract is Ownable, ERC721BasicTokenContract {
    using SafeMath for uint256;

    struct Version {
        string hash;
        string description;
    }

    struct DocumentReference {
        uint256 documentId;
        uint256 versionId;
        uint256 createdAt;
    }

    uint256 docRefCounter = 0; // This will be used as unique auto incremented documentId
    mapping(uint256 => Version[]) versionOf; // mapping(documentId => Version[])
    mapping(bytes32 => DocumentReference) documentReference; // mapping(referenceId => DocumentReference)

    event DocumentSaved (
        bytes32 indexed referenceId,
        uint256 indexed documentId,
        uint256 indexed versionId,
        string hash
    );

    constructor(string _name, string _symbol) ERC721BasicTokenContract(_name, _symbol) public {

    }
    /*
        To save documnet in both create and update
    */
    function _save(uint256 documentId, string hash, string description) internal returns(bytes32) {
        require(!_emptyString(hash));
        require(!_hashExists(hash)); // throw error if hash already exists

        Version memory version = Version(hash, description);
        Version[] storage versions = versionOf[documentId];
        uint256 versionsLength = versions.push(version);
        uint256 versionId = versionsLength - 1;
        versionOf[documentId] = versions;

        //Convert hash of document into solidty-compatible bytes32 hash. This will be used as a transactionId (referenceId) for the document.
        bytes32 referenceId = keccak256(abi.encodePacked(hash));
        DocumentReference memory reference = DocumentReference(documentId, versionId, now);
        documentReference[referenceId] = reference;
        emit DocumentSaved(referenceId, documentId, versionId, hash);

        return referenceId;
    }

    /*
        Double check hash does not already exists.
    */
    function _hashExists(string hash) internal returns(bool) {
        bytes32 referenceId = keccak256(abi.encodePacked(hash));
        DocumentReference storage targetDocumentReference = documentReference[referenceId];
        return targetDocumentReference.createdAt != 0;
    }

    /*
        Check given referenceId in query methods exists.
        Just to check document track exists or not.
    */
    function _isReferenceExists(bytes32 referenceId) internal returns (bool) {
        DocumentReference storage targetDocumentReference = documentReference[referenceId];
        return targetDocumentReference.createdAt != 0;
    }

    function _emptyString(string input) internal returns(bool) {
        bytes memory tempEmptyStringTest = bytes(input); // Uses memory
        return tempEmptyStringTest.length == 0;
    }

    /*
        Get version details(hash, description) by referenceId of that version.
    */
    function _getByReferenceId(bytes32 referenceId) internal view returns(Version) {
        require(_isReferenceExists(referenceId));

        DocumentReference storage targetDocumentReference = documentReference[referenceId];
        Version[] storage versions = versionOf[targetDocumentReference.documentId];
        Version storage targetVersion = versions[targetDocumentReference.versionId];

        return targetVersion;
    }

    /*
        Create a track of new document and return referenceId which can be used to check track of that document.
    */
    function createDocument(string hash, string description) external onlyOwner returns(bytes32) {
        bytes32 referenceId = _save(docRefCounter, hash, description);
        _mint(msg.sender, docRefCounter);
        docRefCounter = docRefCounter + 1;

        return referenceId;
    }

    /*
        Accept referenceId of any previous track of a document and save the new version of that document using given data.
    */
    function updateDocument(bytes32 referenceId, string hash, string description) external onlyOwner returns(bytes32) {
        uint256 documentId = documentReference[referenceId].documentId;
        return _save(documentId, hash, description);
    }

    /*
        Accept a hash of any version of a document and return a list of hashes containing all versions hashes of that document.
    */
    function getAllByHash(string hash) external view returns(string[]) {
        require(_hashExists(hash));

        //Convert hash of document into solidty-compatible bytes32 hash. This will be used as a transactionId (referenceId) for the document.
        bytes32 referenceId =  keccak256(abi.encodePacked(hash));

        return getAllByReferenceId(referenceId);
    }

    /*
        Accept a referenceId of any version of a document and return hash of that version.
        * referenceId get in response of create/update document.
    */
    function getHashByReferenceId(bytes32 referenceId) external view returns(string) {
        return _getByReferenceId(referenceId).hash;
    }

    /*
        Accept a referenceId of any version of a document and return hash and description of that version.
        * referenceId get in response of create/update document.
    */
    function getByReferenceId(bytes32 referenceId) external view returns(string, string) {
        require(_isReferenceExists(referenceId));

        Version memory targetVersion = _getByReferenceId(referenceId);

        return (targetVersion.hash, targetVersion.description);
    }

    /*
        Double check hash does not already exists for error handling.
    */

    function hashExists(string hash) external view returns(bool) {
        return _hashExists(hash);
    }

    /*
        Check given referenceId in query methods exists.
        Just to check document track exists or not.
    */
    function isReferenceExists(bytes32 referenceId) external returns (bool) {
        return _isReferenceExists(referenceId);
    }

    /*
        Accept a referenceId of any version of a document and return a list of hashes containing all versions hashes of that document.
        * referenceId get in response of create/update document.
    */
    function getAllByReferenceId(bytes32 referenceId) public view returns(string[]) {
        require(_isReferenceExists(referenceId));

        DocumentReference storage targetDocumentReference = documentReference[referenceId];
        Version[] storage versions = versionOf[targetDocumentReference.documentId];
        string[] memory hashList = new string[](versions.length);
        for(uint256 i = 0; i < versions.length; i++) {
            hashList[i] = versions[i].hash;
        }

        return hashList;
    }

}