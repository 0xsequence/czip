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
    (bool res, bytes memory decoded) = compressor.call{ gas: 300000000 }(_data);
    require(res, "Failed to decode");
    return decoded;
  }

  function test_noop() external {
    bytes memory data = bytes("");
    bytes memory encoded = vm.encodeAny(data).run();
    bytes memory decoded = decode(encoded);
    assertEq(data, decoded);
  }

  function test_bytes32(bytes32 _word) external {
    vm.assume(_word != bytes32(0));

    bytes memory data = abi.encode(_word);
    bytes memory encoded = vm.encodeAny(data)
      .useStorage(false)
      .allowOps("FLAG_READ_BYTES32")
      .run();
    bytes memory decoded = decode(encoded);
    assertEq(data, decoded);
  }

  function test_literal(uint8 _val) external {
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
    vm.assume(_param1 != bytes32(0));
    bytes memory data = abi.encodePacked(_selector, _param1);
    bytes memory encoded = vm.encodeAny(data)
      .useStorage(false)
      .allowOps("FLAG_ABI_0_PARAM")
      .allowOps("FLAG_READ_BYTES32")
      .run();
    bytes memory decoded = decode(encoded);
    assertEq(data, decoded);
  }

  function test_abiEncode2(bytes4 _selector, bytes32 _param1, bytes32 _param2) external {
    vm.assume(_param1 != bytes32(0));
    vm.assume(_param2 != bytes32(0));
    bytes memory data = abi.encodePacked(_selector, _param1, _param2);
    bytes memory encoded = vm.encodeAny(data)
      .useStorage(false)
      .allowOps("FLAG_ABI_0_PARAM")
      .allowOps("FLAG_READ_BYTES32")
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
    vm.assume(_param1 != bytes32(0));
    vm.assume(_param2 != bytes32(0));
    vm.assume(_param3 != bytes32(0));
    bytes memory data = abi.encodePacked(_selector, _param1, _param2, _param3);
    bytes memory encoded = vm.encodeAny(data)
      .useStorage(false)
      .allowOps("FLAG_ABI_0_PARAM")
      .allowOps("FLAG_READ_BYTES32")
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
    vm.assume(_param1 != bytes32(0));
    vm.assume(_param2 != bytes32(0));
    vm.assume(_param3 != bytes32(0));
    vm.assume(_param4 != bytes32(0));
    bytes memory data = abi.encodePacked(_selector, _param1, _param2, _param3, _param4);
    bytes memory encoded = vm.encodeAny(data)
      .useStorage(false)
      .allowOps("FLAG_ABI_0_PARAM")
      .allowOps("FLAG_READ_BYTES32")
      .run();
    bytes memory decoded = decode(encoded);
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
    vm.assume(_param1 != bytes32(0));
    vm.assume(_param2 != bytes32(0));
    vm.assume(_param3 != bytes32(0));
    vm.assume(_param4 != bytes32(0));
    vm.assume(_param5 != bytes32(0));
    bytes memory data = abi.encodePacked(_selector, _param1, _param2, _param3, _param4);
    bytes memory encoded = vm.encodeAny(data)
      .useStorage(false)
      .allowOps("FLAG_ABI_0_PARAM")
      .allowOps("FLAG_READ_BYTES32")
      .run();
    bytes memory decoded = decode(encoded);
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
    vm.assume(_param1 != bytes32(0));
    vm.assume(_param2 != bytes32(0));
    vm.assume(_param3 != bytes32(0));
    vm.assume(_param4 != bytes32(0));
    vm.assume(_param5 != bytes32(0));
    vm.assume(_param6 != bytes32(0));
    bytes memory data = abi.encodePacked(_selector, _param1, _param2, _param3, _param4);
    bytes memory encoded = vm.encodeAny(data)
      .useStorage(false)
      .allowOps("FLAG_ABI_0_PARAM")
      .allowOps("FLAG_READ_BYTES32")
      .run();
    bytes memory decoded = decode(encoded);
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
      .useStorage(false)
      .allowOps("FLAG_READ_DYNAMIC_ABI")
      .allowOps("FLAG_READ_BYTES32")
      .allowOps("LITERAL_ZERO")
      .run();
    bytes memory decoded = decode(encoded);
    assertEq(data, decoded);
  }

  function test_nestedNFlags(
    bytes32[] memory _words
  ) external {
    vm.assume(_words.length > 0);
    bytes memory data = abi.encodePacked(_words);
    bytes memory encoded = vm.encodeExtra("FLAG_NESTED_N_WORDS", data)
      .useStorage(false)
      .allowOps("FLAG_READ_BYTES32")
      .allowOps("LITERAL_ZERO")
      .run();
    bytes memory decoded = decode(encoded);
    assertEq(data, decoded);
  }

  function test_sequenceAddress(uint8 _weight, address _addr) external {
    bytes memory data = abi.encodePacked(uint8(0x01), _weight, _addr);
    bytes memory encoded = vm.encodeAny(data)
      .useStorage(false)
      .allowOps("FLAG_ADDRESS")
      .allowOps("FLAG_READ_BYTES32")
      .allowOps("LITERAL_ZERO")
      .run();
    bytes memory decoded = decode(encoded);
    assertEq(data, decoded);
  }

  function test_sequenceECDSA(uint8 _weight, bytes32 _p1, bytes32 _p2, bytes2 _p3) external {
    bytes memory data = abi.encodePacked(uint8(0x00), _weight, _p1, _p2, _p3);
    bytes memory encoded = vm.encodeAny(data)
      .useStorage(false)
      .allowOps("FLAG_SIGNATURE")
      .run();
    bytes memory decoded = decode(encoded);
    assertEq(data, decoded);
  }

  function test_sequenceNode(bytes32 _node) external {
    bytes memory data = abi.encodePacked(uint8(0x03), _node);
    bytes memory encoded = vm.encodeAny(data)
      .useStorage(false)
      .allowOps("FLAG_NODE")
      .allowOps("FLAG_READ_BYTES32")
      .allowOps("LITERAL_ZERO")
      .run();
    bytes memory decoded = decode(encoded);
    assertEq(data, decoded);
  }

  function test_sequenceSubdigest(bytes32 _subdigest) external {
    bytes memory data = abi.encodePacked(uint8(0x05), _subdigest);
    bytes memory encoded = vm.encodeAny(data)
      .useStorage(false)
      .allowOps("FLAG_SUBDIGEST")
      .allowOps("FLAG_READ_BYTES32")
      .allowOps("LITERAL_ZERO")
      .run();
    bytes memory decoded = decode(encoded);
    assertEq(data, decoded);
  }

  function test_sequenceDynamicSignature(address _addr, uint8 _weight, bytes memory _sig) external {
    vm.assume(_sig.length < type(uint24).max);
    bytes memory data = abi.encodePacked(_addr, _weight, _sig, uint8(0x03));
    bytes memory expect = abi.encodePacked(uint8(0x02), uint8(_weight), _addr, uint24(_sig.length + 1), _sig, uint8(0x03));
    bytes memory encoded = vm.encodeExtra("SEQUENCE_DYNAMIC_SIGNATURE_PART", data)
      .useStorage(false)
      .run();
    bytes memory decoded = decode(encoded);
    assertEq(expect, decoded);
  }

  function test_sequenceBranchSignature(uint8 _innerWeight, address _innerPart) external {
    bytes memory data = abi.encodePacked(uint8(0x01), _innerWeight, _innerPart);
    bytes memory expected = abi.encodePacked(uint8(0x04), uint24(22), uint8(0x01), _innerWeight, _innerPart);
    bytes memory encoded = vm.encodeExtra("SEQUENCE_BRANCH_SIGNATURE_PART", data)
      .useStorage(false)
      .run();
    bytes memory decoded = decode(encoded);
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
      .useStorage(false)
      .run();
  
    bytes memory decoded = decode(encoded);
    assertEq(expected, decoded);
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
      .useStorage(false) // This treats each signature as a blob of bytes
      .run();
  
    bytes memory decoded = decode(encoded);
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

  function test_sequenceExecute_decode(address _wallet, SequenceTransaction[] memory _txs, uint256 _nonce, bytes memory _signature) external {
    vm.assume(_txs.length > 0 && _txs.length <= 100);

    bytes memory data = abi.encodeWithSelector(0x7a9a1628, _txs, _nonce, _signature);
    bytes memory encoded = vm.encodeSequenceTx("decode", _wallet, data)
      .useStorage(false)
      .run();
    
    bytes memory decoded = decode(encoded);
    assertEq(abi.encodePacked(data, abi.encode(_wallet)), decoded);
  }

  function test_sequenceExecute_call(address _wallet, SequenceTransaction[] memory _txs, uint256 _nonce, bytes memory _signature) external {
    vm.assume(_txs.length > 0 && _txs.length <= 100);
    vm.assume(_wallet != address(this) && _wallet != compressor);

    bytes memory data = abi.encodeWithSelector(0x7a9a1628, _txs, _nonce, _signature);
    bytes memory encoded = vm.encodeSequenceTx("call", _wallet, data)
      .useStorage(false)
      .run();

    vm.expectCall(_wallet, 0, data);

    bytes memory decoded = decode(encoded);
    assertEq(decoded.length, 0);
  }

  function test_call_decode(address _to, bytes memory _data) external {
    bytes memory encoded = vm.encodeCall("decode", _to, _data)
      .useStorage(false)
      .run();

    bytes memory decoded = decode(encoded);
    assertEq(abi.encodePacked(_data, abi.encode(_to)), decoded);
  }

  function test_call_call(address _to, bytes memory _data) external {
    bytes memory encoded = vm.encodeCall("call", _to, _data)
      .useStorage(false)
      .run();

    vm.expectCall(_to, 0, _data);

    bytes memory res = decode(encoded);
    assertEq(res.length, 0);
  }

  function test_calls_decode(Encoder.Call[] calldata _calls) external {
    vm.assume(_calls.length > 0 && _calls.length <= 100);

    bytes memory expected = hex"";
    for (uint i = 0; i < _calls.length; i++) {
      expected = abi.encodePacked(expected, _calls[i].data, abi.encode(_calls[i].to));
    }

    bytes memory encoded = vm.encodeCalls("decode", _calls)
      .useStorage(false)
      .run();

    bytes memory decoded = decode(encoded);
    assertEq(expected, decoded);
  }

  function test_calls_call(Encoder.Call[] memory _calls) external {
    vm.assume(_calls.length > 0 && _calls.length <= 64);

    // Re-hash all `to` so they point to different addresses
    for (uint i = 0; i < _calls.length; i++) {
      _calls[i].to = address(uint160(uint256(keccak256(abi.encodePacked(i, _calls[i].to)))));
    }

    for (uint i = 0; i < _calls.length; i++) {
      vm.expectCall(_calls[i].to, 0, _calls[i].data);
    }

    bytes memory encoded = vm.encodeCalls("call", _calls)
      .useStorage(false)
      .run();

    bytes memory decoded = decode(encoded);
    assertEq(decoded.length, 0);
  }
}
