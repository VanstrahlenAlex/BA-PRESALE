// SPDX-License-Identifier: MIT

pragma solidity 0.8.35;

import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";


contract Presale is Ownable { 

	using SafeERC20 for IERC20;

	address public usdtAddress;
	address public usdcAddress;
	address public fundsReceiverAddress;
	uint256 public maxSellingAmount;
	uint256 public startingTime;
	uint256 public endingTime;
	uint256[][3] public phases;

	uint256 totalSold;
	uint256 public currentPhase;
	mapping(address => bool) public isBlackListed;
	mapping(address => uint256) public userTokenBalance;

	emit TokenBuy(address user, uint256 amount);

	constructor(address usdtAddress_, address usdcAddress_, address fundsReceiverAddress_, uint256 maxSellingAmount_, uint256 startingTime_, uint256 endingTime_, uint256[][3] memory phases_) Ownable(msg.sender) {
		usdtAddress = usdtAddress_;
		usdcAddress = usdcAddress_;
		fundsReceiverAddress = fundsReceiverAddress_;
		maxSellingAmount = maxSellingAmount_;
		startingTime = startingTime_;
		endingTime = endingTime_;
		phases = phases_;

		require(endingTime > startingTime, "Incorrect presale times");
	}

	//Cantidad maxima de tokens a vender
	//Precio por token en USDT 
	//Precio por token en USDC


	//Funciones de BlackList
	/**
	 *  Used to blacklist users
	 * @param user_ the Address of the blacklisted user
	 */
	function blackList(address user_) onlyOwner() external {
		isBlackListed[user_] = true;
	}

	function unBlackList(address user_) onlyOwner() external {
		isBlackListed[user_] = false;
	}

	function checkCurrentPhase(uint256 amount_) private returns(uint256 phase) {
		if((totalSold + amount_ >= phases[currentPhase][0]) || (block.timestamp >= phases[currentPhase][2]) && currentPhase < 3) {
			currentPhase++;
			phase = currentPhase;
		} else {
			phase = currentPhase;
		}
	}


	/**
	 *  Used to buy tokens with stable coins
	 * @param tokenUsedToBuy_ the Address of the token used to buy
	 * @param amount_ the amount of tokens to buy
	 */
	function buyWithStable(address tokenUsedToBuy_, uint256 amount_) external {
		require(!isBlackListed[msg.sender], "Usuario blackListeado");
		require(block.timestamp >= startingTime && block.timestamp <= endingTime, "Presale not started yet");
		require(tokenUsedToBuy_ == usdtAddress || tokenUsedToBuy_ == usdcAddress, "Incorrect token");


		uint256 tokenAmountToReceive; 
		if(IERC20(tokenUsedToBuy_).decimals() == 18) tokenAmountToReceive = amount_  * 1e6 / phases[currentPhase][1]; // 18 decimals + 6 decimals / 6 decimals
		else tokenAmountToReceive = amount_ * 10**(18 - IERC20(tokenUsedToBuy_).decimals()) * 1e6 / phases[currentPhase][1]; //18 decimals - 6 decimals = 14 decimales * 1e4
		
		checkCurrentPhase(tokenAmountToReceive);

		totalSold += tokenAmountToReceive;
		require(totalSold <= maxSellingAmount, "Sold out");

		// 1 Aumentar el blanace del usuario 
		userTokenBalance[msg.sender] += tokenAmountToReceive;
		
		// 2 Transferir los tokens de venta 
		IERC20(tokenUsedToBuy_).safeTransferFrom(msg.sender, fundsReceiverAddress, amount_);

		emit TokenBuy(msg.sender, amount_);


		

	}

	function emergencyERC20Withdraw(address tokenAddress_, uint256 amount_) onlyOwner() external {
		IERC20(tokenAddress_).safeTransfer(msg.sender, amount_);
	}

	function emergencyETHWithdraw() onlyOwner() external {
		uint256 balance = address(this).balance;
		(bool success, ) = msg.sender.call{value: balance}("");
		require(success, "Error al retirar ETH");	
	}
}

