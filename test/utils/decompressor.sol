// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;

import "foundry-huff/HuffDeployer.sol";
import "forge-std/Vm.sol";


library Decompressor {
  type DContract is address;

  function deploy() internal returns (DContract) {
    return DContract.wrap(HuffDeployer
      .config()
      .with_evm_version("paris")
      .deploy("decompressor"));
  }

  function call(DContract _d, bytes memory _data) internal returns (bytes memory) {
    (bool ok, bytes memory res) = DContract.unwrap(_d).call{ gas: 300000000 }(_data);
    require(ok, "Failed to decode");
    return res;
  }

  function eq(DContract _d, address _addr) internal pure returns (bool) {
    return DContract.unwrap(_d) == _addr;
  }

  function bytes32Size(DContract _d) internal returns (uint256) {
    bytes memory res = call(_d, hex"04");
    bytes32 word = abi.decode(res, (bytes32));
    return uint256(word) & uint256(type(uint128).max);
  }

  function addrSize(DContract _d) internal returns (uint256) {
    bytes memory res = call(_d, hex"04");
    bytes32 word = abi.decode(res, (bytes32));
    return uint256(word) >> 128;
  }

  function getAddress(DContract _d, uint256 _i) internal returns (address) {
    bytes memory res = call(_d, abi.encodePacked(uint8(0x02), _i));
    return abi.decode(res, (address));
  }

  function getBytes32(DContract _d, uint256 _i) internal returns (bytes32) {
    bytes memory res = call(_d, abi.encodePacked(uint8(0x03), _i));
    return abi.decode(res, (bytes32));
  }
}
