class BadgesController < ApplicationController
  allow_unauthenticated_access

  def index
    @badges = Badge.order(:badge_family)
  end

  def show
    @badge = Badge.find_by!(badge_family: params[:family])
  end
end
