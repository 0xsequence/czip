CZIP: EVM Calldata Zip
======================

![CZIP 😈](./logo.png)

**czip** is a utility for compressing and decompressing EVM calldata. It is designed to be used in L2s to trade off calldata size for computation cost.

The primary component of czip is the `decompressor.huff` contract, which is a Huff contract that inflates the calldata. It works by implementing a simple state machine that, in a single pass, decompresses the input. The operations of the state machine are specifically designed to work with EVM calldata.

A companion `czip-compressor` tool is provided to compress calldata. It is a simple command-line tool that **does not** perform perfect compression but provides a good starting point for starting to use the `decompressor.huff` contract.

## Install

TODO

## Usage

The compressor has the following commands:

- `encode-call <decode/call/call-return> <hex_data> <addr>` Compresses a call to `addr` with `hex_data`.
- `encode-calls <decode/call> <hex_data_1> <addr_1> <hex_data_2> <addr_2> ...` Compresses multiple calls into one payload.
- `encode-any <data>` Encodes any data into a compressed representation.
- `encode-sequence-tx <decode/call> <sequence_tx> <sequence_wallet>` Compresses a Sequence wallet transaction.

```
czip-compressor is a tool for compressing Ethereum calldata. The compressed data can be decompressed using the decompressor contract.

Usage:
  czip-compressor [command]

Available Commands:
  completion         Generate the autocompletion script for the specified shell
  encode-any         Compress any calldata: <hex>
  encode-call        Compress a call to a contract: <data> <to>
  encode-calls       Compress multiple calls to many contracts: <data> <to> <data> <to> ... <data> <to>
  encode-sequence-tx Compress a Sequence Wallet transaction
  extras             Additional encoding methods, used for testing and debugging.
  help               Help about any command

Flags:
      --allow-opcodes strings      Will only encode using these operations, separated by commas.
      --cache-dir string           Path to the cache dir for indexes. (default "/tmp/czip-cache")
  -c, --contract string            Contract address of the decompressor contract.
      --disallow-opcodes strings   Will not encode using these operations, separated by commas.
  -h, --help                       help for czip-compressor
  -p, --provider string            Ethereum RPC provider URL.
  -s, --use-storage                Use stateful read/write storage during compression.

Use "czip-compressor [command] --help" for more information about a command.
```

### Encode call

It encodes a single call to a contract, the subcommands are:

- `decode` Generates a payload that, when sent to the `decompressor.huff` contract, will decompress the calldata and return the caller, without performing the call.
- `call` Generates a payload that, when sent to the `decompressor.huff` contract, will decompress the calldata and perform the call, ignoring the return value.
- `call-return` Generates a payload that, when sent to the `decompressor.huff` contract, will decompress the calldata and perform the call, returning the return value.

```cmd
czip-compressor encode-call decode \
0xa9059cbb0000000000000000000000008bf74fb902cdad5d2d8ca0d3bbc7bb16894b9c350000000000000000000000000000000000000000000000000000000006052340 \
0xdAC17F958D2ee523a2206206994597C13D831ec7

> 0x0b3701148bf74fb902cdad5d2d8ca0d3bbc7bb16894b9c35332bf214dac17f958d2ee523a2206206994597c13d831ec7
```

### Encode Calls

It encodes multiple calls to contracts, the subcommands are:

- `decode` Generates a payload that, when sent to the `decompressor.huff` contract, will decompress all calls and return them decompressed, without performing the calls.
- `call` Generates a payload that, when sent to the `decompressor.huff` contract, will decompress the calls and perform them, ignoring the return values.

Notice that the `call-return` subcommand is not available in this mode.

```cmd
czip-compressor encode-calls decode \
  0xa9059cbb0000000000000000000000009813d80d0686406b79c29b2b8a672a13725facb300000000000000000000000000000000000000000000000ae56f730e6d840000 \
  0xdac17f958d2ee523a2206206994597c13d831ec7 \
  0x095ea7b30000000000000000000000007c56be0ad3128acc33190484cd1badebc8c76240ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff \
  0xdac17f958d2ee523a2206206994597c13d831ec7

> 0x0c023701149813d80d0686406b79c29b2b8a672a13725facb3338fda14dac17f958d2ee523a2206206994597c13d831ec73702147c56be0ad3128acc33190484cd1badebc8c7624031ff3d001c
```

