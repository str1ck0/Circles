require "test_helper"

class ApplicationCable::ConnectionTest < ActionCable::Connection::TestCase
  FakeWarden = Struct.new(:user)

  test "connects as the signed-in user" do
    user = create_user
    connect env: { "warden" => FakeWarden.new(user) }
    assert_equal user, connection.current_user
  end

  test "rejects anonymous connections" do
    assert_reject_connection do
      connect env: { "warden" => FakeWarden.new(nil) }
    end
  end
end
