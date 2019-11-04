# Sorted Tables

SortedTable implementation using [B-Tree](https://en.wikipedia.org/wiki/Btree)
as an internal data structure.

The  BTree algorithm is based on:
* N. Wirth, J. Gutknecht:
  Project Oberon, The Design of an Operating System and Compiler;
  pages 174-190.

Public API tries to mimic API of Nim's built-in Tables as much as possible.
The ommission of `add` procedure is done on purpose.



## Installation

```
nimble install sorta
```

Required Nim version is at least 1.0.0.



## Usage

See the [documentation](https://narimiran.github.io/sorta).
