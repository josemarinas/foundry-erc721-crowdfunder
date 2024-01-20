pragma solidity ^0.8.17;

import {Test, console2} from "forge-std/Test.sol";
import {ERC721Crowdfunder} from "../src/ERC721Crowdfunder.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

contract ERC721CrowdfunderTest is Test, ERC721Holder {
    ERC721Crowdfunder public crowdfunder;
    string public name = "Test";
    string public symbol = "TST";
    uint public fundingObjective = 100;
    uint public endTimestamp = block.timestamp + 30 days;
    uint public price = 1 ether;

    function setUp() public {
        // make the wallet of the owner to
        // implement the ERC721Holder interface

        address _owner = address(this);
        crowdfunder = new ERC721Crowdfunder(
            name,
            symbol,
            fundingObjective,
            _owner
        );
    }

    function test__constructor() public {
        assertEq(crowdfunder.name(), name);
        assertEq(crowdfunder.symbol(), symbol);
        assertEq(crowdfunder.fundingObjective(), fundingObjective);
        assertEq(crowdfunder.deployer(), address(this));
    }

    function test__mintIncorrectValue() public {
        uint _value = 0.5 ether;
        vm.expectRevert(
            abi.encodeWithSelector(
                ERC721Crowdfunder.IncorrectValue.selector,
                _value,
                price
            )
        );
        crowdfunder.mint{value: _value}();
    }

    function test__mint() public {
        uint _tokenId = 0;
        crowdfunder.mint{value: price}();
        assertEq(crowdfunder.ownerOf(_tokenId), address(this));
    }
}
