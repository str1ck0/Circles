module ApplicationHelper
  def user_avatar(user, **options)
    options[:alt] ||= user.full_name
    source = user.photo.attached? ? user.photo : "avatar/CirclesAvatar.png"
    image_tag source, **options
  end
end
