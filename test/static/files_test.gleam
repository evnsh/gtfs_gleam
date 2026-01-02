//// Static File Parser Tests
////
//// Tests for GTFS static file parsers (agency, stops, routes, trips, stop_times)

import gleam/list
import gleam/option.{None, Some}
import gleeunit/should
import gtfs/static/files/agency
import gtfs/static/files/calendar
import gtfs/static/files/calendar_dates
import gtfs/static/files/routes
import gtfs/static/files/stop_times
import gtfs/static/files/stops
import gtfs/static/files/trips
import gtfs/static/types

// =============================================================================
// Agency Parser Tests
// =============================================================================

pub fn parse_agency_test() {
  let content =
    "agency_id,agency_name,agency_url,agency_timezone,agency_lang,agency_phone,agency_fare_url,agency_email,cemv_support
1,Test Transit,https://example.com,America/New_York,en,555-1234,https://fares.example.com,info@example.com,1"

  let assert Ok(agencies) = agency.parse(content)
  list.length(agencies) |> should.equal(1)

  let assert Ok(a) = list.first(agencies)
  a.agency_id |> should.equal(Some("1"))
  a.agency_name |> should.equal("Test Transit")
  a.agency_url.value |> should.equal("https://example.com")
  a.agency_timezone.name |> should.equal("America/New_York")
  a.cemv_support |> should.equal(types.CemvSupported)
}

pub fn parse_agency_minimal_test() {
  let content =
    "agency_name,agency_url,agency_timezone
Test Transit,https://example.com,America/New_York"

  let assert Ok(agencies) = agency.parse(content)
  let assert Ok(a) = list.first(agencies)

  a.agency_id |> should.equal(None)
  a.agency_name |> should.equal("Test Transit")
  a.agency_lang |> should.equal(None)
  a.cemv_support |> should.equal(types.NoCemvInfo)
}

pub fn parse_multiple_agencies_test() {
  let content =
    "agency_id,agency_name,agency_url,agency_timezone
1,Agency One,https://one.example.com,America/New_York
2,Agency Two,https://two.example.com,America/Los_Angeles"

  let assert Ok(agencies) = agency.parse(content)
  list.length(agencies) |> should.equal(2)
}

pub fn parse_agency_cemv_test() {
  let content =
    "agency_name,agency_url,agency_timezone,cemv_support
Agency A,https://a.com,America/New_York,0
Agency B,https://b.com,America/New_York,1
Agency C,https://c.com,America/New_York,2"

  let assert Ok(agencies) = agency.parse(content)
  let assert [a, b, c] = agencies
  a.cemv_support |> should.equal(types.NoCemvInfo)
  b.cemv_support |> should.equal(types.CemvSupported)
  c.cemv_support |> should.equal(types.CemvNotSupported)
}

// =============================================================================
// Stops Parser Tests
// =============================================================================

pub fn parse_stops_test() {
  let content =
    "stop_id,stop_name,location_type,wheelchair_boarding
S1,Main Street Station,1,1"

  let assert Ok(stop_list) = stops.parse(content)
  let assert Ok(s) = list.first(stop_list)

  s.stop_id |> should.equal("S1")
  s.stop_name |> should.equal(Some("Main Street Station"))
  s.location_type |> should.equal(types.Station)
  s.wheelchair_boarding |> should.equal(types.WheelchairAccessible)
}

pub fn parse_stops_with_parent_station_test() {
  let content =
    "stop_id,stop_name,location_type,parent_station
S1,Main Street Station,1,
P1,Platform 1,0,S1"

  let assert Ok(stop_list) = stops.parse(content)
  list.length(stop_list) |> should.equal(2)

  let assert Ok(platform) = list.last(stop_list)
  platform.parent_station |> should.equal(Some("S1"))
  platform.location_type |> should.equal(types.StopOrPlatform)
}

pub fn parse_stops_location_types_test() {
  let content =
    "stop_id,stop_name,location_type
S0,Stop,0
S1,Station,1
S2,Entrance,2
S3,Node,3
S4,Boarding,4"

  let assert Ok(stop_list) = stops.parse(content)
  list.length(stop_list) |> should.equal(5)
}

