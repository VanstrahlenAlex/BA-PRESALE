// SPDX-License-Identifier: MIT

pragma solidity 0.8.35;

interface IAggregator{

	function latestRoundData()
			external
			view
			returns (
				uint80 roundId,
				int256 value,
				uint256 startedAt,
				uint256 updatedAt,
				uint80 answeredInRound
			);

}