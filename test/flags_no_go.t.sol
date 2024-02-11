pragma solidity ^0.8.0;

import "foundry-huff/HuffDeployer.sol";
import "forge-std/Test.sol";

import "./utils/encoder.sol";

uint8 constant DECODE_ANY             = 0x0d;

uint8 constant FLAG_READ_WORD_1       = 0x01;
uint8 constant FLAG_READ_WORD_32      = 0x20;
uint8 constant FLAG_READ_N_BYTES      = 0x22;
uint8 constant FLAG_NESTED_N_FLAGS_S  = 0x24;
uint8 constant FLAG_COPY_CALLDATA     = 0x3f;
uint8 constant FLAG_MIRROR_FLAG       = 0x3d;

contract FlagsTestNoGo is Test {
  using Encoder for Encoder.CommandBuffer;
  using Encoder for Vm;

  uint256 MAX_LITERAL = type(uint8).max - (0x4f + 1);

  address public compressor;

  function setUp() public {
    compressor = HuffDeployer.deploy("decompressor");
  }

  function decode(bytes memory _data) internal returns (bytes memory) {
    (bool res, bytes memory decoded) = compressor.call(_data);
    require(res, "Failed to decode");
    return decoded;
  }

  function test_copyCalldata(bytes memory _part) external {
    vm.assume(_part.length <= 255);
    bytes memory data = abi.encodePacked(_part, _part);

    bytes memory encoded = abi.encodePacked(
      DECODE_ANY,
      FLAG_NESTED_N_FLAGS_S,
      uint8(0x02),
      FLAG_READ_N_BYTES,
      FLAG_READ_WORD_1,
      uint8(_part.length),
      _part,
      FLAG_COPY_CALLDATA,
      uint16(0x06),
      uint8(_part.length)
    );

    bytes memory decoded = decode(encoded);
    assertEq(data, decoded);
  }

  function test_mirrorFlag(bytes32 _word) external {
    bytes memory data = abi.encode(_word, _word);
    bytes memory encoded = abi.encodePacked(
      DECODE_ANY,
      FLAG_NESTED_N_FLAGS_S,
      uint8(0x02),
      FLAG_READ_WORD_32,
      _word,
      FLAG_MIRROR_FLAG,
      uint16(0x03)
    );

    bytes memory decoded = decode(encoded);
    assertEq(data, decoded);
  }
}
