class StaticPagesController < ApplicationController
  allow_unauthenticated_access(only: [ :about, :courses, :home, :results ])

  EventStruct = Struct.new(:nickname, :location, :date)

  def about
  end

  def admin_dashboard
    @in_progress_events = Event.where("results_ready = ?", false)
  end

  def courses
    # 20th July
    @next_bungarribee_event_fb = "https://www.facebook.com/events/1755918128619731"
    @next_bungarribee_event_strava = "https://www.strava.com/clubs/1343589/group_events/2125976"
    # 17th August
    @next_nepean_event_fb = "https://www.facebook.com/events/653019341094234"
    @next_nepean_event_strava = "https://www.strava.com/clubs/1343589/group_events/2125978"
    # 21st September
    @next_parramatta_event_fb = "https://www.facebook.com/events/711887074801846"
    @next_parramatta_event_strava = "https://www.strava.com/clubs/1343589/group_events/2125983"
  end

  def home
    @upcoming_events = [
      EventStruct.new(nickname: "Bungarribee", location: "Bungarribee Park", date: "20th Jul"),
      EventStruct.new(nickname: "Nepean River", location: "Tench Reserve, Jamisontown", date: "17th Aug"),
      EventStruct.new(nickname: "Parramatta", location: "Parramatta Park", date: "21st Sep")
    ]
  end

  def results
  end
end
