%% ZIP FFI module for GTFS
%% Provides ZIP extraction using Erlang's zip module
-module(gtfs_zip_ffi).
-export([unzip/1]).

%% Unzip a binary ZIP archive and return a list of {filename, content} tuples
-spec unzip(binary()) -> {ok, list({binary(), binary()})} | {error, binary()}.
unzip(Data) ->
    case zip:unzip(Data, [memory]) of
        {ok, Entries} ->
            Result = lists:map(fun({Name, Content}) ->
                NameBin = case is_list(Name) of
                    true -> list_to_binary(Name);
                    false -> Name
                end,
                {NameBin, Content}
            end, Entries),
            {ok, Result};
        {error, Reason} ->
            {error, list_to_binary(io_lib:format("~p", [Reason]))}
    end.
