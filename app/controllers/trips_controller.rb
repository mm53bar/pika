class TripsController < ApplicationController
  before_action :set_trip, only: %i[ show edit update destroy pack ]

  def index
    @trips = Trip.ordered
  end

  def show
  end

  def new
    @trip = Trip.new
  end

  def edit
  end

  def create
    @trip = Trip.new(trip_params)

    if @trip.save
      respond_to do |format|
        format.html { redirect_to @trip, notice: "#{@trip.name} added." }
        format.json { render :show, status: :created, location: @trip }
      end
    else
      render_invalid(:new)
    end
  end

  def update
    if @trip.update(trip_params)
      respond_to do |format|
        format.html { redirect_to @trip, notice: "#{@trip.name} updated.", status: :see_other }
        format.json { render :show }
      end
    else
      render_invalid(:edit)
    end
  end

  def destroy
    @trip.destroy!

    respond_to do |format|
      format.html { redirect_to trips_path, notice: "#{@trip.name} removed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  def pack
    kit = Kit.find(params.expect(:kit_id))
    added = @trip.pack_from!(kit)

    respond_to do |format|
      format.html { redirect_to @trip, notice: "Packed #{added} #{"item".pluralize(added)} from #{kit.name}.", status: :see_other }
      format.json { render :show }
    end
  end

  private

  def set_trip
    @trip = Trip.find(params.expect(:id))
  end

  def render_invalid(template)
    respond_to do |format|
      format.html { render template, status: :unprocessable_entity }
      format.json { render json: { errors: @trip.errors }, status: :unprocessable_entity }
    end
  end

  def trip_params
    params.expect(trip: [ :name, :destination, :trail, :starts_on, :ends_on, :season, :terrain, :notes ])
  end
end
