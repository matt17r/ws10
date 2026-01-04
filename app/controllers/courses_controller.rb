class CoursesController < ApplicationController
  allow_unauthenticated_access

  def show
    @location = Location.find_by!(slug: params[:slug])
    @next_event = @location.next_event
    @latest_event = @location.latest_event
  end
end
