package main

import (
	"fmt"
	"os"
	"strings"

	encoder "github.com/0xsequence/czip/compressor"
	"github.com/0xsequence/ethkit/ethrpc"
	"github.com/0xsequence/ethkit/go-ethereum/common"
)

type ParsedArgs struct {
	Positional []string
	Flags      map[string]string
}

func ParseArgs() (*ParsedArgs, error) {
	res := &ParsedArgs{}

	// Read args from os.Args
	args := os.Args[1:]

	var i int
	for i = 0; i < len(args); i++ {
		if len(args[i]) > 2 && args[i][0] == '-' && args[i][1] == '-' {
			// Parse the flag and its value
			flag := args[i][2:]
			if len(args) <= i+1 {
				return nil, fmt.Errorf("flag %s has no value", flag)
			}
			value := args[i+1]
			i++

			// Add the flag to the map
			if res.Flags == nil {
				res.Flags = make(map[string]string)
			}

			res.Flags[flag] = value
		} else {
			// Add the positional argument
			res.Positional = append(res.Positional, args[i])
		}
	}

	return res, nil
}

func FindOpcodesForFlag(flag string) []uint {
	res := make([]uint, 0)

	for val, op := range encoder.FlagNames() {
		// Fuzzy match
		if strings.Contains(strings.ToLower(val), strings.ToLower(flag)) {
			res = append(res, op)
		}
	}

	if len(res) == 0 {
		fmt.Println("Error: Invalid opcode flag", flag)
		os.Exit(1)
	}

	return res
}

func ParseUseStorage(args *ParsedArgs) bool {
	// One possible flag `--use-storage`
	// If defined, then return true, otherwise false
	val := strings.ToLower(args.Flags["use-storage"])

	switch val {
	case "":
		return false
	case "true":
		return true
	case "false":
		return false
	}

	fmt.Println("Invalid value for use-storage")
	os.Exit(1)
	return false
}

func ParseProvider(args *ParsedArgs) (*ethrpc.Provider, error) {
	val := args.Flags["provider"]
	if val == "" {
		return nil, nil
	}

	provider, err := ethrpc.NewProvider(val)
	if err != nil {
		return nil, err
	}

	return provider, nil
}

func ParseContractAddress(args *ParsedArgs) (common.Address, error) {
	val := args.Flags["contract"]
	if val == "" {
		return common.Address{}, fmt.Errorf("missing contract address")
	}

	return common.HexToAddress(val), nil
}

func ParseAllowOpcodes(args *ParsedArgs) *encoder.AllowOpcodes {
	// Two possible flags `--allow-opcodes` and `--disallow-opcodes`
	// values are separated by commas, and expressed as strings
	// e.g. `--allow-opcodes SIGNATURE_W4,SIG_NO_CHAIN`
	// If allow is defined, then default is disallow
	// and vice versa, both cannot be defined at the same time
	allow := args.Flags["allow-opcodes"]
	disallow := args.Flags["disallow-opcodes"]

	if allow != "" && disallow != "" {
		fmt.Println("Cannot define both allow-opcodes and disallow-opcodes")
		os.Exit(1)
	}

	if allow == "" && disallow == "" {
		return nil
	}

	var res encoder.AllowOpcodes
	res.List = make(map[uint]bool)
	var val string

	if allow != "" {
		val = allow
		res.Default = false
	} else {
		val = disallow
		res.Default = true
	}

	parts := strings.Split(val, ",")
	for _, part := range parts {
		opcodes := FindOpcodesForFlag(part)
		for _, opcode := range opcodes {
			res.List[opcode] = true
		}
	}

	return &res
}
