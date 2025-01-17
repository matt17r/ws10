class StaticPagesController < ApplicationController
  Event = Struct.new(:nickname, :location, :date, :course_url)

  def home
    @upcoming_events = [
      Event.new(nickname: "Bungarribee", location: "Bungarribee Park", date: "19th Jan", course_url: "#"),
      Event.new(nickname: "Nepean River", location: "Tench Reserve, Jamesontown", date: "16th Feb", course_url: nil),
      Event.new(nickname: "Parramatta", location: "Parramatta Park/River", date: "16th Mar", course_url: nil)
    ]
  end

  def courses
  end
end
