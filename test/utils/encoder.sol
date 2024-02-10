pragma solidity ^0.8.0;

import "forge-std/Vm.sol";

library Encoder {
  struct CommandBuffer {
    Vm vm;
    string[] commands;
  }

  function encodeAny(Vm _vm, bytes memory _data) internal pure returns (CommandBuffer memory) {
    string[] memory inputs = new string[](3);
    inputs[0] = "./run_encoder.sh";
    inputs[1] = "encode_any";
    inputs[2] = _vm.toString(_data);
    return CommandBuffer(_vm, inputs);
  }

  function encodeExtra(Vm _vm, string memory _extra, bytes memory _data) internal pure returns (CommandBuffer memory) {
    string[] memory inputs = new string[](4);
    inputs[0] = "./run_encoder.sh";
    inputs[1] = "extras";
    inputs[2] = _extra;
    inputs[3] = _vm.toString(_data);
    return CommandBuffer(_vm, inputs);
  }

  function useStorage(CommandBuffer memory buffer, bool use) internal pure returns (CommandBuffer memory) {
    string[] memory inputs = new string[](buffer.commands.length + 2);
    for (uint i = 0; i < buffer.commands.length; i++) {
      inputs[i] = buffer.commands[i];
    }
    inputs[buffer.commands.length] = "--use-storage";
    inputs[buffer.commands.length + 1] = use ? "true" : "false";
    return CommandBuffer(buffer.vm, inputs);
  }

  function allowOps(CommandBuffer memory buffer, string memory ops) internal pure returns (CommandBuffer memory) {
    string[] memory inputs = new string[](buffer.commands.length + 2);

    bool hasCommand = false;

    for (uint i = 0; i < buffer.commands.length; i++) {
      inputs[i] = buffer.commands[i];
      if (keccak256(bytes(buffer.commands[i])) == keccak256(bytes("--allow-opcodes"))) {
        // Add ",ops" to the command after this
        inputs[i + 1] = string(abi.encodePacked(buffer.commands[i + 1], ",", ops));
        hasCommand = true;
        i++;
      }
    }

    if (!hasCommand) {
      inputs[buffer.commands.length] = "--allow-opcodes";
      inputs[buffer.commands.length + 1] = ops;
    }

    return CommandBuffer(buffer.vm, inputs);
  }

  function forbidOps(CommandBuffer memory buffer, string memory ops) internal pure returns (CommandBuffer memory) {
    string[] memory inputs = new string[](buffer.commands.length + 2);

    bool hasCommand = false;

    for (uint i = 0; i < buffer.commands.length; i++) {
      inputs[i] = buffer.commands[i];
      if (keccak256(bytes(buffer.commands[i])) == keccak256(bytes("--disallow-opcodes"))) {
        // Add ",ops" to the command after this
        inputs[i + 1] = string(abi.encodePacked(buffer.commands[i + 1], ",", ops));
        hasCommand = true;
        i++;
      }
    }

    if (!hasCommand) {
      inputs[buffer.commands.length] = "--disallow-opcodes";
      inputs[buffer.commands.length + 1] = ops;
    }

    return CommandBuffer(buffer.vm, inputs);
  }

  function run(CommandBuffer memory buffer) internal returns (bytes memory) {
    bytes memory res = buffer.vm.ffi(buffer.commands);

    // If string(res) starts with Error: then revert with the error message
    if (res.length >= 6) {
      bool isError = true;
      bytes memory prefix = bytes("Error:");
      for (uint i = 0; i < prefix.length; i++) {
        if (res[i] != prefix[i]) {
          isError = false;
          break;
        }
      }

      if (isError) {
        revert(string(res));
      }
    }

    return res;
  }
}
