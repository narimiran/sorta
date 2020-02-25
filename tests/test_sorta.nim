# This is just an example to get you started. You may wish to put all of your
# tests into a single file, or separate them into multiple `test1`, `test2`
# etc. files (better names are recommended, just make sure the name starts with
# the letter 't').
#
# To run these tests, simply execute `nimble test`.

import unittest, sequtils
import ../src/sorta



test "small (int, string) tree with just a root":
  var a = initSortedTable[int, string]()
  assert len(a) == 0
  a[100] = "123"
  assert len(a) == 1
  a[400] = "456"
  a[500] = "567"
  a[200] = "234"

  assert len(a) == 4
  assert a[400] == "456"
  assert a[100] == "123"

  assert a.getOrDefault(400) == "456"
  assert a.getOrDefault(100) == "123"
  assert a.getOrDefault(999) == ""
  assert a.getOrDefault(999, "abc") == "abc"

  a[100] = "876" # change the existing value
  assert a[100] == "876"
  assert len(a) == 4

  a.del(400)
  assert len(a) == 3
  assert a.getOrDefault(400) == ""
  assert a.getOrDefault(400, "abc") == "abc"

  a.del(500) # delete last element
  assert len(a) == 2
  assert a.getOrDefault(500) == ""
  assert a.getOrDefault(500, "abc") == "abc"

  a.del(100) # delete first element
  assert len(a) == 1
  assert a.getOrDefault(100) == ""
  assert a.getOrDefault(100, "abc") == "abc"

  a[400] = "987" # add previously existing key
  assert len(a) == 2
  assert a[400] == "987"



test "small (string, string) tree with just a root":
  var a = initSortedTable[string, string]()
  assert len(a) == 0
  a["100"] = "123"
  assert len(a) == 1
  a["400"] = "456"
  a["500"] = "567"
  a["200"] = "234"

  assert len(a) == 4
  assert a["400"] == "456"
  assert a["100"] == "123"

  assert a.getOrDefault("400") == "456"
  assert a.getOrDefault("100") == "123"
  assert a.getOrDefault("999") == ""
  assert a.getOrDefault("999", "abc") == "abc"

  a["100"] = "876" # change the existing value
  assert a["100"] == "876"
  assert len(a) == 4

  a.del("400")
  assert len(a) == 3
  assert a.getOrDefault("400") == ""
  assert a.getOrDefault("400", "abc") == "abc"

  a.del("500") # delete last element
  assert len(a) == 2
  assert a.getOrDefault("500") == ""
  assert a.getOrDefault("500", "abc") == "abc"

  a.del("100") # delete first element
  assert len(a) == 1
  assert a.getOrDefault("100") == ""
  assert a.getOrDefault("100", "abc") == "abc"

  a["400"] = "987" # add previously existing key
  assert len(a) == 2
  assert a["400"] == "987"



test "medium (int, string) tree with root and its children":
  var a = initSortedTable[int, string]()
  a[100] = "123"
  a[600] = "678"
  a[400] = "456"
  a[500] = "567"
  a[200] = "234"
  a[300] = "345"
  a[900] = "901"
  a[700] = "789"
  a[800] = "890"

  assert len(a) == 9
  assert a[400] == "456"
  assert a[100] == "123"

  assert a.getOrDefault(400) == "456"
  assert a.getOrDefault(100) == "123"
  assert a.getOrDefault(999) == ""
  assert a.getOrDefault(999, "abc") == "abc"

  a[100] = "876" # change the existing value
  assert a[100] == "876"
  assert len(a) == 9

  a.del(400)
  assert len(a) == 8
  assert a.getOrDefault(400) == ""
  assert a.getOrDefault(400, "abc") == "abc"

  a.del(900) # delete last element
  assert len(a) == 7
  assert a.getOrDefault(900) == ""
  assert a.getOrDefault(900, "abc") == "abc"

  a.del(100) # delete first element
  assert len(a) == 6
  assert a.getOrDefault(100) == ""
  assert a.getOrDefault(100, "abc") == "abc"

  a[400] = "987" # add previously existing key
  assert len(a) == 7
  assert a[400] == "987"

  # delete the root node
  a.del(500)
  assert len(a) == 6

  # make left part shorter than the minimum length
  a.del(200)

  # remove the right part of the tree
  a.del(600)
  a.del(800)
  a.del(700)

  assert len(a) == 2
  assert a.getOrDefault(500) == ""
  assert a.getOrDefault(500, "abc") == "abc"
  assert a.getOrDefault(700) == ""
  assert a.getOrDefault(700, "abc") == "abc"

  # grow it once again
  a[1100] = "11"
  a[1500] = "15"
  a[1200] = "12"
  a[1400] = "14"
  a[1300] = "13"
  a[1700] = "17"
  a[1800] = "18"
  assert len(a) == 9

  a.del(300)
  a.del(400)
  assert len(a) == 7



