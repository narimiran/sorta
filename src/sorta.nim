## SortedTable implementation using `B-Tree<https://en.wikipedia.org/wiki/Btree>`_
## as an internal data structure.
##
## The  BTree algorithm is based on:
## * N. Wirth, J. Gutknecht:
##   Project Oberon, The Design of an Operating System and Compiler;
##   pages 174-190.
##
## Public API tries to mimic API of Nim's built-in Tables as much as possible.
## The ommission of `add` procedure is done on purpose.


const
  # Minimal number of elements per node.
  # This should be a very small number, less than 10 for the most use cases.
  # 2 is chosen for testing purposes, so there are more splits and merges of nodes.
  N = 2

type
  Entry[Key, Val] = object
    key: Key
    val: Val
    p: Node[Key, Val]

  Node[Key, Val] = ref object
    m: int  # number of elements
    p0: Node[Key, Val] # left-most pointer (nr. of pointers is always m+1)
    e: array[2*N, Entry[Key, Val]]

  SortedTable*[Key, Val] = object
    ## Generic sorted table, consisting of key-value pairs.
    ##
    ## `root` and `entries` are internal implementation details which cannot
    ## be directly accessed.
    ##
    ## For creating an empty SortedTable, use `initSortedTable proc<#initSortedTable>`_.
    root: Node[Key, Val]
    entries: int # total number of entries in the tree

  CursorPosition[Key, Val] = tuple
    ## Index into the sorted table allowing access to either the key or the value.
    node: Node[Key, Val]
    entry: int

  Cursor[Key, Val] = seq[CursorPosition[Key, Val]]

template leq(a, b): bool = cmp(a, b) <= 0
template eq(a, b): bool = cmp(a, b) == 0

proc binarySearch[Key, Val](x: Key; a: Node[Key, Val]): int {.inline.} =
  var
    l = 0
    r = a.m
    i: int
  while l < r:
    i = (l+r) div 2
    if leq(x, a.e[i].key):
      r = i
    else:
      l = i+1
  return r

proc initSortedTable*[Key, Val](): SortedTable[Key, Val] =
  ## Creates a new empty SortedTable.
  result = SortedTable[Key, Val](root: Node[Key, Val](m: 0, p0: nil), entries: 0)


proc `[]=`*[Key, Val](b: var SortedTable[Key, Val]; key: Key; val: Val)

proc toSortedTable*[Key, Val](pairs: openArray[(Key, Val)]): SortedTable[Key, Val] =
  ## Creates a new SortedTable which contains the given `pairs`.
  ##
  ## `pairs` is a container consisting of `(key, value)` tuples.
  result = initSortedTable[Key, Val]()
  for key, val in items(pairs):
    result[key] = val


template getHelper(a, x, ifFound, ifNotFound) {.dirty.} =
  while true:
    var r = binarySearch(x, a)
    if (r < a.m) and eq(x, a.e[r].key):
      return ifFound
    a = if r == 0: a.p0 else: a.e[r-1].p
    if a.isNil:
      return ifNotFound


proc getOrDefault*[Key, Val](b: SortedTable[Key, Val]; x: Key): Val =
  ## Retrieves the value at `b[key]` if `key` is in `b`.
  ## Otherwise, the default initialization value for type `B` is returned
  ## (e.g. 0 for any integer type).
  var a =
    if b.root.isNil: Node[Key,Val](m: 0, p0: nil)
    else: b.root
  getHelper(a, x, a.e[r].val, default(Val))


proc getOrDefault*[Key, Val](b: SortedTable[Key, Val];
                             x: Key; default: Val): Val =
  ## Retrieves the value at `b[key]` if `key` is in `b`.
  ## Otherwise, `default` is returned.
  var a =
    if b.root.isNil: Node[Key,Val](m: 0, p0: nil)
    else: b.root
  getHelper(a, x, a.e[r].val, default)


proc `[]`*[Key, Val](b: SortedTable[Key, Val]; x: Key): Val =
  ## Retrieves the value at `b[key]`.
  ##
  ## If `key` is not in `b`, the `KeyError` exception is raised.
  var a =
    if b.root.isNil: Node[Key,Val](m: 0, p0: nil)
    else: b.root
  while true:
    var r = binarySearch(x, a)
    if (r < a.m) and eq(x, a.e[r].key):
      return a.e[r].val
    a = if r == 0: a.p0 else: a.e[r-1].p
    if a.isNil:
      when compiles($key):
        raise newException(KeyError, "key not found: " & $key)
      else:
        raise newException(KeyError, "key not found")


