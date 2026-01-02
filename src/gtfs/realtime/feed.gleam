//// GTFS Realtime Feed
////
//// Module for working with GTFS Realtime feeds.
//// Provides functions to decode and query realtime feed data.
////
//// # Example
////
//// ```gleam
//// import gtfs/realtime/feed
//// import gleam/io
////
//// pub fn main() {
////   // Decode a feed from bytes
////   let assert Ok(feed_message) = feed.decode(my_protobuf_bytes)
////
////   // Get all trip updates
////   let updates = feed.get_trip_updates(feed_message)
////
////   // Get all alerts
////   let alerts = feed.get_alerts(feed_message)
//// }
//// ```

import gleam/list
import gleam/option.{type Option, None, Some}
import gtfs/realtime/decoder
import gtfs/realtime/types.{
  type Alert, type FeedEntity, type FeedMessage, type TripUpdate,
  type VehiclePosition,
}
import protobin

// =============================================================================
// Feed Decoding
// =============================================================================

/// Decode a GTFS Realtime feed from protobuf binary data
pub fn decode(data: BitArray) -> Result(FeedMessage, protobin.ParseError) {
  decoder.decode_feed_message(data)
}

/// Decode a GTFS Realtime feed from raw bytes (alias for decode)
pub fn from_bytes(data: BitArray) -> Result(FeedMessage, protobin.ParseError) {
  decode(data)
}

// =============================================================================
// HTTP Fetching
// =============================================================================

/// Error type for HTTP fetch operations
pub type FetchError {
  /// HTTP request failed
  HttpError(String)
  /// Response was not successful (non-2xx status)
  StatusError(Int)
  /// Protocol Buffer decoding failed
  DecodeError(protobin.ParseError)
}

