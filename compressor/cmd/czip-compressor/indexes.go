package main

import (
	"context"
	"encoding/json"
	"fmt"
	"os"

	"github.com/0xsequence/czip/compressor"
	"github.com/0xsequence/ethkit/go-ethereum/common"
)

func LoadCachedData(path string) (*compressor.Indexes, error) {
	// See if the file exists, if it doesn't, return a new Indexes obj.
	if _, err := os.Stat(path); os.IsNotExist(err) {
		return &compressor.Indexes{
			AddressIndexes: make(map[string]uint),
			Bytes32Indexes: make(map[string]uint),
		}, nil
	}

	// Load the file
	dat, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}

	// Parse the JSON
	tmp := &compressor.Indexes{
		AddressIndexes: make(map[string]uint),
		Bytes32Indexes: make(map[string]uint),
	}

	err = json.Unmarshal(dat, tmp)
	if err != nil {
		return nil, err
	}

	return fromHumanReadable(tmp), nil
}

func SaveCachedData(path string, data *compressor.Indexes) error {
	// Convert to human readable
	tmp := toHumanReadable(data)

	// Marshal the JSON
	dat, err := json.Marshal(tmp)
	if err != nil {
		return err
	}

	// Write the file
	return os.WriteFile(path, dat, 0644)
}

func fromHumanReadable(from *compressor.Indexes) *compressor.Indexes {
	next := &compressor.Indexes{
		AddressIndexes: make(map[string]uint),
		Bytes32Indexes: make(map[string]uint),
	}

	for k, v := range from.AddressIndexes {
		next.AddressIndexes[string(common.FromHex(k))] = v
	}

	for k, v := range from.Bytes32Indexes {
		next.Bytes32Indexes[string(common.FromHex(k))] = v
	}

	return next
}

func toHumanReadable(from *compressor.Indexes) *compressor.Indexes {
	next := &compressor.Indexes{
		AddressIndexes: make(map[string]uint),
		Bytes32Indexes: make(map[string]uint),
	}

	for k, v := range from.AddressIndexes {
		next.AddressIndexes[common.Bytes2Hex([]byte(k))] = v
	}

	for k, v := range from.Bytes32Indexes {
		next.Bytes32Indexes[common.Bytes2Hex([]byte(k))] = v
	}

	return next
}

func UseIndexes(ctx context.Context, args *ParsedArgs) (*compressor.Indexes, error) {
	var indexes *compressor.Indexes

	if ParseUseStorage(args) {
		provider, err := ParseProvider(args)
		if err != nil {
			return nil, err
		}

		if provider == nil {
			return nil, fmt.Errorf("provider is required")
		}

		chainId, err := provider.ChainID(ctx)
		if err != nil {
			return nil, err
		}

		// Load the cache file
		var path string
		if flag, ok := args.Flags["cache-file"]; ok {
			path = flag
		} else {
			path = fmt.Sprintf("/tmp/czip-indexes-%d.json", chainId)
		}

		indexes, err = LoadCachedData(path)
		if err != nil {
			return nil, err
		}

		contract, err := ParseContractAddress(args)
		if err != nil {
			return nil, err
		}

		if contract == (common.Address{}) {
			return nil, fmt.Errorf("contract address is required")
		}

		// Get the highest indexes for addresses and bytes32
		var maxAddressIndex uint
		var maxBytes32Index uint

		for _, v := range indexes.AddressIndexes {
			if v > maxAddressIndex {
				maxAddressIndex = v
			}
		}

		for _, v := range indexes.Bytes32Indexes {
			if v > maxBytes32Index {
				maxBytes32Index = v
			}
		}

		// Fetch the state
		_, ra, _, rb, err := compressor.LoadState(ctx, provider, contract, 2048, maxAddressIndex, maxBytes32Index, 0)
		if err != nil {
			return nil, err
		}

		// Update the indexes
		for k, v := range ra {
			indexes.AddressIndexes[k] = v
		}

		for k, v := range rb {
			indexes.Bytes32Indexes[k] = v
		}

		// Save the cache file
		err = SaveCachedData(path, indexes)
		if err != nil {
			return nil, err
		}
	} else {
		indexes = &compressor.Indexes{
			AddressIndexes: make(map[string]uint),
			Bytes32Indexes: make(map[string]uint),
		}
	}

	indexes.Bytes4Indexes = compressor.LoadBytes4()

	return indexes, nil
}
