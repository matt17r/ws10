class StaticPagesController < ApplicationController
  allow_unauthenticated_access(only: [ :about, :courses, :home, :results ])

  EventStruct = Struct.new(:nickname, :location, :date)

  def about
  end

  def admin_dashboard
    @in_progress_events = Event.where("results_ready = ?", false)
  end

  def courses
  end

  def home
    @upcoming_events = [
      EventStruct.new(nickname: "Nepean River", location: "Tench Reserve, Jamisontown", date: "18th May"),
      EventStruct.new(nickname: "Parramatta", location: "Parramatta Park", date: "15th Jun"),
      EventStruct.new(nickname: "Bungarribee", location: "Bungarribee Park", date: "20th Jul")
    ]
  end

  def results
  end
end
