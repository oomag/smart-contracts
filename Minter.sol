/* Simple token - simple token for PreICO and ICO
   Copyright (C) 2017  Sergey Sherkunov <leinlawun@leinlawun.org>

   This file is part of simple token.

   Token is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <https://www.gnu.org/licenses/>.  */

pragma solidity ^0.4.18;

import {SafeMath} from "./SafeMath.sol";

import {ABXToken} from "./ABXToken.sol";

contract Minter {
    using SafeMath for uint256;

    enum MinterState {
        tokenSaleWait,
        tokenSaleStarted,
        Over
    }

    struct Tokensale {
        uint256 startTime;
        uint256 endTime;
        uint256 tokensMinimumNumberForBuy;
        uint256 tokensCost;
    }

    address public owner;

    address public manager;

    bool public paused = false;

    mapping(address => bool) public whiteList;

    ABXToken public token;

    Tokensale public tokenSale;

    modifier onlyOwner {
        require(owner == msg.sender);

        _;
    }

    modifier onlyNotPaused {
        require(!paused);

        _;
    }

    modifier onlyDuringTokensale {
        require(minterState() == MinterState.tokenSaleStarted);

        _;
    }

    modifier onlyAfterTokensaleOver {
        require(minterState() == MinterState.Over);

        _;
    }

    modifier onlyWhiteList {
        require(whiteList[msg.sender]);

        _;
    }

    modifier checkLimitsToBuyTokens {
        require(tokenSale.tokensMinimumNumberForBuy <=
                tokensNumberForBuy().div(10 ** uint256(token.decimals())));

        _;
    }

    function Minter(address _manager, ABXToken _token,
                    uint256 tokenSaleStartTime, uint256 tokenSaleEndTime,
                    uint256 tokenSaleTokensMinimumNumberForBuy) public {
        owner = msg.sender;
        manager = _manager;
        token = _token;
        tokenSale.startTime = tokenSaleStartTime;
        tokenSale.endTime = tokenSaleEndTime;
        tokenSale.tokensMinimumNumberForBuy =
            tokenSaleTokensMinimumNumberForBuy;
    }

    function setOwner(address _owner) public onlyOwner {
        owner = _owner;
    }

    function setManager(address _manager) public onlyOwner {
        manager = _manager;
    }

    function setPaused(bool _paused) public onlyOwner {
        paused = _paused;
    }

    function addWhiteList(address tokensHolder) public onlyOwner {
        whiteList[tokensHolder] = true;
    }

    function removeWhiteList(address tokensHolder) public onlyOwner {
        whiteList[tokensHolder] = false;
    }

    function setTokenSaleStartTime(uint256 timestamp) public onlyOwner {
        tokenSale.startTime = timestamp;
    }

    function setTokenSaleEndTime(uint256 timestamp) public onlyOwner {
        tokenSale.endTime = timestamp;
    }

    function setTokenSaleTokensMinimumNumberForBuy(uint256 tokensNumber) public
                                               onlyOwner {
        tokenSale.tokensMinimumNumberForBuy = tokensNumber;
    }

    function setTokenSaleTokensCost(uint256 tokensCost) public onlyOwner {
        tokenSale.tokensCost = tokensCost;
    }

    function transferRestTokensToOwner() public onlyOwner
                                      onlyAfterTokensaleOver {
        token.transferFrom(token, msg.sender, token.allowance(token, this));
    }

    function () public payable onlyDuringTokensale onlyNotPaused onlyWhiteList
                checkLimitsToBuyTokens {
        uint256 tokensNumber = tokensNumberForBuy();

        uint256 aviableTokensNumber =
            token.balanceOf(token).min(token.allowance(token, this));

        uint256 restCoins = 0;

        if(tokensNumber >= aviableTokensNumber) {
            uint256 restTokensNumber = tokensNumber.sub(aviableTokensNumber);

            restCoins =
                restTokensNumber.mul(tokenSale.tokensCost)
                                .div(10 ** uint256(token.decimals()));

            tokensNumber = aviableTokensNumber;
        }

        token.transferFrom(token, msg.sender, tokensNumber);

        msg.sender.transfer(restCoins);

        manager.transfer(msg.value.sub(restCoins));
    }

    function minterState() private constant returns(MinterState) {
        if(tokenSale.startTime > now) {
            return MinterState.tokenSaleWait;
        } else if(tokenSale.endTime > now) {
            return MinterState.tokenSaleStarted;
        } else {
            return MinterState.Over;
        }
    }

    function tokensNumberForBuy() private constant returns(uint256) {
        return msg.value.mul(10 ** uint256(token.decimals()))
                        .div(tokenSale.tokensCost);
    }
}
