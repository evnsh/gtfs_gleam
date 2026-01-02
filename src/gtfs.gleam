//// GTFS - A type-safe GTFS library for Gleam
////
//// This library provides complete support for parsing and working with
//// GTFS (General Transit Feed Specification) data, including:
////
//// - **GTFS Static**: Schedule data (routes, stops, trips, times, etc.)
//// - **GTFS Realtime**: Live updates (trip updates, vehicle positions, alerts)
////
//// ## Quick Start - Static Feed
////
//// ```gleam
//// import gtfs/static/feed
////
//// pub fn main() {
////   // Load a GTFS feed from a directory
////   let assert Ok(feed) = feed.load_from_directory("./gtfs_data")
////
////   // Access the data
////   let routes = feed.routes
////   let stops = feed.stops
//// }
//// ```
////
//// ## Quick Start - Realtime Feed
////
//// ```gleam
//// import gtfs/realtime/feed as rt_feed
////
//// pub fn handle_realtime(data: BitArray) {
////   let assert Ok(feed) = rt_feed.decode(data)
////
////   // Get all trip updates
////   let trip_updates = rt_feed.get_trip_updates(feed)
////
////   // Get all vehicle positions
////   let vehicles = rt_feed.get_vehicle_positions(feed)
////
////   // Get all alerts
////   let alerts = rt_feed.get_alerts(feed)
//// }
//// ```
////
//// ## Module Structure
////
//// ### Static (Schedule Data)
//// - `gtfs/static/feed` - Load and query GTFS Static feeds
//// - `gtfs/static/types` - All GTFS Static type definitions
//// - `gtfs/static/validation` - Feed validation utilities
////
//// ### Realtime (Live Updates)
//// - `gtfs/realtime/feed` - Decode and query GTFS Realtime feeds
//// - `gtfs/realtime/types` - All GTFS Realtime type definitions
//// - `gtfs/realtime/decoder` - Protocol Buffer decoder
////
//// ### Common
//// - `gtfs/common/types` - Shared types (Date, Time, Coordinate, etc.)
//// - `gtfs/common/time` - Time parsing and manipulation utilities
//// - `gtfs/common/geo` - Geographic utilities (distance, polylines, etc.)

// Re-export commonly used types for convenience
pub type Date =
  gtfs_common_types.Date

pub type Time =
  gtfs_common_types.Time

pub type Coordinate =
  gtfs_common_types.Coordinate

pub type Color =
  gtfs_common_types.Color

pub type Timezone =
  gtfs_common_types.Timezone

pub type LanguageCode =
  gtfs_common_types.LanguageCode

// Re-export static feed types
pub type Feed =
  gtfs_static_feed.Feed

pub type Agency =
  gtfs_static_types.Agency

pub type Stop =
  gtfs_static_types.Stop

pub type Route =
  gtfs_static_types.Route

pub type Trip =
  gtfs_static_types.Trip

pub type StopTime =
  gtfs_static_types.StopTime

pub type Calendar =
  gtfs_static_types.Calendar

pub type CalendarDate =
  gtfs_static_types.CalendarDate

pub type ShapePoint =
  gtfs_static_types.ShapePoint

// Re-export key enums
pub type RouteType =
  gtfs_static_types.RouteType

pub type LocationType =
  gtfs_static_types.LocationType

pub type ExceptionType =
  gtfs_static_types.ExceptionType

// Re-export realtime types
pub type FeedMessage =
  gtfs_realtime_types.FeedMessage

pub type FeedHeader =
  gtfs_realtime_types.FeedHeader

pub type FeedEntity =
  gtfs_realtime_types.FeedEntity

pub type TripUpdate =
  gtfs_realtime_types.TripUpdate

pub type VehiclePosition =
  gtfs_realtime_types.VehiclePosition

pub type Alert =
  gtfs_realtime_types.Alert

pub type Position =
  gtfs_realtime_types.Position

pub type TripDescriptor =
  gtfs_realtime_types.TripDescriptor

pub type VehicleDescriptor =
  gtfs_realtime_types.VehicleDescriptor

// Module aliases for imports
import gtfs/common/types as gtfs_common_types
import gtfs/realtime/types as gtfs_realtime_types
import gtfs/static/feed as gtfs_static_feed
import gtfs/static/types as gtfs_static_types
