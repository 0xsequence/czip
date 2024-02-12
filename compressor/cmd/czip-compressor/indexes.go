package main

import (
	"context"
	"encoding/json"
	"fmt"
	"os"

	"github.com/0xsequence/czip/compressor"
	"github.com/0xsequence/ethkit/ethrpc"
	"github.com/0xsequence/ethkit/go-ethereum/common"
	"github.com/spf13/cobra"
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

func UseIndexes(ctx context.Context, cmd *cobra.Command) (*compressor.Indexes, error) {
	var indexes *compressor.Indexes

	useStorage, err := cmd.Flags().GetBool("use-storage")
	if err != nil {
		return nil, err
	}

	if useStorage {
		providerUrl, err := cmd.Flags().GetString("provider")
		if err != nil {
			return nil, err
		}

		provider, err := ethrpc.NewProvider(providerUrl)
		if err != nil {
			return nil, err
		}

		chainId, err := provider.ChainID(ctx)
		if err != nil {
			return nil, err
		}

		// Load the cache file
		cachePath, err := cmd.Flags().GetString("cache-dir")
		if err != nil {
			return nil, err
		}

		// If path does not exist, create it
		err = ensureDir(cachePath)
		if err != nil {
			return nil, err
		}

		path := fmt.Sprintf("%s/czip-indexes-%d.json", cachePath, chainId)

		indexes, err = LoadCachedData(path)
		if err != nil {
			return nil, err
		}

		contractAddr, err := cmd.Flags().GetString("contract")
		if err != nil {
			return nil, err
		}

		contract := common.HexToAddress(contractAddr)
		if contract == (common.Address{}) {
			return nil, fmt.Errorf("contract address is required, use --contract")
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
