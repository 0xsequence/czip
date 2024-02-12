// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "./utils/decompressor.sol";
import "./utils/compressor.sol";

uint8 constant DECODE_ANY             = 0x0d;

uint8 constant FLAG_NO_OP              = 0x00;
uint8 constant FLAG_READ_WORD_1        = 0x01;
uint8 constant FLAG_READ_WORD_2        = 0x02;
uint8 constant FLAG_READ_WORD_3        = 0x03;
uint8 constant FLAG_READ_WORD_4        = 0x04;
uint8 constant FLAG_READ_WORD_5        = 0x05;
uint8 constant FLAG_READ_WORD_6        = 0x06;
uint8 constant FLAG_READ_WORD_7        = 0x07;
uint8 constant FLAG_READ_WORD_8        = 0x08;
uint8 constant FLAG_READ_WORD_9        = 0x09;
uint8 constant FLAG_READ_WORD_10       = 0x0a;
uint8 constant FLAG_READ_WORD_11       = 0x0b;
uint8 constant FLAG_READ_WORD_12       = 0x0c;
uint8 constant FLAG_READ_WORD_13       = 0x0d;
uint8 constant FLAG_READ_WORD_14       = 0x0e;
uint8 constant FLAG_READ_WORD_15       = 0x0f;
uint8 constant FLAG_READ_WORD_16       = 0x10;
uint8 constant FLAG_READ_WORD_17       = 0x11;
uint8 constant FLAG_READ_WORD_18       = 0x12;
uint8 constant FLAG_READ_WORD_19       = 0x13;
uint8 constant FLAG_READ_WORD_20       = 0x14;
uint8 constant FLAG_READ_WORD_21       = 0x15;
uint8 constant FLAG_READ_WORD_22       = 0x16;
uint8 constant FLAG_READ_WORD_23       = 0x17;
uint8 constant FLAG_READ_WORD_24       = 0x18;
uint8 constant FLAG_READ_WORD_25       = 0x19;
uint8 constant FLAG_READ_WORD_26       = 0x1a;
uint8 constant FLAG_READ_WORD_27       = 0x1b;
uint8 constant FLAG_READ_WORD_28       = 0x1c;
uint8 constant FLAG_READ_WORD_29       = 0x1d;
uint8 constant FLAG_READ_WORD_30       = 0x1e;
uint8 constant FLAG_READ_WORD_31       = 0x1f;
uint8 constant FLAG_READ_WORD_32       = 0x20;
uint8 constant FLAG_READ_WORD_INV      = 0x21;
uint8 constant FLAG_READ_N_BYTES       = 0x22;
uint8 constant FLAG_WRITE_ZEROS        = 0x23;
uint8 constant FLAG_NESTED_N_FLAGS_S   = 0x24;
uint8 constant FLAG_NESTED_N_FLAGS_L   = 0x25;
uint8 constant FLAG_SAVE_ADDRESS       = 0x26;
uint8 constant FLAG_READ_ADDRESS_2     = 0x27;
uint8 constant FLAG_READ_ADDRESS_3     = 0x28;
uint8 constant FLAG_READ_ADDRESS_4     = 0x29;
uint8 constant FLAG_SAVE_BYTES32       = 0x2a;
uint8 constant FLAG_READ_BYTES32_2     = 0x2b;
uint8 constant FLAG_READ_BYTES32_3     = 0x2c;
uint8 constant FLAG_READ_BYTES32_4     = 0x2d;
uint8 constant FLAG_READ_STORE_FLAG_S  = 0x2e;
uint8 constant FLAG_READ_STORE_FLAG_L  = 0x2f;
uint8 constant FLAG_POW_2              = 0x30;
uint8 constant FLAG_POW_2_MINUS_1      = 0x31;
uint8 constant FLAG_POW_10             = 0x32;
uint8 constant FLAG_POW_10_MANTISSA_S  = 0x33;
uint8 constant FLAG_POW_10_MANTISSA_L  = 0x34;
uint8 constant FLAG_ABI_0_PARAM        = 0x35;
uint8 constant FLAG_ABI_1_PARAM        = 0x36;
uint8 constant FLAG_ABI_2_PARAMS       = 0x37;
uint8 constant FLAG_ABI_3_PARAMS       = 0x38;
uint8 constant FLAG_ABI_4_PARAMS       = 0x39;
uint8 constant FLAG_ABI_5_PARAMS       = 0x3a;
uint8 constant FLAG_ABI_6_PARAMS       = 0x3b;
uint8 constant FLAG_READ_DYNAMIC_ABI   = 0x3c;
uint8 constant FLAG_MIRROR_FLAG_S      = 0x3d;
uint8 constant FLAG_MIRROR_FLAG_L      = 0x3e;
uint8 constant FLAG_COPY_CALLDATA_S    = 0x3f;
uint8 constant FLAG_COPY_CALLDATA_L    = 0x40;
uint8 constant FLAG_COPY_CALLDATA_XL   = 0x41;

