%% HTTP client FFI for fetching binary data
-module(gtfs_http_ffi).
-export([fetch/1]).

fetch(Url) ->
    inets:start(),
    ssl:start(),
    case httpc:request(get, {binary_to_list(Url), []}, [{timeout, 30000}], [{body_format, binary}]) of
        {ok, {{_, Status, _}, _, Body}} when Status >= 200, Status < 300 ->
            {ok, Body};
        {ok, {{_, Status, _}, _, _}} ->
            {error, {status_error, Status}};
        {error, Reason} ->
            {error, {http_error, Reason}}
    end.
