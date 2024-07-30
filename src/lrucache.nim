import lists, tables, options

type
  LruCacheNode[K, T] = object
    key: K
    value: T

  LruCache[K, T] = ref object
    capacity: int
    nodes: DoublyLinkedList[LruCacheNode[K, T]]
    nodeTable: Table[K, DoublyLinkedNode[LruCacheNode[K, T]]]

template correctSize(capacity: int): int =
  when declared(rightSize) and (NimMajor, NimMinor) < (1, 4):
    rightSize(capacity)
  else:
    capacity

proc newLruCache*[K, T](capacity: int): LruCache[K, T] =
  LruCache[K, T](
    capacity: capacity,
    nodes: initDoublyLinkedList[LruCacheNode[K, T]](),
    nodeTable: initTable[K, DoublyLinkedNode[LruCacheNode[K, T]]](correctSize(capacity))
  )

proc resize[K, T](cache: LruCache[K, T]) =
  while cache.len > cache.capacity:
    let tail = cache.nodes.tail
    cache.nodeTable.del(tail.value.key)
    cache.nodes.remove(tail)

proc addNode[K, T](cache: LruCache[K, T], key: K, value: T) =
  let node = newDoublyLinkedNode(LruCacheNode[K, T](key: key, value: value))
  cache.nodeTable[key] = node
  cache.nodes.prepend(node)
  cache.resize()

template capacity*[K, T](cache: LruCache[K, T]): int =
  cache.capacity

proc `capacity=`*[K, T](cache: LruCache[K, T], capacity: int) =
  cache.capacity = capacity
  cache.resize()

template contains*[K, T](cache: LruCache[K, T], key: K): bool =
  cache.nodeTable.contains(key)

template peek*[K, T](cache: LruCache[K, T], key: K): T =
  cache.nodeTable[key].value.value

proc del*[K, T](cache: LruCache[K, T], key: K) =
  let node = cache.nodeTable.getOrDefault(key, nil)
  if not node.isNil:
    cache.nodeTable.del(key)
    cache.nodes.remove(node)

proc clear*[K, T](cache: LruCache[K, T]) =
  cache.nodes = initDoublyLinkedList[LruCacheNode[K, T]]()
  cache.nodeTable.clear()

proc `[]`*[K, T](cache: LruCache[K, T], key: K): T =
  let node = cache.nodeTable[key]
  result = node.value.value
  cache.nodes.remove(node)
  cache.nodes.prepend(node)

proc `[]=`*[K, T](cache: LruCache[K, T], key: K, value: T) =
  let node = cache.nodeTable.getOrDefault(key, nil)
  if node.isNil:
    cache.addNode(key, value)
  else:
    node.value.value = value
    cache.nodes.remove(node)
    cache.nodes.prepend(node)

proc getOrDefault*[K, T](cache: LruCache[K, T], key: K, default: T): T =
  let node = cache.nodeTable.getOrDefault(key, nil)
  if node.isNil:
    default
  else:
    node.value.value

proc getOrPut*[K, T](cache: LruCache[K, T], key: K, default: T): T =
  let node = cache.nodeTable.getOrDefault(key, nil)
  if node.isNil:
    result = default
    cache.addNode(key, default)
  else:
    result = node.value.value

proc getOption*[K, T](cache: LruCache[K, T], key: K): Option[T] =
  let node = cache.nodeTable.getOrDefault(key, nil)
  if node.isNil:
    none(T)
  else:
    some(node.value.value)

iterator items*[K, T](cache: LruCache[K, T]): T =
  for node in cache.nodes:
    yield node.value.value

template len*[K, T](cache: LruCache[K, T]): int =
  cache.nodeTable.len

template isEmpty*[K, T](cache: LruCache[K, T]): bool =
  cache.len == 0

template isFull*[K, T](cache: LruCache[K, T]): bool =
  cache.len == cache.capacity

template getMruKey*[K, T](cache: LruCache[K, T]): K =
  cache.nodes.head.value.key

template getMruValue*[K, T](cache: LruCache[K, T]): T =
  cache.nodes.head.value.value

template getLruKey*[K, T](cache: LruCache[K, T]): K =
  cache.nodes.tail.value.key

template getLruValue*[K, T](cache: LruCache[K, T]): T =
  cache.nodes.tail.value.value

