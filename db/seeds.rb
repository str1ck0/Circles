require "open-uri"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

COLORS = %w[#33a8c7 #52e3e1 #a0e426 #fdf148 #ffab00 #f77976 #f050ae #d883ff
            #9336fd #ffbe0b #fb5607 #ff006e #8338ec #3a86ff].freeze

FALLBACK_IMAGE = Rails.root.join("app/assets/images/avatar/CirclesAvatar.png")

# Attach a remote image to a record's attachment. If the download fails for any
# reason we fall back to a bundled image so presence validations still pass and
# seeding never dies halfway through.
def attach_image(record, attachment, url, filename: "image.png", content_type: "image/png")
  file = URI.parse(url).open
  record.public_send(attachment).attach(io: file, filename: filename, content_type: content_type)
rescue StandardError => e
  puts "  [fallback] #{url} → #{e.class}: #{e.message}"
  record.public_send(attachment).attach(
    io: File.open(FALLBACK_IMAGE), filename: "fallback.png", content_type: "image/png"
  )
end

def avatar_url(index)
  "https://i.pravatar.cc/300?img=#{(index % 70) + 1}"
end

# ---------------------------------------------------------------------------
# Clear
# ---------------------------------------------------------------------------

puts "> Clearing the DB.."
Notification.destroy_all
Invitation.destroy_all
Splittee.destroy_all
Payment.destroy_all
EventPlaylist.destroy_all
CirclePlaylist.destroy_all
CircleEvent.destroy_all
UserEvent.destroy_all
EventMessage.destroy_all
UserCircle.destroy_all
CircleMessage.destroy_all
Event.destroy_all
Circle.destroy_all
User.destroy_all

# ---------------------------------------------------------------------------
# Users
# ---------------------------------------------------------------------------

puts "> Creating the main character..."
main_user = User.create!(
  email: "benten@gmail.com", password: "password",
  username: "benten", first_name: "Liam", last_name: "Strickland"
)
attach_image(main_user, :photo, avatar_url(0))

puts "> Creating other users..."
users = [main_user]
60.times do |i|
  male = i.even?
  user = User.create!(
    email: Faker::Internet.unique.email,
    password: "password",
    username: Faker::Internet.unique.username(specifier: 5..12),
    first_name: male ? Faker::Name.male_first_name : Faker::Name.female_first_name,
    last_name: Faker::Name.last_name
  )
  attach_image(user, :photo, avatar_url(i + 1))
  users << user
end
puts "  created #{User.count} users"

# ---------------------------------------------------------------------------
# Circles
# ---------------------------------------------------------------------------

puts "> Creating circles..."

circle_data = [
  { name: "Family 🧡", private: true, members: 5,
    photo: "https://images.unsplash.com/photo-1511895426328-dc8714191300?auto=format&fit=crop&w=800&q=80",
    banner: "https://images.unsplash.com/photo-1529156069898-49953e39b3ac?auto=format&fit=crop&w=1600&q=80" },
  { name: "Miami Bulls 🏀", private: true, members: 12,
    photo: "https://images.unsplash.com/photo-1515523110800-9415d13b84a8?auto=format&fit=crop&w=800&q=80",
    banner: "https://images.unsplash.com/photo-1546519638-68e109498ffc?auto=format&fit=crop&w=1600&q=80" },
  { name: "The Office 💻", private: false, members: 10,
    photo: "https://images.unsplash.com/photo-1522202176988-66273c2fd55f?auto=format&fit=crop&w=800&q=80",
    banner: "https://images.unsplash.com/photo-1497366216548-37526070297c?auto=format&fit=crop&w=1600&q=80" },
  { name: "The Day Ones 💯", private: true, members: 6,
    photo: "https://images.unsplash.com/photo-1529333166437-7750a6dd5a70?auto=format&fit=crop&w=800&q=80",
    banner: "https://images.unsplash.com/photo-1475483768296-6163e08872a1?auto=format&fit=crop&w=1600&q=80" },
  { name: "Le Wagon Crew 🤓", private: true, members: 14,
    photo: "https://images.unsplash.com/photo-1531482615713-2afd69097998?auto=format&fit=crop&w=800&q=80",
    banner: "https://images.unsplash.com/photo-1521737604893-d14cc237f11d?auto=format&fit=crop&w=1600&q=80" },
  { name: "Chess Club ♟️", private: true, members: 7,
    photo: "https://images.unsplash.com/photo-1529699310859-b163e33e4556?auto=format&fit=crop&w=800&q=80",
    banner: "https://images.unsplash.com/photo-1528819622765-d6bcf132f793?auto=format&fit=crop&w=1600&q=80" },
  { name: "Footy Lads 🍻", private: true, members: 18,
    photo: "https://images.unsplash.com/photo-1543326727-cf6c39e8f84c?auto=format&fit=crop&w=800&q=80",
    banner: "https://images.unsplash.com/photo-1522778119026-d647f0596c20?auto=format&fit=crop&w=1600&q=80" },
  { name: "World Class Ravers 🎧", private: true, members: 9,
    photo: "https://images.unsplash.com/photo-1637561930888-dfedf87bf609?auto=format&fit=crop&w=800&q=80",
    banner: "https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?auto=format&fit=crop&w=1600&q=80" }
]

others = users - [main_user]

circles = circle_data.each_with_index.map do |data, i|
  # The main user is a member of most circles, but gets a pending invite to the last two
  # so the invitations/notifications flow has something to show.
  invite_only = i >= circle_data.size - 2
  members = others.sample(data[:members])
  members.unshift(main_user) unless invite_only

  circle = Circle.new(name: data[:name], private: data[:private],
                      border_color: COLORS.sample, owner: members.first)
  attach_image(circle, :photo, data[:photo])
  attach_image(circle, :banner, data[:banner])
  circle.save!

  members.each { |user| UserCircle.find_or_create_by!(user: user, circle: circle) }

  if invite_only
    invitation = Invitation.create!(circle: circle, inviter: members.first, invitee: main_user)
    Notification.notify(recipient: main_user, actor: members.first, notifiable: invitation, kind: :circle_invitation)
  end
  print "."
  circle
end
puts "\n  created #{Circle.count} circles"

# A few playlists on the first circle to show the feature off.
[
  "https://open.spotify.com/playlist/37i9dQZF1DXcBWIGoYBM5M",
  "https://open.spotify.com/playlist/37i9dQZF1DX0XUsuxWHRQd",
  "https://open.spotify.com/playlist/37i9dQZF1DWTJ0ewkTmTo2"
].each { |url| CirclePlaylist.create!(url: url, circle: circles.first) }

# ---------------------------------------------------------------------------
# Events
# ---------------------------------------------------------------------------

puts "> Creating events..."

event_data = [
  { title: "Surf Trip", private: true, location: "Ericeira, Portugal",
    photo: "https://images.unsplash.com/photo-1526342122811-2a9c8512023d?auto=format&fit=crop&w=1200&q=80" },
  { title: "Nico's Sweet 20th", private: true, location: "Hamburg, Germany",
    photo: "https://images.unsplash.com/photo-1514525253161-7a46d19cd819?auto=format&fit=crop&w=1200&q=80" },
  { title: "Poker Night", private: true, location: "Las Vegas, USA",
    photo: "https://images.unsplash.com/photo-1609769322709-2de28ae6503a?auto=format&fit=crop&w=1200&q=80" },
  { title: "Pangea Festival", private: false, location: "Pütnitz, Germany",
    photo: "https://images.unsplash.com/photo-1459749411175-04bf5292ceea?auto=format&fit=crop&w=1200&q=80" },
  { title: "5-a-Side Football", private: true, location: "London, UK",
    photo: "https://images.unsplash.com/photo-1517927033932-b3d18e61fb3a?auto=format&fit=crop&w=1200&q=80" },
  { title: "Christmas Dinner", private: true, location: "Cape Town, South Africa",
    photo: "https://images.unsplash.com/photo-1543094754-0790f4838e00?auto=format&fit=crop&w=1200&q=80" },
  { title: "Saturday Market", private: false, location: "V&A Waterfront, Cape Town",
    photo: "https://images.unsplash.com/photo-1533900298318-6b8da08a523e?auto=format&fit=crop&w=1200&q=80" },
  { title: "Braai & Watch the Game", private: true, location: "Constantia, Cape Town",
    photo: "https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&w=1200&q=80" }
]

events = event_data.each_with_index.map do |data, i|
  circle = circles[i % circles.size]
  start_date = Faker::Date.forward(days: rand(3..40))
  event = Event.new(
    title: data[:title], private: data[:private], location: data[:location],
    user: circle.users.sample, start_date: start_date, end_date: start_date + rand(1..3)
  )
  attach_image(event, :photos, data[:photo])
  event.save!

  # Attach the event to a circle and put its members on the guest list with a
  # realistic spread of RSVPs. The host is always going.
  CircleEvent.create!(circle: circle, event: event)
  UserEvent.create!(user: event.user, event: event, status: :going)
  circle.users.where.not(id: event.user_id).each do |user|
    UserEvent.create!(user: user, event: event, status: %i[going going going maybe invited declined].sample)
  end
  if event.attendee?(main_user)
    Notification.notify(recipient: main_user, actor: event.user, notifiable: event, kind: :event_created)
  end
  print "."
  event
end
puts "\n  created #{Event.count} events"

EventPlaylist.create!(url: "https://open.spotify.com/playlist/37i9dQZF1DX0BcQWzuB7ZO", event: events.first)

# ---------------------------------------------------------------------------
# Chat history — so the chatrooms aren't empty on the live demo
# ---------------------------------------------------------------------------

puts "> Seeding chat history..."

CIRCLE_CHATTER = [
  "Hey everyone! 👋", "Who's around this weekend?", "Just dropped a new playlist 🎧",
  "Can't wait for the next meetup", "Anyone up for a call later?", "Great seeing you all!",
  "Let's plan something soon 🙌", "Missed you all this week", "Count me in!", "So keen for this 🔥"
]

EVENT_CHATTER = [
  "What time are we meeting?", "I'll bring snacks 🍿", "Can someone give me a lift?",
  "So excited for this!", "Should we make a group playlist?", "Who's in charge of drinks?",
  "See you all there 🙌", "Running 10 mins late, sorry!", "This is going to be epic",
  "Don't forget your tickets 🎟️"
]

circles.each do |circle|
  members = circle.users.to_a
  rand(4..8).times do
    CircleMessage.create!(circle: circle, user: members.sample, content: CIRCLE_CHATTER.sample)
  end
end

events.each do |event|
  members = event.users.to_a
  next if members.empty?

  rand(3..7).times do
    EventMessage.create!(event: event, user: members.sample, content: EVENT_CHATTER.sample)
  end
end

# ---------------------------------------------------------------------------
# Payments — populate balances so the bill-splitting feature shows real numbers
# ---------------------------------------------------------------------------

puts "> Seeding payments..."

events.first(4).each do |event|
  user_events = event.user_events.to_a
  next if user_events.size < 2

  2.times do
    payer = user_events.sample
    splittees = (user_events - [payer]).sample(rand(1..[user_events.size - 1, 4].min))
    amount = rand(20..200)
    payment = Payment.create!(user_event: payer, description: Faker::Commerce.product_name, amount: amount)
    payment.user_events = splittees

    # Same arithmetic as PaymentsController: payer absorbs the integer remainder.
    share = amount / (splittees.count + 1)
    payer.update!(balance: payer.balance + share * splittees.count)
    splittees.each { |se| se.update!(balance: se.balance - share) }
  end
end

# ---------------------------------------------------------------------------

puts "> Finished!"
puts "> #{User.count} users, #{Circle.count} circles, #{Event.count} events, " \
     "#{CircleMessage.count + EventMessage.count} messages, #{Payment.count} payments."
puts "> Log in with  benten@gmail.com / password"
