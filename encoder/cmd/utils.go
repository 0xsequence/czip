package cmd

import (
	"fmt"
	"os"
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