contract FlagsTestNoGo is Test {
  using Decompressor for Decompressor.DContract;
  using Compressor for Compressor.CommandBuffer;
  using Compressor for Vm;

  uint256 MAX_LITERAL = type(uint8).max - (0x4f + 1);

  Decompressor.DContract public decompressor;

  function setUp() public {
    decompressor = Decompressor.deploy();
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
      FLAG_COPY_CALLDATA_S,
      uint16(0x06),
      uint8(_part.length)
    );

    bytes memory decoded = decompressor.call(encoded);
    assertEq(data, decoded);
  }

  function test_copyCalldata_l(bytes memory _part) external {
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
      FLAG_COPY_CALLDATA_L,
      uint24(0x06),
      uint8(_part.length)
    );

    bytes memory decoded = decompressor.call(encoded);
    assertEq(data, decoded);
  }

  function test_copyCalldata_xl(bytes memory _part) external {
    vm.assume(_part.length <= 0xffff);
    bytes memory data = abi.encodePacked(_part, _part);

    bytes memory encoded = abi.encodePacked(
      DECODE_ANY,
      FLAG_NESTED_N_FLAGS_S,
      uint8(0x02),
      FLAG_READ_N_BYTES,
      FLAG_READ_WORD_2,
      uint16(_part.length),
      _part,
      FLAG_COPY_CALLDATA_XL,
      uint24(0x07),
      uint16(_part.length)
    );

    bytes memory decoded = decompressor.call(encoded);
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
      FLAG_MIRROR_FLAG_S,
      uint16(0x03)
    );

    bytes memory decoded = decompressor.call(encoded);
    assertEq(data, decoded);
  }

  function test_mirrorFlag_l(bytes32 _word) external {
    bytes memory data = abi.encode(_word, _word);
    bytes memory encoded = abi.encodePacked(
      DECODE_ANY,
      FLAG_NESTED_N_FLAGS_S,
      uint8(0x02),
      FLAG_READ_WORD_32,
      _word,
      FLAG_MIRROR_FLAG_L,
      uint24(0x03)
    );

    bytes memory decoded = decompressor.call(encoded);
    assertEq(data, decoded);
  }

  function test_writeAddress(address _addr) external {
    bytes memory data = abi.encode(_addr);
    bytes memory encoded = abi.encodePacked(
      DECODE_ANY,
      FLAG_SAVE_ADDRESS,
      _addr
    );

    bytes memory decoded = decompressor.call(encoded);
    assertEq(data, decoded);
    assertEq(decompressor.addrSize(), 1);
    assertEq(decompressor.getAddress(1), _addr);
  }

  function test_writeBytes32(bytes32 _b) external {
    bytes memory data = abi.encode(_b);
    bytes memory encoded = abi.encodePacked(
      DECODE_ANY,
      FLAG_SAVE_BYTES32,
      _b
    );

    bytes memory decoded = decompressor.call(encoded);
    assertEq(data, decoded);
    assertEq(decompressor.bytes32Size(), 1);
    assertEq(decompressor.getBytes32(1), _b);
  }

  function test_writeBoth(bytes32[3] calldata _bs, address[2] calldata _addrs) external {
    bytes memory data = abi.encode(
      _bs[0],
      _bs[1],
      _addrs[0],
      _bs[2],
      _addrs[1]
    );

    bytes memory encoded = abi.encodePacked(
      DECODE_ANY,
      FLAG_NESTED_N_FLAGS_S,
      uint8(5),
      FLAG_SAVE_BYTES32,
      _bs[0],
      FLAG_SAVE_BYTES32,
      _bs[1],
      FLAG_SAVE_ADDRESS,
      _addrs[0],
      FLAG_SAVE_BYTES32,
      _bs[2],
      FLAG_SAVE_ADDRESS,
      _addrs[1]
    );

    bytes memory decoded = decompressor.call(encoded);
    assertEq(data, decoded);
    assertEq(decompressor.addrSize(), 2);
    assertEq(decompressor.bytes32Size(), 3);
    assertEq(decompressor.getBytes32(1), _bs[0]);
    assertEq(decompressor.getBytes32(2), _bs[1]);
    assertEq(decompressor.getBytes32(3), _bs[2]);
    assertEq(decompressor.getAddress(1), _addrs[0]);
    assertEq(decompressor.getAddress(2), _addrs[1]);
  }

  function test_mirrorAddrStorage(address _addr) external {
    bytes memory data = abi.encode(_addr, _addr);

    bytes memory encoded = abi.encodePacked(
      DECODE_ANY,
      FLAG_NESTED_N_FLAGS_S,
      uint8(2),
      FLAG_SAVE_ADDRESS,
      _addr,
      FLAG_READ_STORE_FLAG_S,
      uint16(3)
    );

    vm.record();
    bytes memory decoded = decompressor.call(encoded);
    (bytes32[] memory reads, bytes32[] memory writes) = vm.accesses(Decompressor.DContract.unwrap(decompressor));

    assertEq(data, decoded);
    assertEq(reads.length, 3);
    assertEq(writes.length, 2);
  }

  function test_mirrorBytesStorage(bytes32 _b) external {
    bytes memory data = abi.encode(_b, _b);
    bytes memory encoded = abi.encodePacked(
      DECODE_ANY,
      FLAG_NESTED_N_FLAGS_S,
      uint8(2),
      FLAG_SAVE_BYTES32,
      _b,
      FLAG_READ_STORE_FLAG_L,
      uint24(3)
    );

    vm.record();
    bytes memory decoded = decompressor.call(encoded);
    (bytes32[] memory reads, bytes32[] memory writes) = vm.accesses(Decompressor.DContract.unwrap(decompressor));

    assertEq(data, decoded);
    assertEq(reads.length, 3);
    assertEq(writes.length, 2);
  }

  function test_readAddressStorage(address[3] calldata _addrs) external {
    decompressor.call(abi.encodePacked(
      DECODE_ANY,
      FLAG_NESTED_N_FLAGS_L,
      uint16(3),
      FLAG_SAVE_ADDRESS,
      _addrs[0],
      FLAG_SAVE_ADDRESS,
      _addrs[1],
      FLAG_SAVE_ADDRESS,
      _addrs[2]
    ));

    bytes memory data = abi.encode(_addrs[0], _addrs[1], _addrs[2]);
    bytes memory encoded = abi.encodePacked(
      DECODE_ANY,
      FLAG_NESTED_N_FLAGS_S,
      uint8(3),
      FLAG_READ_ADDRESS_2,
      uint16(1),
      FLAG_READ_ADDRESS_3,
      uint24(2),
      FLAG_READ_ADDRESS_4,
      uint32(3)
    );

    bytes memory decoded = decompressor.call(encoded);
    assertEq(decoded, data);
  }

  function test_readBytes32Storage(bytes32[3] calldata _bs) external {
    decompressor.call(abi.encodePacked(
      DECODE_ANY,
      FLAG_NESTED_N_FLAGS_L,
      uint16(3),
      FLAG_SAVE_BYTES32,
      _bs[0],
      FLAG_SAVE_BYTES32,
      _bs[1],
      FLAG_SAVE_BYTES32,
      _bs[2]
    ));

    bytes memory data = abi.encode(_bs[0], _bs[1], _bs[2]);
    bytes memory encoded = abi.encodePacked(
      DECODE_ANY,
      FLAG_NESTED_N_FLAGS_S,
      uint8(3),
      FLAG_READ_BYTES32_2,
      uint16(1),
      FLAG_READ_BYTES32_3,
      uint24(2),
      FLAG_READ_BYTES32_4,
      uint32(3)
    );

    bytes memory decoded = decompressor.call(encoded);
    assertEq(decoded, data);
  }
}
