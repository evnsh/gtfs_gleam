import gleam/int
import gleam/io

pub type Entry {
  Entry(stage: String, ms: Int)
}

@external(erlang, "gtfs_profile_ffi", "profile_enabled")
fn profile_enabled() -> Bool

@external(erlang, "gtfs_profile_ffi", "monotonic_millis")
fn monotonic_millis() -> Int

pub fn enabled() -> Bool {
  profile_enabled()
}

pub fn now_ms() -> Int {
  monotonic_millis()
}

pub fn log(stage: String, ms: Int) -> Nil {
  io.println("[gtfs][profile] " <> stage <> " " <> int.to_string(ms) <> "ms")
}

pub fn time(stage: String, thunk: fn() -> a) -> a {
  case enabled() {
    True -> {
      let start = now_ms()
      let value = thunk()
      let finish = now_ms()
      log(stage, finish - start)
      value
    }
    False -> thunk()
  }
}

pub fn time_result(stage: String, thunk: fn() -> Result(a, e)) -> Result(a, e) {
  case enabled() {
    True -> {
      let start = now_ms()
      let value = thunk()
      let finish = now_ms()
      log(stage, finish - start)
      value
    }
    False -> thunk()
  }
}
