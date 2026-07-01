// SPDX-License-Identifier: MIT

pragma solidity 0.8.35;

import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../src/interfaces/I_Aggregator.sol";

contract Presale is Ownable { 

	using SafeERC20 for IERC20;

	address public saleTokenAddress;
	address public usdtAddress;
	address public usdcAddress;
	address public fundsReceiverAddress;
	address public dataFeedAddress;
	uint256 public maxSellingAmount;
	uint256 public startingTime;
	uint256 public endingTime;
	uint256[][3] public phases;

	uint256 totalSold;
	uint256 public currentPhase;
	mapping(address => bool) public isBlackListed;
	mapping(address => uint256) public userTokenBalance;

	event TokenBuy(address user, uint256 amount);

	constructor(address saleTokenAddress_, address usdtAddress_, address usdcAddress_, address fundsReceiverAddress_, address dataFeedAddress_, uint256 maxSellingAmount_, uint256 startingTime_, uint256 endingTime_, uint256[][3] memory phases_) Ownable(msg.sender) {
		saleTokenAddress = saleTokenAddress_;
		usdtAddress = usdtAddress_;
		usdcAddress = usdcAddress_;
		fundsReceiverAddress = fundsReceiverAddress_;
		dataFeedAddress = dataFeedAddress_;
		maxSellingAmount = maxSellingAmount_;
		startingTime = startingTime_;
		endingTime = endingTime_;
		phases = phases_;

		require(endingTime > startingTime, "Incorrect presale times");
		IERC20(saleTokenAddress_).safeTransferFrom(msg.sender, address(this), maxSellingAmount);
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
		// forge-lint: disable-next-line(block-timestamp)
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
		// forge-lint: disable-next-line(block-timestamp)
		require(block.timestamp >= startingTime && block.timestamp <= endingTime, "Presale not started yet");
		require(tokenUsedToBuy_ == usdtAddress || tokenUsedToBuy_ == usdcAddress, "Incorrect token");


		uint256 tokenAmountToReceive; 
		if(IERC20Metadata(tokenUsedToBuy_).decimals() == 18) tokenAmountToReceive = amount_  * 1e6 / phases[currentPhase][1]; // 18 decimals + 6 decimals / 6 decimals
		else tokenAmountToReceive = amount_ * 10**(18 - IERC20Metadata(tokenUsedToBuy_).decimals()) * 1e6 / phases[currentPhase][1]; //18 decimals - 6 decimals = 14 decimales * 1e4
		
		checkCurrentPhase(tokenAmountToReceive);

		totalSold += tokenAmountToReceive;
		require(totalSold <= maxSellingAmount, "Sold out");

		// 1 Aumentar el blanace del usuario 
		userTokenBalance[msg.sender] += tokenAmountToReceive;
		
		// 2 Transferir los tokens de venta 
		IERC20(tokenUsedToBuy_).safeTransferFrom(msg.sender, fundsReceiverAddress, amount_);

		emit TokenBuy(msg.sender, amount_);
	}

	function buyWithEther() external payable {
		require(!isBlackListed[msg.sender], "Usuario blackListeado");
		// forge-lint: disable-next-line(block-timestamp)
		require(block.timestamp >= startingTime && block.timestamp <= endingTime, "Presale not started yet");

		uint256 usdValue = msg.value * getEtherPrice() / 1e18;
		uint256 tokenAmountToReceive = usdValue * 1e6 / phases[currentPhase][1];
		checkCurrentPhase(tokenAmountToReceive);
		
		
		checkCurrentPhase(tokenAmountToReceive);

		totalSold += tokenAmountToReceive;
		require(totalSold <= maxSellingAmount, "Sold out");

		// 1 Aumentar el blanace del usuario 
		userTokenBalance[msg.sender] += tokenAmountToReceive;
		
		(bool success, ) = fundsReceiverAddress.call{value: msg.value}("");
		require(success, "Error al enviar ETH");

		emit TokenBuy(msg.sender, tokenAmountToReceive);
	}

	function claim() external {
		// forge-lint: disable-next-line(block-timestamp)
		require(block.timestamp > endingTime, "Presale not ended");

		uint256 amount = userTokenBalance[msg.sender];
		delete userTokenBalance[msg.sender];
		IERC20(saleTokenAddress).safeTransfer(msg.sender, amount);

	}


	function getEtherPrice() public view returns (uint256){
		(, int256 price,,,) = IAggregator(dataFeedAddress).latestRoundData();
		require(price > 0, "Invalid price");
		price = price * (10 **10);
		
		// casting to 'uint256' is safe because price > 0 is enforced above
		// forge-lint: disable-next-line(unsafe-typecast)
		return uint256(price);
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

