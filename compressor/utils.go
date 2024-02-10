package compressor

import (
	"bytes"
	"encoding/binary"
	"fmt"
	"log"
	"math/big"
)

func isPow2minus1(b []byte) int {
	seen1 := false
	val := 1

	for _, byteVal := range b {
		for ii := 7; ii >= 0; ii-- {
			bit := (byteVal >> ii) & 1
			if bit == 1 {
				if !seen1 {
					seen1 = true
					continue
				}
				val += 1
			} else {
				if seen1 {
					return -1
				}
			}
		}
	}

	return val
}

func isPow2(b []byte) int {
	seen1 := false
	val := 0

	for _, byteVal := range b {
		for ii := 7; ii >= 0; ii-- {
			bit := (byteVal >> ii) & 1
			if bit == 1 {
				if !seen1 {
					seen1 = true
					continue
				} else {
					return -1
				}
			} else {
				if seen1 {
					val++
				}
			}
		}
	}

	return val
}

func isPow10(b []byte) int {
	num := big.NewInt(0).SetBytes(b)

	ten := big.NewInt(10)
	zero := big.NewInt(0)
	count := 0

	for num.Cmp(ten) >= 0 {
		remainder := big.NewInt(0)
		remainder.Mod(num, ten)

		if remainder.Cmp(zero) != 0 {
			return -1
		}

		num.Div(num, ten)
		count++
	}

	if num.Cmp(big.NewInt(1)) != 0 {
		return -1
	}

	return count
}

func isPow10Mantissa(b []byte, maxExp int, maxMantissa int) (int, int) {
	num := big.NewInt(0).SetBytes(b)

	var n int

	ten := big.NewInt(10)
	maxByteValue := big.NewInt(int64(maxMantissa))
	zero := big.NewInt(0)

	for n = 1; n < maxExp; n++ {
		powerOfTen := new(big.Int).Exp(ten, big.NewInt(int64(n)), nil)

		if powerOfTen.Cmp(num) > 0 {
			break
		}

		quotient := new(big.Int)
		remainder := new(big.Int)
		quotient.DivMod(num, powerOfTen, remainder)

		if remainder.Cmp(zero) == 0 && quotient.Cmp(maxByteValue) <= 0 {
			return n, int(quotient.Int64())
		}
	}

	return -1, -1
}

func minBytesToRepresent(num uint) uint {
	if num == 0 {
		return 1
	}

	var bitsNeeded uint
	for num > 0 {
		bitsNeeded++
		num >>= 1
	}

	// Convert bits to bytes
	return uint((bitsNeeded + 7) / 8)
}

func uintToBytes(n uint64) []byte {
	buf := new(bytes.Buffer)
	err := binary.Write(buf, binary.BigEndian, n)

	if err != nil {
		log.Fatalf("binary.Write failed: %v", err)
	}

	return buf.Bytes()
}

func padToX(b []byte, n uint) ([]byte, error) {
	if len(b) > int(n) {
		// Try trimming leading zeros, if that doesn't work, return an error
		b = bytes.TrimLeft(b, "\x00")
		if len(b) > int(n) {
			return nil, fmt.Errorf("value too large to pad")
		}
	}

	if len(b) == int(n) {
		return b, nil
	}

	pad := make([]byte, int(n)-len(b))
	return append(pad, b...), nil
}

func uintPadToX(u uint, n uint) ([]byte, error) {
	buff := make([]byte, 8)
	binary.BigEndian.PutUint64(buff, uint64(u))
	return padToX(buff, n)
}

func bytesToUint64(b []byte) uint {
	// Read byte by byte, as it may be shorter
	// this is big endian
	var val uint
	for _, byteVal := range b {
		val <<= 8
		val |= uint(byteVal)
	}
	return val
}

func maxPriority(a EncodeType, b EncodeType) EncodeType {
	if a == WriteStorage || b == WriteStorage {
		return WriteStorage
	}

	if a == ReadStorage || b == ReadStorage {
		return ReadStorage
	}

	if a == Mirror || b == Mirror {
		return Mirror
	}

	return Stateless
}
