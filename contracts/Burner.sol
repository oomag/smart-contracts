pragma solidity ^0.4.24;

import "./mixins/ERC223ReceiverMixin.sol";


interface ERC223TokenBurner {
  function burn(uint256 _amount) external returns (bool);
}


contract Burner is ERC223ReceiverMixin {

  event Burn(address burner, uint256 amount, uint8 discount);

  uint64 public constant DATE_01_JUNE_2018 = 1527811200;
  uint64 public constant DATE_31_DEC_2018 = 1546214400;
  uint64 public constant DATE_31_DEC_2019 = 1577750400;
  uint64 public constant DATE_31_DEC_2020 = 1609372800;
  uint64 public constant DATE_31_DEC_2021 = 1640908800;
  uint64 public constant DATE_31_DEC_2022 = 1672444800;

  uint64[] public dates = [
    DATE_31_DEC_2018, 
    DATE_31_DEC_2019, 
    DATE_31_DEC_2020, 
    DATE_31_DEC_2021, 
    DATE_31_DEC_2022
  ];

  uint8[] public discounts = [
    50, 
    75, 
    80, 
    90, 
    95
  ];

  function tokenFallback(address _from, uint256 _value, bytes _data) public {
    // solium-disable-next-line security/no-block-members
    require(now >= DATE_01_JUNE_2018); 
    uint8 i = 0;
    // solium-disable-next-line security/no-block-members
    while (i < dates.length && dates[i] < now) {
      i++;
    }
    assert(i < dates.length);
    require(ERC223TokenBurner(msg.sender).burn(_value));
    emit Burn(_from, _value, discounts[i]);
  }
}
