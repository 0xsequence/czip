package main

import (
	"fmt"
	"os"
	"strings"

	encoder "github.com/0xsequence/czip/compressor"
)

func ensureDir(path string) error {
	info, err := os.Stat(path)
	if err == nil {
		if info.IsDir() {
			return nil
		}
		return fmt.Errorf("path exists but is not a directory: %s", path)
	}
	if !os.IsNotExist(err) {
		return err
	}

	err = os.MkdirAll(path, 0755)
	if err != nil {
		return fmt.Errorf("failed to create directory: %s, error: %v", path, err)
	}
	return nil
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

func ParseAllowOpcodes(allow []string, disable []string) *encoder.AllowOpcodes {
	var res encoder.AllowOpcodes
	res.List = make(map[uint]bool)
	var val []string

	if len(allow) != 0 {
		val = allow
		res.Default = false
	} else {
		val = disable
		res.Default = true
	}

	for _, part := range val {
		opcodes := FindOpcodesForFlag(part)
		for _, opcode := range opcodes {
			res.List[opcode] = true
		}
	}

	return &res
}
