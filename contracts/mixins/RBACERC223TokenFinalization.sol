pragma solidity ^0.4.24;
import "./RBACMixin.sol";
import "./ERC223Mixin.sol";


contract RBACERC223TokenFinalization is ERC223Mixin, RBACMixin {
  bool public sane;

  modifier isSane() {
    require(sane);
    _;
  }

  modifier notSane() {
    require(!sane);
    _;
  }

  function saneIt() public notSane senderIsOwner returns (bool) {
    sane = true;
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) public isSane returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  // solium-disable-next-line arg-overflow
  function transferFrom(address _from, address _to, uint256 _value, bytes _data) public isSane returns (bool) {
    return super.transferFrom(_from, _to, _value, _data); // solium-disable-line arg-overflow
  }

  function transfer(address _to, uint256 _value, bytes _data) public isSane returns (bool) {
    return super.transfer(_to, _value, _data);
  }

  function transfer(address _to, uint256 _value) public isSane returns (bool) {
    return super.transfer(_to, _value);
  }

  function approve(address _spender, uint256 _value) public isSane returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint256 _addedValue) public isSane returns (bool) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint256 _subtractedValue) public isSane returns (bool) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}