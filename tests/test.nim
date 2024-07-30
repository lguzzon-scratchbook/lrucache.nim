import unittest, options, strutils
import lrucache

suite "LruCache":

  test "put, get, del":
    let cache = newLruCache[int, int](100)

    # put
    for i in 1..10: cache[i] = i
    check: cache.len == 10

    # get
    for i in 1..10: check: cache[i] == i

    # del
    for i in 1..10: cache.del(i)
    check: cache.len == 0

  test "remove items if capacity exceeded":
    let cache = newLruCache[int, int](5)

    # put
    for i in 1..10: cache[i] = i
    check: cache.len == 5

    # check
    for i in 1..5:
      check: i notin cache
    for i in 6..10:
      check: i in cache

  test "remove least recently used item if capacity exceeded":
    let cache = newLruCache[int, int](2)
    cache[1] = 1
    cache[2] = 2
    cache[3] = 3
    check: 1 notin cache
    check: 2 in cache
    check: 3 in cache

    # access 2
    discard cache[2]
    cache[1] = 1

    check: 1 in cache
    check: 2 in cache
    check: 3 notin cache

  test "peek should not update recentness":
    let cache = newLruCache[int, int](2)
    cache[1] = 1
    cache[2] = 2

    # peek
    check: cache.peek(1) == 1
    cache[3] = 3

    check: 1 notin cache
    check: 2 in cache
    check: 3 in cache

  test "[]= should update recentness":
    let cache = newLruCache[int, int](2)
    cache[1] = 1
    cache[2] = 2

    # access cache element
    check: cache[1] == 1
    cache[3] = 3

    check: 1 in cache
    check: 2 notin cache
    check: 3 in cache

  test "getOrDefault()":
    let cache = newLruCache[int, int](2)
    check: cache.getOrDefault(1, 1) == 1
    check: 1 notin cache
    cache[1] = 2
    check: cache.getOrDefault(1, 1) == 2

  test "getOrPut()":
    let cache = newLruCache[int, int](2)
    check: cache.getOrPut(1, 1) == 1
    check: 1 in cache

  test "getOption()":
    let cache = newLruCache[int, int](1)
    check: cache.getOption(1).isNone
    cache[1] = 1
    check: cache.getOption(1) == some(1)

  test "isEmpty":
    let cache = newLruCache[int, int](2)
    check: cache.isEmpty
    cache[1] = 1
    check: not cache.isEmpty

  test "isFull":
    let cache = newLruCache[int, int](1)
    check: not cache.isFull
    cache[1] = 1
    check: cache.isFull

  test "clear":
    let cache = newLruCache[int, int](10)
    check: cache.isEmpty
    cache[1] = 1
    check: not cache.isEmpty
    cache.clear()
    check: cache.isEmpty

  test "re-capacity dynamically":
    let cache = newLruCache[int, int](1)
    cache[1] = 1
    cache[2] = 2
    check: 1 notin cache
    check: 2 in cache

    cache.capacity = 2
    cache[1] = 1

    check: 1 in cache
    check: 2 in cache

  test "getLruKey":
    let cache = newLruCache[int, int](2)
    cache[1] = 10
    check: cache.getLruKey == 1
    cache[2] = 20
    check: cache.getLruKey == 1
    check: cache[1] == 10
    check: cache.getLruKey == 2
    cache[3] = 30
    check: cache.getLruKey == 1 # overflow

  test "getLruValue":
    let cache = newLruCache[int, int](2)
    cache[1] = 10
    check: cache.getLruValue == 10
    cache[2] = 20
    check: cache.getLruValue == 10
    check: cache[1] == 10
    check: cache.getLruValue == 20
    cache[3] = 30
    check: cache.getLruValue == 10

  test "getMruKey":
    let cache = newLruCache[int, int](2)
    cache[1] = 10
    check: cache.getMruKey == 1
    cache[2] = 20
    check: cache.getMruKey == 2
    check: cache[1] == 10
    check: cache.getMruKey == 1
    cache[3] = 30
    check: cache.getMruKey == 3

  test "getMruValue":
    let cache = newLruCache[int, int](2)
    cache[1] = 10
    check: cache.getMruValue == 10
    cache[2] = 20
    check: cache.getMruValue == 20
    check: cache[1] == 10
    check: cache.getMruValue == 10
    cache[3] = 30
    check: cache.getMruValue == 30

  test "README usage":
    # create a new LRU cache with initial capacity of 1 items
    let cache = newLruCache[int, string](1)

    cache[1] = "a"
    cache[2] = "b"

    # key 1 is not in cache, because key 1 is eldest and capacity is only 1
    assert: 1 notin cache
    assert: 2 in cache

    # increase capacity and add key 1
    cache.capacity = 2
    cache[1] = "a"
    assert: 1 in cache
    assert: 2 in cache

    # update recentness of key 2 and add key 3, then key 1 will be discarded.
    assert: cache[2] == "b"
    cache[3] = "c"
    assert: 1 notin cache
    assert: 2 in cache
    assert: 3 in cache

  test "update value":
    let cache = newLruCache[int, int](2)
    cache[1] = 10
    cache[1] = 20 # updating the value of existing key
    check: cache[1] == 20 # ensure the value is updated correctly

  test "delete non-existent key":
    let cache = newLruCache[int, int](2)
    cache[1] = 10
    cache.del(2) # deleting a non-existent key
    check: cache.len == 1 # length should remain unchanged
    check: 1 in cache # ensure existing key is still there

  test "get or put on existing key":
    let cache = newLruCache[int, int](2)
    cache[1] = 10
    check: cache.getOrPut(1, 20) == 10 # should return existing value, not new default
    check: cache[1] == 10 # no change to value

  test "complex eviction scenario":
    let cache = newLruCache[int, int](3)
    cache[1] = 10
    cache[2] = 20
    cache[3] = 30
    check: cache.getLruKey == 1 # 1 is the least recently used
    cache[4] = 40
    check: cache.len == 3
    check: 1 notin cache
    check: 2 in cache
    check: 3 in cache
    check: 4 in cache

  test "large capacity usage":
    let cache = newLruCache[int, string](1000)
    for i in 1..500:
      cache[i] = "value" & $i
    check: cache.len == 500
    for i in 1..500:
      check: cache[i] == "value" & $i

  test "edge case zero capacity":
    let cache = newLruCache[int, int](0)
    cache[1] = 10
    check: cache.len == 0
    check: 1 notin cache

  test "edge case single capacity":
    let cache = newLruCache[int, int](1)
    cache[1] = 10
    check: cache.len == 1
    check: cache[1] == 10
    cache[2] = 20
    check: cache.len == 1
    check: 1 notin cache
    check: 2 in cache
    check: cache[2] == 20

  test "access order testing":
    let cache = newLruCache[int, int](3)
    cache[1] = 10
    cache[2] = 20
    cache[3] = 30
    discard cache[1] # access to update recentness
    cache[4] = 40
    check: cache.len == 3
    check: 2 notin cache # 2 should be evicted as it was the least recently used
    check: 1 in cache
    check: 3 in cache
    check: 4 in cache

  test "updating accessed value":
    let cache = newLruCache[int, int](2)
    cache[1] = 10
    cache[2] = 20
    discard cache[1] # accessing to make it most recently used
    cache[3] = 30 # this should evict 2
    check: 1 in cache
    check: 2 notin cache
    check: 3 in cache
    cache[1] = 15 # updating the value of 1
    check: cache[1] == 15

  test "clear and reuse":
    let cache = newLruCache[int, int](2)
    cache[1] = 10
    cache[2] = 20
    check: cache.len == 2
    cache.clear()
    check: cache.isEmpty
    cache[3] = 30
    check: cache.len == 1
    check: cache[3] == 30

  test "getOption correctness":
    let cache = newLruCache[int, int](2)
    check: cache.getOption(1).isNone
    cache[1] = 10
    check: cache.getOption(1) == some(10)
    cache[2] = 20
    check: cache.getOption(2) == some(20)
    check: cache.getOption(3).isNone
    cache[3] = 30
    check: cache.getOption(1).isNone

  test "cache with non-integer keys and values":
    let cache = newLruCache[string, string](2)
    cache["a"] = "apple"
    cache["b"] = "banana"
    check: cache["a"] == "apple"
    check: cache["b"] == "banana"
    cache["c"] = "cherry"
    check: "a" notin cache
    check: "b" in cache
    check: "c" in cache

  test "removal of specific key":
    let cache = newLruCache[int, int](3)
    cache[1] = 10
    cache[2] = 20
    cache[3] = 30
    cache.del(2) # remove specific key
    check: 2 notin cache
    check: 1 in cache
    check: 3 in cache
    cache[4] = 40
    check: 1 in cache
    check: 3 in cache
    check: 4 in cache

  test "cache stores large keys and values":
    let longString = "a".repeat(10000)
    let longNumber = 1234567890
    let cache = newLruCache[string, int](2)
    cache[longString] = longNumber
    check: cache[longString] == longNumber
    let anotherString = "b".repeat(10000)
    cache[anotherString] = longNumber
    check: cache[anotherString] == longNumber

  test "eviction policy across boundary":
    let cache = newLruCache[int, int](2)
    for i in 1..100:
      cache[i] = i
      if i > 1:
        if i > 2:
          check: (i-2) notin cache
        check: (i-1) in cache
      check: i in cache
