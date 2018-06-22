pragma solidity ^0.4.24;
// pragma experimental ABIEncoderV2;


contract RBACMixin {
  string constant FORBIDDEN = "Haven't enough right to access";
  
  uint8 constant public STRANGER_ROLE = 0;
  uint8 constant public ALL_ROLES     = 0xFF;
  uint8 constant public ADMIN_ROLE    = 1 << 0;
  uint8 constant public MINTER_ROLE   = 1 << 1;

  mapping (address => bool) public owners;
  mapping (address => bool) public minters;

  event AddOwner(address indexed _who);
  event RemoveOwner(address indexed _who);

  event AddMinter(address indexed _who);
  event RemoveMinter(address indexed _who);

  constructor () public {
    _setOwner(msg.sender, true);
  }

  modifier senderIsOwner() {
    require(isOwner(msg.sender), FORBIDDEN);
    _;
  }

  modifier senderIsMinter() {
    require(isMinter(msg.sender), FORBIDDEN);
    _;
  }

  function isOwner(address _who) public view returns (bool) {
    return owners[_who];
  }

  function isMinter(address _who) public view returns (bool) {
    return minters[_who] || owners[_who];
  }

  function addOwner(address _who) public senderIsOwner returns (bool) {
    _setOwner(_who, true);
  }

  function removeOwner(address _who) public senderIsOwner returns (bool) {
    _setOwner(_who, false);
  }

  function addMinter(address _who) public senderIsOwner returns (bool) {
    _setMinter(_who, true);
  }

  function removeMinter(address _who) public senderIsOwner returns (bool) {
    _setMinter(_who, false);
  }

  function _setOwner(address _who, bool _flag) private returns (bool) {
    require(owners[_who] != _flag);
    owners[_who] = _flag;
    if (_flag) {
      emit AddOwner(_who);
    } else {
      emit RemoveOwner(_who);
    }
    return true;
  }

  function _setMinter(address _who, bool _flag) private returns (bool) {
    require(minters[_who] != _flag);
    minters[_who] = _flag;
    if (_flag) {
      emit AddMinter(_who);
    } else {
      emit RemoveMinter(_who);
    }
    return true;
  }
}