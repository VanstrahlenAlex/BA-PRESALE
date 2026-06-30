// SPDX-License-Identifier: MIT

pragma solidity 0.8.35;

import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";


contract Presale is Ownable { 

	using SafeERC20 for IERC20;

	address public usdtAddres;
	address public usdcAddress;
	address public fundsReceiverAddress;
	uint256 public maxSellingAmount;
	uint256[][3] public phases;

	mapping(address => bool) public isBlackListed;

	constructor(address usdtAddress_, address usdcAddress_, address fundsReceiverAddress_, uint256 maxSellingAmount_, uint256[][3] memory phases_) Ownable(msg.sender) {
		usdtAddres = usdtAddress_;
		usdcAddress = usdcAddress_;
		fundsReceiverAddress = fundsReceiverAddress_;
		maxSellingAmount = maxSellingAmount_;
		phases = phases_;
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

	function buyWithStable() external {
		require(!isBlackListed[msg.sender], "Usuario blackListeado");
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

