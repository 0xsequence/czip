package main

import (
	"fmt"
	"os"
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
