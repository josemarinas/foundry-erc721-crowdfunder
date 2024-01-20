// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

enum CrowdfundState {
    Active,
    Cancelled,
    Ended
}

/// @title ERC721CrowdFunder
/// @notice Crowdfund an NFT
/// @author Jose Marinas

contract ERC721Crowdfunder is ERC721{
    error SenderIsNotDeployer();
    error CrowdfundNotActive();
    error CrowdfundIsActive();
    error SenderIsNotOwner(address sender, uint tokenId);
    error FundingObjectiveNotReached(uint fundingObjective, uint balance);
    error FundingObjectiveReached(uint fundingObjective, uint balance);
    error CrowdfundNotEnded(uint endTimestamp, uint blockTimestamp);
    error CrowdfundEnded(uint endTimestamp, uint blockTimestamp);
    error IncorrectValue(uint value, uint price);
    error FailedToRefund();
    error FailedToWithdraw();

    /// @notice Token id
    uint private tokenId = 0;

    /// @notice Crowdfund is active or not
    bool public isActive = true;

    /// @notice Objective funding of the crowdfund
    uint public fundingObjective;

    /// @notice Timestamp when the crowdfund ends
    uint public endTimestamp;

    /// @notice Address of the deployer
    address public deployer;

    constructor(
        string memory _name,
        string memory _symbol,
        uint _fundingObjective,
        address _deployer
    ) ERC721(_name, _symbol) {
        endTimestamp = block.timestamp + 30 days;
        fundingObjective = _fundingObjective;
        deployer = _deployer;
    }
    // modifiers
    // check if the sender is the deployer
    modifier isDeployer() {
        if (msg.sender != deployer) {
            revert SenderIsNotDeployer();
        }
        _;
    }

    // check if the token can be refunded
    // the crowdfund is cancelled
    // the sender must be the owner of the token
    // the token must not be refunded yet
    modifier canRefund(uint _tokenId) {
        if (isActive) {
            revert CrowdfundIsActive();
        } else if (ownerOf(_tokenId) != msg.sender) {
            revert SenderIsNotOwner(msg.sender, tokenId);
        }
        _;
    }

    // chcek if the crowdfund can be cancelled
    // the crowdfund must be ended
    // the crowdfund must not have reached the objective funding
    modifier canCancel() {
        if (block.timestamp < endTimestamp) {
            revert CrowdfundNotEnded(endTimestamp, block.timestamp);
        } else if (address(this).balance >= fundingObjective) {
            revert FundingObjectiveReached(
                fundingObjective,
                address(this).balance
            );
        }
        _;
    }
    // check if the crowdfund can be withdrawn
    // the crowdfund must be ended
    // the crowdfund must be active => not cancelled
    // the crowdfund must have reached the objective funding
    modifier canWithdraw() {
        if (block.timestamp < endTimestamp) {
            revert CrowdfundNotEnded(endTimestamp, block.timestamp);
        } else if (address(this).balance < fundingObjective) {
            revert FundingObjectiveNotReached(
                fundingObjective,
                address(this).balance
            );
        }
        _;
    }

    /// @notice Mint an NFT if you send 1 ether
    function mint() public payable {
        if (block.timestamp > endTimestamp) {
            revert CrowdfundEnded(endTimestamp, block.timestamp);
        } else if (msg.value != 1 ether) {
            revert IncorrectValue(msg.value, 1 ether);
        }
        _safeMint(msg.sender, tokenId);
        tokenId += 1;
    }

    /// @notice Owner can withdraw the funds if the crowdfund is successful
    function withdraw() public isDeployer canWithdraw {
        (bool sent, ) = msg.sender.call{value: address(this).balance}("");
        if (!sent) {
            revert FailedToWithdraw();
        }
    }

    /// @notice Cancel the crowdfund if tjhe funding objective is not reached
    function cancel() public isDeployer canCancel {
        isActive = false;
        // emit Cancelled();
    }

    /// @notice Refund the sender if the crowdfund is cancelled
    /// @param _tokenId The id of the token to refund
    function refund(uint _tokenId) public canRefund(_tokenId) {
        _burn(_tokenId);
        (bool sent, ) = msg.sender.call{value: 1 ether}("");
        if (!sent) {
            revert FailedToRefund();
        }
    }
}