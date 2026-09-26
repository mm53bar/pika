class TripMealsController < ApplicationController
  before_action :set_trip_meal, only: %i[ update destroy ]

  def create
    trip = Trip.find(params.expect(:trip_id))
    @trip_meal = trip.trip_meals.new(trip_meal_params)

    if @trip_meal.save
      respond_to do |format|
        format.html { redirect_to trip, notice: "Added #{@trip_meal.meal.name}.", status: :see_other }
        format.json { render :show, status: :created }
      end
    else
      render_invalid(trip)
    end
  end

  def update
    if @trip_meal.update(trip_meal_params.except(:meal_id))
      respond_to do |format|
        format.html { redirect_to @trip_meal.trip, status: :see_other }
        format.json { render :show }
      end
    else
      render_invalid(@trip_meal.trip)
    end
  end

  def destroy
    @trip_meal.destroy!

    respond_to do |format|
      format.html { redirect_to @trip_meal.trip, notice: "Removed #{@trip_meal.meal.name}.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private

  def set_trip_meal
    @trip_meal = TripMeal.find(params.expect(:id))
  end

  def render_invalid(trip)
    respond_to do |format|
      format.html { redirect_to trip, alert: @trip_meal.errors.full_messages.to_sentence, status: :see_other }
      format.json { render json: { errors: @trip_meal.errors }, status: :unprocessable_entity }
    end
  end

  def trip_meal_params
    params.expect(trip_meal: [ :meal_id, :quantity, :notes ])
  end
end
