package main

import (
	"fmt"
	"os"

	"github.com/0xsequence/czip/compressor"
	"github.com/0xsequence/ethkit/go-ethereum/common"
)

func main() {
	args, err := ParseArgs()
	if err != nil {
		fmt.Println(err)
	}

	if len(args.Positional) < 1 {
		fmt.Println("Usage: encode_sequence_tx / encode_call / encode_calls / encode_any / extras")
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
	case "extras":
		res, err = encodeExtras(args)
	default:
		fmt.Println("Usage: encode_sequence_tx / encode_call / encode_calls / encode_any / extras ")
		os.Exit(1)
	}

	if err != nil {
		fmt.Print("Error: ")
		fmt.Println(err)
		os.Exit(1)
	}

	fmt.Println(res)
	os.Exit(0)
}

func encodeAny(args *ParsedArgs) (string, error) {
	buf := compressor.NewBuffer(compressor.METHOD_DECODE_ANY, nil, ParseAllowOpcodes(args), ParseUseStorage(args))

	if len(args.Positional) < 2 {
		return "", fmt.Errorf("usage: encode_any <hex>")
	}

	input := common.FromHex(args.Positional[1])
	_, err := buf.WriteBytesOptimized(input, true)
	if err != nil {
		return "", err
	}

	return fmt.Sprintf("0x%x", buf.Commited), nil
}

func encodeCalls(args *ParsedArgs) (string, error) {
	return "", fmt.Errorf("Not implemented")
}

func encodeCall(args *ParsedArgs) (string, error) {
	return "", fmt.Errorf("Not implemented")
}

func encodeSequenceTx(args *ParsedArgs) (string, error) {
	return "", fmt.Errorf("Not implemented")
}
