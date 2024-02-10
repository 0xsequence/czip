package compressor

import "bytes"

type Indexes struct {
	AddressIndexes map[string]uint
	Bytes32Indexes map[string]uint
	Bytes4Indexes  map[string]uint
}

type AllowOpcodes struct {
	Default bool
	List    map[uint]bool
}

type Buffer struct {
	Commited []byte
	Pending  []byte

	Refs *References
}

type References struct {
	AllowOpcodes       *AllowOpcodes
	useContractStorage bool

	Indexes *Indexes

	usedFlags        map[string]int
	usedStorageFlags map[string]int
}

func NewBuffer(method uint, indexes *Indexes, allowOpcodes *AllowOpcodes, useStorage bool) *Buffer {
	if indexes == nil {
		indexes = &Indexes{
			AddressIndexes: make(map[string]uint),
			Bytes32Indexes: make(map[string]uint),
			Bytes4Indexes:  make(map[string]uint),
		}
	}

	return &Buffer{
		// Start with an empty byte, this
		// will be used as the method when calling the compressor
		// contract.
		Commited: []byte{byte(method)},
		Pending:  make([]byte, 0),

		Refs: &References{
			AllowOpcodes:       allowOpcodes,
			Indexes:            indexes,
			useContractStorage: useStorage,
			usedFlags:          make(map[string]int),
			usedStorageFlags:   make(map[string]int),
		},
	}
}

func (r *References) Copy() *References {
	usedFlags := make(map[string]int, len(r.usedFlags))
	for k, v := range r.usedFlags {
		usedFlags[k] = v
	}

	usedStorageFlags := make(map[string]int, len(r.usedStorageFlags))
	for k, v := range r.usedStorageFlags {
		usedStorageFlags[k] = v
	}

	return &References{
		AllowOpcodes:       r.AllowOpcodes,
		Indexes:            r.Indexes,
		useContractStorage: r.useContractStorage,

		usedFlags:        usedFlags,
		usedStorageFlags: usedStorageFlags,
	}
}

func (cb *Buffer) Allows(op uint) bool {
	if cb.Refs.AllowOpcodes == nil {
		return true
	}

	if cb.Refs.AllowOpcodes.List[op] {
		return !cb.Refs.AllowOpcodes.Default
	}

	return cb.Refs.AllowOpcodes.Default
}

func (cb *Buffer) Data() []byte {
	return cb.Commited
}

func (cb *Buffer) Len() int {
	return len(cb.Commited)
}

func (cb *Buffer) commitByte(b byte) {
	cb.Pending = append(cb.Pending, b)
}

func (cb *Buffer) commitBytes(b []byte) {
	cb.Pending = append(cb.Pending, b...)
}

func (cb *Buffer) commitUint(i uint) {
	cb.commitByte(byte(i))
}

func (cb *Buffer) FindPastData(data []byte) int {
	for i := 0; i+len(data) < len(cb.Commited); i++ {
		if bytes.Equal(cb.Commited[i:i+len(data)], data) {
			return i
		}
	}

	return -1
}

func (cb *Buffer) end(uncompressed []byte, t EncodeType) {
	// We need 2 bytes to point to a flag, so any uncompressed value
	// that is 2 bytes or less is not worth saving.
	if len(uncompressed) > 2 {
		rindex := cb.Len()

		switch t {
		case ReadStorage:
		case Stateless:
			cb.Refs.usedFlags[string(uncompressed)] = rindex + 1
		case WriteStorage:
			cb.Refs.usedStorageFlags[string(uncompressed)] = rindex + 1
		default:
		}
	}

	cb.Commited = append(cb.Commited, cb.Pending...)
	cb.Pending = nil
}

type Snapshot struct {
	Commited []byte

	SignatureLevel uint

	Refs *References
}

func (cb *Buffer) Snapshot() *Snapshot {
	// Create a copy of the commited buffer
	// and of the references.
	com := make([]byte, len(cb.Commited))
	copy(com, cb.Commited)

	refs := cb.Refs.Copy()

	return &Snapshot{
		Commited: com,
		Refs:     refs,
	}
}

func (cb *Buffer) Restore(snap *Snapshot) {
	cb.Commited = snap.Commited
	cb.Refs = snap.Refs
}