proc hasKey*[Key, Val](b: SortedTable[Key, Val]; x: Key): bool =
  ## Returns true if `key` is in the table `b`.
  var a =
    if b.root.isNil: Node[Key,Val](m: 0, p0: nil)
    else: b.root
  getHelper(a, x, true, false)


proc contains*[Key, Val](b: SortedTable[Key, Val]; x: Key): bool =
  ## Alias of `hasKey proc<#hasKey,SortedTable[Key,Val],Key>`_ for use with
  ## the `in` operator.
  return hasKey(b, x)


proc insertImpl[Key, Val](x: Key; a: Node[Key, Val];
                          h: var bool; v: var Entry[Key, Val]): bool =
  # Search key x in B-tree with root a;
  # if found, change the value to the new one and return true.
  # Otherwise insert new item with key x.
  # If an entry is to be passed up, assign it to v.
  # h = "tree has become higher"

  result = true
  var u = v
  var r = binarySearch(x, a)

  if (r < a.m) and (a.e[r].key == x): # found
    a.e[r].val = v.val
    return false

  else: # item not on this page
    var b = if r == 0: a.p0 else: a.e[r-1].p

    if b.isNil: # not in tree, insert
      u.p = nil
      h = true
      u.key = x
    else:
      result = insertImpl(x, b, h, u)

    var i: int
    if h: # insert u to the left of a.e[r]
      if a.m < 2*N:
        h = false
        i = a.m
        while i > r:
          dec(i)
          a.e[i+1] = a.e[i]
        a.e[r] = u
        inc(a.m)
      else:
        new(b) # overflow; split a into a,b and assign the middle entry to v
        if r < N: # insert in left page a
          i = N-1
          v = a.e[i]
          while i > r:
            dec(i)
            a.e[i+1] = a.e[i]
          a.e[r] = u
          i = 0
          while i < N:
            b.e[i] = a.e[i+N]
            inc(i)
        else: # insert in right page b
          dec(r, N)
          i = 0
          if r == 0:
            v = u
          else:
            v = a.e[N]
            while i < r-1:
              b.e[i] = a.e[i+N+1]
              inc(i)
            b.e[i] = u
            inc(i)
          while i < N:
            b.e[i] = a.e[i+N]
            inc(i)
        a.m = N
        b.m = N
        b.p0 = v.p
        v.p = b


template insertHelper(b, key, val) =
  var u = Entry[Key, Val](key: key, val: val)
  var h = false
  var wasAdded = insertImpl(key, b.root, h, u)
  if wasAdded:
    inc(b.entries)
  if h: # the previous root had to be splitted, create a new one
    var q = b.root
    new(b.root)
    b.root.m = 1
    b.root.p0 = q
    b.root.e[0] = u


proc `[]=`*[Key, Val](b: var SortedTable[Key, Val]; key: Key; val: Val) =
  ## Inserts a `(key, value)` pair into `b`.
  if b.root.isNil: b = initSortedTable[Key, Val]()
  insertHelper(b, key, val)


proc hasKeyOrPut*[Key, Val](b: var SortedTable[Key, Val]; key: Key; val: Val): bool =
  ## Returns true if `key` is in the table, otherwise inserts `value`.
  if b.root.isNil: b = initSortedTable[Key, Val]()
  if hasKey(b, key):
    result = true
  else:
    insertHelper(b, key, val)
    result = false


