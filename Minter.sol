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

import {SimpleToken} from "./SimpleToken.sol";

contract Minter {
    using SafeMath for uint256;

    enum MinterState {
        PreICOWait,
        PreICOStarted,
        Over
    }

    struct Tokensale {
        uint256 startTime;
        uint256 endTime;
        uint256 tokensMinimumNumberForBuy;
        uint256 tokensCost;
/*
        uint256 tokensScale;
        uint256 tokensDecimalsCost;
        uint256 tokensDecimalsScale;
*/
    }

    address public owner;

    address public manager;

    bool public paused = false;

    mapping(address => bool) public whiteList;

    SimpleToken public token;

    Tokensale public PreICO;

    modifier onlyOwner {
        require(owner == msg.sender);

        _;
    }

    modifier onlyNotPaused {
        require(!paused);

        _;
    }

    modifier onlyDuringTokensale {
        require(minterState() == MinterState.PreICOStarted);

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
        require(PreICO.tokensMinimumNumberForBuy <= tokensNumberForBuy());

        _;
    }

    function Minter(SimpleToken _token) public {
        owner = msg.sender;
        token = _token;
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

    function setPreICOStartTime(uint256 timestamp) public onlyOwner {
        PreICO.startTime = timestamp;
    }

    function setPreICOEndTime(uint256 timestamp) public onlyOwner {
        PreICO.endTime = timestamp;
    }

    function setPreICOTokensMinimumNumberForBuy(uint256 tokensNumber) public
                                               onlyOwner {
        PreICO.tokensMinimumNumberForBuy = tokensNumber;
    }

    function setPreICOTokensCost(uint256 tokensCost) public onlyOwner {
/*
        uint256 tokensGranularity;

        for(uint8 decimals = token.decimals(); decimals > 0; decimals--) {
            tokensGranularity = 10 ** uint256(decimals);

            if(tokensCost > tokensGranularity) {
                break;
            }
        }

        uint256 tokensScale = 10 ** uint256(token.decimals());
*/

        PreICO.tokensCost = tokensCost;
/*
        PreICO.tokensScale = tokensScale;
        PreICO.tokensDecimalsCost = tokensCost.div(tokensGranularity);
        PreICO.tokensDecimalsScale = tokensScale.div(tokensGranularity);
*/
    }

    function transferRestTokensToOwner() public onlyOwner
                                      onlyAfterTokensaleOver {
        token.transferFrom(token, msg.sender, token.allowance(token, this));
    }

    function () public payable onlyDuringTokensale onlyNotPaused onlyWhiteList
                checkLimitsToBuyTokens {
        uint256 tokensNumber;

/*
        if(msg.value >= PreICO.tokensCost) {
            tokensNumber =
                msg.value.mul(PreICO.tokensScale).div(PreICO.tokensCost);
        } else {
            tokensNumber =
                msg.value.mul(PreICO.tokensDecimalsScale)
                         .div(PreICO.tokensDecimalsCost);
        }
*/

        tokensNumber = tokensNumberForBuy();

        uint256 aviableTokensNumber =
            token.balanceOf(token).min(token.allowance(token, this));

        uint256 restCoins = 0;

        if(tokensNumber >= aviableTokensNumber) {
            uint256 restTokensNumber = tokensNumber.sub(aviableTokensNumber);

            restCoins =
                restTokensNumber.mul(PreICO.tokensCost)
                                .div(10 ** token.decimals());

            tokensNumber = aviableTokensNumber;
        }

        token.transferFrom(token, msg.sender, tokensNumber);

        msg.sender.transfer(restCoins);

        manager.transfer(msg.value.sub(restCoins));
    }

    function minterState() private constant returns(MinterState) {
        if(PreICO.startTime > now) {
            return MinterState.PreICOWait;
        } else if(PreICO.endTime > now) {
            return MinterState.PreICOStarted;
        } else {
            return MinterState.Over;
        }
    }

    function tokensNumberForBuy() private constant returns(uint256) {
        return msg.value.mul(10 ** token.decimals()).div(PreICO.tokensCost);
    }
}