import gleam/io
import simplifile

pub fn debug_working_directory_test() {
  case simplifile.current_directory() {
    Ok(cwd) -> {
      io.println("\n=== Current Working Directory ===")
      io.println(cwd)

      // Check if spec/resources/gtfs.zip exists from current directory
      case simplifile.is_file("./spec/resources/gtfs.zip") {
        Ok(True) -> io.println("✓ ./spec/resources/gtfs.zip EXISTS")
        Ok(False) -> io.println("✗ ./spec/resources/gtfs.zip IS NOT A FILE")
        Error(_) -> io.println("✗ ./spec/resources/gtfs.zip NOT FOUND")
      }

      // Try absolute path
      case
        simplifile.is_file(
          "/Users/evan/Developer/@evnsh/gtfs_gleam/spec/resources/gtfs.zip",
        )
      {
        Ok(True) -> io.println("✓ Absolute path EXISTS")
        Ok(False) -> io.println("✗ Absolute path IS NOT A FILE")
        Error(_) -> io.println("✗ Absolute path NOT FOUND")
      }
    }
    Error(_) -> io.println("Cannot determine working directory")
  }
}