proc underflowImpl[Key, Val](c, a: Node[Key, Val]; s: int; h: var bool) =
  # a = underflowing page,
  # c = ancestor page,
  # s = index of deleted entry in c
  var
    s = s
    b: Node[Key, Val]
    i, k: int

  if s < c.m: # b = page to the *right* of a
    b = c.e[s].p
    k = (b.m - N + 1) div 2 # k = number of surplus items available on page b
    a.e[N-1] = c.e[s]
    a.e[N-1].p = b.p0

    if k > 0: # balance by moving k-1 items from b to a
      while i < k-1:
        a.e[i+N] = b.e[i]
        inc(i)
      c.e[s] = b.e[k-1]
      b.p0 = c.e[s].p
      c.e[s].p = b
      dec(b.m, k)
      i = 0
      while i < b.m:
        b.e[i] = b.e[i+k]
        inc(i)
      a.m = N-1+k
      h = false
    else: # no surplus items in b: merge pages a and b, discard *b*
      i = 0
      while i < N:
        a.e[i+N] = b.e[i]
        inc(i)
      i = s
      dec(c.m)
      while i < c.m:
        c.e[i] = c.e[i+1]
        inc(i)
      a.m = 2*N
      h = c.m < N

  else: # b = page to the *left* of a
    dec(s)
    b = if s == 0: c.p0 else: c.e[s-1].p
    k = (b.m - N + 1) div 2 # k = number of surplus items available on page b

    if k > 0:
      i = N-1
      while i > 0:
        dec(i)
        a.e[i+k] = a.e[i]
      i = k-1
      a.e[i] = c.e[s]
      a.e[i].p = a.p0
      # move k-1 items from b to a, and one to c
      dec(b.m, k)
      while i > 0:
        dec(i)
        a.e[i] = b.e[i+b.m+1]
      c.e[s] = b.e[b.m]
      a.p0 = c.e[s].p
      c.e[s].p = a
      a.m = N-1 + k
      h = false
    else: # no surplus items in b: merge pages a and b, discard *a*
      c.e[s].p = a.p0
      b.e[N] = c.e[s]
      i = 0
      while i < N-1:
        b.e[i+N+1] = a.e[i]
        inc(i)
      b.m = 2*N
      dec(c.m)
      h = c.m < N



proc deleteImpl[Key, Val](x: Key; a: Node[Key, Val]; h: var bool): bool =
  # search and delete key x in B-tree a;
  # if a page underflow arises, balance with adjacent page or merge;
  # h = "page a is undersize"
  if a.isNil: # if the key wasn't in the table
    return false

  result = true
  var r = binarySearch(x, a)
  var q = if r == 0: a.p0 else: a.e[r-1].p

  proc del[Key, Val](p, a: Node[Key, Val]; h: var bool) =
    var
      k: int
      q: Node[Key, Val]
    k = p.m-1
    q = p.e[k].p
    if q != nil:
      del(q, a, h)
      if h:
        underflowImpl(p, q, p.m, h)
    else:
      p.e[k].p = a.e[r].p
      a.e[r] = p.e[k]
      dec(p.m)
      h = p.m < N

  var i: int
  if (r < a.m) and (a.e[r].key == x): # found
    if q.isNil: # a is leaf page
      dec(a.m)
      h = a.m < N
      i = r
      while i < a.m:
        a.e[i] = a.e[i+1]
        inc(i)
    else:
      del(q, a, h)
      if h:
        underflowImpl(a, q, r, h)
  else:
    result = deleteImpl(x, q, h)
    if h:
      underflowImpl(a, q, r, h)


proc delHelper[Key, Val](b: var SortedTable[Key, Val]; key: Key) =
  var h = false
  var wasDeleted = deleteImpl(key, b.root, h)
  if wasDeleted:
    dec(b.entries)
  if h: # the previous root is gone, appoint a new one
    if b.root.m == 0:
      b.root = b.root.p0

proc del*[Key, Val](b: var SortedTable[Key, Val]; key: Key) =
  ## Deletes `key` from table `b`. Does nothing if the key does not exist.
  if b.root.isNil: b = initSortedTable[Key, Val]()
  delHelper(b, key)


proc take*[Key, Val](b: var SortedTable[Key, Val];
                     key: Key; val: var Val): bool =
  ## Deletes the `key` from the table.
  ## Returns `true`, if the `key` existed, and sets `val` to the
  ## mapping of the key. Otherwise, returns `false`, and the `val` is
  ## unchanged.
  if b.root.isNil: b = initSortedTable[Key, Val]()
  result = b.hasKey(key)
  if result:
    val = b[key]
    delHelper(b, key)


proc dollarImpl[Key, Val](h: Node[Key, Val],
                          indent: string; result: var string) =
  if h.p0.isNil:
    for j in 0..<h.m:
      result.add(indent & $h.e[j].key & ": " & $h.e[j].val & "\n")
  else:
    dollarImpl(h.p0, indent & "   ", result)
    for j in 0..<h.m:
      result.add(indent & "(" & $h.e[j].key & ": " & $h.e[j].val & ")\n")
      dollarImpl(h.e[j].p, indent & "   ", result)