> Compressing multiple calls into one payload is more efficient than compressing each call individually, as data can be de-duplicated and the overhead of the decompressor is amortized over multiple calls.

### Encode Any

It encodes any data into a compressed representation. Sending the payload to the `decompressor.huff` contract will return the original data.

```cmd
czip-compressor encode-any \
  0x0000000000000000000000000000000000000000000000012a5f58168ee60000

> 0x0d3388d7
```

### Encode Sequence Transaction

It works similarly to `encode-calls`, but it is specifically designed to compress a Sequence wallet transaction. It expects the data to be a Sequence Transaction ABI-encoded.

## Using storage indexes

By default all commands run with `--use-storage false`, which means that the decompressor won't write any data to the storage, or read any addresses or bytes32 using indexes.

Storage indexes can be enabled using the following flags:

- `--use-storage true` Enables the use of storage indexes.
- `--contract <address>` An instance of the `decompressor.huff` contract to use for storage indexes.
- `--provider <provider>` The provider from which to fetch the pointers.

Notice that a cache on `/tmp/czip-cache/czip-indexes-<chain-id>.json` is automatically created to avoid fetching the same pointers multiple times. The cache dir can be changed using the `--cache-dir` flag.

### Example

```cmd
czip-compressor encode-call decode \
  0xa9059cbb000000000000000000000000963752cac40e583dea143d6262e24f89c9e1f91100000000000000000000000000000000000000000000000000000000000003fc \
  0x750ba8b76187092B0D1E87E28daaf484d1b5273b

> 0x0b370114963752cac40e583dea143d6262e24f89c9e1f9110203fc14750ba8b76187092b0d1e87e28daaf484d1b5273b

czip-compressor encode-call decode \
  --contract 0x8C5CF0a201C1F0C1517a23699BE48070724e7a70 \
  --provider https://nodes.sequence.app/arbitrum-nova \
  --use-storage \
  0xa9059cbb000000000000000000000000963752cac40e583dea143d6262e24f89c9e1f91100000000000000000000000000000000000000000000000000000000000003fc \
  0x750ba8b76187092B0D1E87E28daaf484d1b5273b

> 0x0b37012700010203fc270002
```

See it in action: https://nova.arbiscan.io/tx/0x86e7b4177c0d219a87cc58f93ae2ecf2f490a719119c283f61cdc88585cc7c7b

## How to decompress

Sending the generated payload to the `decompressor.huff` will either return the decompressed data or perform the call (depending on the command used to generate the payload).

The `decompressor.huff` contract has no selectors; the data does not need to be re-encoded and can be sent directly to the contract.

### Cast example

Try running the following command; it will inflate the data and return the original call data. You can do the same thing on-chain.

```cmd
cast call \
  --rpc-url https://nodes.sequence.app/arbitrum-nova \
  0x8C5CF0a201C1F0C1517a23699BE48070724e7a70 \
  0x0b37012700010203fc270002

> 0xa9059cbb000000000000000000000000963752cac40e583dea143d6262e24f89c9e1f91100000000000000000000000000000000000000000000000000000000000003fc000000000000000000000000750ba8b76187092b0d1e87e28daaf484d1b5273b
```

### Solidity example

Decompressing on-chain is as simple as calling the decompressor contract with the payload.

```solidity
contract YourContract {
  event WeGotData(bytes data);

  function doSomething(bytes calldata _compressed) external {
    (bool ok, bytes memory data) = address(0x8C5CF0a201C1F0C1517a23699BE48070724e7a70).call(_compressed);
    require(ok, "Decompression failed");
    emit WeGotData(data);
  }
}
```

Notice that if the data was compressed using the `call` command, the compressor will not return the decompressed data; it will perform the call. In this example, we used the `decode` command, so the data will be returned.

## Compression gains

The compression gains are highly dependent on the ratio of computation cost to calldata cost of a given network. It is most effective on "rollup" style L2s, but it can also achieve some small gains on some other networks.

| Network       | Decompressor Address                       | Savings  |
|---------------|--------------------------------------------|----------|
| Arbitrum      | 0x8C5CF0a201C1F0C1517a23699BE48070724e7a70 | ~50%     |
| Optimism      | 0x8C5CF0a201C1F0C1517a23699BE48070724e7a70 | ~50%     |
| Base          | 0x8C5CF0a201C1F0C1517a23699BE48070724e7a70 | ~50%     |
| Arbitrum Nova | 0x8C5CF0a201C1F0C1517a23699BE48070724e7a70 | ~15%     |
| Polygon       | --                                         | Negative |
| Ethereum      | --                                         | Negative |
| Polygon zkEVM | --                                         | Negative |