pub fn parse_stops_with_stop_access_test() {
  let content =
    "stop_id,stop_name,location_type,stop_access
S1,Stop One,0,0
S2,Stop Two,0,1"

  let assert Ok(stop_list) = stops.parse(content)
  let assert [s1, s2] = stop_list
  s1.stop_access |> should.equal(Some(types.MustUsePathways))
  s2.stop_access |> should.equal(Some(types.DirectStreetAccess))
}

// =============================================================================
// Routes Parser Tests
// =============================================================================

pub fn parse_routes_test() {
  let content =
    "route_id,agency_id,route_short_name,route_long_name,route_type,route_color,route_text_color
R1,1,1,First Avenue Local,3,FF0000,FFFFFF"

  let assert Ok(route_list) = routes.parse(content)
  let assert Ok(r) = list.first(route_list)

  r.route_id |> should.equal("R1")
  r.agency_id |> should.equal(Some("1"))
  r.route_short_name |> should.equal(Some("1"))
  r.route_long_name |> should.equal(Some("First Avenue Local"))
  r.route_type |> should.equal(types.Bus)
}

pub fn parse_routes_all_types_test() {
  let content =
    "route_id,route_short_name,route_type
R0,Tram,0
R1,Subway,1
R2,Rail,2
R3,Bus,3
R4,Ferry,4
R5,Cable,5
R6,Gondola,6
R7,Funicular,7
R11,Trolley,11
R12,Monorail,12"

  let assert Ok(route_list) = routes.parse(content)
  list.length(route_list) |> should.equal(10)

  let assert [r0, r1, r2, r3, r4, r5, r6, r7, r11, r12] = route_list
  r0.route_type |> should.equal(types.Tram)
  r1.route_type |> should.equal(types.Subway)
  r2.route_type |> should.equal(types.Rail)
  r3.route_type |> should.equal(types.Bus)
  r4.route_type |> should.equal(types.Ferry)
  r5.route_type |> should.equal(types.CableTram)
  r6.route_type |> should.equal(types.AerialLift)
  r7.route_type |> should.equal(types.Funicular)
  r11.route_type |> should.equal(types.Trolleybus)
  r12.route_type |> should.equal(types.Monorail)
}

// =============================================================================
// Trips Parser Tests
// =============================================================================

pub fn parse_trips_test() {
  let content =
    "route_id,service_id,trip_id,trip_headsign,direction_id,block_id,shape_id
R1,WD,T1,Downtown,0,B1,SH1"

  let assert Ok(trip_list) = trips.parse(content)
  let assert Ok(t) = list.first(trip_list)

  t.route_id |> should.equal("R1")
  t.service_id |> should.equal("WD")
  t.trip_id |> should.equal("T1")
  t.trip_headsign |> should.equal(Some("Downtown"))
  t.direction_id |> should.equal(Some(types.Outbound))
  t.block_id |> should.equal(Some("B1"))
  t.shape_id |> should.equal(Some("SH1"))
}

pub fn parse_trips_direction_ids_test() {
  let content =
    "route_id,service_id,trip_id,direction_id
R1,WD,T1,0
R1,WD,T2,1"

  let assert Ok(trip_list) = trips.parse(content)
  let assert [t1, t2] = trip_list

  t1.direction_id |> should.equal(Some(types.Outbound))
  t2.direction_id |> should.equal(Some(types.Inbound))
}

// =============================================================================
// Stop Times Parser Tests
// =============================================================================

pub fn parse_stop_times_test() {
  let content =
    "trip_id,arrival_time,departure_time,stop_id,stop_sequence,stop_headsign,pickup_type,drop_off_type
T1,08:30:00,08:31:00,S1,1,Downtown,0,0
T1,08:45:00,08:46:00,S2,2,,0,0"

  let assert Ok(st_list) = stop_times.parse(content)
  list.length(st_list) |> should.equal(2)

  let assert Ok(st) = list.first(st_list)
  st.trip_id |> should.equal("T1")
  st.stop_sequence |> should.equal(1)
  st.stop_headsign |> should.equal(Some("Downtown"))
}

pub fn parse_stop_times_overnight_test() {
  // Times exceeding 24:00:00 for overnight service
  let content =
    "trip_id,arrival_time,departure_time,stop_id,stop_sequence
T1,25:30:00,25:31:00,S1,1"

  let assert Ok(st_list) = stop_times.parse(content)
  let assert Ok(st) = list.first(st_list)

  // Arrival time should be parsed as 25:30:00
  let assert Some(arr) = st.arrival_time
  arr.hours |> should.equal(25)
  arr.minutes |> should.equal(30)
  arr.seconds |> should.equal(0)
}

