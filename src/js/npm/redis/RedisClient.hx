package js.npm.redis;
import js.node.events.EventEmitter;
import haxe.DynamicAccess;
import haxe.extern.Rest;
import haxe.Constraints;

@:enum abstract RedisEvent<T:Function>(Event<T>) to Event<T> {
  /**
    client will emit ready once a connection is established. Commands issued before the ready event are queued,
    then replayed just before this event is emitted.
   **/
  var Ready : RedisEvent<Void->Void> = "ready";

  /**
    client will emit connect at the same time as it emits ready unless client.options.no_ready_check is set.
    If this options is set, connect will be emitted when the stream is connected.
   **/
  var Connect : RedisEvent<Void->Void> = "connect";

  /**
    client will emit reconnecting when trying to reconnect to the Redis server after losing the connection.
    Listeners are passed an object containing delay (in ms) and attempt (the attempt #) attributes.
   **/
  var Reconnecting : RedisEvent<{ delay:Float, attempt:Int }->Void> = "reconnecting";

  /**
    client will emit error when encountering an error connecting to the Redis server or when any other in node_redis occurs.
    So please attach the error listener to node_redis.
   **/
  var Error : RedisEvent<js.Error->Void> = "error";

  /**
    client will emit end when an established Redis server connection has closed.
   **/
  var End : RedisEvent<Void->Void> = "end";

  /**
    client will emit drain when the TCP connection to the Redis server has been buffering, but is now writable.
    This event can be used to stream commands in to Redis and adapt to backpressure.

    If the stream is buffering client.should_buffer is set to true. Otherwise the variable is always set to false.
    That way you can decide when to reduce your send rate and resume sending commands when you get drain.
    You can also check the return value of each command as it will also return the backpressure indicator. If false is returned the stream had to buffer.
   **/
  var Drain : RedisEvent<Void->Void> = "drain";

  /**
    client will emit idle when there are no outstanding commands that are awaiting a response.
   **/
  var Idle : RedisEvent<Void->Void> = "idle";
}

@:enum abstract RedisSubscriptionEvent<T:Function>(Event<T>) to Event<T> {
  /**
    Client will emit message for every message received that matches an active subscription. Listeners are passed the
    channel name as channel and the message Buffer as message.
   **/
  var Message : RedisSubscriptionEvent<String->String->Void> = "message"; /** (channel, message) **/

  /**
    Client will emit pmessage for every message received that matches an active subscription pattern. Listeners are passed
    the original pattern used with PSUBSCRIBE as pattern, the sending channel name as channel, and the message Buffer as
    message.
   **/
  var PMessage : RedisSubscriptionEvent<String->String->String->Void> = "pmessage"; /** (pattern, channel, message) **/

  /**
    Client will emit subscribe in response to a SUBSCRIBE command. Listeners are passed the channel name as channel and
    the new count of subscriptions for this client as count.
   **/
  var Subscribe : RedisSubscriptionEvent<String->Int->Void> = "subscribe"; /** (channel, count) **/

  /**
    Client will emit psubscribe in response to a PSUBSCRIBE command. Listeners are passed the original pattern as pattern,
    and the new count of subscriptions for this client as count.
   **/
  var PSubscribe : RedisSubscriptionEvent<String->Int->Void> = "psubscribe"; /** (pattern, count) **/

  /**
    Client will emit unsubscribe in response to a UNSUBSCRIBE command. Listeners are passed the channel name as channel
    and the new count of subscriptions for this client as count. When count is 0, this client has left subscriber mode and
    no more subscriber events will be emitted.
   **/
  var Unsubscribe : RedisSubscriptionEvent<String->Int->Void> = "unsubscribe"; /** (channel, count) **/

  /**
    Client will emit punsubscribe in response to a PUNSUBSCRIBE command. Listeners are passed the channel name as channel
    and the new count of subscriptions for this client as count. When count is 0, this client has left subscriber mode and
    no more subscriber events will be emitted.
   **/
  var PUnsubscribe : RedisSubscriptionEvent<String->Int->Void> = "punsubscribe"; /** (pattern, count) **/
}

