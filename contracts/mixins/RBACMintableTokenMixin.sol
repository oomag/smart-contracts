pragma solidity ^0.4.24;
import "./RBACMixin.sol";
import "zeppelin-solidity/contracts/token/ERC20/MintableToken.sol";


contract RBACMintableTokenMixin is MintableToken, RBACMixin {
  // @dev override the Mintable token modifier to add role based logic
  modifier hasMintPermission() {
    require(isMinter(msg.sender));
    _;
  }
}