@external(erlang, "gtfs_http_ffi", "fetch")
fn do_fetch(url: String) -> Result(BitArray, #(atom, a))

/// Fetch and decode a GTFS Realtime feed from a URL
///
/// ## Example
///
/// ```gleam
/// import gtfs/realtime/feed
///
/// pub fn main() {
///   case feed.fetch("https://api.transit.example.com/gtfs-rt/vehiclepositions") {
///     Ok(feed_message) -> {
///       let vehicles = feed.get_vehicle_positions(feed_message)
///       // Process vehicles...
///     }
///     Error(feed.HttpError(msg)) -> io.println("HTTP error: " <> msg)
///     Error(feed.StatusError(code)) -> io.println("Bad status: " <> int.to_string(code))
///     Error(feed.DecodeError(_)) -> io.println("Failed to decode protobuf")
///   }
/// }
/// ```
pub fn fetch(url: String) -> Result(FeedMessage, FetchError) {
  case do_fetch(url) {
    Ok(body) -> {
      case decode(body) {
        Ok(feed) -> Ok(feed)
        Error(err) -> Error(DecodeError(err))
      }
    }
    Error(#(_reason, status)) -> Error(StatusError(coerce_to_int(status)))
  }
}

@external(erlang, "gleam_stdlib", "identity")
fn coerce_to_int(value: a) -> Int

// =============================================================================
// Query Functions
// =============================================================================

/// Get all trip updates from a feed
pub fn get_trip_updates(feed: FeedMessage) -> List(TripUpdate) {
  list.filter_map(feed.entity, fn(entity) {
    case entity.trip_update {
      Some(tu) -> Ok(tu)
      None -> Error(Nil)
    }
  })
}

/// Get all vehicle positions from a feed
pub fn get_vehicle_positions(feed: FeedMessage) -> List(VehiclePosition) {
  list.filter_map(feed.entity, fn(entity) {
    case entity.vehicle {
      Some(vp) -> Ok(vp)
      None -> Error(Nil)
    }
  })
}

/// Get all alerts from a feed
pub fn get_alerts(feed: FeedMessage) -> List(Alert) {
  list.filter_map(feed.entity, fn(entity) {
    case entity.alert {
      Some(alert) -> Ok(alert)
      None -> Error(Nil)
    }
  })
}

/// Get a specific entity by ID
pub fn get_entity(feed: FeedMessage, id: String) -> Option(FeedEntity) {
  list.find(feed.entity, fn(entity) { entity.id == id })
  |> option_from_result
}

/// Get trip update for a specific trip ID
pub fn get_trip_update(feed: FeedMessage, trip_id: String) -> Option(TripUpdate) {
  list.find_map(feed.entity, fn(entity) {
    case entity.trip_update {
      Some(tu) -> {
        case tu.trip.trip_id {
          Some(tid) if tid == trip_id -> Ok(tu)
          _ -> Error(Nil)
        }
      }
      None -> Error(Nil)
    }
  })
  |> option_from_result
}

/// Get vehicle position for a specific vehicle ID
pub fn get_vehicle_position(
  feed: FeedMessage,
  vehicle_id: String,
) -> Option(VehiclePosition) {
  list.find_map(feed.entity, fn(entity) {
    case entity.vehicle {
      Some(vp) -> {
        case vp.vehicle {
          Some(v) -> {
            case v.id {
              Some(vid) if vid == vehicle_id -> Ok(vp)
              _ -> Error(Nil)
            }
          }
          None -> Error(Nil)
        }
      }
      None -> Error(Nil)
    }
  })
  |> option_from_result
}

/// Get all vehicle positions for a specific route
pub fn get_vehicles_on_route(
  feed: FeedMessage,
  route_id: String,
) -> List(VehiclePosition) {
  list.filter_map(feed.entity, fn(entity) {
    case entity.vehicle {
      Some(vp) -> {
        case vp.trip {
          Some(trip) -> {
            case trip.route_id {
              Some(rid) if rid == route_id -> Ok(vp)
              _ -> Error(Nil)
            }
          }
          None -> Error(Nil)
        }
      }
      None -> Error(Nil)
    }
  })
}

/// Get all alerts affecting a specific route
pub fn get_alerts_for_route(feed: FeedMessage, route_id: String) -> List(Alert) {
  list.filter_map(feed.entity, fn(entity) {
    case entity.alert {
      Some(alert) -> {
        let affects_route =
          list.any(alert.informed_entity, fn(selector) {
            case selector.route_id {
              Some(rid) -> rid == route_id
              None -> False
            }
          })
        case affects_route {
          True -> Ok(alert)
          False -> Error(Nil)
        }
      }
      None -> Error(Nil)
    }
  })
}

/// Get all alerts affecting a specific stop
pub fn get_alerts_for_stop(feed: FeedMessage, stop_id: String) -> List(Alert) {
  list.filter_map(feed.entity, fn(entity) {
    case entity.alert {
      Some(alert) -> {
        let affects_stop =
          list.any(alert.informed_entity, fn(selector) {
            case selector.stop_id {
              Some(sid) -> sid == stop_id
              None -> False
            }
          })
        case affects_stop {
          True -> Ok(alert)
          False -> Error(Nil)
        }
      }
      None -> Error(Nil)
    }
  })
}

/// Get delay for a specific trip (in seconds, positive = late)
pub fn get_trip_delay(feed: FeedMessage, trip_id: String) -> Option(Int) {
  case get_trip_update(feed, trip_id) {
    Some(tu) -> tu.delay
    None -> None
  }
}

/// Check if the feed is a full dataset or differential update
pub fn is_full_dataset(feed: FeedMessage) -> Bool {
  case feed.header.incrementality {
    types.FullDataset -> True
    types.Differential -> False
  }
}

/// Get the feed timestamp (when the content was created)
pub fn get_timestamp(feed: FeedMessage) -> Option(Int) {
  feed.header.timestamp
}

/// Get the GTFS Realtime version
pub fn get_version(feed: FeedMessage) -> String {
  feed.header.gtfs_realtime_version
}

/// Get the total number of entities in the feed
pub fn entity_count(feed: FeedMessage) -> Int {
  list.length(feed.entity)
}

/// Get count of trip updates in the feed
pub fn trip_update_count(feed: FeedMessage) -> Int {
  list.count(feed.entity, fn(e) { option.is_some(e.trip_update) })
}

/// Get count of vehicle positions in the feed
pub fn vehicle_position_count(feed: FeedMessage) -> Int {
  list.count(feed.entity, fn(e) { option.is_some(e.vehicle) })
}

/// Get count of alerts in the feed
pub fn alert_count(feed: FeedMessage) -> Int {
  list.count(feed.entity, fn(e) { option.is_some(e.alert) })
}

// =============================================================================
// Helper Functions
// =============================================================================

fn option_from_result(result: Result(a, b)) -> Option(a) {
  case result {
    Ok(val) -> Some(val)
    Error(_) -> None
  }
}