test "delete non-existing elements":
  var a = initSortedTable[int, string]()
  a[100] = "123"
  a[600] = "678"
  a[400] = "456"
  a[500] = "567"

  assert len(a) == 4
  a.del(999)
  assert len(a) == 4

  a.del(400)
  assert len(a) == 3
  a.del(400)
  assert len(a) == 3

  a[400] = "987"
  assert a[400] == "987"
  assert len(a) == 4

  # have a medium tree with leaves"
  a[200] = "234"
  a[300] = "345"
  a[900] = "901"
  a[700] = "789"
  a[800] = "890"

  assert len(a) == 9
  a.del(999)
  assert len(a) == 9

  a.del(100) # delete first
  assert len(a) == 8
  a.del(100)
  assert len(a) == 8
  a.del(900) # delete last
  assert len(a) == 7
  a.del(900)
  assert len(a) == 7

  a.del(400) # delete root
  assert len(a) == 6
  a.del(400)
  assert len(a) == 6



test "take":
  var a = initSortedTable[int, string]()
  var s = ""
  a[100] = "123"
  a[600] = "678"
  a[400] = "456"
  a[500] = "567"

  assert len(a) == 4
  assert not a.take(999, s)
  assert len(a) == 4
  assert s == ""

  assert a.take(400, s)
  assert len(a) == 3
  assert s == "456"
  s = ""
  assert not a.take(400, s)
  assert len(a) == 3
  assert s == ""

  a[400] = "987"
  assert a[400] == "987"
  assert len(a) == 4

  # have a medium tree with leaves"
  a[200] = "234"
  a[300] = "345"
  a[900] = "901"
  a[700] = "789"
  a[800] = "890"

  assert len(a) == 9
  assert not a.take(999, s)
  assert len(a) == 9
  assert s == ""

  assert a.take(100, s) # take first
  assert len(a) == 8
  assert s == "123"
  s = ""
  assert not a.take(100, s)
  assert len(a) == 8
  assert s == ""


  assert a.take(900, s) # take last
  assert len(a) == 7
  assert s == "901"
  s = ""
  assert not a.take(900, s)
  assert len(a) == 7
  assert s == ""

  assert a.take(400, s) # take root
  assert len(a) == 6
  assert s == "987"
  s = ""
  assert not a.take(400, s)
  assert len(a) == 6
  assert s == ""



test "toSortedTable":
  var x = @[(3, 30), (4, 40), (1, 10), (2, 20), (6, 60), (5, 50), (7, 70)]
  var y =  [(3, "30"), (4, "40"), (1, "10"), (2, "20"), (6, "60"), (5, "50"), (7, "70")]
  var z = @[("3", 30), ("4", 40), ("1", 10), ("2", 20), ("6", 60), ("5", 50), ("7", 70)]

  var a = toSortedTable(x)
  assert len(a) == 7
  a[8] = 80
  assert len(a) == 8
  a.del(5)
  assert len(a) == 7
  a.del(99)
  assert len(a) == 7
  assert a.getOrDefault(99) == 0
  assert a.getOrDefault(1) == 10

  var b = toSortedTable(y)
  assert len(b) == 7
  b[8] = "80"
  assert len(b) == 8
  b.del(5)
  assert len(b) == 7
  b.del(99)
  assert len(b) == 7
  assert b.getOrDefault(99) == ""
  assert b.getOrDefault(1) == "10"

  var c = toSortedTable(z)
  assert len(c) == 7
  c["8"] = 80
  assert len(c) == 8
  c.del("5")
  assert len(c) == 7
  c.del("99")
  assert len(c) == 7
  assert c.getOrDefault("99") == 0
  assert c.getOrDefault("1") == 10



test "hasKey/contains":
  var x = @[(3, 30), (4, 40), (1, 10), (2, 20), (6, 60), (5, 50), (7, 70)]
  var a = toSortedTable(x)

  assert a.hasKey(1)
  assert a.contains(1)

  a.del(1)
  assert not a.hasKey(1)
  assert not a.contains(1)

  assert not a.hasKey(8)
  assert not a.contains(8)
  a[8] = 80
  assert a.hasKey(8)
  assert a.contains(8)



