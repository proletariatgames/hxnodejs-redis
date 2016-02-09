package js.npm;
import js.npm.redis.RedisClient;
import haxe.DynamicAccess;

@:jsRequire("redis")
extern class Redis {
  @:overload(function(options:RedisOptions):RedisClient {})
  @:overload(function(unix_socket:String, options:RedisOptions):RedisClient {})
  @:overload(function(redis_url:String, options:RedisOptions):RedisClient {})
  @:overload(function(port:Int, host:String, options:RedisOptions):RedisClient {})
  public static function createClient():js.npm.redis.RedisClient;
}

typedef RedisOptions = {
  /**
    127.0.0.1; The host to connect to
   **/
  @:optional var host : String;
  /**
    6379; The port to connect to
   **/
  @:optional var port : Int;
  /**
    null; The unix socket string to connect to
   **/
  @:optional var path : String;
  /**
    null; The redis url to connect to ([redis:]//[user][:password@][host][:port][/db-number][?db=db-number[&password=bar[&option=value]]]
    For more info check IANA)
   **/
  @:optional var url : String;
  /**
    hiredis; Which Redis protocol reply parser to use. If hiredis is not installed it will fallback to javascript.
   **/
  @:optional var parser : String;
  /**
    false; If set to true, then all replies will be sent to callbacks as Buffers instead of Strings.
   **/
  @:optional var return_buffers : Bool;
  /**
    false; If set to true, then replies will be sent to callbacks as Buffers. Please be aware that this can't work
    properly with the pubsub mode. A subscriber has to either always return strings or buffers. if any of the input
    arguments to the original command were Buffers. This option lets you switch between Buffers and Strings on a
    per-command basis, whereas return_buffers applies to every command on a client.
   **/
  @:optional var detect_buffers : Bool;
  /**
    true; Whether the keep-alive functionality is enabled on the underlying socket.
   **/
  @:optional var socket_keepalive : Bool;
  /**
    false; When a connection is established to the Redis server, the server might still be loading the database from
    disk. While loading the server will not respond to any commands. To work around this, node_redis has a "ready check"
    which sends the INFO command to the server. The response from the INFO command indicates whether the server is ready
    for more commands. When ready, node_redis emits a ready event. Setting no_ready_check to true will inhibit this
    check.
   **/
  @:optional var no_ready_check : Bool;
  /**
    true; By default, if there is no active connection to the redis server, commands are added to a queue and are
    executed once the connection has been established. Setting enable_offline_queue to false will disable this feature
    and the callback will be executed immediately with an error, or an error will be emitted if no callback is
    specified.
   **/
  @:optional var enable_offline_queue : Bool;
  /**
    null; By default every time the client tries to connect and fails the reconnection delay almost doubles. This delay
    normally grows infinitely, but setting retry_max_delay limits it to the maximum value, provided in milliseconds.
   **/
  @:optional var retry_max_delay : Int;
  /**
    3600000; Setting connect_timeout limits total time for client to connect and reconnect. The value is provided in
    milliseconds and is counted from the moment on a new client is created / a connection is lost. The last retry is
    going to happen exactly at the timeout time. Default is to try connecting until the default system socket timeout
    has been exceeded and to try reconnecting until 1h passed.
   **/
  @:optional var connect_timeout : Float;
  /**
    0; By default client will try reconnecting until connected. Setting max_attempts limits total amount of connection
    tries. Setting this to 1 will prevent any reconnect tries.
   **/
  @:optional var max_attempts : Int;
  /**
    false; If set to true, all commands that were unfulfulled while the connection is lost will be retried after the
    connection has reestablished again. Use this with caution, if you use state altering commands (e.g. incr). This is
    especially useful if you use blocking commands.
   **/
  @:optional var retry_unfulfilled_commands : Bool;
  /**
    null; If set, client will run redis auth command on connect. Alias auth_pass
   **/
  @:optional var password : String;
  /**
    null; If set, client will run redis select command on connect. This is not recommended.
   **/
  @:optional var db : String;
  /**
    IPv4; You can force using IPv6 if you set the family to 'IPv6'. See Node.js net or dns modules how to use the family type.
   **/
  @:optional var family : js.node.net.Socket.SocketAdressFamily;
  /**
    false; If set to true, a client won't resubscribe after disconnecting
   **/
  @:optional var disable_resubscribing : Bool;
  /**
    null; pass a object with renamed commands to use those instead of the original functions. See the redis security topics for more info.
   **/
  @:optional var rename_commands : DynamicAccess<String>;
  /**
    an object containing options to pass to tls.connect, to set up a TLS connection to Redis (if, for example, it is set up to be accessible via a tunnel).
   **/
  @:optional var tls : js.node.Tls.TlsConnectOptions;
  /**
    null; pass a string to prefix all used keys with that string as prefix e.g. 'namespace:test'
   **/
  @:optional var prefix : String;
}
