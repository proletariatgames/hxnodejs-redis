package js.npm.redis;

typedef ErrCallback<Err : js.Error, Res> = Null<Err>->Res->Void;

typedef ErrVoidCallback<Err : js.Error> = Null<Err>->Void;

typedef Callback<Res> = ErrCallback<js.Error, Res>;

typedef VoidCallback = ErrVoidCallback<js.Error>;