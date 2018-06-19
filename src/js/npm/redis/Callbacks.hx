package js.npm.redis;
import js.npm.redis.RedisClient;

typedef ErrCallback<Err : js.Error, Res> = Null<Err>->Res->Void;

typedef ErrVoidCallback<Err : js.Error> = Null<Err>->Void;

typedef Callback<Res> = ErrCallback<RedisError, Res>;

typedef VoidCallback = ErrVoidCallback<RedisError>;

typedef ExecCallback = ErrCallback<ExecError, MultiRedisResponseArray>;