class Location < ApplicationRecord
  has_many :events, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9-]+\z/ }
  validates :nickname, presence: true
  validates :subtitle, presence: true
  validates :full_address, presence: true
  validates :start_point_description, presence: true
  validates :google_maps_url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp }
  validates :apple_maps_url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp }
  validates :facilities, presence: true
  validates :course_description, presence: true
  validates :strava_route_url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp }
  validates :strava_embed_id, presence: true
  validates :strava_map_hash, presence: true

  def to_param
    slug
  end

  def to_s
    name
  end

  def next_event
    events.where("date >= ?", Date.today).where.not(status: "finalised").order(:date).first
  end

  def latest_event
    events.where(status: "finalised").order(date: :desc).first
  end
end
