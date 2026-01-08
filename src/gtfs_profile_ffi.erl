-module(gtfs_profile_ffi).
-export([profile_enabled/0, monotonic_millis/0]).

profile_enabled() ->
    case os:getenv("GTFS_GLEAM_PROFILE") of
        false -> false;
        "" -> false;
        "0" -> false;
        "false" -> false;
        "FALSE" -> false;
        _ -> true
    end.

monotonic_millis() ->
    erlang:monotonic_time(millisecond).
