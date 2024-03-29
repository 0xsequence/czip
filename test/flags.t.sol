// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;

import "foundry-huff/HuffDeployer.sol";
import "forge-std/Test.sol";

import "./utils/decompressor.sol";
import "./utils/compressor.sol";

contract FlagsTest is Test {
  using Decompressor for Decompressor.DContract;
  using Compressor for Compressor.CommandBuffer;
  using Compressor for Vm;


  uint256 MAX_LITERAL = type(uint8).max - (88 + 1);

  Decompressor.DContract public decompressor;

  function setUp() public {
    decompressor = Decompressor.deploy();
  }

  function test_noop() external {
    bytes memory data = bytes("");
    bytes memory encoded = vm.encodeAny(data).run();
    bytes memory decoded = decompressor.call(encoded);
    assertEq(data, decoded);
  }

  function test_bytes32(bytes32 _word) external {
    vm.assume(_word != bytes32(0));

    bytes memory data = abi.encode(_word);
    bytes memory encoded = vm.encodeAny(data)
      .allowOps("FLAG_READ_WORD")
      .run();
    bytes memory decoded = decompressor.call(encoded);
    assertEq(data, decoded);
  }

  function test_bytes32_inv(bytes32 _word) external {
    vm.assume(_word != bytes32(0));

    bytes memory data = abi.encode(_word);
    bytes memory encoded = vm.encodeAny(data)
      .allowOps("FLAG_READ_WORD")
      .allowOps("FLAG_READ_WORD")
      .run();
    bytes memory decoded = decompressor.call(encoded);
    assertEq(data, decoded);
  }

  function test_literal(uint8 _val) external {
    uint256 v = bound(_val, 0, MAX_LITERAL);
    bytes memory data = abi.encode(v);
    bytes memory encoded = vm.encodeAny(data)
      .allowOps("LITERAL_ZERO")
      .run();
    bytes memory decoded = decompressor.call(encoded);
    assertEq(data, decoded);
  }

  function test_pow10(uint8 _exp) external {
    uint256 v = bound(_exp, 1, 77);
    uint256 r = 10**v;
    bytes memory data = abi.encode(r);
    bytes memory encoded = vm.encodeAny(data)
      .allowOps("FLAG_POW_10")
      .run();
    bytes memory decoded = decompressor.call(encoded);
    assertEq(data, decoded);
  }

  function test_pow10Mantissa_S(uint8 _exp, uint8 _mantissa) external {
    uint256 v = bound(_exp, 1, 31);
    uint256 m = bound(_mantissa, 1, 2047);
    uint256 r; unchecked { r = 10**v * m;}
    bytes memory data = abi.encode(r);
    bytes memory encoded = vm.encodeAny(data)
      .allowOps("FLAG_POW_10_MANTISSA_S")
      .run();
    bytes memory decoded = decompressor.call(encoded);
    assertEq(data, decoded);
  }

  function test_pow10Mantissa_L(uint8 _exp, uint24 _mantissa) external {
    uint256 v = bound(_exp, 1, 62);
    uint256 m = bound(_mantissa, 1, 262142);
    uint256 r; unchecked { r = 10**v * m;}
    bytes memory data = abi.encode(r);
    bytes memory encoded = vm.encodeAny(data)
      .allowOps("FLAG_POW_10_MANTISSA_L")
      .run();
    bytes memory decoded = decompressor.call(encoded);
    assertEq(data, decoded);
  }

  function test_pow2(uint8 _exp) external {
    uint256 v = bound(_exp, 1, type(uint8).max);
    uint256 r = 2**v;
    bytes memory data = abi.encode(r);
    bytes memory encoded = vm.encodeAny(data)
      .allowOps("FLAG_POW_2")
      .run();
    bytes memory decoded = decompressor.call(encoded);
    assertEq(data, decoded);
  }

  function test_pow2Minus1(uint8 _exp) external {
    uint256 v = bound(_exp, 1, type(uint8).max);
    uint256 r; unchecked { r = (2**v)-1; }
    bytes memory data = abi.encode(r);
    bytes memory encoded = vm.encodeAny(data)
      .allowOps("FLAG_POW_2_MINUS_1")
      .run();
    bytes memory decoded = decompressor.call(encoded);
    assertEq(data, decoded);
  }

  function test_abiEncode0(bytes4 _selector) external {
    bytes memory data = abi.encodePacked(_selector);
    bytes memory encoded = vm.encodeAny(data)
      .allowOps("FLAG_ABI_0_PARAM")
      .run();
    bytes memory decoded = decompressor.call(encoded);
    assertEq(data, decoded);
  }

  function test_abiEncode1(bytes4 _selector, bytes32 _param1) external {
    bytes memory data = abi.encodePacked(_selector, _param1);
    bytes memory encoded = vm.encodeAny(data)
      .allowOps("FLAG_ABI_0_PARAM")
      .allowOps("FLAG_READ_WORD")
      .allowOps("LITERAL_ZERO")
      .run();
    bytes memory decoded = decompressor.call(encoded);
    assertEq(data, decoded);
  }

  function test_abiEncode2(bytes4 _selector, bytes32 _param1, bytes32 _param2) external {
    bytes memory data = abi.encodePacked(_selector, _param1, _param2);
    bytes memory encoded = vm.encodeAny(data)
      .allowOps("FLAG_ABI_0_PARAM")
      .allowOps("FLAG_READ_WORD")
      .allowOps("LITERAL_ZERO")
      .run();
    bytes memory decoded = decompressor.call(encoded);
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
      .allowOps("FLAG_ABI_0_PARAM")
      .allowOps("FLAG_READ_WORD")
      .allowOps("LITERAL_ZERO")
      .run();
    bytes memory decoded = decompressor.call(encoded);
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
      .allowOps("FLAG_ABI_0_PARAM")
      .allowOps("FLAG_READ_WORD")
      .allowOps("LITERAL_ZERO")
      .run();
    bytes memory decoded = decompressor.call(encoded);
    assertEq(data, decoded);
  }

  function test_abiEncode5(
    bytes4 _selector,
    bytes32 _param1,
    bytes32 _param2,
    bytes32 _param3,
    bytes32 _param4,
    bytes32 _param5
  ) external {
    bytes memory data = abi.encodePacked(_selector, _param1, _param2, _param3, _param4, _param5);
    bytes memory encoded = vm.encodeAny(data)
      .allowOps("FLAG_ABI_0_PARAM")
      .allowOps("FLAG_READ_WORD")
      .allowOps("LITERAL_ZERO")
      .run();
    bytes memory decoded = decompressor.call(encoded);
    assertEq(data, decoded);
  }

  function test_abiEncode6(
    bytes4 _selector,
    bytes32 _param1,
    bytes32 _param2,
    bytes32 _param3,
    bytes32 _param4,
    bytes32 _param5,
    bytes32 _param6
  ) external {
    bytes memory data = abi.encodePacked(_selector, _param1, _param2, _param3, _param4, _param5, _param6);
    bytes memory encoded = vm.encodeAny(data)
      .allowOps("FLAG_ABI_0_PARAM")
      .allowOps("FLAG_READ_WORD")
      .allowOps("LITERAL_ZERO")
      .run();
    bytes memory decoded = decompressor.call(encoded);
    assertEq(data, decoded);
  }

  function test_abiDynamic_allWords(
    bytes4 _selector,
    bytes32[] memory _words
  ) external {
    vm.assume(_words.length > 0);
    vm.assume(_words.length <= 255);

    bytes memory data = abi.encodePacked(_selector, _words);
    bytes memory encoded = vm.encodeAny(data)
      .allowOps("FLAG_READ_DYNAMIC_ABI")
      .allowOps("FLAG_READ_WORD")
      .allowOps("LITERAL_ZERO")
      .run();
    bytes memory decoded = decompressor.call(encoded);
    assertEq(data, decoded);
  }

  function test_nestedNFlags(
    bytes32[] memory _words
  ) external {
    vm.assume(_words.length > 0);
    bytes memory data = abi.encodePacked(_words);
    bytes memory encoded = vm.encodeExtra("FLAG_SEQUENCE_NESTED_N_WORDS", data)
      .allowOps("FLAG_READ_WORD")
      .allowOps("LITERAL_ZERO")
      .run();
    bytes memory decoded = decompressor.call(encoded);
    assertEq(data, decoded);
  }

  function test_writeZeros(
    uint8 _size
  ) external {
    bytes memory input = new bytes(_size);
    bytes memory data = abi.encodePacked(input);
    bytes memory encoded = vm.encodeAny(data)
      .allowOps("FLAG_WRITE_ZEROS")
      .allowOps("LITERAL_ZERO")
      .run();
    bytes memory decoded = decompressor.call(encoded);
    assertEq(data, decoded);
  }

  function test_sequenceAddress(uint8 _weight, address _addr) external {
    bytes memory data = abi.encodePacked(uint8(0x01), _weight, _addr);
    bytes memory encoded = vm.encodeAny(data)
      .allowOps("FLAG_SEQUENCE_ADDRESS")
      .allowOps("FLAG_READ_WORD")
      .allowOps("LITERAL_ZERO")
      .run();
    bytes memory decoded = decompressor.call(encoded);
    assertEq(data, decoded);
  }

  function test_sequenceECDSA(uint8 _weight, bytes32 _p1, bytes32 _p2, bytes2 _p3) external {
    bytes memory data = abi.encodePacked(uint8(0x00), _weight, _p1, _p2, _p3);
    bytes memory encoded = vm.encodeAny(data)
      .allowOps("FLAG_SEQUENCE_SIGNATURE")
      .run();
    bytes memory decoded = decompressor.call(encoded);
    assertEq(data, decoded);
  }

  function test_sequenceNode(bytes32 _node) external {
    bytes memory data = abi.encodePacked(uint8(0x03), _node);
    bytes memory encoded = vm.encodeAny(data)
      .allowOps("FLAG_SEQUENCE_NODE")
      .allowOps("FLAG_READ_WORD")
      .allowOps("LITERAL_ZERO")
      .run();
    bytes memory decoded = decompressor.call(encoded);
    assertEq(data, decoded);
  }

  function test_sequenceSubdigest(bytes32 _subdigest) external {
    bytes memory data = abi.encodePacked(uint8(0x05), _subdigest);
    bytes memory encoded = vm.encodeAny(data)
      .allowOps("FLAG_SEQUENCE_SUBDIGEST")
      .allowOps("FLAG_READ_WORD")
      .allowOps("LITERAL_ZERO")
      .run();
    bytes memory decoded = decompressor.call(encoded);
    assertEq(data, decoded);
  }

  function test_sequenceDynamicSignature(address _addr, uint8 _weight, bytes memory _sig) external {
    vm.assume(_sig.length < type(uint24).max);
    bytes memory data = abi.encodePacked(_addr, _weight, _sig, uint8(0x03));
    bytes memory expect = abi.encodePacked(uint8(0x02), uint8(_weight), _addr, uint24(_sig.length + 1), _sig, uint8(0x03));
    bytes memory encoded = vm.encodeExtra("SEQUENCE_DYNAMIC_SIGNATURE_PART", data)
      .run();
    bytes memory decoded = decompressor.call(encoded);
    assertEq(expect, decoded);
  }

  function test_sequenceBranchSignature(uint8 _innerWeight, address _innerPart) external {
    bytes memory data = abi.encodePacked(uint8(0x01), _innerWeight, _innerPart);
    bytes memory expected = abi.encodePacked(uint8(0x04), uint24(22), uint8(0x01), _innerWeight, _innerPart);
    bytes memory encoded = vm.encodeExtra("SEQUENCE_BRANCH_SIGNATURE_PART", data)
      .run();
    bytes memory decoded = decompressor.call(encoded);
    assertEq(expected, decoded);
  }

  function test_sequenceNestedSignature(uint8 _weight, uint8 _threshold, uint8 _innerWeight, address _innerPart) external {
    bytes memory data = abi.encodePacked(_weight, _threshold, uint8(0x01), _innerWeight, _innerPart);
    bytes memory expected = abi.encodePacked(
      uint8(0x06),
      _weight,
      uint16(_threshold),
      uint24(22),
      uint8(0x01),
      _innerWeight,
      _innerPart
    );

    bytes memory encoded = vm.encodeExtra("SEQUENCE_NESTED_SIGNATURE_PART", data)
      .run();
  
    bytes memory decoded = decompressor.call(encoded);
    assertEq(expected, decoded);
  }

  function test_sequenceSignature(uint16 _t, uint32 _c, uint8 _w1, address _part1, uint8 _w2, address _part2) external {
    bytes memory data = abi.encodePacked(uint8(0x01), _t, _c, uint8(0x01), _w1, _part1, uint8(0x01), _w2, _part2);

    bytes memory encoded = vm.encodeExtra("FLAG_SEQUENCE_SIG", data)
      .run();
    
    bytes memory decoded = decompressor.call(encoded);
    assertEq(data, decoded);
  }

  function test_sequenceChainedSignature(address[] calldata _parts) external {
    vm.assume(_parts.length > 0);

    bytes memory data = hex"";
    bytes memory expected = hex"03";

    for (uint i = 0; i < _parts.length; i++) {
      bytes memory subsig = abi.encodePacked(uint16(0x00), uint32(0x223344), uint8(0x01), uint8(0x02), _parts[i]);
      data = abi.encodePacked(data, uint24(subsig.length), subsig);
      expected = abi.encodePacked(expected, uint24(subsig.length + 1), uint8(0x01), subsig);
    }

    bytes memory encoded = vm.encodeExtra("SEQUENCE_CHAINED_SIGNATURE", data)
      .run();
  
    bytes memory decoded = decompressor.call(encoded);
    assertEq(expected, decoded);
  }

  struct SequenceTransaction {
    bool delegateCall;
    bool revertOnError;
    uint256 gasLimit;
    address target;
    uint256 value; 
    bytes data;
  }

  function test_sequenceExecute_decode(address _wallet, SequenceTransaction[] calldata _txs, uint256 _nonce, bytes memory _signature) external {
    vm.assume(_txs.length > 0 && _txs.length <= 100);

    bytes memory data = abi.encodeWithSelector(0x7a9a1628, _txs, _nonce, _signature);
    bytes memory encoded = vm.encodeSequenceTx("decode", _wallet, data)
      .run();
    
    bytes memory decoded = decompressor.call(encoded);
    assertEq(abi.encodePacked(data, abi.encode(_wallet)), decoded);
  }

  function test_sequenceExecute_flag(SequenceTransaction[] calldata _txs, uint256 _nonce, bytes memory _signature) external {
    vm.assume(_txs.length > 0 && _txs.length <= 100);

    bytes memory data = abi.encodeWithSelector(0x7a9a1628, _txs, _nonce, _signature);
    bytes memory encoded = vm.encodeExtra("FLAG_SEQUENCE_EXECUTE", data)
      .run();
    
    bytes memory decoded = decompressor.call(encoded);
    assertEq(data, decoded);
  }

  function test_sequenceSelfExecute_flag(SequenceTransaction[] calldata _txs) external {
    vm.assume(_txs.length > 0 && _txs.length <= 100);

    bytes memory data = abi.encodeWithSelector(0x61c2926c, _txs);
    bytes memory encoded = vm.encodeExtra("FLAG_SEQUENCE_SELF_EXECUTE", data)
      .run();
    
    bytes memory decoded = decompressor.call(encoded);
    assertEq(data, decoded);
  }

  function test_sequenceExecute_call(address _wallet, SequenceTransaction[] calldata _txs, uint256 _nonce, bytes memory _signature) external {
    vm.assume(_txs.length > 0 && _txs.length <= 3);
    vm.assume(_wallet != address(this) && !decompressor.eq(_wallet));
    vm.assume(_wallet != 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
    vm.assume(_wallet != 0x000000000000000000636F6e736F6c652e6c6f67);

    bytes memory data = abi.encodeWithSelector(0x7a9a1628, _txs, _nonce, _signature);
    bytes memory encoded = vm.encodeSequenceTx("call", _wallet, data)
      .run();

    vm.expectCall(_wallet, 0, data);

    bytes memory decoded = decompressor.call(encoded);
    assertEq(decoded.length, 0);
  }

  function test_call_decode(address _to, bytes calldata _data) external {
    bytes memory encoded = vm.encodeCall("decode", _to, _data)
      .run();

    bytes memory decoded = decompressor.call(encoded);
    assertEq(abi.encodePacked(_data, abi.encode(_to)), decoded);
  }

  function test_call_call(address _to, bytes calldata _data) external {
    vm.assume(_to != 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
    vm.assume(_to != 0x000000000000000000636F6e736F6c652e6c6f67);

    bytes memory encoded = vm.encodeCall("call", _to, _data)
      .run();

    vm.expectCall(_to, 0, _data);

    bytes memory res = decompressor.call(encoded);
    assertEq(res.length, 0);
  }

  function test_calls_decode(Compressor.Call[] calldata _calls) external {
    vm.assume(_calls.length > 0 && _calls.length <= 2);

    bytes memory expected = hex"";
    for (uint i = 0; i < _calls.length; i++) {
      expected = abi.encodePacked(expected, _calls[i].data, abi.encode(_calls[i].to));
    }

    bytes memory encoded = vm.encodeCalls("decode", _calls)
      .run();

    bytes memory decoded = decompressor.call(encoded);
    assertEq(expected, decoded);
  }

  function test_call_and_return(address _to, bytes calldata _data, bytes calldata _return) external {
    vm.assume(_to != address(this) && !decompressor.eq(_to));
    vm.assume(_to != 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
    vm.assume(_to != 0x000000000000000000636F6e736F6c652e6c6f67);

    bytes memory encoded = vm.encodeCall("call-return", _to, _data)
      .run();

    vm.mockCall(_to, 0, _data, _return);

    bytes memory res = decompressor.call(encoded);
    assertEq(res, _return);
  }

  function test_calls_call(Compressor.Call[] memory _calls) external {
    vm.assume(_calls.length > 0 && _calls.length <= 64);

    // Re-hash all `to` so they point to different addresses
    for (uint i = 0; i < _calls.length; i++) {
      _calls[i].to = address(uint160(uint256(keccak256(abi.encodePacked(i, _calls[i].to)))));
    }

    for (uint i = 0; i < _calls.length; i++) {
      vm.expectCall(_calls[i].to, 0, _calls[i].data);
    }

    bytes memory encoded = vm.encodeCalls("call", _calls)
      .run();

    bytes memory decoded = decompressor.call(encoded);
    assertEq(decoded.length, 0);
  }
}