test "get non-existing elements":
  var x = @[(3, 30), (4, 40), (1, 10), (2, 20), (6, 60), (5, 50), (7, 70)]
  var a = toSortedTable(x)

  doAssertRaises(KeyError): discard a[9]

  assert a[1] == 10
  a.del(1)
  assert a.getOrDefault(1) == 0
  assert a.getOrDefault(1, 999) == 999
  doAssertRaises(KeyError): discard a[1]

  assert a[4] == 40
  a.del(4)
  assert a.getOrDefault(4) == 0
  assert a.getOrDefault(4, 999) == 999
  doAssertRaises(KeyError): discard a[4]



test "hasKeyOrPut":
  var x = @[(3, 30), (4, 40), (1, 10), (2, 20), (6, 60), (5, 50), (7, 70)]
  var a = toSortedTable(x)

  assert a.hasKeyOrPut(1, 999)
  assert a[1] == 10

  assert a.hasKeyOrPut(3, 999)
  assert a[3] == 30

  assert not a.hasKeyOrPut(8, 888)
  assert a[8] == 888
  assert len(a) == 8

  assert a.hasKeyOrPut(8, 111)
  assert a[8] == 888
  assert len(a) == 8



test "iterators":
  var x = @[(3, 30), (4, 40), (1, 10), (2, 20), (6, 60), (5, 50), (7, 70)]

  var p_exp = @[(1, 10), (2, 20), (3, 30), (4, 40), (5, 50), (6, 60), (7, 70)]
  var k_exp = @[1, 2, 3, 4, 5, 6, 7]
  var v_exp = @[10, 20, 30, 40, 50, 60, 70]

  var a = toSortedTable(x)

  var p = toSeq(pairs(a))
  var k = toSeq(keys(a))
  var v = toSeq(values(a))

  assert p == p_exp
  assert k == k_exp
  assert v == v_exp

  var animals = @["cat", "bat", "mouse", "dog", "elephant", "cow", "horse"]
  var animalLengths: SortedTable[string, int]

  for animal in animals:
    animalLengths[animal] = animal.len

  var a_keys = @["bat", "cat", "cow", "dog", "elephant", "horse", "mouse"]
  var a_pairs = @[("bat", 3), ("cat", 3), ("cow", 3), ("dog", 3),
                  ("elephant", 8), ("horse", 5), ("mouse", 5)]

  var ak = toSeq(keys(animalLengths))
  var ap = toSeq(pairs(animalLengths))

  assert ak == a_keys
  assert ap == a_pairs



test "not initialized":
  var a1: SortedTable[int, int]
  var a2: SortedTable[int, int]
  var a3: SortedTable[int, int]
  var a4: SortedTable[int, int]
  var a5: SortedTable[int, int]
  var a6: SortedTable[int, int]
  var a7: SortedTable[int, int]

  a1[1] = 10
  assert len(a1) == 1
  assert a1[1] == 10

  assert a2.getOrDefault(1) == 0
  assert len(a2) == 0

  assert not a3.hasKeyOrPut(1, 10)
  assert len(a3) == 1
  assert a3[1] == 10

  doAssertRaises(KeyError): discard a4[1]

  assert not a5.hasKey(1)

  a6.del(1)
  assert len(a6) == 0

  var i: int
  assert not a7.take(1, i)
  assert len(a7) == 0



test "equal":
  var a1: SortedTable[int, int]
  var b1: SortedTable[int, int]
  assert a1 == b1
  a1[1] = 10
  b1[9] = 10
  assert not (a1 == b1)

  var a2 = initSortedTable[int, int]()
  var b2 = initSortedTable[int, int]()
  assert a2 == b2
  a2[1] = 10
  assert not (a2 == b2)

  var a3 = initSortedTable[int, int]()
  var b3 = initSortedTable[int, int]()
  a3[1] = 10
  b3[1] = 10
  assert a3 == b3
  a3[2] = 20
  assert not (a3 == b3)

  var a4 = initSortedTable[int, int]()
  var b4 = initSortedTable[int, int]()
  a4[1] = 10
  b4[1] = 99
  assert not (a4 == b4)
  b4[1] = 10
  assert a4 == b4

  var x = @[(1, 10), (2, 20), (3, 30), (4, 40), (5, 50)]
  var y = @[(3, 30), (4, 40), (1, 10), (2, 20), (5, 50)]
  var a5 = toSortedTable(x)
  var b5 = toSortedTable(y)
  assert a5 == b5
  a5[6] = 60
  b5[6] = 60
  assert a5 == b5



test "modify values":
    var a = {'a': 99, 'b': 88, 'c': 77, 'd': 66, 'e': 55, 'f': 44}.toSortedTable
    for k, v in mpairs(a):
      v = v div 11
    doAssert a['a'] == 9
    doAssert a['b'] == 8
    doAssert a['f'] == 4
    for v in mvalues(a):
      v += 10
    doAssert a['a'] == 19
    doAssert a['b'] == 18
    doAssert a['f'] == 14
