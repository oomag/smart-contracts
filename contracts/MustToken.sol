pragma solidity ^0.4.24;
import "./mixins/RBACMixin.sol";
import "./mixins/RBACMintableTokenMixin.sol";
import "./mixins/RBACERC223TokenFinalization.sol";
import "zeppelin-solidity/contracts/token/ERC20/StandardBurnableToken.sol";


contract MustToken is StandardBurnableToken, RBACERC223TokenFinalization, RBACMintableTokenMixin {
  // solium-disable-next-line uppercase
  string constant public name = "Main Universal Standard of Tokenization"; 
  string constant public symbol = "MUST"; // solium-disable-line uppercase
  uint256 constant public decimals = 8; // solium-disable-line uppercase
  uint256 constant public cap = 5 * (10 ** 6) * (10 ** decimals); // solium-disable-line uppercase

  function mint(
    address _to,
    uint256 _amount
  )
    public
    returns (bool) 
  {
    require(totalSupply().add(_amount) <= cap);
    return super.mint(_to, _amount);
  }

  function saneIt() public returns (bool) {
    require(super.saneIt());
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}