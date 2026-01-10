module BadgesHelper
  def badge_border_class(badge, left: false)
    prefix = left ? "border-l-badge-" : "border-badge-"
    "#{prefix}#{badge.level}"
  end

  def badge_text_class(badge)
    "text-badge-#{badge.level}"
  end

  def badge_border_colour(badge)
    case badge.level
    when "singular"
      "#DB2955"
    when "bronze"
      "#CD7F32"
    when "silver"
      "#C0C0C0"
    when "gold"
      "#FFD700"
    end
  end

  def badge_icon_url(badge)
    "#{root_url}badges/#{badge.badge_family}.png"
  end
end
