require "application_system_test_case"

class EventInvitationsTest < ApplicationSystemTestCase
  include Warden::Test::Helpers

  teardown { Warden.test_reset! }

  test "host invites a person and the guest responds on mobile" do
    host = create_user
    guest = create_user(first_name: "ChessGuest")
    circle = create_circle(owner: host, private: true)
    event = create_event(host: host, circles: [circle], private: true, title: "Friday chess")

    login_as host, scope: :user
    visit event_path(event)
    click_link "Invite people"
    fill_in "Search by name or handle", with: "ChessGuest"
    click_button "Search"
    find("button[aria-label='Invite ChessGuest Smith']").click
    assert_text "ChessGuest is on the guest list."

    logout :user
    login_as guest, scope: :user
    page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride",
                                    width: 390, height: 844, deviceScaleFactor: 1, mobile: true)
    visit notifications_path
    within ".event-invitation" do
      assert_text "Friday chess"
      click_button "Going"
    end
    assert_current_path event_path(event)
    assert_selector ".rsvp-button.is-active[aria-pressed='true']", text: "Going"
    assert_selector "[data-chatroom-subscription-channel-value='EventChatroomChannel']"
    assert_no_text "Invite people"

    click_button "Maybe"
    assert_selector ".rsvp-button.is-active[aria-pressed='true']", text: "Maybe"
    assert_selector ".guest-list-heading", text: /maybe · 1/i
    assert_not circle.member?(guest)
    assert page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth"), "Event page overflows on mobile"
    save_screenshot Rails.root.join("tmp/screenshots/event-invitation-mobile.png")
  end
end
