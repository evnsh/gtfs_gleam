import gleam/io
import gtfs/realtime/feed as rt_feed

pub fn main() {
  case
    rt_feed.fetch("https://mybusfinder.fr/gtfsrt/zou-prox/vehicle_positions.pb")
  {
    Ok(feed) -> {
      io.println("Success! Version: " <> feed.header.gtfs_realtime_version)
    }
    Error(e) -> {
      io.println("Error:")
      io.debug(e)
      Nil
    }
  }
}
