class Admin::LocationsController < ApplicationController
  include AdminAuthentication

  before_action :set_location, only: [ :show, :edit, :update, :destroy ]

  def index
    @locations = Location.all.order(:name)
  end

  def show
  end

  def new
    @location = Location.new
  end

  def create
    @location = Location.new(location_params)

    if @location.save
      redirect_to admin_location_path(@location), notice: "Location was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @location.update(location_params)
      redirect_to admin_location_path(@location), notice: "Location was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @location.destroy!
    redirect_to admin_locations_path, notice: "Location was successfully deleted."
  end

  private

  def set_location
    @location = Location.find_by!(slug: params[:slug])
  end

  def location_params
    params.expect(location: [
      :name, :slug, :nickname, :subtitle, :full_address,
      :start_point_description, :google_maps_url, :apple_maps_url,
      :facilities, :course_description, :strava_route_url,
      :strava_embed_id, :strava_map_hash, :start_image_1,
      :start_image_2, :og_title, :og_description
    ])
  end
end
