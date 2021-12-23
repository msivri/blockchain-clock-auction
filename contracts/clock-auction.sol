// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./lib/nf-token.sol";
import "./clock-auction-base.sol";

/// @title Clock auction for non-fungible tokens.
/// @notice We omit a fallback function to prevent accidental sends to this contract.
contract ClockAuction is ClockAuctionBase {
  /**
   * @dev List of revert message codes. Implementing dApp should handle showing the correct message.
   */
  string internal constant INVALID_CUT_AMOUNT = "005001";
  string internal constant NOT_VALID_NFT = "005002";
  string internal constant NOT_OWNER_APPROVED_OR_OPERATOR = "005004";
  string internal constant OWERFLOW_CHECK_FAIL = "009008";
  string internal constant NOT_NFT_OWNER = "009002";
  string internal constant SELLER_MUST_BE_SENDER = "005010";

  /// @dev The ERC-165 interface signature for ERC-721.
  ///  Ref: https://github.com/ethereum/EIPs/issues/165
  ///  Ref: https://github.com/ethereum/EIPs/issues/721
  bytes4 internal constant INTERFACE_SIGNATURE_ERC721 = bytes4(0x80ac58cd);

  /// @dev Constructor creates a reference to the NFT ownership contract
  ///  and verifies the owner cut is in the valid range.
  /// @param _nftAddress - address of a deployed contract implementing
  ///  the Nonfungible Interface.
  /// @param _transactionCut - percent cut the owner takes on each auction, must be
  ///  between 0-10,000.
  constructor(address _nftAddress, uint256 _transactionCut) {
    require(_transactionCut <= 10000, INVALID_CUT_AMOUNT);
    ownerCut = _transactionCut;

    NFToken candidateContract = NFToken(_nftAddress);
    require(
      candidateContract.supportsInterface(INTERFACE_SIGNATURE_ERC721),
      NOT_VALID_NFT
    );
    nonFungibleContract = candidateContract;
  }

  /// @dev Remove all Ether from the contract, which is the owner's cuts
  ///  as well as any Ether sent directly to the contract address.
  ///  Always transfers to the NFT contract, but can be called either by
  ///  the owner or the NFT contract.
  function withdrawBalance() external {
    address nftAddress = address(nonFungibleContract);

    require(
      msg.sender == owner || msg.sender == nftAddress,
      NOT_OWNER_APPROVED_OR_OPERATOR
    );

    console.log("Balance to withdraw: %s", address(this).balance);

    // We are using this boolean method to make sure that even if one fails it will still work
    address payable nftPayableAddress = payable(address(nonFungibleContract));
    nftPayableAddress.transfer(address(this).balance);

    console.log("Balance after withdraw: %s", address(this).balance);
  }

  /// @dev Creates and begins a new auction.
  /// @param _tokenId - ID of token to auction, sender must be owner.
  /// @param _startingPrice - Price of item (in wei) at beginning of auction.
  /// @param _endingPrice - Price of item (in wei) at end of auction.
  /// @param _duration - Length of time to move between starting
  ///  price and ending price (in seconds).
  /// @param _seller - Seller, if not the message sender
  function createAuction(
    uint256 _tokenId,
    uint256 _startingPrice,
    uint256 _endingPrice,
    uint256 _duration,
    address _seller
  ) external whenNotPaused {
    // Sanity check that no inputs overflow how many bits we've allocated
    // to store them in the auction struct.
    require(
      _startingPrice == uint256(uint128(_startingPrice)),
      OWERFLOW_CHECK_FAIL
    );
    require(
      _endingPrice == uint256(uint128(_endingPrice)),
      OWERFLOW_CHECK_FAIL
    );
    require(_duration == uint256(uint64(_duration)), OWERFLOW_CHECK_FAIL);

    require(_owns(msg.sender, _tokenId), NOT_NFT_OWNER);
    _escrow(msg.sender, _tokenId);

    Auction memory auction = Auction(
      _seller,
      uint128(_startingPrice),
      uint128(_endingPrice),
      uint64(_duration),
      uint64(block.timestamp)
    );

    _addAuction(_tokenId, auction);
  }

  /// @dev Bids on an open auction, completing the auction and transferring
  ///  ownership of the NFT if enough Ether is supplied.
  /// @param _tokenId - ID of token to bid on.
  function bid(uint256 _tokenId) external payable whenNotPaused {
    // _bid will throw if the bid or funds transfer fails
    _bid(_tokenId, msg.value);
    _transfer(msg.sender, _tokenId);
  }

  /// @dev Cancels an auction that hasn't been won yet.
  ///  Returns the NFT to original owner.
  /// @notice This is a state-modifying function that can
  ///  be called while the contract is paused.
  /// @param _tokenId - ID of token on auction
  function cancelAuction(uint256 _tokenId) external {
    Auction storage auction = tokenIdToAuction[_tokenId];
    require(_isOnAuction(auction), NOT_ON_AUCTION);
    address seller = auction.seller;
    require(msg.sender == seller, SELLER_MUST_BE_SENDER);
    _cancelAuction(_tokenId, seller);
  }

  /// @dev Cancels an auction when the contract is paused.
  ///  Only the owner may do this, and NFTs are returned to
  ///  the seller. This should only be used in emergencies.
  /// @param _tokenId - ID of the NFT on auction to cancel.
  function cancelAuctionWhenPaused(uint256 _tokenId)
    external
    whenPaused
    onlyOwner
  {
    Auction storage auction = tokenIdToAuction[_tokenId];
    require(_isOnAuction(auction), NOT_ON_AUCTION);
    _cancelAuction(_tokenId, auction.seller);
  }

  /// @dev Returns auction info for an NFT on auction.
  /// @param _tokenId - ID of NFT on auction.
  function getAuction(uint256 _tokenId)
    external
    view
    returns (
      address seller,
      uint256 startingPrice,
      uint256 endingPrice,
      uint256 duration,
      uint256 startedAt
    )
  {
    Auction storage auction = tokenIdToAuction[_tokenId];
    require(_isOnAuction(auction), NOT_ON_AUCTION);
    return (
      auction.seller,
      auction.startingPrice,
      auction.endingPrice,
      auction.duration,
      auction.startedAt
    );
  }

  /// @dev Returns the current price of an auction.
  /// @param _tokenId - ID of the token price we are checking.
  function getCurrentPrice(uint256 _tokenId) external view returns (uint256) {
    Auction storage auction = tokenIdToAuction[_tokenId];
    require(_isOnAuction(auction), NOT_ON_AUCTION);
    return _currentPrice(auction);
  }
}
