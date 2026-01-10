class Badge < ApplicationRecord
  has_many :user_badges, dependent: :destroy
  has_many :users, through: :user_badges

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9-]+\z/ }
  validates :badge_family, presence: true
  validates :level, presence: true, inclusion: { in: %w[bronze silver gold singular] }
  validates :level_order, presence: true, numericality: { only_integer: true, greater_than: 0 }

  scope :by_level_order, -> { order(:level_order) }
  scope :in_family, ->(family) { where(badge_family: family) }

  def to_param
    badge_family
  end

  def bronze?
    level == "bronze"
  end

  def silver?
    level == "silver"
  end

  def gold?
    level == "gold"
  end

  def singular?
    level == "singular"
  end

  def family_badges
    Badge.in_family(badge_family).by_level_order
  end

  def next_level
    family_badges.where("level_order > ?", level_order).first
  end

  def previous_level
    family_badges.where("level_order < ?", level_order).last
  end

  def icon
    svg_path = Rails.root.join("app", "assets", "images", "badges", "#{badge_family}.svg")
    File.read(svg_path).html_safe
  end
end