extern class RedisClientBase<TSelf:RedisClientBase<TSelf,TReturn>, TReturn> extends EventEmitter<TSelf> {
  /**
    When connecting to a Redis server that requires authentication, the AUTH command must be sent as the first command
    after connecting. This can be tricky to coordinate with reconnections, the ready check, etc. To make this easier,
    client.auth() stashes password and will send it after each connection, including reconnections. callback is invoked
    only once, after the response to the very first AUTH command sent. NOTE: Your call to client.auth() should not be
    inside the ready handler. If you are doing this wrong, client will emit an error that looks something like this
    Error: Ready check failed: ERR operation not permitted.
   **/
  @:overload(function(password:String):TReturn {})
  function auth(password:String, callback:Null<js.Error>->Void):TReturn;

  /**
    Forcibly close the connection to the Redis server. Note that this does not wait until all replies have been parsed.
    If you want to exit cleanly, call client.quit() to send the QUIT command after you have handled all replies.

    You should set flush to true, if you are not absolutely sure you do not care about any other commands. If you set
    flush to false all still running commands will silently fail.
   **/
  function end(flush:Bool):Void;

  /**
    Call unref() on the underlying socket connection to the Redis server, allowing the program to exit once no more
    commands are pending.

    This is an experimental feature, and only supports a subset of the Redis protocol. Any commands where client state
    is saved on the Redis server, e.g. *SUBSCRIBE or the blocking BL* commands will NOT work with .unref().
   **/
  function unref():Void;

  /**
    The reply from an HGETALL command will be converted into a JavaScript Object by node_redis. That way you can
    interact with the responses using JavaScript syntax.
   **/
  function hgetall(name:String, callback:Null<js.Error>->DynamicAccess<String>->Void):TReturn;

  /**
    Multiple values in a hash can be set by supplying an object:
   **/
  @:overload(function (name:String, obj:Dynamic<String>):TReturn {})
  @:overload(function (name:String, obj:Dynamic<String>, callback:Null<js.Error>->Void):TReturn {})
  @:overload(function (name:String, values:Rest<String>):TReturn {})
  @:overload(function (name:String, values:Array<String>):TReturn {})
  @:overload(function (name:String, values:Array<String>, callback:Null<js.Error>->Void):TReturn {})
  @:overload(function (name:String, key:String, value:String, callback:Null<js.Error>->Void):TReturn {})
  function hmset(name:String, obj:DynamicAccess<String>, callback:Null<js.Error>->Void):TReturn;

  /**
    When a client issues a SUBSCRIBE or PSUBSCRIBE, that connection is put into a "subscriber" mode. At that point, only
    commands that modify the subscription set are valid. When the subscription set is empty, the connection is put back
    into regular mode.

    If you need to send regular commands to Redis while in subscriber mode, just open another connection.
   **/
  function subscribe(channel:String):TReturn;

  /**
    Subscribes to a pattern
   **/
  function psubscribe(channel:String):TReturn;

  function publish(channel:String, message:String):TReturn;

  /**
    MULTI commands are queued up until an EXEC is issued, and then all commands are run atomically by Redis. The
    interface in node_redis is to return an individual Multi object by calling client.multi(). If any command fails to
    queue, all commands are rolled back and none is going to be executed (For further information look at transactions).
   **/
  function multi():Multi;

  /**
    Identical to .multi without transactions. This is recommended if you want to execute many commands at once but don't
    have to rely on transactions.

    BATCH commands are queued up until an EXEC is issued, and then all commands are run atomically by Redis. The
    interface in node_redis is to return an individual Batch object by calling client.batch(). The only difference
    between .batch and .multi is that no transaction is going to be used. Be aware that the errors are - just like in
    multi statements - in the result. Otherwise both, errors and results could be returned at the same time.

    If you fire many commands at once this is going to boost the execution speed by up to 400% [sic!] compared to
    fireing the same commands in a loop without waiting for the result! See the benchmarks for further comparison.
    Please remember that all commands are kept in memory until they are fired.
   **/
  function batch():Multi;

  /**
    Start redis API dump
   **/

  /**
    Appends the string value to the value at key. If key doesn’t already exist, create it with a value of value. Returns
    the new length of the value at key.
   **/
  @:overload(function(name:String, value:String, callback:Null<js.Error>->String->Void):TReturn {})
  function append(name:String, value:String):TReturn;

  /**
    Tell the Redis server to rewrite the AOF file from data in memory.
   **/
  @:overload(function(callback:Null<js.Error>->String->Void):TReturn {})
  function bgrewriteaof():TReturn;

  /**
    Tell the Redis server to save its data to disk.
   **/
  @:overload(function (callback:Null<js.Error>->String->Void):TReturn {})
  function bgsave():TReturn;

  // TODO: see how timeout is handled
  // /**
  //   LPOP a value off of the first non-empty list named in the keys list.
  //
  //   If none of the lists in keys has a value to LPOP, then block for timeout seconds, or until a value gets pushed on to one of the lists.
  //
  //   If timeout is 0, then block indefinitely.
  //  **/
  // @:overload(function (keys:Array<String>):TReturn {})
  // @:overload(function (keys:Array<String>, timeout:Int):TReturn {})
  // @:overload(function (keys:Array<String>, timeout:Int, callback:Null<js.Error>->String->Void):TReturn {})
  // function blpop(keys:Rest<String>):TReturn;

  // TODO: see how timeout is handled
  // /**
  //   RPOP a value off of the first non-empty list named in the keys list.
  //
  //   If none of the lists in keys has a value to LPOP, then block for timeout seconds, or until a value gets pushed on to
  //   one of the lists.
  //
  //   If timeout is 0, then block indefinitely.
  //  **/
  // function brpop(keys:Rest<String>, timeout=0):TReturn;

  // TODO: see how timeout is handled
  // /**
  //   Pop a value off the tail of src, push it on the head of dst and then return it.
  //
  //   This command blocks until a value is in src or until timeout seconds elapse, whichever is first. A timeout value of
  //   0 blocks forever.
  //  **/
  // function brpoplpush(src, dst, timeout=0):TReturn;

  /**
    Returns the number of keys in the current database
   **/
  @:overload(function (callback:Null<js.Error>->Int->Void):TReturn {})
  function dbsize():TReturn;

  /**
    Returns version specific metainformation about a give key
    `type` should be `object`
   **/
  @:overload(function (type:String, key:String, callback:Null<js.Error>->String->Void):TReturn {})
  function debug(type:String, key:String):TReturn;

  /**
    Decrements the value of key by 1. If no key exists, the value will be initialized as -1
   **/
  @:overload(function (name:String, callback:Null<js.Error>->Int->Void):TReturn {})
  function decr(name:String):TReturn;

  /**
    Decrements the value of key by amount. If no key exists, the value will be initialized as 0 - amount
   **/
  @:overload(function (name:String, amount:Int, callback:Null<js.Error>->Int->Void):TReturn {})
  function decrby(name:String, amount:Int):TReturn;

  /**
    Delete one or more keys specified by names
   **/
  @:overload(function (args:Array<String>, callback:Null<js.Error>->Int->Void):TReturn {})
  @:overload(function (key:String, callback:Null<js.Error>->Int->Void):TReturn {})
  function del(keys:Rest<String>):TReturn;

  /**
    Echo the string back from the server
   **/
  @:overload(function (value:String, callback:Null<js.Error>->String->Void):TReturn {})
  function echo(value:String):TReturn;

  /**
    Returns an Int (0 = false, 1 = true) indicating whether key name exists
   **/
  @:overload(function (name:String, callback:Null<js.Error>->Int->Void):TReturn {})
  function exists(name:String):TReturn;

  /**
    Set an expire flag on key name for time seconds
   **/
  @:overload(function (name:String, time:Int, callback:Null<js.Error>->Int->Void):TReturn {})
  function expire(name:String, time:Int):TReturn;

  /**
    Set an expire flag on key name. when can be represented as a float indicating unix time
   **/
  @:overload(function (name:String, when:Float, callback:Null<js.Error>->Int->Void):TReturn {})
  function expireat(name:String, when:Float):TReturn;

  /**
    Delete all keys in all databases on the current host
   **/
  @:overload(function (callback:Null<js.Error>->String->Void):TReturn {})
  function flushall():TReturn;

  /**
    Delete all keys in the current database
   **/
  @:overload(function (callback:Null<js.Error>->String->Void):TReturn {})
  function flushdb():TReturn;

  /**
    Return the value at key name, or None if the key doesn’t exist
   **/
  @:overload(function (name:String, callback:Null<js.Error>->String->Void):TReturn {})
  function get(name:String):TReturn;

  /**
    Returns a boolean indicating the value of offset in name
   **/
  @:overload(function (name:String, offset:Int, callback:Null<js.Error>->Int->Void):TReturn {})
  function getbit(name:String, offset:Int):TReturn;

  /**
    Set the value at key name to value if key doesn’t exist Return the value at key name atomically
   **/
  @:overload(function (name:String, value:String, callback:Null<js.Error>->String->Void):TReturn {})
  function getset(name:String, value:String):TReturn;

  /**
    Delete keys from hash name
   **/
  @:overload(function (args:Array<String>, callback:Null<js.Error>->Int->Void):TReturn {})
  @:overload(function (name:String, key:String, callback:Null<js.Error>->Int->Void):TReturn {})
  function hdel(name:String, keys:Rest<String>):TReturn;

  /**
    Returns an Int (0 = false, 1 = true) indicating if key exists within hash name
   **/
  @:overload(function (name:String, key:String, callback:Null<js.Error>->Int->Void):TReturn {})
  function hexists(name:String, key:String):TReturn;

  /**
    Return the value of key within the hash name
   **/
  @:overload(function (name:String, key:String, callback:Null<js.Error>->String->Void):TReturn {})
  function hget(name:String, key:String):TReturn;

  /**
    Increment the value of key in hash name by amount
   **/
  @:overload(function (name:String, key:String, amount:Int, callback:Null<js.Error>->Int->Void):TReturn {})
  function hincrby(name:String, key:String, amount:Int):TReturn;

  /**
    Return the list of keys within hash name
   **/
  @:overload(function (name:String, callback:Null<js.Error>->Array<String>->Void):TReturn {})
  function hkeys(name:String):TReturn;

  /**
    Return the number of elements in hash name
   **/
  @:overload(function (name:String, callback:Null<js.Error>->Int->Void):TReturn {})
  function hlen(name:String):TReturn;

  /**
    Returns a list of values ordered identically to keys
   **/
  @:overload(function (args:Array<String>, callback:Null<js.Error>->Array<String>->Void):TReturn {})
  @:overload(function (key:String, callback:Null<js.Error>->Array<String>->Void):TReturn {})
  function hmget(name:String, keys:Rest<String>):TReturn;

  /**
    Set key to value within hash name Returns 1 if HSET created a new field, otherwise 0
   **/
  @:overload(function (name:String, key:String, value:String, callback:Null<js.Error>->Int->Void):TReturn {})
  function hset(name:String, key:String, value:String):TReturn;

  /**
    Set key to value within hash name if key does not exist. Returns 1 if HSETNX created a field, otherwise 0.
   **/
  @:overload(function (name:String, key:String, value:String, callback:Null<js.Error>->Int->Void):TReturn {})
  function hsetnx(name:String, key:String, value:String):TReturn;

  /**
    Return the list of values within hash name
   **/
  @:overload(function (name:String, callback:Null<js.Error>->Array<String>->Void):TReturn {})
  function hvals(name:String):TReturn;

  /**
    Increments the value of key by 1. If no key exists, the value will be initialized as 1
   **/
  @:overload(function (name:String, callback:Null<js.Error>->Int->Void):TReturn {})
  function incr(name:String):TReturn;

  /**
    Increments the value of key by amount. If no key exists, the value will be initialized as amount
   **/
  @:overload(function (name:String, amount:Int, callback:Null<js.Error>->Int->Void):TReturn {})
  function incrby(name:String, amount:Int):TReturn;

  /**
    Returns a list of keys matching pattern
   **/
  @:overload(function (pattern:String, callback:Null<js.Error>->Array<String>->Void):TReturn {})
  function keys(pattern:String):TReturn;

  /**
    Return a unix timestamp representing the last time the Redis database was saved to disk
   **/
  @:overload(function (callback:Null<js.Error>->Int->Void):TReturn {})
  function lastsave():TReturn;

  /**
    Return the item from list name at position index

    Negative indexes are supported and will return an item at the end of the list
   **/
  @:overload(function (name:String, index:Int, callback:Null<js.Error>->String->Void):TReturn {})
  function lindex(name:String, index:Int):TReturn;

  /**
    Insert value in list name either immediately before or after [where] refvalue

    Returns the new length of the list on success or -1 if refvalue is not in the list.
   **/
  @:overload(function (name:String, where:BeforeAfter, refvalue:String, value:String,
        callback:Null<js.Error>->Int->Void):TReturn {})
  function linsert(name:String, where:BeforeAfter, refvalue:String, value:String):TReturn;

  /**
    Return the length of the list name
   **/
  @:overload(function (name:String, callback:Null<js.Error>->Int->Void):TReturn {})
  function llen(name:String):TReturn;

  // TODO: see how timeout is handled
  // /**
  //   Return a new Lock object using key name that mimics the behavior of threading.Lock.
  //
  //   If specified, timeout indicates a maximum life for the lock. By default, it will remain locked until release() is
  //   called.
  //
  //   sleep indicates the amount of time to sleep per loop iteration when the lock is in blocking mode and another client
  //   is currently holding the lock.
  //  **/
  // function lock(name, timeout=None, sleep=0.1):TReturn;

  /**
    Remove and return the first item of the list name
   **/
  @:overload(function (name:String, callback:Null<js.Error>->String->Void):TReturn {})
  function lpop(name:String):TReturn;

  /**
    Push values onto the head of the list name
   **/
  @:overload(function (args:Array<String>, callback:Null<js.Error>->Int->Void):TReturn {})
  @:overload(function (name:String, value:String, callback:Null<js.Error>->Int->Void):TReturn {})
  function lpush(name:String, values:Rest<String>):TReturn;

  /**
    Push value onto the head of the list name if name exists
   **/
  @:overload(function (name:String, value:String, callback:Null<js.Error>->Int->Void):TReturn {})
  function lpushx(name:String, value:String):TReturn;

  /**
    Return a slice of the list name between position start and end - end included

    start and end can be negative numbers just like Python slicing notation
   **/
  @:overload(function (name:String, start:Int, end:Int, callback:Null<js.Error>->Array<String>->Void):TReturn {})
  function lrange(name:String, start:Int, end:Int):TReturn;

  /**
    Remove the first count occurrences of elements equal to value from the list stored at name.

    The count argument influences the operation in the following ways:
    count > 0: Remove elements equal to value moving from head to tail. count < 0: Remove elements equal to value moving from tail to head. count = 0: Remove all elements equal to value.
   **/
  @:overload(function (name:String, count:Int, value:String, callback:Null<js.Error>->Int->Void):TReturn {})
  function lrem(name:String, count:Int, value:String):TReturn;

  /**
    Set position of list name to value
   **/
  @:overload(function (name:String, index:Int, value:String, callback:Null<js.Error>->String->Void):TReturn {})
  function lset(name:String, index:Int, value:String):TReturn;

  /**
    Trim the list name, removing all values not within the slice between start and end - end included

    start and end can be negative numbers just like Python slicing notation
   **/
  @:overload(function (name:String, start:Int, end:Int, callback:Null<js.Error>->String->Void):TReturn {})
  function ltrim(name:String, start:Int, end:Int):TReturn;

  /**
    Returns a list of values ordered identically to keys
   **/
  @:overload(function (args:Array<String>, callback:Null<js.Error>->Array<String>->Void):TReturn {})
  @:overload(function (key:String, callback:Null<js.Error>->Array<String>->Void):TReturn {})
  function mget(keys:Rest<String>):TReturn;

  /**
    Moves the key name to a different Redis database db
   **/
  @:overload(function (name:String, db:String, callback:Null<js.Error>->Int->Void):TReturn {})
  function move(name:String, db:String):TReturn;

  /**
    Sets each key in the mapping dict to its corresponding value
   **/
  @:overload(function (args:Array<String>, callback:Null<js.Error>->String->Void):TReturn {})
  @:overload(function (key:String, value:String, callback:Null<js.Error>->String->Void):TReturn {})
  function mset(mapping:Rest<String>):TReturn;

  /**
    Sets each key in the mapping dict to its corresponding value if none of the keys are already set
   **/
  @:overload(function (args:Array<String>, callback:Null<js.Error>->Int->Void):TReturn {})
  @:overload(function (key:String, value:String, callback:Null<js.Error>->Int->Void):TReturn {})
  function msetnx(mapping:Rest<String>):TReturn;

  // /**
  //   Return the encoding, idletime, or refcount about the key
  //  **/
  // function object(infotype, key):TReturn;

  /**
    Removes an expiration on name
   **/
  @:overload(function (name:String, callback:Null<js.Error>->Int->Void):TReturn {})
  function persist(name:String):TReturn;

  /**
    Ping the Redis server
   **/
  @:overload(function (callback:Null<js.Error>->String->Void):TReturn {})
  function ping():TReturn;

  /**
    Returns the name of a random key
   **/
  @:overload(function (callback:Null<js.Error>->String->Void):TReturn {})
  function randomkey():TReturn;

  /**
    Rename key src to dst
   **/
  @:overload(function (src:String, dst:String, callback:Null<js.Error>->String->Void):TReturn {})
  function rename(src:String, dst:String):TReturn;

  /**
    Rename key src to dst if dst doesn’t already exist
   **/
  @:overload(function (src:String, dst:String, callback:Null<js.Error>->Int->Void):TReturn {})
  function renamenx(src:String, dst:String):TReturn;

  /**
    Remove and return the last item of the list name
   **/
  @:overload(function (name:String, callback:Null<js.Error>->String->Void):TReturn {})
  function rpop(name:String):TReturn;

  /**
    RPOP a value off of the src list and atomically LPUSH it on to the dst list. Returns the value.
   **/
  @:overload(function (src:String, dst:String, callback:Null<js.Error>->String->Void):TReturn {})
  function rpoplpush(src:String, dst:String):TReturn;

  /**
    Push values onto the tail of the list name
   **/
  @:overload(function (args:Array<String>, callback:Null<js.Error>->Int->Void):TReturn {})
  @:overload(function (name:String, values:String, callback:Null<js.Error>->Int->Void):TReturn {})
  function rpush(name:String, values:Rest<String>):TReturn;

  /**
    Push value onto the tail of the list name if name exists
   **/
  @:overload(function (name:String, value:String, callback:Null<js.Error>->Int->Void):TReturn {})
  function rpushx(name:String, value:String):TReturn;

  /**
    Add value(s) to set name
   **/
  @:overload(function (args:Array<String>, callback:Null<js.Error>->Int->Void):TReturn {})
  @:overload(function (name:String, value:String, callback:Null<js.Error>->Int->Void):TReturn {})
  function sadd(name:String, values:Rest<String>):TReturn;

  /**
    Tell the Redis server to save its data to disk. Blocks all requests until finished
   **/
  @:overload(function (callback:Null<js.Error>->String->Void):TReturn {})
  function save():TReturn;

  /**
    Return the number of elements in set name
   **/
  @:overload(function (name:String, callback:Null<js.Error>->Int->Void):TReturn {})
  function scard(name:String):TReturn;

  /**
    Return the difference of sets specified by keys
   **/
  @:overload(function (args:Array<String>, callback:Null<js.Error>->Array<String>->Void):TReturn {})
  @:overload(function (key:String, callback:Null<js.Error>->Array<String>->Void):TReturn {})
  function sdiff(keys:Rest<String>):TReturn;

  /**
    Store the difference of sets specified by keys into a new set named dest. Returns the number of keys in the new set.
   **/
  @:overload(function (args:Array<String>, callback:Null<js.Error>->Int->Void):TReturn {})
  @:overload(function (dest:String, key:String, callback:Null<js.Error>->Int->Void):TReturn {})
  function sdiffstore(dest:String, keys:Rest<String>):TReturn;

  /**
    Set the value at key name to value
   **/
  @:overload(function (name:String, value:String, callback:Null<js.Error>->String->Void):TReturn {})
  function set(name:String, value:String):TReturn;

  /**
    Flag the offset in name as value. Returns an Int indicating the previous value of offset.
   **/
  @:overload(function (name:String, offset:Int, value:Int, callback:Null<js.Error>->Int->Void):TReturn {})
  function setbit(name:String, offset:Int, value:Int):TReturn;

  /**
    Set the value of key name to value that expires in time seconds
   **/
  @:overload(function (name:String, time:Int, value:String, callback:Null<js.Error>->Int->Void):TReturn {})
  function setex(name:String, time:Int, value:String):TReturn;

  /**
    Set the value of key name to value if key doesn’t exist
   **/
  @:overload(function (name:String, value:String, callback:Null<js.Error>->Int->Void):TReturn {})
  function setnx(name:String, value:String):TReturn;

  /**
    Overwrite bytes in the value of name starting at offset with value. If offset plus the length of value exceeds the
    length of the original value, the new value will be larger than before. If offset exceeds the length of the original
    value, null bytes will be used to pad between the end of the previous value and the start of what’s being injected.

    Returns the length of the new string.
   **/
  @:overload(function (name:String, offset:Int, value:String, callback:Null<js.Error>->Int->Void):TReturn {})
  function setrange(name:String, offset:Int, value:String):TReturn;

  /**
    Shutdown the server
   **/
  @:overload(function (callback:Null<js.Error>->String->Void):TReturn {})
  function shutdown():TReturn;

  /**
    Return the intersection of sets specified by keys
   **/
  @:overload(function (args:Array<String>, callback:Null<js.Error>->Array<String>->Void):TReturn {})
  @:overload(function (key:String, callback:Null<js.Error>->Array<String>->Void):TReturn {})
  function sinter(keys:Rest<String>):TReturn;

  /**
    Store the intersection of sets specified by keys into a new set named dest. Returns the number of keys in the new
    set.
   **/
  @:overload(function (args:Array<String>, callback:Null<js.Error>->Int->Void):TReturn {})
  @:overload(function (dest:String, keys:String, callback:Null<js.Error>->Int->Void):TReturn {})
  function sinterstore(dest:String, keys:Rest<String>):TReturn;

  /**
    Return an Int indicating if value is a member of set name
   **/
  @:overload(function (name:String, value:String, callback:Null<js.Error>->Int->Void):TReturn {})
  function sismember(name:String, value:String):TReturn;

  /**
    Set the server to be a replicated slave of the instance identified by the host and port. If called without
    arguements, the instance is promoted to a master instead.
   **/
  @:overload(function (host:String, port:Int, callback:Null<js.Error>->String->Void):TReturn {})
  function slaveof(host:String, port:Int):TReturn;

  // /**
  //   Return the last count items from the slowlog
  //  **/
  // function slowlog_get(count=None):TReturn;
  //
  // /**
  //   Get the current slowlog length
  //  **/
  // function slowlog_len():TReturn;
  //
  // /**
  //   Reset the slowlog
  //  **/
  // function slowlog_reset():TReturn;

  /**
    Return all members of the set name
   **/
  @:overload(function (name:String, callback:Null<js.Error>->Array<String>->Void):TReturn {})
  function smembers(name:String):TReturn;

  /**
    Move value from set src to set dst atomically
   **/
  @:overload(function (src:String, dst:String, value:String, callback:Null<js.Error>->Int->Void):TReturn {})
  function smove(src:String, dst:String, value:String):TReturn;

  // TODO
//   /**
//     Sort and return the list, set or sorted set at name.
//
//     start and num allow for paging through the sorted data
//
//     by allows using an external key to weight and sort the items.  Use an “*” to indicate where in the key the item
//     value is located get allows for returning items from external keys rather than the sorted data itself. Use an “*” to
//     indicate where int he key the item value is located desc allows for reversing the sort
//
//     alpha allows for sorting lexicographically rather than numerically
//
//     store allows for storing the result of the sort into
// the key store **/
//   function sort(name:String, start=None, num=None, by=None, get=None, desc=False, alpha=False, store=None):TReturn;

  /**
    Remove and return a random member of set name
   **/
  @:overload(function (name:String, callback:Null<js.Error>->String->Void):TReturn {})
  function spop(name:String):TReturn;

  /**
    Return a random member of set name
   **/
  @:overload(function (name:String, callback:Null<js.Error>->String->Void):TReturn {})
  function srandmember(name:String):TReturn;

  /**
    Remove values from set name
   **/
  @:overload(function (args:Array<String>, callback:Null<js.Error>->Int->Void):TReturn {})
  @:overload(function (name:String, values:String, callback:Null<js.Error>->Int->Void):TReturn {})
  function srem(name:String, values:Rest<String>):TReturn;

  /**
    Return the number of bytes stored in the value of name
   **/
  @:overload(function (name:String, callback:Null<js.Error>->Int->Void):TReturn {})
  function strlen(name:String):TReturn;

  /**
    Return the union of sets specifiued by keys
   **/
  @:overload(function (args:Array<String>, callback:Null<js.Error>->Array<String>->Void):TReturn {})
  @:overload(function (keys:String, callback:Null<js.Error>->Array<String>->Void):TReturn {})
  function sunion(keys:Rest<String>):TReturn;

  /**
    Store the union of sets specified by keys into a new set named dest. Returns the number of keys in the new set.
   **/
  @:overload(function (args:Array<String>, callback:Null<js.Error>->Int->Void):TReturn {})
  @:overload(function (dest:String, keys:String, callback:Null<js.Error>->Int->Void):TReturn {})
  function sunionstore(dest:String, keys:Rest<String>):TReturn;

  /**
    Returns the number of seconds until the key name will expire
   **/
  @:overload(function (name:String, callback:Null<js.Error>->Int->Void):TReturn {})
  function ttl(name:String):TReturn;

  /**
    Returns the type of key name
   **/
  @:overload(function (name:String, callback:Null<js.Error>->String->Void):TReturn {})
  function type(name:String):TReturn;

  /**
    Set any number of score, element-name pairs to the key name
   **/
  @:overload(function (name:String, opt:ZAddOptions, score:ZFloat, member:String, callback:Null<js.Error>->Int->Void):TReturn {})
  @:overload(function (name:String, opt:ZAddOptions, score:ZFloat, member:String):TReturn {})
  @:overload(function (name:String, score:ZFloat, member:String, callback:Null<js.Error>->Int->Void):TReturn {})
  @:overload(function (name:String, score:ZFloat, member:String, scoreMemebers:Rest<Dynamic>):TReturn {})
  @:overload(function (args:Array<Dynamic>, callback:Null<js.Error>->Int->Void):TReturn {})
  function zadd(name:String, score:ZFloat, member:String):TReturn;

  /**
    Return the number of elements in the sorted set name
   **/
  @:overload(function (name:String, callback:Null<js.Error>->Int->Void):TReturn {})
  function zcard(name:String):TReturn;

  /**
    Increment the score of value in sorted set name by amount
    Returns a String representing the floating point value of the new score of the member
   **/
  @:overload(function (name:String, value:ZFloat, member:String, callback:Null<js.Error>->String->Void):TReturn {})
  function zincrby(name:String, value:ZFloat, member:String):TReturn;

  // /**
  //   Intersect multiple sorted sets specified by keys into a new sorted set, dest. Scores in the destination will be
  //   aggregated based on the aggregate, or SUM if none is provided.
  //  **/
  // function zinterstore(dest:String, numkeys:Int, key, keys, aggregate=None):TReturn;

  /**
    Return a range of values from sorted set name between start and end sorted in ascending order.
    start and end can be negative, indicating the end of the range.
    desc a boolean indicating whether to sort the results descendingly
    withscores indicates to return the scores along with the values.
   **/
  @:overload(function (name:String, start:Int, end:Int, withScores:ZWithScores,
        callback:Null<js.Error>->Array<Dynamic>->Void):TReturn {})
  @:overload(function (name:String, start:Int, end:Int, callback:Null<js.Error>->Array<String>->Void):TReturn {})
  @:overload(function (name:String, start:Int, end:Int, withScores:ZWithScores):TReturn {})
  function zrange(name:String, start:Int, end:Int):TReturn;

  /**
    Return a range of values from the sorted set name with scores between min and max.
    withscores indicates to return the scores along with the values.
   **/
  @:overload(function (name:String, min:ZFloat, max:ZFloat, limit:ZLimit, offset:Int, count:Int,
        callback:Null<js.Error>->Array<String>->Void):TReturn {})
  @:overload(function (name:String, min:ZFloat, max:ZFloat, withScores:ZWithScores, limit:ZLimit, offset:Int, count:Int,
        callback:Null<js.Error>->Array<Dynamic>->Void):TReturn {})
  @:overload(function (name:String, min:ZFloat, max:ZFloat, withScores:ZWithScores,
        callback:Null<js.Error>->Array<Dynamic>->Void):TReturn {})
  @:overload(function (name:String, min:ZFloat, max:ZFloat, callback:Null<js.Error>->Array<String>->Void):TReturn {})
  @:overload(function (name:String, min:ZFloat, max:ZFloat, limit:ZLimit, offset:Int, count:Int):TReturn {})
  @:overload(function (name:String, min:ZFloat, max:ZFloat, withScores:ZWithScores, limit:ZLimit, offset:Int, count:Int ):TReturn {})
  @:overload(function (name:String, min:ZFloat, max:ZFloat, withScores:ZWithScores):TReturn {})
  function zrangebyscore(name:String, min:ZFloat, max:ZFloat):TReturn;

  /**
    Returns a 0-based value indicating the rank of key in sorted set name
   **/
  @:overload(function (name:String, key:String, callback:Null<js.Error>->Null<Int>->Void):TReturn {})
  function zrank(name:String, key:String):TReturn;

  /**
    Remove member values from sorted set name
   **/
  @:overload(function (args:Array<String>, callback:Null<js.Error>->Int->Void):TReturn {})
  @:overload(function (name:String, key:String, callback:Null<js.Error>->Int->Void):TReturn {})
  function zrem(name:String, keys:Rest<String>):TReturn;

  /**
    Remove all elements in the sorted set name with ranks between min and max. Values are 0-based, ordered from smallest
    score to largest. Values can be negative indicating the highest scores. Returns the number of elements removed
   **/
  @:overload(function (name:String, min:Int, max:Int, callback:Null<js.Error>->Int->Void):TReturn {})
  function zremrangebyrank(name:String, min:Int, max:Int):TReturn;

  /**
    Remove all elements in the sorted set name with scores between min and max. Returns the number of elements removed.
   **/
  @:overload(function (name:String, min:ZFloat, max:ZFloat, callback:Null<js.Error>->Int->Void):TReturn {})
  function zremrangebyscore(name:String, min:ZFloat, max:ZFloat):TReturn;

  /**
    Return a range of values from sorted set name between start and num sorted in descending order.
    start and num can be negative, indicating the end of the range.
    withscores indicates to return the scores along with the values The return type is a list of (value, score) pairs
   **/
  @:overload(function (name:String, start:Int, end:Int, withScores:ZWithScores,
        callback:Null<js.Error>->Array<Dynamic>->Void):TReturn {})
  @:overload(function (name:String, start:Int, end:Int, callback:Null<js.Error>->Array<String>->Void):TReturn {})
  @:overload(function (name:String, start:Int, end:Int, withScores:ZWithScores):TReturn {})
  function zrevrange(name:String, start:Int, num:Int):TReturn;

  /**
    Return a range of values from the sorted set name with scores between min and max in descending order.

    If start and num are specified, then return a slice of the range.

    withscores indicates to return the scores along with the values. The return type is a list of (value, score) pairs

    score_cast_func a callable used to cast the score return value
   **/
  @:overload(function (name:String, min:ZFloat, max:ZFloat, limit:ZLimit, offset:Int, count:Int,
        callback:Null<js.Error>->Array<String>->Void):TReturn {})
  @:overload(function (name:String, min:ZFloat, max:ZFloat, withScores:ZWithScores, limit:ZLimit, offset:Int, count:Int,
        callback:Null<js.Error>->Array<Dynamic>->Void):TReturn {})
  @:overload(function (name:String, min:ZFloat, max:ZFloat, withScores:ZWithScores,
        callback:Null<js.Error>->Array<Dynamic>->Void):TReturn {})
  @:overload(function (name:String, min:ZFloat, max:ZFloat, callback:Null<js.Error>->Array<String>->Void):TReturn {})
  @:overload(function (name:String, min:ZFloat, max:ZFloat, limit:ZLimit, offset:Int, count:Int):TReturn {})
  @:overload(function (name:String, min:ZFloat, max:ZFloat, withScores:ZWithScores, limit:ZLimit, offset:Int, count:Int ):TReturn {})
  @:overload(function (name:String, min:ZFloat, max:ZFloat, withScores:ZWithScores):TReturn {})
  function zrevrangebyscore(name:String, min:ZFloat, max:ZFloat):TReturn;

  /**
    Returns a 0-based value indicating the descending rank of key in sorted set name
   **/
  @:overload(function (name:String, key:String, callback:Null<js.Error>->Int->Void):TReturn {})
  function zrevrank(name:String, key:String):TReturn;

  /**
    Return the score of element key in sorted set name
    Returns a string representing a Float
   **/
  @:overload(function (name:String, key:String, callback:Null<js.Error>->String->Void):TReturn {})
  function zscore(name:String, key:String):TReturn;

  // /**
  //   Union multiple sorted sets specified by keys into a new sorted set, dest. Scores in the destination will be
  //   aggregated based on the aggregate, or SUM if none is provided.
  //  **/
  // function zunionstore(dest, keys, aggregate=None):TReturn;
}

