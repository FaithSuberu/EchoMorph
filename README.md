# EchoMorph: Mirror NFT Behavioral Twin Token System

A dual-token NFT smart contract on Stacks that creates linked "Original" and "Mirror" NFT pairs, where Mirror tokens evolve based on Original token transfer history.

## Overview

EchoMorph implements a novel NFT mechanic where:

1. **Original NFT** - The primary token that tracks transfer history
2. **Mirror NFT** - A linked token that evolves as the Original changes hands

Each transfer of an Original NFT increments a counter. At specific thresholds (5, 10, 15 transfers), the Mirror NFT's metadata can be updated to reflect "evolution" stages.

## Features

- ✅ Paired token minting with linked metadata
- ✅ Automatic transfer counter incrementation
- ✅ Ownership tracking and authorization checks
- ✅ Metadata management (256-byte URI support)
- ✅ Read-only query functions for token info
- 🔄 Evolution logic ready for threshold implementation

## Smart Contract Functions

### Public Functions

#### `mint-pair`
Creates a linked Original and Mirror NFT pair.

```clarity
(mint-pair (orig-uri (buff 256)) (mirror-uri (buff 256)))
```

**Parameters:**
- `orig-uri` - Metadata URI for the Original NFT
- `mirror-uri` - Initial metadata URI for the Mirror NFT

**Returns:** `{original: uint, mirror: uint}`

#### `transfer`
Transfers an Original NFT and updates the Mirror's transfer counter.

```clarity
(transfer (id uint) (to principal))
```

**Parameters:**
- `id` - Original NFT token ID
- `to` - Recipient principal address

**Returns:** `true` on success

### Read-Only Functions

#### `get-owner`
Returns the current owner of a token.

```clarity
(get-owner (id uint))
```

#### `get-metadata`
Retrieves the metadata URI for a token.

```clarity
(get-metadata (id uint))
```

#### `get-pair-info`
Returns Original-Mirror pair information including transfer count.

```clarity
(get-pair-info (id uint))
```

#### `get-total-supply`
Returns the total number of tokens minted.

```clarity
(get-total-supply)
```

## Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| u401 | `ERR-NOT-OWNER` | Caller is not the token owner |
| u404 | `ERR-NOT-FOUND` | Token does not exist |
| u405 | `ERR-NOT-A-PAIR` | Original token has no linked Mirror |
| u406 | `ERR-NOT-AUTHORIZED` | Unauthorized operation |

## Data Structures

### mirror-pairs Map
Stores the relationship between Original and Mirror NFTs.

```clarity
{
  original: uint,    ;; Original NFT ID
  mirror: uint,      ;; Mirror NFT ID
  transfers: uint    ;; Transfer counter
}
```

### metadata Map
Stores token metadata URIs (up to 256 bytes).

```clarity
{
  id: uint,
  uri: (buff 256)
}
```

### owners Map
Tracks token ownership.

```clarity
{
  id: uint,
  holder: principal
}
```

## Usage Example

```clarity
;; Mint a new Original-Mirror pair
(contract-call? .EchoMorph mint-pair
  0x68747470733a2f2f6170692e6578616d706c652e636f6d2f6f726967696e616c
  0x68747470733a2f2f6170692e6578616d706c652e636f6d2f6d6972726f72)

;; Transfer the Original NFT
(contract-call? .EchoMorph transfer u1 'SP3QSGJRQWFAAGVQWPW5PHCKCNP342GQSZ5PXVX3X)

;; Check Mirror evolution status
(contract-call? .EchoMorph get-pair-info u1)
```

## Roadmap

- [ ] Implement evolution logic at transfer thresholds (5, 10, 15)
- [ ] Add burn/retire functionality
- [ ] Add `list-tokens-by-owner` query function
- [ ] Implement marketplace integration
- [ ] Add trait-based evolution system
- [ ] Deploy to Stacks mainnet
