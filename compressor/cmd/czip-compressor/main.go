package main

import (
	"context"
	"fmt"
	"os"

	"github.com/0xsequence/czip/compressor"
	"github.com/0xsequence/ethkit/go-ethereum/common"
	"github.com/0xsequence/go-sequence"
)

func main() {
	args, err := ParseArgs()
	if err != nil {
		fmt.Println(err)
	}

	if len(args.Positional) < 1 {
		fmt.Printf("Usage (%s): encode_sequence_tx / encode_call / encode_calls / encode_any / extras\n", compressor.VERSION)
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
	indexes, err := UseIndexes(context.Background(), args)
	if err != nil {
		return "", err
	}

	buf := compressor.NewBuffer(compressor.METHOD_DECODE_ANY, indexes, ParseAllowOpcodes(args), ParseUseStorage(args))

	if len(args.Positional) < 2 {
		return "", fmt.Errorf("usage: encode_any <hex>")
	}

	input := common.FromHex(args.Positional[1])
	_, err = buf.WriteBytesOptimized(input, true)
	if err != nil {
		return "", err
	}

	return fmt.Sprintf("0x%x", buf.Commited), nil
}

func encodeCalls(args *ParsedArgs) (string, error) {
	if len(args.Positional) < 2 {
		return "", fmt.Errorf("usage: encode_calls <action> <hex> <addr> <hex> <addr> ... <hex> <addr>")
	}

	if len(args.Positional)%2 != 0 {
		return "", fmt.Errorf("invalid number of arguments")
	}

	action := args.Positional[1]
	if action != "decode" && action != "call" {
		return "", fmt.Errorf("invalid action: %s", action)
	}

	var method uint
	if action == "decode" {
		method = compressor.METHOD_DECODE_N_CALLS
	} else if action == "call" {
		method = compressor.METHOD_EXECUTE_N_CALLS
	} else {
		return "", fmt.Errorf("unsupported action: %s", action)
	}

	datas := make([][]byte, (len(args.Positional)-2)/2)
	addrs := make([][]byte, (len(args.Positional)-2)/2)

	for i := 2; i < len(args.Positional); i += 2 {
		datas[i/2-1] = common.FromHex(args.Positional[i])
		addrs[i/2-1] = common.HexToAddress(args.Positional[i+1]).Bytes()
	}

	indexes, err := UseIndexes(context.Background(), args)
	if err != nil {
		return "", err
	}

	buf := compressor.NewBuffer(method, indexes, ParseAllowOpcodes(args), ParseUseStorage(args))
	_, err = buf.WriteCalls(addrs, datas)
	if err != nil {
		return "", err
	}

	return fmt.Sprintf("0x%x", buf.Commited), nil
}

func encodeCall(args *ParsedArgs) (string, error) {
	action, data, addr, err := ParseCommonArgs(args)
	if err != nil {
		return "", err
	}

	var method uint
	if action == "decode" {
		method = compressor.METHOD_DECODE_CALL
	} else if action == "call" {
		method = compressor.METHOD_EXECUTE_CALL
	} else {
		method = compressor.METHOD_EXECUTE_CALL_RETURN
	}

	indexes, err := UseIndexes(context.Background(), args)
	if err != nil {
		return "", err
	}

	buf := compressor.NewBuffer(method, indexes, ParseAllowOpcodes(args), ParseUseStorage(args))
	_, err = buf.WriteCall(addr, data)
	if err != nil {
		return "", err
	}

	return fmt.Sprintf("0x%x", buf.Commited), nil
}

func encodeSequenceTx(args *ParsedArgs) (string, error) {
	action, data, addr, err := ParseCommonArgs(args)
	if err != nil {
		return "", err
	}

	txs, nonce, sig, err := sequence.DecodeExecdata(data)
	if err != nil {
		return "", err
	}

	var method uint
	if action == "decode" {
		method = compressor.METHOD_DECODE_SEQUENCE_TX
	} else if action == "call" {
		method = compressor.METHOD_EXECUTE_SEQUENCE_TX
	} else {
		return "", fmt.Errorf("unsupported action: %s", action)
	}

	indexes, err := UseIndexes(context.Background(), args)
	if err != nil {
		return "", err
	}

	buf := compressor.NewBuffer(method, indexes, ParseAllowOpcodes(args), ParseUseStorage(args))
	_, err = buf.WriteSequenceExecute(addr, &sequence.Transaction{
		Nonce:        nonce,
		Transactions: txs,
		Signature:    sig,
	})

	if err != nil {
		return "", err
	}

	return fmt.Sprintf("0x%x", buf.Commited), nil
}

func ParseCommonArgs(args *ParsedArgs) (string, []byte, []byte, error) {
	if len(args.Positional) < 4 {
		return "", nil, nil, fmt.Errorf("usage: <decode/call/call-return> <data> <addr>")
	}

	action := args.Positional[1]
	if action != "decode" && action != "call" && action != "call-return" {
		return "", nil, nil, fmt.Errorf("invalid action: %s", action)
	}

	data := common.FromHex(args.Positional[2])
	addr := common.HexToAddress(args.Positional[3])

	return action, data, addr.Bytes(), nil
}
