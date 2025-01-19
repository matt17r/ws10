class StaticPagesController < ApplicationController
  Event = Struct.new(:nickname, :location, :date, :course_url)

  def about
  end

  def courses
  end

  def home
    @upcoming_events = [
      Event.new(nickname: "Nepean River", location: "Tench Reserve, Jamisontown", date: "16th Feb", course_url: nil),
      Event.new(nickname: "Parramatta", location: "Parramatta Park/River", date: "16th Mar", course_url: nil),
      Event.new(nickname: "Bungarribee", location: "Bungarribee Park", date: "20th Apr", course_url: "#"),
    ]
  end

  def results
  end
end
