package js.npm.redis;
import js.npm.redis.RedisClient;
#if haxe4
import js.lib.Error;
#else
import js.Error;
#end

typedef ErrCallback<Err : Error, Res> = Null<Err>->Res->Void;

typedef ErrVoidCallback<Err : Error> = Null<Err>->Void;

typedef Callback<Res> = ErrCallback<RedisError, Res>;

typedef VoidCallback = ErrVoidCallback<RedisError>;

typedef ExecCallback = ErrCallback<ExecError, MultiRedisResponseArray>;