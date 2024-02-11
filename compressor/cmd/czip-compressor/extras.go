package main

import (
	"fmt"

	encoder "github.com/0xsequence/czip/compressor"
	"github.com/0xsequence/ethkit/go-ethereum/common"
)

func encodeExtras(args *ParsedArgs) (string, error) {
	if len(args.Positional) < 3 {
		return "", fmt.Errorf("usage: encode_extra <code> <hex>")
	}

	data := common.FromHex(args.Positional[2])
	buf := encoder.NewBuffer(encoder.METHOD_DECODE_ANY, nil, ParseAllowOpcodes(args), ParseUseStorage(args))

	var err error

	switch args.Positional[1] {
	case "FLAG_SEQUENCE_NESTED_N_WORDS":
		buf.WriteNWords(data)
	case "SEQUENCE_DYNAMIC_SIGNATURE_PART":
		err = encodeSequenceDynamicSignaturePart(buf, data)
	case "SEQUENCE_BRANCH_SIGNATURE_PART":
		buf.WriteSequenceBranchSignaturePart(data)
	case "SEQUENCE_NESTED_SIGNATURE_PART":
		err = encodeSequenceNestedSignaturePart(buf, data)
	case "SEQUENCE_CHAINED_SIGNATURE":
		buf.WriteSequenceChainedSignature(data)

	default:
		return "", fmt.Errorf("unknown extra: %s", args.Positional[1])
	}

	if err != nil {
		return "", err
	}

	return fmt.Sprintf("0x%x", buf.Commited), nil
}

func encodeSequenceDynamicSignaturePart(buf *encoder.Buffer, data []byte) error {
	// 1 byte of type, 20 bytes of address, 1 byte of weight and the rest is the signature
	if len(data) < 21 {
		return fmt.Errorf("invalid data length")
	}

	address := data[:20]
	weight := uint(data[20])
	signature := data[21:]

	buf.WriteSequenceDynamicSignaturePart(address, weight, signature)
	return nil
}

func encodeSequenceNestedSignaturePart(buf *encoder.Buffer, data []byte) error {
	// 1 byte weight, 1 byte threshold, the rest is the signature
	if len(data) < 2 {
		return fmt.Errorf("invalid data length")
	}

	weight := uint(data[0])
	threshold := uint(data[1])
	signature := data[2:]
	buf.WriteSequenceNestedSignaturePart(weight, threshold, signature)
	return nil
}
