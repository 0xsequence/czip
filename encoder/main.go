package main

import (
	"fmt"
	"os"

	"github.com/0xsequence/compressor/encoder/cmd"
	encoder "github.com/0xsequence/compressor/encoder/lib"
	"github.com/0xsequence/ethkit/go-ethereum/common"
)

func main() {
	args, err := cmd.ParseArgs()
	if err != nil {
		fmt.Println(err)
	}

	if len(args.Positional) < 1 {
		fmt.Println("Usage: encode_sequence_tx / encode_call / encode_calls / encode_any ")
		os.Exit(1)
	}

	var res string

	switch args.Positional[0] {
	case "encode_sequence_tx":
		res, err = encodeSequenceTx(args)
	case "encode_call":
		res, err = encodeCall(args)
	case "encode_calls":
		res, err = encodeCalls(args)
	case "encode_any":
		res, err = encodeAny(args)
	default:
		fmt.Println("Usage: encode_sequence_tx / encode_call / encode_calls / encode_any ")
		os.Exit(1)
	}

	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	fmt.Println(res)
	os.Exit(0)
}

func encodeAny(args *cmd.ParsedArgs) (string, error) {
	buf := encoder.NewBuffer(encoder.METHOD_DECODE_ANY, nil, false)

	if len(args.Positional) < 2 {
		return "", fmt.Errorf("usage: encode_any <hex>")
	}

	input := common.FromHex(args.Positional[1])
	buf.WriteBytesOptimized(input, true)
	return fmt.Sprintf("0x%x", buf.Commited), nil
}

func encodeCalls(args *cmd.ParsedArgs) (string, error) {
	return "", fmt.Errorf("Not implemented")
}

func encodeCall(args *cmd.ParsedArgs) (string, error) {
	return "", fmt.Errorf("Not implemented")
}

func encodeSequenceTx(args *cmd.ParsedArgs) (string, error) {
	return "", fmt.Errorf("Not implemented")
}
