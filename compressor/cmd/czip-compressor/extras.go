package main

import (
	"fmt"

	encoder "github.com/0xsequence/czip/compressor"
	"github.com/0xsequence/ethkit/go-ethereum/common"
)

func EncodeExtras(args *ParsedArgs) (string, error) {
	if len(args.Positional) < 3 {
		return "", fmt.Errorf("usage: encode_extra <code> <hex>")
	}

	data := common.FromHex(args.Positional[2])

	buf := encoder.NewBuffer(encoder.METHOD_DECODE_ANY, nil, ParseAllowOpcodes(args), ParseUseStorage(args))

	switch args.Positional[1] {
	case "FLAG_NESTED_N_WORDS":
		buf.WriteNWords(data)

	default:
		return "", fmt.Errorf("unknown extra: %s", args.Positional[1])
	}

	return fmt.Sprintf("0x%x", buf.Commited), nil
}