extern class RedisClient extends RedisClientBase<RedisClient, Void> {}

extern class Multi extends RedisClientBase<Multi, Multi> {
  /**
    client.multi() is a constructor that returns a Multi object. Multi objects share all of the same command methods as
    client objects do. Commands are queued up inside the Multi object until Multi.exec() is invoked.

    If your code contains an syntax error an EXECABORT error is going to be thrown and all commands are going to be
    aborted. That error contains a .errors property that contains the concret errors. If all commands were queued
    successfully and an error is thrown by redis while processing the commands that error is going to be returned in the
    result array! No other command is going to be aborted though than the onces failing.

    You can either chain together MULTI commands as in the above example, or you can queue individual commands while
    still sending regular client command as in this example:
   **/
  @:overload(function(callback:Null<MultiError>->Array<GenericRedisResponse>->Void):Void {})
  function exec():Void;

  /**
    Identical to Multi.exec but with the difference that executing a single command will not use transactions.
   **/
  @:overload(function(callback:Null<MultiError>->Array<GenericRedisResponse>->Void):Void {})
  function exec_atomic():Void;
}

extern class MultiError extends js.Error {
  public var errors:Array<js.Error>;
}

@:enum abstract BeforeAfter(String) from String {
  var Before = "BEFORE";
  var After = "AFTER";
}