proc `$`*[Key, Val](b: SortedTable[Key, Val]): string =
  ## The `$` operator for tables. Used internally when calling `echo`
  ## on a table.
  result = ""
  if not b.root.isNil:
    dollarImpl(b.root, "", result)


proc len*[Key, Val](b: SortedTable[Key, Val]): int {.inline.} = b.entries

proc key[Key, Val](position: CursorPosition[Key, Val]): Key =
  ## Return the key for a given cursor position.
  position.node.e[position.entry].key

proc val[Key, Val](position: CursorPosition[Key, Val]): Val =
  ## Return the value for a given cursor position.
  position.node.e[position.entry].val

proc mval[Key, Val](position: CursorPosition[Key, Val]): var Val =
  ## Returns a reference to the value for a given cursor position.
  position.node.e[position.entry].val

proc search[Key, Val](b: SortedTable[Key, Val], key: Key): Cursor[Key, Val] =
  ## Calculates the cursor pointing to the given key.
  var a = b.root
  while not a.isNil:
    var r = binarySearch(key, a)
    if r < a.m:
      result.add((a, r))
      if eq(key, a.e[r].key):
        break
    a = if r == 0: a.p0 else: a.e[r-1].p
  # add a dummy entry for first next call
  result.add((nil, 0))

proc current[Key, Val](cursor: Cursor[Key, Val]): CursorPosition[Key, Val] =
  ## Returns the current position of a cursor.
  ## This call is only valid if cursor.next previously returned true.
  cursor[^1]

proc next[Key, Val](cursor: var Cursor[Key, Val]): bool =
  ## Moves the cursor forward returning true if cursor.current is now valid.
  ## Never call current after next returns false.
  var (node, oldEntry) = cursor.pop()
  if not node.isNil:
    var newEntry = oldEntry + 1
    if newEntry < node.m:
        cursor.add((node, newEntry))
    var child = node.e[oldEntry].p
    if not child.isNil:
      while not child.isNil:
        cursor.add((child, 0))
        child = child.p0
  return cursor.len > 0 and cursor.current.node.m > 0

proc cursorFromStart[Key, Val](b: SortedTable[Key, Val]): Cursor[Key, Val] =
  result = @[]
  var a = b.root
  while not a.isNil:
    result.add((a, 0))
    a = a.p0
  result.add((nil, 0))

iterator pairsFrom*[Key, Val](b: SortedTable[Key, Val], fromKey: Key): tuple[key: Key, val: Val] =
  ## Iterates the sorted table from the given key to the end.
  var cursor = b.search(fromKey)
  while cursor.next:
    let position = cursor.current
    yield (position.key, position.val)

iterator pairsBetween*[Key, Val](b: SortedTable[Key, Val], fromKey: Key, toKey: Key): tuple[key: Key, val: Val] =
  ## Iterates the sorted table from fromKey to toKey inclusive.
  var cursor = b.search(fromKey)
  while cursor.next:
    let position = cursor.current
    if not leq(position.key, toKey):
      break
    yield (position.key, position.val)

iterator entries[Key, Val](b: SortedTable[Key, Val]): CursorPosition[Key, Val] =
  var cursor = b.cursorFromStart
  while cursor.next:
    yield cursor.current

iterator keys*[Key, Val](b: SortedTable[Key, Val]): Key =
  ## Iterates over all the keys in the table `b`.
  for e in entries(b):
    yield e.key

iterator values*[Key, Val](b: SortedTable[Key, Val]): Val =
  ## Iterates over all the values in the table `b`.
  for e in entries(b):
    yield e.val

iterator mvalues*[Key, Val](b: var SortedTable[Key, Val]): var Val =
  ## Iterates over all the values in the table `b`.
  ## The values can be modified.
  for e in entries(b):
    yield e.mval

iterator pairs*[Key, Val](b: SortedTable[Key, Val]): (Key, Val) =
  ## Iterates over all `(key, value)` pairs in the table `b`.
  for e in entries(b):
    yield (e.key, e.val)

iterator mpairs*[Key, Val](b: var SortedTable[Key, Val]): (Key, var Val) =
  ## Iterates over all `(key, value)` pairs in the table `b`.
  ## The values can be modified.
  for e in entries(b):
    yield (e.key, e.mval)


proc `==`*[Key, Val](a, b: SortedTable[Key, Val]): bool =
  ## The `==` operator for SortedTables.
  ##
  ## Returns `true` if the content of both tables contains the same
  ## key-value pairs. Insert order does not matter.
  if a.root.isNil and b.root.isNil:
    return true
  if a.entries == b.entries:
    for k, v in a:
      if not b.hasKey(k): return false
      if b.getOrDefault(k) != v: return false
    return true



