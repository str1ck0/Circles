module ApplicationHelper
  def user_avatar(user, **options)
    options[:alt] ||= user.full_name
    source = user.photo.attached? ? user.photo : "avatar/CirclesAvatar.png"
    image_tag source, **options
  end

  def sidebar_link(label, path, icon)
    active = current_page?(path)
    link_to path, class: "sidebar-link #{'is-active' if active}", "aria-current": (active ? "page" : nil) do
      safe_join([tag.i(class: icon), tag.span(label)])
    end
  end

  def sidebar_circles
    @sidebar_circles ||= current_user.circles.includes(photo_attachment: :blob).order(:name).to_a
  end

  def sidebar_discover_circles
    @sidebar_discover_circles ||= Circle.publicly_visible.where.not(id: current_user.circle_ids)
                                        .includes(photo_attachment: :blob).order(:name).limit(8).to_a
  end
end
