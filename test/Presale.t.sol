// SPDX-License-Identifier: MIT

pragma solidity 0.8.35;

import "forge-std/Test.sol";
import "../src/Presale.sol";

contract PresaleTest is Test {
	Presale presale;
	address saleTokenAddress_ = vm.addr(1);
	address usdtAddress_ = vm.addr(2);
	address usdcAddress_ = vm.addr(3);
	address fundsReceiverAddress_ = vm.addr(4);
	address dataFeedAddress_ = vm.addr(5);
	uint256 maxSellingAmount_ = 1000000;
	uint256 startingTime_;
	uint256 endingTime_;
	uint256[][3] phases_;

	function setUp() public {
		saleTokenAddress_ = address(0x1);
		usdtAddress_ = address(0x2);
		usdcAddress_ = address(0x3);
		fundsReceiverAddress_ = address(0x4);
		dataFeedAddress_ = address(0x5);
		maxSellingAmount_ = 1000000;
		startingTime_ = 1678886400;
		endingTime_ = 1700000000;
		phases_ = [[
			[500000, 10000000000, 1700000000],
			[1000000, 11000000000, 1700000000],
			[2000000, 12000000000, 1700000000],
			[3000000, 13000000000, 1700000000]
		]];
		phases_[0] = [10000000 * 1e18, 50000, block.timestamp + 1000];
		phases_[1] = [10000000 * 1e18, 5000, block.timestamp + 1000];
		phases_[2] = [10000000 * 1e18, 50, block.timestamp + 1000];
		presale = new Presale(saleTokenAddress_, usdtAddress_, usdcAddress_, fundsReceiverAddress_, dataFeedAddress_, maxSellingAmount_, startingTime_, endingTime_, phases_);
	}

	function testDeploy() public {
		assertEq(presale.saleTokenAddress(), saleTokenAddress_);
		assertEq(presale.usdtAddress(), usdtAddress_);
		assertEq(presale.usdcAddress(), usdcAddress_);
		assertEq(presale.fundsReceiverAddress(), fundsReceiverAddress_);
		assertEq(presale.dataFeedAddress(), dataFeedAddress_);
		assertEq(presale.maxSellingAmount(), maxSellingAmount_);
		assertEq(presale.startingTime(), startingTime_);
		assertEq(presale.endingTime(), endingTime_);
		assertEq(presale.currentPhase(), 0);
		// assertEq(presale.totalSold(), 0);
	}
}