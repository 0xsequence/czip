package main

import (
	"context"
	"fmt"
	"os"

	"github.com/0xsequence/czip/compressor"
	"github.com/0xsequence/ethkit/go-ethereum/common"
	"github.com/0xsequence/go-sequence"
	"github.com/spf13/cobra"
)

var (
	rootCmd = &cobra.Command{
		Use:   "czip-compressor",
		Short: "A compressor for Ethereum calldata.",
		Long:  `czip-compressor is a tool for compressing Ethereum calldata. The compressed data can be decompressed using the decompressor contract.`,
	}
)

func main() {
	err := rootCmd.Execute()
	if err != nil {
		fail(err)
	}
}

func init() {
	rootCmd.PersistentFlags().BoolP("use-storage", "s", false, "Use stateful read/write storage during compression.")
	rootCmd.PersistentFlags().StringP("provider", "p", "", "Ethereum RPC provider URL.")
	rootCmd.PersistentFlags().StringP("contract", "c", "", "Contract address of the decompressor contract.")
	rootCmd.PersistentFlags().String("cache-dir", "/tmp/czip-cache", "Path to the cache dir for indexes.")
	rootCmd.MarkFlagsRequiredTogether("provider", "contract")

	rootCmd.PersistentFlags().StringSlice("allow-opcodes", []string{}, "Will only encode using these operations, separated by commas.")
	rootCmd.PersistentFlags().StringSlice("disallow-opcodes", []string{}, "Will not encode using these operations, separated by commas.")
	rootCmd.MarkFlagsMutuallyExclusive("allow-opcodes", "disallow-opcodes")

	rootCmd.AddCommand(encodeAnyCmd)
	rootCmd.AddCommand(extrasCmd)

	addEncodeCallCommands(rootCmd)
	addEncodeCallsCommands(rootCmd)
	addEncodeSequenceCommands(rootCmd)
}

func fail(err error) {
	fmt.Print("Error: ")
	fmt.Println(err)
	os.Exit(1)
}

func useBuffer(method uint, cmd *cobra.Command) (*compressor.Buffer, error) {
	indexes, err := UseIndexes(context.Background(), cmd)
	if err != nil {
		fail(err)
	}

	allowOpcodes, err := cmd.Flags().GetStringSlice("allow-opcodes")
	if err != nil {
		return nil, err
	}

	disallowOpcodes, err := cmd.Flags().GetStringSlice("disallow-opcodes")
	if err != nil {
		return nil, err
	}

	useStorage, err := cmd.Flags().GetBool("use-storage")
	if err != nil {
		return nil, err
	}

	allowList := ParseAllowOpcodes(allowOpcodes, disallowOpcodes)

	return compressor.NewBuffer(method, indexes, allowList, useStorage), nil
}

var encodeAnyCmd = &cobra.Command{
	Use:   "encode-any",
	Short: "Compress any calldata: <hex>",
	Args:  cobra.ExactArgs(1),
	Run: func(cmd *cobra.Command, args []string) {
		buf, err := useBuffer(compressor.METHOD_DECODE_ANY, cmd)
		if err != nil {
			fail(err)
		}

		input := common.FromHex(args[0])
		if _, err := buf.WriteBytesOptimized(input, true); err != nil {
			fail(err)
		}

		fmt.Printf("0x%x\n", buf.Commited)
	},
}

func addEncodeCallsCommands(cmd *cobra.Command) {
	encodeCallsCmd := &cobra.Command{
		Use:   "encode-calls",
		Short: "Compress multiple calls to many contracts: <data> <to> <data> <to> ... <data> <to>",
	}
	encodeCallsCmd.AddCommand(&cobra.Command{
		Use:   "decode",
		Short: "The decompressor contract will only return the decompressed calls.",
		Args:  validateCallsArgs,
		Run: func(cmd *cobra.Command, args []string) {
			writeCallsForMethod(cmd, compressor.METHOD_DECODE_N_CALLS, args)
		},
	})
	encodeCallsCmd.AddCommand(&cobra.Command{
		Use:   "call",
		Short: "The decompressor contract will execute the decompressed calls, discarting the results.",
		Args:  validateCallsArgs,
		Run: func(cmd *cobra.Command, args []string) {
			writeCallsForMethod(cmd, compressor.METHOD_EXECUTE_N_CALLS, args)
		},
	})
	cmd.AddCommand(encodeCallsCmd)
}

func validateCallsArgs(cmd *cobra.Command, args []string) error {
	if len(args) < 2 {
		return fmt.Errorf("usage: <decode/call/call-return> <data> <addr>")
	}

	if len(args)%2 != 0 {
		return fmt.Errorf("invalid number of arguments, must be even")
	}

	return nil
}

