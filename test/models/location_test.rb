require "test_helper"

class LocationTest < ActiveSupport::TestCase
  test "accepts a gpx file" do
    location = locations(:bungarribee)
    location.gpx_file.attach(io: file_fixture("course.gpx").open, filename: "course.gpx", content_type: "application/gpx+xml")

    assert location.valid?
    assert location.gpx_file.attached?
  end

  test "is valid without a gpx file" do
    assert locations(:bungarribee).valid?
  end

  test "accepts a gpx file with a generic content type" do
    location = locations(:bungarribee)
    location.gpx_file.attach(io: file_fixture("course.gpx").open, filename: "course.gpx", content_type: "application/octet-stream")

    assert location.valid?
  end

  test "rejects a file without a gpx extension" do
    location = locations(:bungarribee)
    location.gpx_file.attach(io: StringIO.new("not a route"), filename: "route.pdf", content_type: "application/pdf")

    assert_not location.valid?
    assert_includes location.errors[:gpx_file], "must be a .gpx file"
  end

  test "rejects a gpx file over the size limit" do
    location = locations(:bungarribee)
    location.gpx_file.attach(io: StringIO.new("x" * (Location::MAX_GPX_FILE_SIZE + 1)), filename: "huge.gpx", content_type: "application/gpx+xml")

    assert_not location.valid?
    assert_includes location.errors[:gpx_file], "must be smaller than 5 MB"
  end
end
