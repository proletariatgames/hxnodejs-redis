package js.npm.redis;
import js.node.buffer.Buffer;
import js.node.events.EventEmitter;
import js.npm.redis.Callbacks;
import haxe.DynamicAccess;
import haxe.extern.Rest;
import haxe.Constraints;
#if haxe4
import js.lib.Error;
#else
import js.Error;
#end

abstract RedisString(Dynamic) from String from Buffer {
  @:to public function asBuffer():Buffer {
    return (this == null || Std.is(this, Buffer)) ? this : new Buffer(this);
  }

  @:to public function asString():String {
    return (this == null || Std.is(this, String)) ? this : this.toString();
  }
}

typedef SimpleStringReply = String;

@:enum abstract SimpleString(SimpleStringReply) from SimpleStringReply to SimpleStringReply
{
  var Ok = "OK";

  inline public function toString()
  {
    return this;
  }
}

@:forward abstract AnyKey(RedisString) from String from Buffer to RedisString from RedisString {}
@:forward abstract Key(AnyKey) from String from Buffer from AnyKey to AnyKey to RedisString from RedisString {}
@:forward abstract HashKey(AnyKey) from String from Buffer from AnyKey to AnyKey to RedisString from RedisString {}
@:forward abstract SetKey(AnyKey) from String from Buffer from AnyKey to AnyKey to RedisString from RedisString {}
@:forward abstract ZSetKey(AnyKey) from String from Buffer from AnyKey to AnyKey to RedisString from RedisString {}
@:forward abstract ListKey(AnyKey) from String from Buffer from AnyKey to AnyKey to RedisString from RedisString {}
// @:forward abstract Key(String) from String to String {}
// @:forward abstract Key(String) from String to String {}



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
  var Error : RedisEvent<Error->Void> = "error";

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
  var Message : RedisSubscriptionEvent<RedisString->RedisString->Void> = "message"; /** (channel, message) **/

  /**
    Client will emit pmessage for every message received that matches an active subscription pattern. Listeners are passed
    the original pattern used with PSUBSCRIBE as pattern, the sending channel name as channel, and the message Buffer as
    message.
   **/
  var PMessage : RedisSubscriptionEvent<RedisString->RedisString->RedisString->Void> = "pmessage"; /** (pattern, channel, message) **/

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
  @:overload(function(password:RedisString):TReturn {})
  function auth(password:RedisString, callback:VoidCallback):TReturn;

  /**
    Forcibly close the connection to the Redis server. Note that this does not wait until all replies have been parsed.
    If you want to exit cleanly, call client.quit() to send the QUIT command after you have handled all replies.

    You should set flush to true, if you are not absolutely sure you do not care about any other commands. If you set
    flush to false all still running commands will silently fail.
   **/
  function end(flush:Bool):Void;

  /**
    This sends the quit command to the redis server and ends cleanly right after all running commands were properly
    handled. If this is called while reconnecting (and therefor no connection to the redis server exists) it is going to
    end the connection right away instead of resulting in further reconnections! All offline commands are going to be
    flushed with an error in that case.
   **/
  function quit():Void;

  /**
    Call unref() on the underlying socket connection to the Redis server, allowing the program to exit once no more
    commands are pending.

    This is an experimental feature, and only supports a subset of the Redis protocol. Any commands where client state
    is saved on the Redis server, e.g. *SUBSCRIBE or the blocking BL* commands will NOT work with .unref().
   **/
  function unref():Void;

  /**
    Duplicate all current options and return a new redisClient instance. All
    options passed to the duplicate function are going to replace the
    original option. If you pass a callback, duplicate is going to wait until
    the client is ready and returns it in the callback. If an error occurs in
    the meanwhile, that is going to return an error instead in the callback.

    One example of when to use duplicate() would be to accommodate the
    connection- blocking redis commands BRPOP, BLPOP, and BRPOPLPUSH. If
    these commands are used on the same redisClient instance as non-blocking
    commands, the non-blocking ones may be queued up until after the blocking
    ones finish.
  **/
  @:overload(function(callback:Error->RedisClient->Void):RedisClient {})
  @:overload(function(options:js.npm.Redis.RedisOptions, callback:Error->RedisClient->Void):RedisClient {})
  @:overload(function(options:js.npm.Redis.RedisOptions):RedisClient {})
  function duplicate():RedisClient;

  /**
    The reply from an HGETALL command will be converted into a JavaScript Object by node_redis. That way you can
    interact with the responses using JavaScript syntax.
   **/
  function hgetall(name:HashKey, callback:Callback<DynamicAccess<RedisString>>):TReturn;

  /**
    Multiple values in a hash can be set by supplying an object:
   **/
  @:overload(function (name:HashKey, obj:Dynamic<String>):TReturn {})
  @:overload(function (name:HashKey, obj:Dynamic<String>, callback:VoidCallback):TReturn {})
  @:overload(function (name:HashKey, values:Rest<RedisString>):TReturn {})
  @:overload(function (name:HashKey, values:Array<RedisString>):TReturn {})
  @:overload(function (name:HashKey, values:Array<RedisString>, callback:VoidCallback):TReturn {})
  @:overload(function (name:HashKey, key:RedisString, value:RedisString, callback:VoidCallback):TReturn {})
  function hmset(name:HashKey, obj:Dynamic<String>, callback:VoidCallback):TReturn;

  /**
    When a client issues a SUBSCRIBE or PSUBSCRIBE, that connection is put into a "subscriber" mode. At that point, only
    commands that modify the subscription set are valid. When the subscription set is empty, the connection is put back
    into regular mode.

    If you need to send regular commands to Redis while in subscriber mode, just open another connection.
   **/
  @:overload(function(channels:Rest<RedisString>):TReturn {})
  @:overload(function(channels:Array<RedisString>):TReturn {})
  function subscribe(channel:RedisString):TReturn;

  /**
    Subscribes to a pattern
   **/
  function psubscribe(channel:RedisString):TReturn;

  /**
    Unsubscribe to a pattern
   **/
  @:overload(function(channels:Rest<RedisString>):Void {})
  @:overload(function(channels:Array<RedisString>):Void {})
  function unsubscribe():Void;

  @:overload(function(channel:RedisString, message:RedisString, callback:Callback<Int>):TReturn {})
  function publish(channel:RedisString, message:RedisString):TReturn;

  /**
    MULTI commands are queued up until an EXEC is issued, and then all commands are run atomically by Redis. The
    interface in node_redis is to return an individual Multi object by calling client.multi(). If any command fails to
    queue, all commands are rolled back and none is going to be executed (For further information look at transactions).
   **/
  function multi(?commandList :Array<Array<String>>):Multi;

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
  @:overload(function(name:Key, value:RedisString, callback:Callback<RedisString>):TReturn {})
  function append(name:Key, value:RedisString):TReturn;

  /**
    Tell the Redis server to rewrite the AOF file from data in memory.
   **/
  @:overload(function(callback:Callback<RedisString>):TReturn {})
  function bgrewriteaof():TReturn;

  /**
    Tell the Redis server to save its data to disk.
   **/
  @:overload(function (callback:Callback<RedisString>):TReturn {})
  function bgsave():TReturn;

  /**
    LPOP a value off of the first non-empty list named in the keys list.

    If none of the lists in keys has a value to LPOP, then block for timeout seconds, or until a value gets pushed on to one of the lists.

    If timeout is 0, then block indefinitely.
   **/
  @:overload(function (data:Array<Dynamic>):TReturn {})
  @:overload(function (data:Array<Dynamic>, callback:Callback<Null<Array<RedisString>>>):TReturn {})
  @:overload(function (key:ListKey, timeoutSeconds:Int, callback:Callback<Null<Array<RedisString>>>):TReturn {})
  function blpop(key:ListKey, timeoutSeconds:Int):TReturn;

  /**
    RPOP a value off of the first non-empty list named in the keys list.

    If none of the lists in keys has a value to LPOP, then block for timeout seconds, or until a value gets pushed on to
    one of the lists.

    If timeout is 0, then block indefinitely.
   **/
  @:overload(function (data:Array<Dynamic>):TReturn {})
  @:overload(function (data:Array<Dynamic>, callback:Callback<Null<Array<RedisString>>>):TReturn {})
  @:overload(function (key:ListKey, timeoutSeconds:Int, callback:Callback<Null<Array<RedisString>>>):TReturn {})
  function brpop(key:ListKey, timeoutSeconds:Int):TReturn;

  /**
    Pop a value off the tail of src, push it on the head of dst and then return it.

    This command blocks until a value is in src or until timeout seconds elapse, whichever is first. A timeout value of
    0 blocks forever.
   **/
  @:overload(function (src:ListKey, dst:ListKey, timeoutSeconds:Int, callback:Callback<Null<RedisString>>):TReturn {})
  function brpoplpush(src:ListKey, dst:ListKey, timeoutSeconds:Int):TReturn;

  /**
    Returns the number of keys in the current database
   **/
  @:overload(function (callback:Callback<Int>):TReturn {})
  function dbsize():TReturn;

  /**
    Returns version specific metainformation about a give key
    `type` should be `object`
   **/
  @:overload(function (type:RedisString, key:RedisString, callback:Callback<RedisString>):TReturn {})
  function debug(type:RedisString, key:RedisString):TReturn;

  /**
    Decrements the value of key by 1. If no key exists, the value will be initialized as -1
   **/
  @:overload(function (name:Key, callback:Callback<Int>):TReturn {})
  function decr(name:Key):TReturn;

  /**
    Decrements the value of key by amount. If no key exists, the value will be initialized as 0 - amount
   **/
  @:overload(function (name:Key, amount:Int, callback:Callback<Int>):TReturn {})
  function decrby(name:Key, amount:Int):TReturn;

  /**
    Delete one or more keys specified by names
   **/
  @:overload(function (args:Array<AnyKey>):TReturn {})
  @:overload(function (args:Array<AnyKey>, callback:Callback<Int>):TReturn {})
  @:overload(function (key:AnyKey, callback:Callback<Int>):TReturn {})
  function del(keys:Rest<AnyKey>):TReturn;

  /**
    Echo the string back from the server
   **/
  @:overload(function (value:RedisString, callback:Callback<RedisString>):TReturn {})
  function echo(value:RedisString):TReturn;

  /**
    Returns an Int (0 = false, 1 = true) indicating whether key name exists
   **/
  @:overload(function (name:AnyKey, callback:Callback<Int>):TReturn {})
  function exists(name:AnyKey):TReturn;

  /**
    Set an expire flag on key name for time seconds
   **/
  @:overload(function (name:AnyKey, time:Int, callback:Callback<Int>):TReturn {})
  function expire(name:AnyKey, time:Int):TReturn;

  /**
    Set an expire flag on key name. when can be represented as a float indicating unix time
   **/
  @:overload(function (name:AnyKey, when:Float, callback:Callback<Int>):TReturn {})
  function expireat(name:AnyKey, when:Float):TReturn;

  /**
    Evaluate Lua script
   **/
  public function eval(prms:Array<Dynamic>,callback:Callback<Dynamic>):TReturn;

  /**
    Evaluate Lua script by its SHA digest
   **/
  public function evalsha(prms:Array<Dynamic>,callback:Callback<Dynamic>):TReturn;

  /**
    Delete all keys in all databases on the current host
   **/
  @:overload(function (callback:Callback<RedisString>):TReturn {})
  function flushall():TReturn;

  /**
    Delete all keys in the current database
   **/
  @:overload(function (callback:Callback<RedisString>):TReturn {})
  function flushdb():TReturn;

  /**
    Return the value at key name, or None if the key doesn’t exist
   **/
  @:overload(function (name:Key, callback:Callback<RedisString>):TReturn {})
  function get(name:Key):TReturn;

  /**
    Returns a boolean indicating the value of offset in name
   **/
  @:overload(function (name:RedisString, offset:Int, callback:Callback<Int>):TReturn {})
  function getbit(name:RedisString, offset:Int):TReturn;

  /**
    Set the value at key name to value if key doesn’t exist Return the value at key name atomically
   **/
  @:overload(function (name:Key, value:RedisString, callback:Callback<RedisString>):TReturn {})
  function getset(name:Key, value:RedisString):TReturn;

  /**
    Delete keys from hash name
   **/
  @:overload(function (args:Array<RedisString>):TReturn {})
  @:overload(function (args:Array<RedisString>, callback:Callback<Int>):TReturn {})
  @:overload(function (name:HashKey, key:RedisString, callback:Callback<Int>):TReturn {})
  function hdel(name:HashKey, keys:Rest<RedisString>):TReturn;

  /**
    Returns an Int (0 = false, 1 = true) indicating if key exists within hash name
   **/
  @:overload(function (name:HashKey, key:RedisString, callback:Callback<Int>):TReturn {})
  function hexists(name:HashKey, key:RedisString):TReturn;

  /**
    Return the value of key within the hash name
   **/
  @:overload(function (name:HashKey, key:RedisString, callback:Callback<RedisString>):TReturn {})
  function hget(name:HashKey, key:RedisString):TReturn;

  /**
    Increment the value of key in hash name by amount
   **/
  @:overload(function (name:HashKey, key:RedisString, amount:Int, callback:Callback<Int>):TReturn {})
  function hincrby(name:HashKey, key:RedisString, amount:Int):TReturn;

  /**
    Return the list of keys within hash name
   **/
  @:overload(function (name:HashKey, callback:Callback<Array<RedisString>>):TReturn {})
  function hkeys(name:HashKey):TReturn;

  /**
    Return the number of elements in hash name
   **/
  @:overload(function (name:HashKey, callback:Callback<Int>):TReturn {})
  function hlen(name:HashKey):TReturn;

  /**
    Returns a list of values ordered identically to keys
   **/
  @:overload(function (args:Array<RedisString>):TReturn {})
  @:overload(function (args:Array<RedisString>, callback:Callback<Array<RedisString>>):TReturn {})
  @:overload(function (key:HashKey, callback:Callback<Array<RedisString>>):TReturn {})
  function hmget(name:HashKey, keys:Rest<RedisString>):TReturn;

  /**
    Set key to value within hash name Returns 1 if HSET created a new field, otherwise 0
   **/
  @:overload(function (name:HashKey, key:RedisString, value:RedisString, callback:Callback<Int>):TReturn {})
  function hset(name:HashKey, key:RedisString, value:RedisString):TReturn;

  /**
    Set key to value within hash name if key does not exist. Returns 1 if HSETNX created a field, otherwise 0.
   **/
  @:overload(function (name:HashKey, key:RedisString, value:RedisString, callback:Callback<Int>):TReturn {})
  function hsetnx(name:HashKey, key:RedisString, value:RedisString):TReturn;

  /**
    Return the list of values within hash name
   **/
  @:overload(function (name:HashKey, callback:Callback<Array<RedisString>>):TReturn {})
  function hvals(name:HashKey):TReturn;

  /**
    Increments the value of key by 1. If no key exists, the value will be initialized as 1
   **/
  @:overload(function (name:Key, callback:Callback<Int>):TReturn {})
  function incr(name:Key):TReturn;

  /**
    Increments the value of key by amount. If no key exists, the value will be initialized as amount
   **/
  @:overload(function (name:Key, amount:Int, callback:Callback<Int>):TReturn {})
  function incrby(name:Key, amount:Int):TReturn;

  /**
    Returns a list of keys matching pattern
   **/
  @:overload(function (pattern:RedisString, callback:Callback<Array<RedisString>>):TReturn {})
  function keys(pattern:RedisString):TReturn;

  /**
    Return a unix timestamp representing the last time the Redis database was saved to disk
   **/
  @:overload(function (callback:Callback<Int>):TReturn {})
  function lastsave():TReturn;

  /**
    Return the item from list name at position index

    Negative indexes are supported and will return an item at the end of the list
   **/
  @:overload(function (name:ListKey, index:Int, callback:Callback<RedisString>):TReturn {})
  function lindex(name:ListKey, index:Int):TReturn;

  /**
    Insert value in list name either immediately before or after [where] refvalue

    Returns the new length of the list on success or -1 if refvalue is not in the list.
   **/
  @:overload(function (name:ListKey, where:BeforeAfter, refvalue:RedisString, value:RedisString,
        callback:Callback<Int>):TReturn {})
  function linsert(name:ListKey, where:BeforeAfter, refvalue:RedisString, value:RedisString):TReturn;

  /**
    Return the length of the list name
   **/
  @:overload(function (name:ListKey, callback:Callback<Int>):TReturn {})
  function llen(name:ListKey):TReturn;

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
  @:overload(function (name:ListKey, callback:Callback<RedisString>):TReturn {})
  function lpop(name:ListKey):TReturn;

  /**
    Push values onto the head of the list name
   **/
  @:overload(function (args:Array<RedisString>):TReturn {})
  @:overload(function (args:Array<RedisString>, callback:Callback<Int>):TReturn {})
  @:overload(function (name:ListKey, value:RedisString, callback:Callback<Int>):TReturn {})
  function lpush(name:ListKey, values:Rest<RedisString>):TReturn;

  /**
    Push value onto the head of the list name if name exists
   **/
  @:overload(function (name:ListKey, value:RedisString, callback:Callback<Int>):TReturn {})
  function lpushx(name:ListKey, value:RedisString):TReturn;

  /**
    Return a slice of the list name between position start and end - end included

    start and end can be negative numbers just like Python slicing notation
   **/
  @:overload(function (name:ListKey, start:Int, end:Int, callback:Callback<Array<RedisString>>):TReturn {})
  function lrange(name:ListKey, start:Int, end:Int):TReturn;

  /**
    Remove the first count occurrences of elements equal to value from the list stored at name.

    The count argument influences the operation in the following ways:
    count > 0: Remove elements equal to value moving from head to tail. count < 0: Remove elements equal to value moving from tail to head. count = 0: Remove all elements equal to value.
   **/
  @:overload(function (name:ListKey, count:Int, value:RedisString, callback:Callback<Int>):TReturn {})
  function lrem(name:ListKey, count:Int, value:RedisString):TReturn;

  /**
    Set position of list name to value
   **/
  @:overload(function (name:ListKey, index:Int, value:RedisString, callback:Callback<RedisString>):TReturn {})
  function lset(name:ListKey, index:Int, value:RedisString):TReturn;

  /**
    Trim the list name, removing all values not within the slice between start and end - end included

    start and end can be negative numbers just like Python slicing notation
   **/
  @:overload(function (name:ListKey, start:Int, end:Int, callback:Callback<RedisString>):TReturn {})
  function ltrim(name:ListKey, start:Int, end:Int):TReturn;

  /**
    Returns a list of values ordered identically to keys
   **/
  @:overload(function (args:Array<RedisString>):TReturn {})
  @:overload(function (args:Array<RedisString>, callback:Callback<Array<RedisString>>):TReturn {})
  @:overload(function (key:Key, callback:Callback<Array<RedisString>>):TReturn {})
  function mget(keys:Rest<RedisString>):TReturn;

  /**
    Moves the key name to a different Redis database db
   **/
  @:overload(function (name:AnyKey, db:RedisString, callback:Callback<Int>):TReturn {})
  function move(name:AnyKey, db:RedisString):TReturn;

  /**
    Sets each key in the mapping dict to its corresponding value
   **/
  @:overload(function (args:Array<RedisString>):TReturn {})
  @:overload(function (args:Array<RedisString>, callback:Callback<RedisString>):TReturn {})
  @:overload(function (key:Key, value:RedisString, callback:Callback<RedisString>):TReturn {})
  function mset(mapping:Rest<RedisString>):TReturn;

  /**
    Sets each key in the mapping dict to its corresponding value if none of the keys are already set
   **/
  @:overload(function (args:Array<RedisString>):TReturn {})
  @:overload(function (args:Array<RedisString>, callback:Callback<Int>):TReturn {})
  @:overload(function (key:Key, value:RedisString, callback:Callback<Int>):TReturn {})
  function msetnx(mapping:Rest<RedisString>):TReturn;

  // /**
  //   Return the encoding, idletime, or refcount about the key
  //  **/
  // function object(infotype, key):TReturn;

  /**
    Removes an expiration on name
   **/
  @:overload(function (name:AnyKey, callback:Callback<Int>):TReturn {})
  function persist(name:AnyKey):TReturn;

  /**
    Ping the Redis server
   **/
  @:overload(function (callback:Callback<RedisString>):TReturn {})
  function ping():TReturn;

  /**
    Returns the name of a random key
   **/
  @:overload(function (callback:Callback<RedisString>):TReturn {})
  function randomkey():TReturn;

  /**
    Rename key src to dst
   **/
  @:overload(function (src:AnyKey, dst:AnyKey, callback:Callback<RedisString>):TReturn {})
  function rename(src:AnyKey, dst:AnyKey):TReturn;

  /**
    Rename key src to dst if dst doesn’t already exist
   **/
  @:overload(function (src:AnyKey, dst:AnyKey, callback:Callback<Int>):TReturn {})
  function renamenx(src:AnyKey, dst:AnyKey):TReturn;

  /**
    Remove and return the last item of the list name
   **/
  @:overload(function (name:ListKey, callback:Callback<RedisString>):TReturn {})
  function rpop(name:ListKey):TReturn;

  /**
    RPOP a value off of the src list and atomically LPUSH it on to the dst list. Returns the value.
   **/
  @:overload(function (src:ListKey, dst:ListKey, callback:Callback<RedisString>):TReturn {})
  function rpoplpush(src:ListKey, dst:ListKey):TReturn;

  /**
    Push values onto the tail of the list name
   **/
  @:overload(function (args:Array<RedisString>):TReturn {})
  @:overload(function (args:Array<RedisString>, callback:Callback<Int>):TReturn {})
  @:overload(function (name:ListKey, values:RedisString, callback:Callback<Int>):TReturn {})
  function rpush(name:ListKey, values:Rest<RedisString>):TReturn;

  /**
    Push value onto the tail of the list name if name exists
   **/
  @:overload(function (name:ListKey, value:RedisString, callback:Callback<Int>):TReturn {})
  function rpushx(name:ListKey, value:RedisString):TReturn;

  /**
    Add value(s) to set name
   **/
  @:overload(function (args:Array<RedisString>):TReturn {})
  @:overload(function (args:Array<RedisString>, callback:Callback<Int>):TReturn {})
  @:overload(function (name:SetKey, value:RedisString, callback:Callback<Int>):TReturn {})
  function sadd(name:SetKey, values:Rest<RedisString>):TReturn;

  /**
    Tell the Redis server to save its data to disk. Blocks all requests until finished
   **/
  @:overload(function (callback:Callback<RedisString>):TReturn {})
  function save():TReturn;

  /**
    Return the number of elements in set name
   **/
  @:overload(function (name:SetKey, callback:Callback<Int>):TReturn {})
  function scard(name:SetKey):TReturn;

  /**
    Return the difference of sets specified by keys
   **/
  @:overload(function (args:Array<RedisString>):TReturn {})
  @:overload(function (args:Array<RedisString>, callback:Callback<Array<RedisString>>):TReturn {})
  @:overload(function (key:SetKey, callback:Callback<Array<RedisString>>):TReturn {})
  function sdiff(keys:Rest<RedisString>):TReturn;

  /**
    Store the difference of sets specified by keys into a new set named dest. Returns the number of keys in the new set.
   **/
  @:overload(function (args:Array<RedisString>):TReturn {})
  @:overload(function (args:Array<RedisString>, callback:Callback<Int>):TReturn {})
  @:overload(function (dest:SetKey, key:SetKey, callback:Callback<Int>):TReturn {})
  function sdiffstore(dest:SetKey, keys:Rest<SetKey>):TReturn;

  /**
    Set the value at key name to value
   **/
  @:overload(function (name:Key, value:RedisString, callback:Callback<SimpleString>):TReturn {})
  @:overload(function (name:Key, value:RedisString, expOpt:SetExpireOptions, secsOrMs:Int, opt:SetOptions):TReturn {})
  @:overload(function (name:Key, value:RedisString, expOpt:SetExpireOptions, secsOrMs:Int):TReturn {})
  @:overload(function (name:Key, value:RedisString, expOpt:SetExpireOptions, secsOrMs:Int, opt:SetOptions, callback:Callback<SimpleString>):TReturn {})
  @:overload(function (name:Key, value:RedisString, expOpt:SetExpireOptions, secsOrMs:Int, callback:Callback<SimpleString>):TReturn {})
  @:overload(function (name:Key, value:RedisString, opt:SetOptions):TReturn {})
  @:overload(function (name:Key, value:RedisString, opt:SetOptions, callback:Callback<SimpleString>):TReturn {})
  @:overload(function (name:Key, value:RedisString, callback:Callback<SimpleString>):TReturn {})
  function set(name:Key, value:RedisString):TReturn;

  /**
    Flag the offset in name as value. Returns an Int indicating the previous value of offset.
   **/
  @:overload(function (name:Key, offset:Int, value:Int, callback:Callback<Int>):TReturn {})
  function setbit(name:Key, offset:Int, value:Int):TReturn;

  /**
    Set the value of key name to value that expires in time seconds
   **/
  @:overload(function (name:Key, time:Int, value:RedisString, callback:Callback<Int>):TReturn {})
  function setex(name:Key, time:Int, value:RedisString):TReturn;

  /**
    Set the value of key name to value if key doesn’t exist
   **/
  @:overload(function (name:Key, value:RedisString, callback:Callback<Int>):TReturn {})
  function setnx(name:Key, value:RedisString):TReturn;

  /**
    Overwrite bytes in the value of name starting at offset with value. If offset plus the length of value exceeds the
    length of the original value, the new value will be larger than before. If offset exceeds the length of the original
    value, null bytes will be used to pad between the end of the previous value and the start of what’s being injected.

    Returns the length of the new string.
   **/
  @:overload(function (name:Key, offset:Int, value:RedisString, callback:Callback<Int>):TReturn {})
  function setrange(name:Key, offset:Int, value:RedisString):TReturn;

  /**
    Shutdown the server
   **/
  @:overload(function (callback:Callback<RedisString>):TReturn {})
  function shutdown():TReturn;

  /**
    Return the intersection of sets specified by keys
   **/
  @:overload(function (args:Array<SetKey>):TReturn {})
  @:overload(function (args:Array<SetKey>, callback:Callback<Array<RedisString>>):TReturn {})
  @:overload(function (key:SetKey, callback:Callback<Array<RedisString>>):TReturn {})
  function sinter(keys:Rest<SetKey>):TReturn;

  /**
    Store the intersection of sets specified by keys into a new set named dest. Returns the number of keys in the new
    set.
   **/
  @:overload(function (args:Array<SetKey>):TReturn {})
  @:overload(function (args:Array<SetKey>, callback:Callback<Int>):TReturn {})
  @:overload(function (dest:SetKey, keys:SetKey, callback:Callback<Int>):TReturn {})
  function sinterstore(dest:SetKey, keys:Rest<SetKey>):TReturn;

  /**
    Return an Int indicating if value is a member of set name
   **/
  @:overload(function (name:SetKey, value:RedisString, callback:Callback<Int>):TReturn {})
  function sismember(name:SetKey, value:RedisString):TReturn;

  /**
    Set the server to be a replicated slave of the instance identified by the host and port. If called without
    arguements, the instance is promoted to a master instead.
   **/
  @:overload(function (host:RedisString, port:Int, callback:Callback<RedisString>):TReturn {})
  function slaveof(host:RedisString, port:Int):TReturn;

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
  @:overload(function (name:SetKey, callback:Callback<Array<RedisString>>):TReturn {})
  function smembers(name:SetKey):TReturn;

  /**
    Move value from set src to set dst atomically
   **/
  @:overload(function (src:SetKey, dst:SetKey, value:RedisString, callback:Callback<Int>):TReturn {})
  function smove(src:SetKey, dst:SetKey, value:RedisString):TReturn;

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
//   function sort(name:RedisString, start=None, num=None, by=None, get=None, desc=False, alpha=False, store=None):TReturn;

  /**
    Remove and return a random member of set name
   **/
  @:overload(function (name:SetKey, callback:Callback<RedisString>):TReturn {})
  function spop(name:SetKey):TReturn;

  /**
    Return a random member of set name
   **/
  @:overload(function (name:SetKey, count:Int):TReturn {})
  @:overload(function (name:SetKey, count:Int, callback:Callback<Array<RedisString>>):TReturn {})
  @:overload(function (name:SetKey, callback:Callback<RedisString>):TReturn {})
  function srandmember(name:SetKey):TReturn;

  /**
    Remove values from set name
   **/
  @:overload(function (args:Array<RedisString>):TReturn {})
  @:overload(function (args:Array<RedisString>, callback:Callback<Int>):TReturn {})
  @:overload(function (name:SetKey, values:RedisString, callback:Callback<Int>):TReturn {})
  function srem(name:SetKey, values:Rest<RedisString>):TReturn;

  /**
    Return the number of bytes stored in the value of name
   **/
  @:overload(function (name:Key, callback:Callback<Int>):TReturn {})
  function strlen(name:Key):TReturn;

  /**
    Return the union of sets specifiued by keys
   **/
  @:overload(function (args:Array<RedisString>):TReturn {})
  @:overload(function (args:Array<RedisString>, callback:Callback<Array<RedisString>>):TReturn {})
  @:overload(function (keys:SetKey, callback:Callback<Array<RedisString>>):TReturn {})
  function sunion(keys:Rest<RedisString>):TReturn;

  /**
    Store the union of sets specified by keys into a new set named dest. Returns the number of keys in the new set.
   **/
  @:overload(function (args:Array<RedisString>):TReturn {})
  @:overload(function (args:Array<RedisString>, callback:Callback<Int>):TReturn {})
  @:overload(function (dest:SetKey, keys:RedisString, callback:Callback<Int>):TReturn {})
  function sunionstore(dest:SetKey, keys:Rest<RedisString>):TReturn;

  /**
    Returns the number of seconds until the key name will expire
   **/
  @:overload(function (name:AnyKey, callback:Callback<Int>):TReturn {})
  function ttl(name:AnyKey):TReturn;

  /**
    Returns the type of key name
   **/
  @:overload(function (name:AnyKey, callback:Callback<RedisString>):TReturn {})
  function type(name:AnyKey):TReturn;

  /**
    Marks the given keys to be watched for conditional execution of a transaction.
  **/
  function watch(key:AnyKey):TReturn;

  /**
    Set any number of score, element-name pairs to the key name
   **/
  @:overload(function (name:ZSetKey, opt:ZAddOptions, score:ZFloat, member:RedisString, callback:Callback<Int>):TReturn {})
  @:overload(function (name:ZSetKey, opt:ZAddOptions, score:ZFloat, member:RedisString):TReturn {})
  @:overload(function (name:ZSetKey, opt:ZAddOptions, opt2:ZAddOptions, score:ZFloat, member:RedisString, callback:Callback<Int>):TReturn {})
  @:overload(function (name:ZSetKey, opt:ZAddOptions, opt2:ZAddOptions, score:ZFloat, member:RedisString):TReturn {})
  @:overload(function (name:ZSetKey, opt:ZAddOptions, opt2:ZAddOptions, opt3:ZAddOptions, score:ZFloat, member:RedisString, callback:Callback<Int>):TReturn {})
  @:overload(function (name:ZSetKey, opt:ZAddOptions, opt2:ZAddOptions, opt3:ZAddOptions, score:ZFloat, member:RedisString):TReturn {})
  @:overload(function (name:ZSetKey, score:ZFloat, member:RedisString, callback:Callback<Int>):TReturn {})
  @:overload(function (name:ZSetKey, score:ZFloat, member:RedisString, scoreMemebers:Rest<Dynamic>):TReturn {})
  @:overload(function (args:Array<Dynamic>, callback:Callback<Int>):TReturn {})
  function zadd(name:ZSetKey, score:ZFloat, member:RedisString):TReturn;

  /**
    Return the number of elements in the sorted set name
   **/
  @:overload(function (name:ZSetKey, callback:Callback<Int>):TReturn {})
  function zcard(name:ZSetKey):TReturn;

  /**
    Increment the score of value in sorted set name by amount
    Returns a RedisString representing the floating point value of the new score of the member
   **/
  @:overload(function (name:ZSetKey, value:ZFloat, member:RedisString, callback:Callback<RedisString>):TReturn {})
  function zincrby(name:ZSetKey, value:ZFloat, member:RedisString):TReturn;

  // /**
  //   Intersect multiple sorted sets specified by keys into a new sorted set, dest. Scores in the destination will be
  //   aggregated based on the aggregate, or SUM if none is provided.
  //  **/
  // function zinterstore(dest:ZSetKey, numkeys:Int, key, keys, aggregate=None):TReturn;

  /**
    Return a range of values from sorted set name between start and end sorted in ascending order.
    start and end can be negative, indicating the end of the range.
    desc a boolean indicating whether to sort the results descendingly
    withscores indicates to return the scores along with the values.
   **/
  @:overload(function (name:ZSetKey, start:Int, end:Int, withScores:ZWithScores,
        callback:Callback<Array<Dynamic>>):TReturn {})
  @:overload(function (name:ZSetKey, start:Int, end:Int, callback:Callback<Array<RedisString>>):TReturn {})
  @:overload(function (name:ZSetKey, start:Int, end:Int, withScores:ZWithScores):TReturn {})
  function zrange(name:ZSetKey, start:Int, end:Int):TReturn;

  /**
    Return a range of values from the sorted set name with scores between min and max.
    withscores indicates to return the scores along with the values.
   **/
  @:overload(function (name:ZSetKey, min:ZFloat, max:ZFloat, limit:ZLimit, offset:Int, count:Int,
        callback:Callback<Array<RedisString>>):TReturn {})
  @:overload(function (name:ZSetKey, min:ZFloat, max:ZFloat, withScores:ZWithScores, limit:ZLimit, offset:Int, count:Int,
        callback:Callback<Array<Dynamic>>):TReturn {})
  @:overload(function (name:ZSetKey, min:ZFloat, max:ZFloat, withScores:ZWithScores,
        callback:Callback<Array<Dynamic>>):TReturn {})
  @:overload(function (name:ZSetKey, min:ZFloat, max:ZFloat, callback:Callback<Array<RedisString>>):TReturn {})
  @:overload(function (name:ZSetKey, min:ZFloat, max:ZFloat, limit:ZLimit, offset:Int, count:Int):TReturn {})
  @:overload(function (name:ZSetKey, min:ZFloat, max:ZFloat, withScores:ZWithScores, limit:ZLimit, offset:Int, count:Int ):TReturn {})
  @:overload(function (name:ZSetKey, min:ZFloat, max:ZFloat, withScores:ZWithScores):TReturn {})
  function zrangebyscore(name:ZSetKey, min:ZFloat, max:ZFloat):TReturn;

  /**
    Returns a 0-based value indicating the rank of key in sorted set name
   **/
  @:overload(function (name:ZSetKey, key:RedisString, callback:Callback<Null<Int>>):TReturn {})
  function zrank(name:ZSetKey, key:RedisString):TReturn;

  /**
    Remove member values from sorted set name
   **/
  @:overload(function (args:Array<RedisString>):TReturn {})
  @:overload(function (args:Array<RedisString>, callback:Callback<Int>):TReturn {})
  @:overload(function (name:ZSetKey, key:RedisString, callback:Callback<Int>):TReturn {})
  function zrem(name:ZSetKey, keys:Rest<RedisString>):TReturn;

  /**
    Remove all elements in the sorted set name with ranks between min and max. Values are 0-based, ordered from smallest
    score to largest. Values can be negative indicating the highest scores. Returns the number of elements removed
   **/
  @:overload(function (name:ZSetKey, min:Int, max:Int, callback:Callback<Int>):TReturn {})
  function zremrangebyrank(name:ZSetKey, min:Int, max:Int):TReturn;

  /**
    Remove all elements in the sorted set name with scores between min and max. Returns the number of elements removed.
   **/
  @:overload(function (name:ZSetKey, min:ZFloat, max:ZFloat, callback:Callback<Int>):TReturn {})
  function zremrangebyscore(name:ZSetKey, min:ZFloat, max:ZFloat):TReturn;

  /**
    Return a range of values from sorted set name between start and num sorted in descending order.
    start and num can be negative, indicating the end of the range.
    withscores indicates to return the scores along with the values The return type is a list of (value, score) pairs
   **/
  @:overload(function (name:ZSetKey, start:Int, end:Int, withScores:ZWithScores,
        callback:Callback<Array<RedisString>>):TReturn {})
  @:overload(function (name:ZSetKey, start:Int, end:Int, callback:Callback<Array<RedisString>>):TReturn {})
  @:overload(function (name:ZSetKey, start:Int, end:Int, withScores:ZWithScores):TReturn {})
  function zrevrange(name:ZSetKey, start:Int, num:Int):TReturn;

  /**
    Return a range of values from the sorted set name with scores between min and max in descending order.

    If start and num are specified, then return a slice of the range.

    withscores indicates to return the scores along with the values. The return type is a list of (value, score) pairs

    score_cast_func a callable used to cast the score return value
   **/
  @:overload(function (name:ZSetKey, max:ZFloat, min:ZFloat, limit:ZLimit, offset:Int, count:Int,
        callback:Callback<Array<RedisString>>):TReturn {})
  @:overload(function (name:ZSetKey, max:ZFloat, min:ZFloat, withScores:ZWithScores, limit:ZLimit, offset:Int, count:Int,
        callback:Callback<Array<Dynamic>>):TReturn {})
  @:overload(function (name:ZSetKey, max:ZFloat, min:ZFloat, withScores:ZWithScores,
        callback:Callback<Array<Dynamic>>):TReturn {})
  @:overload(function (name:ZSetKey, max:ZFloat, min:ZFloat, callback:Callback<Array<RedisString>>):TReturn {})
  @:overload(function (name:ZSetKey, max:ZFloat, min:ZFloat, limit:ZLimit, offset:Int, count:Int):TReturn {})
  @:overload(function (name:ZSetKey, max:ZFloat, min:ZFloat, withScores:ZWithScores, limit:ZLimit, offset:Int, count:Int ):TReturn {})
  @:overload(function (name:ZSetKey, max:ZFloat, min:ZFloat, withScores:ZWithScores):TReturn {})
  function zrevrangebyscore(name:ZSetKey, max:ZFloat, min:ZFloat):TReturn;

  /**
    Returns a 0-based value indicating the descending rank of key in sorted set name
   **/
  @:overload(function (name:ZSetKey, key:RedisString, callback:Callback<Int>):TReturn {})
  function zrevrank(name:ZSetKey, key:RedisString):TReturn;

  /**
    Return the score of element key in sorted set name
    Returns a string representing a Float
   **/
  @:overload(function (name:ZSetKey, key:RedisString, callback:Callback<RedisString>):TReturn {})
  function zscore(name:ZSetKey, key:RedisString):TReturn;

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

    Warning: As of version 2.8.0, errors that occur on individual calls may still send a null Error object, and instead
    send the error inside the result array. So be sure to check the individual elements if they are errors - there are the
    convenience `asError` / `isError` helpers on each MultiRedisResponse object
   **/
  @:overload(function(callback:ExecCallback):Void {})
  function exec():Void;

  /**
    Identical to Multi.exec but with the difference that executing a single command will not use transactions.
   **/
  @:overload(function(callback:ExecCallback):Void {})
  function exec_atomic():Void;
}