pub fn parse_stop_times_pickup_dropoff_types_test() {
  let content =
    "trip_id,arrival_time,departure_time,stop_id,stop_sequence,pickup_type,drop_off_type
T1,08:00:00,08:01:00,S1,1,0,0
T1,08:10:00,08:11:00,S2,2,1,1
T1,08:20:00,08:21:00,S3,3,2,2
T1,08:30:00,08:31:00,S4,4,3,3"

  let assert Ok(st_list) = stop_times.parse(content)
  let assert [st1, st2, st3, st4] = st_list

  st1.pickup_type |> should.equal(types.RegularPickup)
  st1.drop_off_type |> should.equal(types.RegularDropOff)

  st2.pickup_type |> should.equal(types.NoPickup)
  st2.drop_off_type |> should.equal(types.NoDropOff)

  st3.pickup_type |> should.equal(types.PhoneForPickup)
  st3.drop_off_type |> should.equal(types.PhoneForDropOff)

  st4.pickup_type |> should.equal(types.DriverCoordinatedPickup)
  st4.drop_off_type |> should.equal(types.DriverCoordinatedDropOff)
}

pub fn parse_stop_times_timepoint_test() {
  let content =
    "trip_id,arrival_time,departure_time,stop_id,stop_sequence,timepoint
T1,08:00:00,08:01:00,S1,1,0
T1,08:10:00,08:11:00,S2,2,1"

  let assert Ok(st_list) = stop_times.parse(content)
  let assert [st1, st2] = st_list

  st1.timepoint |> should.equal(types.Approximate)
  st2.timepoint |> should.equal(types.Exact)
}

// =============================================================================
// Calendar Parser Tests
// =============================================================================

pub fn parse_calendar_test() {
  let content =
    "service_id,monday,tuesday,wednesday,thursday,friday,saturday,sunday,start_date,end_date
WD,1,1,1,1,1,0,0,20250101,20251231"

  let assert Ok(cal_list) = calendar.parse(content)
  let assert Ok(c) = list.first(cal_list)

  c.service_id |> should.equal("WD")
  c.monday |> should.equal(True)
  c.tuesday |> should.equal(True)
  c.wednesday |> should.equal(True)
  c.thursday |> should.equal(True)
  c.friday |> should.equal(True)
  c.saturday |> should.equal(False)
  c.sunday |> should.equal(False)
  c.start_date.year |> should.equal(2025)
  c.start_date.month |> should.equal(1)
  c.start_date.day |> should.equal(1)
  c.end_date.year |> should.equal(2025)
  c.end_date.month |> should.equal(12)
  c.end_date.day |> should.equal(31)
}

pub fn parse_calendar_weekend_service_test() {
  let content =
    "service_id,monday,tuesday,wednesday,thursday,friday,saturday,sunday,start_date,end_date
WE,0,0,0,0,0,1,1,20250101,20251231"

  let assert Ok(cal_list) = calendar.parse(content)
  let assert Ok(c) = list.first(cal_list)

  c.monday |> should.equal(False)
  c.saturday |> should.equal(True)
  c.sunday |> should.equal(True)
}

// =============================================================================
// Calendar Dates Parser Tests
// =============================================================================

pub fn parse_calendar_dates_test() {
  let content =
    "service_id,date,exception_type
WD,20251225,2
WD,20251226,2
HOL,20251225,1"

  let assert Ok(cd_list) = calendar_dates.parse(content)
  list.length(cd_list) |> should.equal(3)

  let assert Ok(first) = list.first(cd_list)
  first.service_id |> should.equal("WD")
  first.date.year |> should.equal(2025)
  first.date.month |> should.equal(12)
  first.date.day |> should.equal(25)
  first.exception_type |> should.equal(types.ServiceRemoved)
}

pub fn parse_calendar_dates_exception_types_test() {
  let content =
    "service_id,date,exception_type
S1,20250101,1
S2,20250101,2"

  let assert Ok(cd_list) = calendar_dates.parse(content)
  let assert [cd1, cd2] = cd_list

  cd1.exception_type |> should.equal(types.ServiceAdded)
  cd2.exception_type |> should.equal(types.ServiceRemoved)
}