The following benchmarking transactions are from the Arbitrum network, they show savings of ~50% in gas costs. The savings account for the cost of the decompressor contract, notice that they use an older version of the compressor, but the inner workings are the same.

![Sending ETH cost comparation](https://ipfs.io/ipfs/QmbJ3rZRdUyie8bpF7tbDHK5acqU7ncigsNLqJvW6qZViu?filename=Compressed%20ETH%20transactions%20-%20Sequence%20wallet.svg)

```
Send ETH uncompressed (1st):
0xa0efbb458309f1ccc14035a53e20c36155d722b1c5d991bfa7c43a21174ec468

Send ETH compressed + write storage (1st):
0x9a34d5787b0dd6fba248ebeb407d51526445b496f45f2b4f6ff1d56875f04f7c

Send ETH compressed (1st):
0x6197b0770cdb3efcdb252bf3932ff9964e3467906a7ac1de6361e2d9fe1bb84e

Send ETH uncompressed (2nd):
0x7b519df3f10a0e0ae507d6d18d775f1ed80e65c76df06e5632f402903cd9afb8

Send ETH compressed + write storage (2nd):
0x1680bae9b790bb54d522ebc033da92cb5261b73c27058767c55011957083ea41

Send ETH compressed + write storage (2nd):
0x1ccc93227065df0b9d6acc64504280ad7e55b5823b90111a0b6477c881291de4
```

![Sending ETH cost comparation](https://ipfs.io/ipfs/QmNXyKPgcba7a4bFAMzRsQS3GSgykSD2FkpD9Qpk2FE2oV?filename=Compressed%20ERC20%20transactions%20-%20Sequence%20wallet.svg)

```
Send ERC20 uncompressed:
0x0559ea8161e9cfed3298091d1f7626fe551bd40a38d2ff65d2340a52203e582a

Send ERC20 compressed + write storage:
0xbbf1d0250c37155f2da1d72cc01ff68fb5ccd4b4834a4accf53caf9374e64e3b

Send ERC20 compressed:
0x07e3b4de0b2cd3c8c531e90f32afc7a5dc3691b399ae4ab33d833b3e10741d05

Approve ERC20 uncompressed:
0x03c5f3d5c5a556439215c751a0d84b838266e9ec2481f862a912943e1bc309d6

Aprove ERC20 compressed:
0x7186dcf623d6bf5436691d28c649215900c4c71c2061863b0388786e07299428
```

## Decompressor contract

The `decompressor.huff` serves as the decompressor for all data. It has been carefully designed to be as efficient as possible. It also serves the role of a "repository"; it can store `address` and `bytes32` values that can later be referenced using a pointer.

The contract **does not** follow the Solidity ABI convention. The contract uses a single byte for the function selector. The following functions are available:

- `0x00` Execute sequence transaction.
- `0x01` Execute many sequence transactions.
- `0x02` Fetch one address using a pointer.
- `0x03` Fetch one `bytes32` using a pointer.
- `0x04` Fetch the total number of addresses and `bytes32` stored.
- `0x05` Fetch a list of storage slots.
- `0x06` Decompress a sequence transaction and return the data.
- `0x07` Decompress many sequence transactions and return the data.
- `0x08` Execute a call and ignore the return value.
- `0x09` Execute a call and return the return value.
- `0x0a` Execute many calls and ignore the return values.
- `0x0b` Decompress a call and return the data.
- `0x0c` Decompress many calls and return the data.
- `0x0d` Decompress any data and return the data.

> The `czip-compressor` tool is designed to generate the payloads for the `0x08`, `0x09`, `0x0a`, `0x0b`, `0x0c`, and `0x0d` functions automatically; there is no need to manually prefix the payload with the function selector.

### State machine

The state machine used by the `decompressor.huff` contract allows for a single-pass decompression of the calldata. It reads a single `operation`, but operations can be composed of multiple operations.

The operations are 1 byte long, they may contain any number of arguments, there are 89 operations available. The leftover space is used to express literal values. 

The operations are:

| Code          | Name          | Args   | Description                                                                                  |
|---------------|---------------|--------|----------------------------------------------------------------------------------------------|
| `0x00`          | `NO_OP`         |        | It writes an empty array of bytes to the buffer.                                             |
| `0x01` ... `0x20` | `READ_WORD_*`   | <u*: word> | It reads a word of N bytes, the word is written to the buffer as a left-padded 32 byte word. |
| `0x21`          | `READ_WORD_INV` | <op: READ_WORD>| Reads a (following) READ_WORD operation, but it pads the word to the right.           |
| `0x22`          | `READ_N_BYTES`  | <op: *>   | Reads N bytes from the calldata and writes them to the buffer, the arg is another operation. |
| `0x23`          | `WRITE_ZEROS`   | <u8: size>   | Writes N zeros to the buffer.                                                                 |
| `0x24`          | `NESTED_FLAGS_S` | <u8: len> <...op>   | Executes N operations (max 255). |
| `0x25`          | `NESTED_FLAGS_L` | <u16: len> <...op>   | Executes N operations. |
| `0x26`          | `SAVE_ADDRESS`  | <u160: addr> | Saves an address on the repository, it writes the address to the buffer (padding to 32 bytes). |
| `0x27`          | `READ_ADDRESS_2` | <u16: pointer> | Reads an address from the respository into the buffer, it uses 2 bytes for the pointer. |
| `0x28`          | `READ_ADDRESS_3` | <u24: pointer> | Reads an address from the respository into the buffer, it uses 3 bytes for the pointer. |
| `0x29`          | `READ_ADDRESS_4` | <u32: pointer> | Reads an address from the respository into the buffer, it uses 4 bytes for the pointer. |
| `0x2a`          | `WRITE_BYTES32`  | <u256: bytes32> | Saves a bytes32 on the respository, it writes the value to the buffer. |
| `0x2b`          | `READ_BYTES32_2` | <u16: pointer> | Reads a bytes32 from the respository into the buffer, it uses 2 bytes for the pointer. |
| `0x2c`          | `READ_BYTES32_3` | <u24: pointer> | Reads a bytes32 from the respository into the buffer, it uses 3 bytes for the pointer. |
| `0x2d`          | `READ_BYTES32_4` | <u32: pointer> | Reads a bytes32 from the respository into the buffer, it uses 4 bytes for the pointer. |
| `0x2e`          | `READ_STORE_FLAG_S` | <u16: calldata_pointer> | Reads an "storage" flag, the pointer is absolute, it only writes the value to the buffer. |
| `0x2f`          | `READ_STORE_FLAG_L` | <u24: calldata_pointer> | Reads an "storage" flag, the pointer is absolute, it only writes the value to the buffer. |
| `0x30`          | `POW_2` | <u8: exponent> | Writes 2^N to the buffer, padded left to 32 bytes. |
| `0x31`          | `POW_2_MINUS_1` | <u8: exponent> | Writes (2^(N + 1)) - 1 to the buffer, padded left to 32 bytes. |
| `0x32`          | `POW_10` | <u8: exponent> | Writes 10^N to the buffer, padded left to 32 bytes. |
| `0x33`          | `POW_10_MANTISSA_S` | <u5: exponent> <u11: mantissa> | Writes 10^N * M to the buffer, padded left to 32 bytes. |
| `0x34`          | `POW_10_MANTISSA_L` | <u6: exponent> <u18: mantissa> | Writes 10^N * M to the buffer, padded left to 32 bytes. |
| `0x35`          | `ABI_0_PARAM` | \<selector\> | Writes the ABI-encoded selector for a function with 0 parameters to the buffer. |
| `0x36` ... `0x3b` | `ABI_*_PARAM` | \<selector\> <op: arg_1> ... | Writes the ABI-encoded selector for a function with N parameters to the buffer. |
| `0x3c`          | `ABI_DYNAMIC` | \<selector\> <u8: size> <u8: dynamic_bitmap> <op: arg_1> ... | Writes the ABI-encoded selector for a function with dynamic parameters to the buffer, the bitmap determines what arguments are dynamic in size. |
| `0x3d`          | `MIRROR_FLAG_S` | <u16: calldata_pointer> | Re-reads the flag at the given pointer and writes it to the buffer. |
| `0x3e`          | `MIRROR_FLAG_L` | <u24: calldata_pointer> | Re-reads the flag at the given pointer and writes it to the buffer. |
| `0x3f`          | `CALLDATA_S` | <u16: calldata_pointer> <u8: size> | Writes N bytes from the calldata to the buffer, the pointer is absolute. |
| `0x40`          | `CALLDATA_L` | <u24: calldata_pointer> <u8: size> | Writes N bytes from the calldata to the buffer, the pointer is absolute. |
| `0x40`          | `CALLDATA_XL` | <u24: calldata_pointer> <u16: size> | Writes N bytes from the calldata to the buffer, the pointer is absolute. |

#### Sequence Specific Operations

| Code          | Name          | Args   | Description                                                                                  |
|---------------|---------------|--------|----------------------------------------------------------------------------------------------|
| `0x42`        | `SEQUENCE_EXECUTE` | View detail | Writes an ABI encoded Sequence transaction to the buffer. |
| `0x43`        | `SEQUENCE_SELF_EXECUTE` | View detail | Writes an ABI encoded Sequence self execute transaction to the buffer. |
| `0x44` | `SEQUENCE_SIGNATURE_W0` | <u8: weight> <bytes[66]: sig> | Writes a Sequence signature part to the buffer. |
| `0x45` | `SEQUENCE_SIGNATURE_W1` | <bytes[66]: sig> | Writse a Sequence Signature part to the buffer, with static weight 1. |
| `0x46` | `SEQUENCE_SIGNATURE_W2` | <bytes[66]: sig> | Writes a Sequence Signature part to the buffer, with static weight 2. |
| `0x47` | `SEQUENCE_SIGNATURE_W3` | <bytes[66]: sig> | Writes a Sequence Signature part to the buffer, with static weight 3. |
| `0x48` | `SEQUENCE_SIGNATURE_W4` | <bytes[66]: sig> | Writes a Sequence Signature part to the buffer, with static weight 4. |
| `0x49` | `SEQUENCE_ADDRESS_W0` | <u8: weight> <u16: pointer> | Writes a Sequence address flag to the buffer. |
| `0x4a` | `SEQUENCE_ADDRESS_W1` | <u16: pointer> | Writes a Sequence address flag to the buffer, with static weight 1. |
| `0x4b` | `SEQUENCE_ADDRESS_W2` | <u16: pointer> | Writes a Sequence address flag to the buffer, with static weight 2. |
| `0x4c` | `SEQUENCE_ADDRESS_W3` | <u16: pointer> | Writes a Sequence address flag to the buffer, with static weight 3. |
| `0x4d` | `SEQUENCE_ADDRESS_W4` | <u16: pointer> | Writes a Sequence address flag to the buffer, with static weight 4. |
| `0x4e` | `SEQUENCE_NODE` | <op: node> | Writes a Sequence node to the buffer. |
| `0x4f` | `SEQUENCE_BRANCH` | <op: content> | Writes a Sequence branch to the buffer. |
| `0x50` | `SEQUENCE_SUBDIGEST` | <op: subdigest> | Writes a Sequence subdigest to the buffer. |
| `0x51` | `SEQUENCE_NESTED` | <u8: weight> <u8: threshold> <op: content> | Writes a Sequence nested signature part to the buffer. |
| `0x52` | `SEQUENCE_DYNAMIC_SIGNATURE` | <u8: weight> <op: signer> <op: signature> | Writes a Sequence EIP1271 dynamic signature to the buffer. |
| `0x53` | `SEQUENCE_S_SIG_NO_CHAIN` | <u8: weight> <op: checkpoint> <op: signature> | Writes a Sequence signature (chain id 0) to the buffer. |
| `0x54` | `SEQUENCE_S_SIG` | <u8: weight> <op: checkpoint> <op: signature> | Writes a Sequence signature to the buffer. |
| `0x55` | `SEQUENCE_S_L_SIG_NO_CHAIN` | <u16: weight> <op: checkpoint> <op: signature> | Writes a Sequence signature (chain id 0) to the buffer. |
| `0x56` | `SEQUENCE_S_L_SIG` | <u16: weight> <op: checkpoint> <op: signature> | Writes a Sequence signature to the buffer. |
| `0x57` | `SEQUENCE_READ_CHAINED_S` | <u8: size> <op: sig_1> ... | Reads a chained Sequence signature. |
| `0x58` | `SEQUENCE_READ_CHAINED_L` | <u16: size> <op: sig_1> ... | Reads a chained Sequence signature. |

#### Literals

The highest defined operation is `0x58`, the remaining space is used to express literal values. Any operation with a code higher than `0x58` is a literal value.

The first literal flag is `0x59`, which is the literal `0x00`. The next literal flag is `0x5a`, which is the literal `0x01`, and so on. Literals are written to the buffer left-padded to 32 bytes.

#### Array operations

All operations that accept an array of operations **MUST** be used with non-zero arrays, as the decompressor will not handle zero-length arrays correctly. If you need to write a zero-length array, use the `NO_OP` operation.

#### Function selectors

The `decompressor.huff` contract contains a pre-defined set of function selectors, this list has been generated from common selectors used in the Ethereum network. It should account for ~90% of the cases.

If a selector is not in the list, it can be provided as a literal value by prefixing it with `00`, all operations that use selectors accept both indexed and literal values.

#### Sequence Execute

The Sequence Execute operation is the same one used by the Sequence call and decode top level functions, it encodes a Sequence transaction to the buffer, ABI encoded.

It reads the following values:

- `op: nonce_space` The nonce space for the transaction.
- `op: nonce_value` The nonce value for the transaction.
- `u8: len_transactions` The number of transactions in the Sequence transaction.
- `<transactions>` The transactions in the Sequence transaction (see Sequence Transactions).
- `op: signature` The signature of the transaction.

#### Sequence Self Execute

It works similarly to the Sequence Execute operation, but it encodes a Sequence self execute transaction to the buffer, ABI encoded. This operation only has the `<transactions>` value.

#### Sequence Transactions

A Sequence transaction is prefixed by a bitmap byte, this byte determines which values are non-default. The bitmap is as follows:

- `1000 0000` - 1 if it uses delegate call
- `0100 0000` - 1 if it uses revert on error
- `0010 0000` - 1 if it has a defined gas limit
- `0001 0000` - 1 if it has a defined value
- `0000 1000` - Unused
- `0000 0100` - Unused
- `0000 0010` - Unused
- `0000 0001` - 1 if it has a defined data

 Afterwards, the each value is read (only if the corresponding bit is set):
 
- `op: gas_limit` The gas limit for the transaction.
- `op: target` The target for the transaction.
- `op: value` The value for the transaction.
- `op: data` The data for the transaction.

## FAQs

### Can the Huff code be optimized?

It probably can. This is my first time working with Huff, and this is a big contract. I am sure it can be gas-golfed further, but the gains should be minimal.

### Does the compressor always generate the most efficient payload?

No, the compressor is a bit naive in its current form. It should work well for most "common" cases, but it may not pick the best compression for all cases. If you want to improve this tool, I think the biggest gains can be made here.

### Why doesn't it compress using X/Y/Z method?

Because it didn't occur to me. The opcode set has a lot of room left for new operations. If you have a good idea for a new operation, please open an issue.

### Why `callvalue` and not `push0`?

I wanted to support all networks with the same code, and there is no reason to be sending funds to the decompressor contract. Notice that the behavior if `msg.value != 0` is undefined, expect the decompresor to fail if `msg.value != 0`.

### Why not a built-in list of common contracts too?

Again, I wanted the same code for all networks, and "common contracts" will look different on different networks. But it is something that could be added if a single network is the main target.

### Can I reuse the decompressor indexes?

Yes! The decompressor has the `0x05` "function" that allows you to fetch any storage slots from itself. If you build a similar contract, you can use it to fetch the indexes that the decompressor has stored.

### Has this been audited?

No, but it can still be used safely. See the next question.

### How should I use this in my project?

The contract is quite big and could have vulnerabilities, so I would not recommend "trusting" it in your setup. However, you can use it as long as it acts as a "router" or "entrypoint" to some other contract that validates the data, just make sure to have an alternative path for uncompressed data.

---

## Setup dev environment

If you'd like to setup the dev environment to run tests:

1. Install [foundry](https://getfoundry.sh/)
2. Install [huff](https://docs.huff.sh/get-started/installing/)
3. Install [go](https://go.dev/)
4. `make bootstrap`
## Development

If you'd like to develop on the repo, here are some useful commands:

1. `make forge`
2. `make build`
3. `make test`
