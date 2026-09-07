ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

# Never hit a real geocoder from the suite.
Geocoder.configure(lookup: :test, ip_lookup: :test)
Geocoder::Lookup::Test.set_default_stub(
  [{ "coordinates" => [52.52, 13.405], "address" => "Berlin, Germany", "country" => "Germany", "country_code" => "DE" }]
)

class ActiveSupport::TestCase
  # Run tests in parallel with specified workers
  parallelize(workers: :number_of_processors)

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  def create_user(**attrs)
    User.create!({
      email: "user-#{SecureRandom.hex(4)}@example.com",
      password: "password",
      first_name: "Sam",
      last_name: "Smith"
    }.merge(attrs))
  end

  def create_circle(owner:, private: false, members: [], **attrs)
    circle = Circle.new({ name: "Circle #{SecureRandom.hex(2)}", private: private, border_color: "#ffffff", owner: owner }.merge(attrs))
    circle.photo.attach(io: File.open(file_fixture("avatar.png")), filename: "avatar.png", content_type: "image/png")
    circle.banner.attach(io: File.open(file_fixture("avatar.png")), filename: "banner.png", content_type: "image/png")
    circle.save!
    ([owner] + members).uniq.each { |user| UserCircle.find_or_create_by!(user: user, circle: circle) }
    circle
  end

  def create_event(host:, circles: [], attendees: [], private: false, **attrs)
    event = Event.new({
      title: "Event #{SecureRandom.hex(2)}",
      location: "Berlin",
      start_date: 1.week.from_now,
      end_date: 8.days.from_now,
      private: private,
      user: host
    }.merge(attrs))
    event.circles = circles
    event.save!
    UserEvent.create!(user: host, event: event, status: :going)
    attendees.each { |user| UserEvent.find_or_create_by!(user: user, event: event) }
    event
  end
end

class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
end
