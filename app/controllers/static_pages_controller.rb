class StaticPagesController < ApplicationController
  allow_unauthenticated_access(only: [ :about, :courses, :home, :results ])

  Event = Struct.new(:nickname, :location, :date)

  def about
  end

  def courses
  end

  def home
    @upcoming_events = [
      Event.new(nickname: "Parramatta", location: "Parramatta Park", date: "16th Mar"),
      Event.new(nickname: "Bungarribee", location: "Bungarribee Park", date: "20th Apr"),
      Event.new(nickname: "Nepean River", location: "Tench Reserve, Jamisontown", date: "18th May")
    ]
  end

  def results
  end
end
