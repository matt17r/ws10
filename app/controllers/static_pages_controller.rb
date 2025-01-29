class StaticPagesController < ApplicationController
  Event = Struct.new(:nickname, :location, :date)

  def about
  end

  def courses
  end

  def home
    @upcoming_events = [
      Event.new(nickname: "Nepean River", location: "Tench Reserve, Jamisontown", date: "16th Feb"),
      Event.new(nickname: "Parramatta", location: "Parramatta Park", date: "16th Mar"),
      Event.new(nickname: "Bungarribee", location: "Bungarribee Park", date: "20th Apr"),
    ]
  end

  def results
  end
end