func writeCallsForMethod(cmd *cobra.Command, method uint, args []string) {
	datas := make([][]byte, (len(args))/2)
	addrs := make([][]byte, (len(args))/2)

	for i := 0; i < len(args); i += 2 {
		datas[i/2] = common.FromHex(args[i])
		addrs[i/2] = common.FromHex(args[i+1])

		if len(addrs[i/2]) != 20 {
			fail(fmt.Errorf("invalid address length"))
		}
	}

	buf, err := useBuffer(method, cmd)
	if err != nil {
		fail(err)
	}

	if _, err := buf.WriteCalls(addrs, datas); err != nil {
		fail(err)
	}

	fmt.Printf("0x%x\n", buf.Commited)
}

func addEncodeCallCommands(cmd *cobra.Command) {
	encodeCallCmd := &cobra.Command{
		Use:   "encode-call",
		Short: "Compress a call to a contract: <data> <to>",
	}
	encodeCallCmd.AddCommand(&cobra.Command{
		Use:   "decode",
		Short: "The decompressor contract will only return the decompressed call.",
		Args:  cobra.ExactArgs(2),
		Run: func(cmd *cobra.Command, args []string) {
			writeCallForMethod(cmd, compressor.METHOD_DECODE_CALL, args)
		},
	})
	encodeCallCmd.AddCommand(&cobra.Command{
		Use:   "call",
		Short: "The decompressor contract will execute the decompressed call, discarting the result.",
		Args:  cobra.ExactArgs(2),
		Run: func(cmd *cobra.Command, args []string) {
			writeCallForMethod(cmd, compressor.METHOD_EXECUTE_CALL, args)
		},
	})
	encodeCallCmd.AddCommand(&cobra.Command{
		Use:   "call-return",
		Short: "The decompressor contract will execute the decompressed call and return the result.",
		Args:  cobra.ExactArgs(2),
		Run: func(cmd *cobra.Command, args []string) {
			writeCallForMethod(cmd, compressor.METHOD_EXECUTE_CALL_RETURN, args)
		},
	})
	cmd.AddCommand(encodeCallCmd)
}

func writeCallForMethod(cmd *cobra.Command, method uint, args []string) {
	buf, err := useBuffer(method, cmd)
	if err != nil {
		fail(err)
	}

	data := common.FromHex(args[0])
	addr := common.FromHex(args[1])

	if len(addr) != 20 {
		fail(fmt.Errorf("invalid address length"))
	}

	if _, err := buf.WriteCall(addr, data); err != nil {
		fail(err)
	}

	fmt.Printf("0x%x\n", buf.Commited)
}

func addEncodeSequenceCommands(cmd *cobra.Command) {
	encodeSequenceCmd := &cobra.Command{
		Use:   "encode-sequence-tx",
		Short: "Compress a Sequence Wallet transaction",
	}
	encodeSequenceCmd.AddCommand(&cobra.Command{
		Use:   "decode",
		Short: "The decompressor contract will only return the decompressed Sequence transaction.",
		Args:  cobra.ExactArgs(2),
		Run: func(cmd *cobra.Command, args []string) {
			writeSequenceForMethod(cmd, compressor.METHOD_DECODE_SEQUENCE_TX, args)
		},
	})
	encodeSequenceCmd.AddCommand(&cobra.Command{
		Use:   "call",
		Short: "The decompressor contract will execute the decompressed Sequence transaction.",
		Args:  cobra.ExactArgs(2),
		Run: func(cmd *cobra.Command, args []string) {
			writeSequenceForMethod(cmd, compressor.METHOD_EXECUTE_SEQUENCE_TX, args)
		},
	})
	cmd.AddCommand(encodeSequenceCmd)
}

func writeSequenceForMethod(cmd *cobra.Command, method uint, args []string) {
	data := common.FromHex(args[0])
	if len(data) == 0 {
		fail(fmt.Errorf("invalid data length"))
	}

	addr := common.FromHex(args[1])
	if len(addr) != 20 {
		fail(fmt.Errorf("invalid address length"))
	}

	txs, nonce, sig, err := sequence.DecodeExecdata(data)
	if err != nil {
		fail(err)
	}

	buf, err := useBuffer(method, cmd)
	if err != nil {
		fail(err)
	}

	_, err = buf.WriteSequenceExecute(addr, &sequence.Transaction{
		Nonce:        nonce,
		Transactions: txs,
		Signature:    sig,
	})

	if err != nil {
		fail(err)
	}

	fmt.Printf("0x%x\n", buf.Commited)
}