abstract GenericRedisResponse(Dynamic)
  from Dynamic
  from Array<String> to Array<String>
  from String to String
  from Int to Int
{
  @:extern inline public function asArray():Array<String> {
    if (Std.is(this, Array)) {
      return this;
    } else {
      return null;
    }
  }

  @:extern inline public function asString():String {
    if (Std.is(this, String)) {
      return this;
    } else {
      return null;
    }
  }

  @:extern inline public function asInt():Null<Int> {
    if (Std.is(this, Int)) {
      return this;
    } else {
      return null;
    }
  }
}

@:enum abstract ZAddOptions(String) to String {
  /**
    Only update elements that already exist. Never add elements.
   **/
  var Xx = 'XX';

  /**
    Don't update already existing elements. Always add new elements.
   **/
  var Nx = 'NX';

  /**
    Modify the return value from the number of new elements added, to the total number of elements changed (CH is an
    abbreviation of changed). Changed elements are new elements added and elements already existing for which the score
    was updated. So elements specified in the command line having the same score as they had in the past are not
    counted. Note: normally the return value of ZADD only counts the number of new elements added.
   **/
  var Ch = 'CH';

  /**
    When this option is specified ZADD acts like ZINCRBY. Only one score-element pair can be specified in this mode.
   **/
  var Incr = 'INCR';
}

@:enum abstract ZAggregate(String) to String {
  var Sum = 'SUM';
  var Min = 'MIN';
  var Max = 'MAX';
}

@:enum abstract ZWithScores(String) to String {
  var WithScores = 'WITHSCORES';
}

@:enum abstract ZLimit(String) to String {
  var Limit = 'LIMIT';
}

abstract ZFloat(String) to String {
  public static var infinity(get,never):ZFloat;
  public static var negativeInfinity(get,never):ZFloat;

  @:extern inline private static function get_infinity():ZFloat {
    return cast '+inf';
  }
  @:extern inline private static function get_negativeInfinity():ZFloat {
    return cast '-inf';
  }

  @:from @:extern inline public static function fromFloat(f:Float):ZFloat {
    return cast f + '';
  }

  @:to @:extern inline public function toFloat() {
    return Std.parseFloat(this);
  }
}
