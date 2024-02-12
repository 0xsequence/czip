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
    (bool res, bytes memory decoded) = DContract.unwrap(_d).call{ gas: 300000000 }(_data);
    require(res, "Failed to decode");
    return decoded;
  }

  function eq(DContract _d, address _addr) internal pure returns (bool) {
    return DContract.unwrap(_d) == _addr;
  }
}
