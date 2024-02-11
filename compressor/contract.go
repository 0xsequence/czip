package compressor

import (
	"context"
	"encoding/binary"
	"fmt"
	"math/big"

	"github.com/0xsequence/ethkit/ethrpc"
	"github.com/0xsequence/ethkit/go-ethereum"
	"github.com/0xsequence/ethkit/go-ethereum/common"
)

func AddressIndex(i uint) []byte {
	padded32 := make([]byte, 32)
	binary.BigEndian.PutUint64(padded32[24:32], uint64(i+1))
	return padded32
}

func Bytes32Index(i uint) []byte {
	padded32 := make([]byte, 32)
	binary.BigEndian.PutUint64(padded32[8:16], uint64(i))
	return padded32
}

func GetTotals(ctx context.Context, provider *ethrpc.Provider, contract common.Address, skipBlocks uint) (uint, uint, error) {
	// Get the last block
	block, err := provider.BlockNumber(ctx)
	if err != nil {
		return 0, 0, err
	}

	block -= uint64(skipBlocks)

	res, err := provider.CallContract(ctx, ethereum.CallMsg{
		To:   &contract,
		Data: []byte{byte(METHOD_READ_SIZES)},
	}, big.NewInt(int64(block)))

	if err != nil {
		return 0, 0, err
	}

	// First 16 bytes are the total number of addresses
	// Next 16 bytes are the total number of bytes32

	// Read only an uint64, since there will be no more than 2^64 addresses
	asize := uint(binary.BigEndian.Uint64(res[8:16])) + 1
	bsize := uint(binary.BigEndian.Uint64(res[24:32])) + 1

	return asize, bsize, nil
}

func LoadState(ctx context.Context, provider *ethrpc.Provider, contract common.Address, batchSize uint, skipa uint, skipb uint, skipBlocks uint) (uint, map[string]uint, uint, map[string]uint, error) {
	ah, addresses, err := LoadAddresses(ctx, provider, contract, batchSize, skipa, skipBlocks)
	if err != nil {
		return 0, nil, 0, nil, err
	}

	bh, bytes32, err := LoadBytes32(ctx, provider, contract, batchSize, skipb, skipBlocks)
	if err != nil {
		return 0, nil, 0, nil, err
	}

	return ah, addresses, bh, bytes32, nil
}

func LoadAddresses(ctx context.Context, provider *ethrpc.Provider, contract common.Address, batchSize uint, skip uint, skipBlocks uint) (uint, map[string]uint, error) {
	// Load total number of addresses
	asize, _, err := GetTotals(ctx, provider, contract, skipBlocks)
	if err != nil {
		return 0, nil, err
	}

	return LoadStorage(ctx, provider, contract, batchSize, skip, asize, AddressIndex)
}

func LoadBytes32(ctx context.Context, provider *ethrpc.Provider, contract common.Address, batchSize uint, skip uint, skipBlocks uint) (uint, map[string]uint, error) {
	// Always skip index 0 for bytes32, it maps to the size slot
	// it technically can be used, but it is not write-once, so
	// it will lead to decompression errors
	if skip == 0 {
		skip = 1
	}

	// Load total number of bytes32
	_, bsize, err := GetTotals(ctx, provider, contract, skipBlocks)
	if err != nil {
		return 0, nil, err
	}

	return LoadStorage(ctx, provider, contract, batchSize, skip, bsize, Bytes32Index)
}

func LoadStorage(ctx context.Context, provider *ethrpc.Provider, contract common.Address, batchSize uint, skip uint, total uint, itemplate func(uint) []byte) (uint, map[string]uint, error) {
	out := make(map[string]uint)

	for i := skip; i < total; i += batchSize {
		batch := GenBatch(i, total, batchSize, itemplate)

		res, err := provider.CallContract(ctx, ethereum.CallMsg{
			To:   &contract,
			Data: append([]byte{byte(METHOD_READ_STORAGE_SLOTS)}, batch...),
		}, nil)

		if err != nil {
			return 0, nil, err
		}

		err = ParseBatchResult(out, res, i)
		if err != nil {
			return 0, nil, err
		}
	}

	return total, out, nil
}

func GenBatch(from uint, to uint, max uint, itemplate func(uint) []byte) []byte {
	var end uint

	if to < max {
		end = to
	} else {
		end = max
	}

	indexes := make([]byte, end*32)

	for j := uint(0); j < end; j++ {
		copy(indexes[j*32:j*32+32], itemplate(from+j))
	}

	return indexes
}

func ParseBatchResult(to map[string]uint, res []byte, offset uint) error {
	if len(res)%32 != 0 {
		return fmt.Errorf("invalid result length")
	}

	for j := uint(0); j < uint(len(res)/32); j++ {
		// Ignore results that all 0s
		r := res[j*32 : j*32+32]
		allZero := true
		for i := 31; i >= 0; i-- {
			if r[i] != 0 {
				allZero = false
				break
			}
		}
		if !allZero {
			to[string(res[j*32:j*32+32])] = j + offset
		}
	}

	return nil
}