when isMainModule:
  import random, tables, sequtils

  proc main =
    var st = initSortedTable[string, string]()
    st["www.cs.princeton.edu"] =  "abc"
    st["www.princeton.edu"] =  "128.112.128.15"
    st["www.yale.edu"] =  "130.132.143.21"
    st["www.simpsons.com"] =  "209.052.165.60"
    st["www.apple.com"] =  "17.112.152.32"
    st["www.amazon.com"] =  "207.171.182.16"
    st["www.ebay.com"] =  "66.135.192.87"
    st["www.cnn.com"] =  "64.236.16.20"
    st["www.google.com"] =  "216.239.41.99"
    st["www.nytimes.com"] =  "199.239.136.200"
    st["www.microsoft.com"] =  "207.126.99.140"
    st["www.dell.com"] =  "143.166.224.230"
    st["www.slashdot.org"] =  "66.35.250.151"
    st["www.espn.com"] =  "199.181.135.201"
    st["www.weather.com"] =  "63.111.66.11"
    st["www.yahoo.com"] =  "216.109.118.65"

    assert st.getOrDefault("www.cs.princeton.edu") == "abc"
    assert st.getOrDefault("www.harvardsucks.com") == ""

    assert st.getOrDefault("www.simpsons.com") == "209.052.165.60"
    assert st.getOrDefault("www.apple.com") == "17.112.152.32"
    assert st.getOrDefault("www.ebay.com") == "66.135.192.87"
    assert st.getOrDefault("www.dell.com") == "143.166.224.230"
    assert(st.entries == 16)

    proc collect_from_keys(from_key: string): seq[string] =
      result = @[]
      for position in st.pairsFrom(from_key):
        result.add(position.key)

    var keys = toSeq(st.keys())
    assert keys.len == 16

    for i in 0..<keys.len:
      let key = keys[i]
      assert collect_from_keys(key) == keys[i..<keys.len]

      let lesskey = keys[i][0..^2]
      assert collect_from_keys(lesskey) == keys[i..<keys.len]

      let morekey = keys[i] & "_"
      assert collect_from_keys(morekey) == keys[i+1..<keys.len]

    proc collect_keys(from_key: string, to_key: string): seq[string] =
      result = @[]
      for position in st.pairsBetween(from_key, to_key):
        result.add(position.key)

    for i in 0..<keys.len:
      let from_key = keys[i]
      for j in i..<keys.len:
        let to_key = keys[j]
        assert collect_keys(from_key, to_key) == keys[i..j]

        let to_lesskey = to_key[0..^2]
        assert collect_keys(from_key, to_lesskey) == keys[i..<j]

        let to_morekey = to_key & "_"
        assert collect_keys(from_key, to_morekey) == keys[i..j]

    for k, v in st:
      echo k, ": ", v

    when false:
      var b2 = initSortedTable[string, string]()
      const iters = 10_000
      for i in 1..iters:
        b2.add($i, $(iters - i))
      for i in 1..iters:
        let x = b2.getOrDefault($i)
        if x != $(iters - i):
          echo "got ", x, ", but expected ", iters - i
      echo b2.m

    when true:
      var b2 = initSortedTable[int, string]()
      var t2 = initTable[int, string]()
      const iters = 100_000
      for i in 1..iters:
        let x = rand(high(int))
        if not t2.hasKey(x):
          doAssert b2.getOrDefault(x).len == 0, " what, tree has this element " & $x
          t2[x] = $x
          b2[x] = $x

      doAssert b2.entries == t2.len
      echo "unique entries ", b2.entries
      for k, v in t2:
        doAssert $k == v
        doAssert b2.getOrDefault(k) == $k

    # ensure first time cursor.next is called on tree with an empty root node it returns false
    var b3 = initSortedTable[int, string]()
    var cursor = b3.cursorFromStart
    assert not cursor.next

    # check that mvalues works
    var mutate_st = initSortedTable[string, string]()
    mutate_st["a"] = "one"
    for val in mutate_st.mvalues:
      val = "two"
    doAssert mutate_st["a"] == "two"

    # check again with mpairs
    for key, val in mutate_st.mpairs:
      val = "three"
    doAssert mutate_st["a"] == "three"
  
  main()
