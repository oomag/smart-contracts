pragma solidity ^0.4.24;
import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "./mixins/RBACMixin.sol";

interface IMintableToken {
  function mint(address _to, uint256 _amount) external returns (bool);
}


contract TokenBucket is RBACMixin {
  using SafeMath for uint;
  uint256 public size;
  uint256 public rate;
  uint256 public lastMintTime;
  uint256 public leftOnLastMint;

  IMintableToken public token;

  event Leak(address indexed beneficiar, uint256 left);

  constructor (address _token, uint256 _size, uint256 _rate) public {
    token = IMintableToken(_token);
    size = _size;
    rate = _rate;
  }

  function setSize(uint256 _size) public senderIsOwner returns (bool) {
    size = _size;
  }

  function setRate(uint256 _rate) public senderIsOwner returns (bool) {
    rate = _rate;
  }

  function setSizeAndRate(uint256 _size, uint256 _rate) public senderIsOwner returns (bool) {
    return setSize(_size) && setRate(_rate);
  }

  function mint(address _beneficiar, uint256 _amount) public senderIsMinter returns (bool) {
    uint256 available = availableRate();
    require(_amount <= available);
    leftOnLastMint = available.sub(_amount);
    lastMintTime = now; // solium-disable-line security/no-block-members
    require(token.mint(_beneficiar, _amount));
    return true;
  }

  function availableRate() public view returns (uint) {
     // solium-disable-next-line security/no-block-members
    uint256 timeAfterMint = now.sub(lastMintTime);
    uint256 availableRate = rate.mul(timeAfterMint).add(leftOnLastMint);
    return size < availableRate ? size : availableRate;
  }
}