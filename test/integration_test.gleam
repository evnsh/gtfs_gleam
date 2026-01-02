//// Integration Tests
////
//// Tests that verify type structures and enum variants

import gleam/list
import gleam/option.{None}
import gleeunit/should
import gtfs/common/types as common_types
import gtfs/static/feed
import gtfs/static/types

// =============================================================================
// Feed Type Tests
// =============================================================================

pub fn empty_feed_structure_test() {
  // Verify Feed type has all expected fields
  let empty_feed =
    feed.Feed(
      agencies: [],
      routes: [],
      trips: [],
      stop_times: [],
      stops: [],
      calendar: None,
      calendar_dates: None,
      feed_info: None,
      levels: None,
      shapes: None,
      frequencies: None,
      transfers: None,
      pathways: None,
      fare_attributes: None,
      fare_rules: None,
      translations: None,
      attributions: None,
      areas: None,
      stop_areas: None,
      networks: None,
      route_networks: None,
      timeframes: None,
      fare_media: None,
      fare_products: None,
      fare_leg_rules: None,
      fare_leg_join_rules: None,
      fare_transfer_rules: None,
      location_groups: None,
      location_group_stops: None,
      locations: None,
      booking_rules: None,
    )

  list.length(empty_feed.agencies) |> should.equal(0)
  list.length(empty_feed.routes) |> should.equal(0)
  list.length(empty_feed.trips) |> should.equal(0)
  list.length(empty_feed.stop_times) |> should.equal(0)
  list.length(empty_feed.stops) |> should.equal(0)
}

// =============================================================================
// Route Type Enum Tests
// =============================================================================

pub fn all_route_types_test() {
  let route_types = [
    types.Tram,
    types.Subway,
    types.Rail,
    types.Bus,
    types.Ferry,
    types.CableTram,
    types.AerialLift,
    types.Funicular,
    types.Trolleybus,
    types.Monorail,
  ]

  list.length(route_types) |> should.equal(10)
}

// =============================================================================
// Location Type Enum Tests
// =============================================================================

pub fn all_location_types_test() {
  let location_types = [
    types.StopOrPlatform,
    types.Station,
    types.EntranceExit,
    types.GenericNode,
    types.BoardingArea,
  ]

  list.length(location_types) |> should.equal(5)
}

// =============================================================================
// Wheelchair Boarding Enum Tests
// =============================================================================

pub fn all_wheelchair_boarding_types_test() {
  let wheelchair_types = [
    types.NoWheelchairInfo,
    types.WheelchairAccessible,
    types.NotWheelchairAccessible,
  ]

  list.length(wheelchair_types) |> should.equal(3)
}

// =============================================================================
// Color Type Tests
// =============================================================================

pub fn color_type_test() {
  let white = common_types.Color(255, 255, 255)
  let black = common_types.Color(0, 0, 0)
  let red = common_types.Color(255, 0, 0)

  white.red |> should.equal(255)
  white.green |> should.equal(255)
  white.blue |> should.equal(255)

  black.red |> should.equal(0)
  red.red |> should.equal(255)
  red.green |> should.equal(0)
}

// =============================================================================
// Time Type Tests
// =============================================================================

pub fn time_type_test() {
  let morning = common_types.Time(8, 30, 0)
  let overnight = common_types.Time(25, 30, 0)

  morning.hours |> should.equal(8)
  morning.minutes |> should.equal(30)
  morning.seconds |> should.equal(0)

  // GTFS allows times > 24:00:00
  overnight.hours |> should.equal(25)
}

pub fn date_type_test() {
  let date = common_types.Date(2025, 10, 28)

  date.year |> should.equal(2025)
  date.month |> should.equal(10)
  date.day |> should.equal(28)
}

// =============================================================================
// GTFS-Flex Type Tests
// =============================================================================

pub fn booking_type_enum_test() {
  let booking_types = [
    types.RealTimeBooking,
    types.SameDayBooking,
    types.PriorDayBooking,
  ]

  list.length(booking_types) |> should.equal(3)
}

// =============================================================================
// GTFS-Fares v2 Type Tests
// =============================================================================

pub fn fare_media_type_enum_test() {
  let media_types = [
    types.NoFareMedia,
    types.PaperTicket,
    types.TransitCard,
    types.Cemv,
    types.MobileApp,
  ]

  list.length(media_types) |> should.equal(5)
}

// =============================================================================
// Transfer Type Tests
// =============================================================================

pub fn transfer_type_enum_test() {
  let transfer_types = [
    types.RecommendedTransfer,
    types.TimedTransfer,
    types.MinimumTimeTransfer,
    types.NoTransfer,
    types.InSeatTransfer,
    types.ReBoardTransfer,
  ]

  list.length(transfer_types) |> should.equal(6)
}

// =============================================================================
// Pathway Type Tests
// =============================================================================

pub fn pathway_mode_enum_test() {
  let pathway_modes = [
    types.Walkway,
    types.Stairs,
    types.MovingSidewalk,
    types.Escalator,
    types.Elevator,
    types.FareGate,
    types.ExitGate,
  ]

  list.length(pathway_modes) |> should.equal(7)
}

// =============================================================================
// Pickup/DropOff Type Tests
// =============================================================================

pub fn pickup_type_enum_test() {
  let pickup_types = [
    types.RegularPickup,
    types.NoPickup,
    types.PhoneForPickup,
    types.DriverCoordinatedPickup,
  ]

  list.length(pickup_types) |> should.equal(4)
}

pub fn dropoff_type_enum_test() {
  let dropoff_types = [
    types.RegularDropOff,
    types.NoDropOff,
    types.PhoneForDropOff,
    types.DriverCoordinatedDropOff,
  ]

  list.length(dropoff_types) |> should.equal(4)
}

// =============================================================================
// Exception Type Tests
// =============================================================================

pub fn exception_type_enum_test() {
  let exception_types = [types.ServiceAdded, types.ServiceRemoved]

  list.length(exception_types) |> should.equal(2)
}

// =============================================================================
// Timepoint Type Tests
// =============================================================================

pub fn timepoint_enum_test() {
  let timepoints = [types.Approximate, types.Exact]

  list.length(timepoints) |> should.equal(2)
}

// =============================================================================
// Direction Type Tests
// =============================================================================

pub fn direction_enum_test() {
  let directions = [types.Outbound, types.Inbound]

  list.length(directions) |> should.equal(2)
}

// =============================================================================
// Continuous Pickup/DropOff Type Tests
// =============================================================================

pub fn continuous_pickup_enum_test() {
  let pickup_types = [
    types.ContinuousStoppingPickup,
    types.NoContinuousStoppingPickup,
    types.PhoneAgencyForPickup,
    types.CoordinateWithDriverForPickup,
  ]

  list.length(pickup_types) |> should.equal(4)
}

pub fn continuous_dropoff_enum_test() {
  let dropoff_types = [
    types.ContinuousStoppingDropOff,
    types.NoContinuousStoppingDropOff,
    types.PhoneAgencyForDropOff,
    types.CoordinateWithDriverForDropOff,
  ]

  list.length(dropoff_types) |> should.equal(4)
}
