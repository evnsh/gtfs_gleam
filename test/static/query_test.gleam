//// GTFS Static Query Tests
////
//// Tests for query functions and indexed lookups

import gleam/list
import gleam/option.{None, Some}
import gleeunit/should
import gtfs/common/types as common_types
import gtfs/static/feed
import gtfs/static/query
import gtfs/static/types as static_types

// =============================================================================
// Helper Functions
// =============================================================================

fn create_date(year: Int, month: Int, day: Int) -> common_types.Date {
  common_types.Date(year, month, day)
}

fn create_calendar(
  service_id: String,
  days: List(Int),
  start_date: common_types.Date,
  end_date: common_types.Date,
) -> static_types.Calendar {
  static_types.Calendar(
    service_id: service_id,
    monday: list.contains(days, 1),
    tuesday: list.contains(days, 2),
    wednesday: list.contains(days, 3),
    thursday: list.contains(days, 4),
    friday: list.contains(days, 5),
    saturday: list.contains(days, 6),
    sunday: list.contains(days, 0),
    start_date: start_date,
    end_date: end_date,
  )
}

fn create_calendar_date(
  service_id: String,
  date: common_types.Date,
  exception_type: static_types.ExceptionType,
) -> static_types.CalendarDate {
  static_types.CalendarDate(service_id, date, exception_type)
}

// =============================================================================
// Indexed Feed Tests
// =============================================================================

pub fn index_feed_test() {
  let f = feed.empty()
  let stop =
    static_types.Stop(
      "S1",
      None,
      None,
      None,
      None,
      None,
      None,
      None,
      None,
      static_types.Station,
      None,
      None,
      static_types.NoWheelchairInfo,
      None,
      None,
      None,
    )
  let route =
    static_types.Route(
      "R1",
      None,
      None,
      None,
      None,
      static_types.Bus,
      None,
      None,
      None,
      None,
      static_types.NoContinuousStoppingPickup,
      static_types.NoContinuousStoppingDropOff,
      None,
    )
  let trip =
    static_types.Trip(
      "R1",
      "S_WD",
      "T1",
      None,
      None,
      None,
      None,
      None,
      static_types.NoAccessibilityInfo,
      static_types.NoBikeInfo,
    )

  let feed_data = feed.Feed(..f, stops: [stop], routes: [route], trips: [trip])

  let indexed = query.index_feed(feed_data)

  // Test O(1) lookups
  query.get_stop(indexed, "S1") |> should.be_some
  query.get_route(indexed, "R1") |> should.be_some
  query.get_trip(indexed, "T1") |> should.be_some

  // Test lookups for non-existent items
  query.get_stop(indexed, "S99") |> should.be_none
}

// =============================================================================
// Service Active Tests
// =============================================================================

pub fn is_service_active_test() {
  let start = create_date(2025, 1, 1)
  let end = create_date(2025, 12, 31)

  // Service runs on Mondays (1) and Wednesdays (3)
  let cal = create_calendar("WD", [1, 3], start, end)

  // Exception: Service added on a Friday (2025-01-10)
  let added =
    create_calendar_date(
      "WD",
      create_date(2025, 1, 10),
      static_types.ServiceAdded,
    )

  // Exception: Service removed on a specific Monday (2025-01-6)
  let removed =
    create_calendar_date(
      "WD",
      create_date(2025, 1, 6),
      static_types.ServiceRemoved,
    )

  let f =
    feed.Feed(
      ..feed.empty(),
      calendar: Some([cal]),
      calendar_dates: Some([added, removed]),
    )

  // Test standard active day (Wednesday, Jan 1st 2025)
  // Jan 1 2025 is a Wednesday
  query.is_service_active(f, "WD", create_date(2025, 1, 1))
  |> should.be_true

  // Test standard inactive day (Tuesday, Jan 2nd 2025)
  query.is_service_active(f, "WD", create_date(2025, 1, 2))
  |> should.be_false

  // Test added service (Friday, Jan 10th 2025)
  query.is_service_active(f, "WD", create_date(2025, 1, 10))
  |> should.be_true

  // Test removed service (Monday, Jan 6th 2025)
  query.is_service_active(f, "WD", create_date(2025, 1, 6))
  |> should.be_false

  // Test date out of range (2026)
  query.is_service_active(f, "WD", create_date(2026, 1, 1))
  |> should.be_false
}

pub fn get_active_services_test() {
  let start = create_date(2025, 1, 1)
  let end = create_date(2025, 12, 31)

  // Service A: Mondays
  let cal_a = create_calendar("A", [1], start, end)
  // Service B: Tuesdays
  let cal_b = create_calendar("B", [2], start, end)

  let f = feed.Feed(..feed.empty(), calendar: Some([cal_a, cal_b]))

  // Monday Jan 6, 2025
  let active = query.get_active_services(f, create_date(2025, 1, 6))
  list.contains(active, "A") |> should.be_true
  list.contains(active, "B") |> should.be_false

  // Tuesday Jan 7, 2025
  let active = query.get_active_services(f, create_date(2025, 1, 7))
  list.contains(active, "A") |> should.be_false
  list.contains(active, "B") |> should.be_true
}
