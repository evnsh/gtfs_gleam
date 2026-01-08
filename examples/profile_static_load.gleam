//// Example: Profile loading a GTFS Static Feed
////
//// This repo is a library package; `gleam run -m` runs modules from `src/`.
//// To use this example, copy the code into your application project and run it
//// with the env var `GTFS_GLEAM_PROFILE=1`.

import gleam/int
import gleam/io
import gleam/list
import gtfs/static/feed

pub fn main() {
  let path = "./gtfs_rla.zip"

  io.println("Profiling static GTFS load")
  io.println("Path: " <> path)

  case feed.load(path) {
    Ok(f) -> {
      io.println("Loaded")
      io.println("Agencies: " <> int.to_string(list.length(f.agencies)))
      io.println("Stops: " <> int.to_string(list.length(f.stops)))
      io.println("Routes: " <> int.to_string(list.length(f.routes)))
      io.println("Trips: " <> int.to_string(list.length(f.trips)))
      io.println("Stop times: " <> int.to_string(list.length(f.stop_times)))
    }
    Error(e) -> {
      io.println("Load error:")
      let _ = e
      io.println("(error details omitted)")
    }
  }
}
