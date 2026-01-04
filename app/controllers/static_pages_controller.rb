class StaticPagesController < ApplicationController
  allow_unauthenticated_access(only: [ :about, :courses, :home, :results ])

  EventStruct = Struct.new(:nickname, :location, :date)

  def about
  end

  def admin_dashboard
    @event = Event.in_progress.order(date: :asc).includes(:finish_positions, :finish_times, :results, :volunteers, :location).first
  end

  def courses
    # @default_tab = "tab-bungarribee"
    # @default_tab = "tab-nepean"
    @default_tab = "tab-parramatta"

    # 19th Oct
    # @next_bungarribee_event_fb = "https://www.facebook.com/events/1226001902067312/"
    # @next_bungarribee_event_strava = "https://www.strava.com/clubs/1343589/group_events/2125977"

    # 16th November
    # @next_nepean_event_fb = "https://www.facebook.com/events/693210060205889/"
    # @next_nepean_event_strava = "https://www.strava.com/clubs/1343589/group_events/2125979"

    # 21st December
    @next_parramatta_event_fb = "https://www.facebook.com/events/1952283132276856/"
    @next_parramatta_event_strava = "https://www.strava.com/clubs/1343589/group_events/2125986"
  end

  def home
    @upcoming_events = [
      EventStruct.new(nickname: "Parramatta", location: "Parramatta Park", date: "21st Dec")
      # EventStruct.new(nickname: "Bungarribee", location: "Bungarribee Park", date: "?")
      # EventStruct.new(nickname: "Nepean River", location: "Tench Reserve, Jamisontown", date: "?")
    ].first(3)
  end

  def results
  end
end
