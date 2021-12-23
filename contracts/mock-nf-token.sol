// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./lib/nf-token.sol";
import "./lib/ownable.sol";
import "./clock-auction-base.sol";

/**
 * @dev Implementation of ERC-721 non-fungible token standard.
 */
contract MockNFToken is NFToken, Ownable {
  address private auctionAddress;

  receive() external payable {
    console.log("NFT Balance after withdraw: %s", address(this).balance);
  }

  /**
   * @dev Set auction contract address
   * @param _address address of the auction contract.
   */
  function setAuctionaddress(address _address) external onlyOwner {
    auctionAddress = _address;
  }

  /**
   * @dev Mints a new NFT.
   * @param _tokenId of the NFT to be minted by the msg.sender.
   */
  function mint(uint256 _tokenId) external {
    _mint(msg.sender, _tokenId);
  }

  /**
   * @dev Guarantees that the msg.sender is allowed to transfer NFT.
   * @param _tokenId ID of the NFT to transfer.
   */
  modifier canTransferAuction(uint256 _tokenId) {
    address tokenOwner = idToOwner[_tokenId];
    require(
      auctionAddress == msg.sender ||
        tokenOwner == msg.sender ||
        idToApproval[_tokenId] == msg.sender ||
        ownerToOperators[tokenOwner][msg.sender],
      NOT_OWNER_APPROVED_OR_OPERATOR
    );
    _;
  }

  /**
   * @notice Override transfer from to check if the auction contract is initiating the transfer.
   * @dev Throws unless `msg.sender` is the current owner, an authorized operator, or the approved
   * address for this NFT or the auction contract. Throws if `_from` is not the current owner. Throws if `_to` is the zero
   * address. Throws if `_tokenId` is not a valid NFT. This function can be changed to payable.
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  ) external override canTransferAuction(_tokenId) validNFToken(_tokenId) {
    address tokenOwner = idToOwner[_tokenId];
    require(tokenOwner == _from, NOT_OWNER);
    require(_to != address(0), ZERO_ADDRESS);

    _transfer(_to, _tokenId);
  }
}
