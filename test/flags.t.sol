pragma solidity ^0.8.0;

import "foundry-huff/HuffDeployer.sol";
import "forge-std/Test.sol";

import "./utils/encoder.sol";

contract FlagsTest is Test {
  using Encoder for Encoder.CommandBuffer;
  using Encoder for Vm;

  uint256 MAX_LITERAL = type(uint8).max - (0x4f + 1);

  address public compressor;

  function setUp() public {
    compressor = HuffDeployer.deploy("compressor");
  }

  function decode(bytes memory _data) internal returns (bytes memory) {
    (bool res, bytes memory decoded) = compressor.call(_data);
    require(res, "Failed to decode");
    return decoded;
  }

  function test_decompressNoop() external {
    bytes memory data = bytes("");
    bytes memory encoded = vm.encodeAny(data).run();
    bytes memory decoded = decode(encoded);
    assertEq(data, decoded);
  }

  function test_decompressBytes32(bytes32 _word) external {
    bytes memory data = abi.encode(_word);
    bytes memory encoded = vm.encodeAny(data)
      .useStorage(false)
      .allowOps("FLAG_READ_BYTES32_1_BYTES")
      .run();
    bytes memory decoded = decode(encoded);
    assertEq(data, decoded);
  }

  function test_decompressLiteral(uint8 _val) external {
    uint256 v = bound(_val, 0, MAX_LITERAL);
    bytes memory data = abi.encode(v);
    bytes memory encoded = vm.encodeAny(data)
      .useStorage(false)
      .allowOps("LITERAL_ZERO")
      .run();
    bytes memory decoded = decode(encoded);
    assertEq(data, decoded);
  }

  function test_pow10(uint8 _exp) external {
    uint256 v = bound(_exp, 1, 77);
    uint256 r = 10**v;
    bytes memory data = abi.encode(r);
    bytes memory encoded = vm.encodeAny(data)
      .useStorage(false)
      .allowOps("FLAG_READ_POWER_OF_10")
      .run();
    bytes memory decoded = decode(encoded);
    assertEq(data, decoded);
  }

  function test_pow10Mantissa_S(uint8 _exp, uint8 _mantissa) external {
    uint256 v = bound(_exp, 1, 62);
    uint256 m = bound(_mantissa, 1, 255);
    uint256 r; unchecked { r = 10**v * m;}
    bytes memory data = abi.encode(r);
    bytes memory encoded = vm.encodeAny(data)
      .useStorage(false)
      .allowOps("FLAG_READ_POWER_OF_10")
      .run();
    bytes memory decoded = decode(encoded);
    assertEq(data, decoded);
  }

  function test_pow10Mantissa_L(uint8 _exp, uint24 _mantissa) external {
    uint256 v = bound(_exp, 1, 62);
    uint256 m = bound(_mantissa, 1, 262142);
    uint256 r; unchecked { r = 10**v * m;}
    bytes memory data = abi.encode(r);
    bytes memory encoded = vm.encodeAny(data)
      .useStorage(false)
      .allowOps("FLAG_READ_POW_10_MANTISSA")
      .run();
    bytes memory decoded = decode(encoded);
    assertEq(data, decoded);
  }

  function test_pow2(uint8 _exp) external {
    uint256 v = bound(_exp, 1, type(uint8).max);
    uint256 r = 2**v;
    bytes memory data = abi.encode(r);
    bytes memory encoded = vm.encodeAny(data)
      .useStorage(false)
      .allowOps("FLAG_READ_POWER_OF_2")
      .run();
    bytes memory decoded = decode(encoded);
    assertEq(data, decoded);
  }

  function test_pow2Minus1(uint8 _exp) external {
    uint256 v = bound(_exp, 1, type(uint8).max);
    uint256 r; unchecked { r = (2**v)-1; }
    bytes memory data = abi.encode(r);
    bytes memory encoded = vm.encodeAny(data)
      .useStorage(false)
      .allowOps("FLAG_READ_POWER_OF_2")
      .run();
    bytes memory decoded = decode(encoded);
    assertEq(data, decoded);
  }

  function test_abiEncode0(bytes4 _selector) external {
    bytes memory data = abi.encodePacked(_selector);
    bytes memory encoded = vm.encodeAny(data)
      .useStorage(false)
      .allowOps("FLAG_ABI_0_PARAM")
      .run();
    bytes memory decoded = decode(encoded);
    assertEq(data, decoded);
  }

  function test_abiEncode1(bytes4 _selector, bytes32 _param1) external {
    bytes memory data = abi.encodePacked(_selector, _param1);
    bytes memory encoded = vm.encodeAny(data)
      .useStorage(false)
      .allowOps("FLAG_ABI_0_PARAM,FLAG_READ_BYTES32_1_BYTES")
      .run();
    bytes memory decoded = decode(encoded);
    assertEq(data, decoded);
  }

  function test_abiEncode2(bytes4 _selector, bytes32 _param1, bytes32 _param2) external {
    bytes memory data = abi.encodePacked(_selector, _param1, _param2);
    bytes memory encoded = vm.encodeAny(data)
      .useStorage(false)
      .allowOps("FLAG_ABI_0_PARAM,FLAG_READ_BYTES32_1_BYTES")
      .run();
    bytes memory decoded = decode(encoded);
    assertEq(data, decoded);
  }

  function test_abiEncode3(
    bytes4 _selector,
    bytes32 _param1,
    bytes32 _param2,
    bytes32 _param3
  ) external {
    bytes memory data = abi.encodePacked(_selector, _param1, _param2, _param3);
    bytes memory encoded = vm.encodeAny(data)
      .useStorage(false)
      .allowOps("FLAG_ABI_0_PARAM,FLAG_READ_BYTES32_1_BYTES")
      .run();
    bytes memory decoded = decode(encoded);
    assertEq(data, decoded);
  }

  function test_abiEncode4(
    bytes4 _selector,
    bytes32 _param1,
    bytes32 _param2,
    bytes32 _param3,
    bytes32 _param4
  ) external {
    bytes memory data = abi.encodePacked(_selector, _param1, _param2, _param3, _param4);
    bytes memory encoded = vm.encodeAny(data)
      .useStorage(false)
      .allowOps("FLAG_ABI_0_PARAM,FLAG_READ_BYTES32_1_BYTES")
      .run();
    bytes memory decoded = decode(encoded);
    assertEq(data, decoded);
  }
}