@:enum abstract BeforeAfter(String) from String {
  var Before = "BEFORE";
  var After = "AFTER";
}

@:forward
abstract MultiRedisResponseArray(Array<MultiRedisResponse>) from Array<MultiRedisResponse> to Array<MultiRedisResponse>
{
  @:extern inline public function getFirstError()
  {
    var ret = null;
    for (obj in this)
    {
      ret = obj.asError();
      if (ret != null)
      {
        break;
      }
    }
    return ret;
  }

  @:extern inline public function hasAnyErrors()
  {
    var ret = false;
    for (obj in this)
    {
      if (obj.isError())
      {
        ret = true;
        break;
      }
    }
    return ret;
  }
}

@:forward
abstract MultiRedisResponse(Dynamic)
  from GenericRedisResponse
  to GenericRedisResponse
  from RedisError
  to RedisError
{
  @:extern inline public function asError():RedisError {
    if (Std.is(this, RedisError)) {
      return cast this;
    } else {
      return null;
    }
  }

  @:extern inline public function isError():Bool {
    return Std.is(this, RedisError);
  }

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

abstract GenericRedisResponse(Dynamic)
  from Dynamic
  from Array<GenericRedisResponse> to Array<GenericRedisResponse>
  from String to String
  from Int to Int
{
  @:extern inline public function asArray():Array<GenericRedisResponse> {
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

  @:extern inline public function asFloat():Null<Float> {
    if (Std.is(this, Float)) {
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

@:enum abstract SetExpireOptions(String) to String {
  /**
    Expire argument is in seconds
  **/
  var Ex = "EX";
  /**
    Expire argument is in milliseconds
  **/
  var Px = "PX";
}

@:enum abstract SetOptions(String) to String {
  /**
    Only set the key if it already exists. Returns null if the condition fails
  **/
  var Xx = "XX";

  /**
    Only set the key if it does not already exist. Returns null if the condition fails
  **/
  var Nx = "NX";
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

@:enum abstract ErrorCode(String) from String to String
{
  /**
    Returns if the client connection was dropped
  **/
  var ClosedError = "NR_CLOSED";

  /**
    If an unresolved command was rejected
  **/
  var UncertainState = "UNCERTAIN_STATE";

  /**
    In case node_redis gives up to reconnect
  **/
  var ConnectionBroken = "CONNECTION_BROKEN";
}

@:jsRequire("redis", "RedisError")
extern class RedisError extends Error {
  public var code(default, null):ErrorCode;
}
@:jsRequire("redis", "ReplyError")
extern class ReplyError extends RedisError {
  public var command(default, null):String;
  public var args(default, null):Array<Dynamic>;
}
@:jsRequire("redis", "AbortError")
extern class AbortError extends RedisError {}
@:jsRequire("redis", "ParserError")
extern class ParserError extends RedisError {}
@:jsRequire("redis", "AggregateError")
extern class AggregateError extends AbortError {
  public var errors(default, null):Array<RedisError>;
}

extern class ExecError extends RedisError {
  public var errors(default, null):Array<RedisError>;
}