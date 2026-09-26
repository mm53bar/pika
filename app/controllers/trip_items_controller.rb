class TripItemsController < ApplicationController
  before_action :set_trip_item, only: %i[ update destroy ]

  # An item packed without saying whether it's worn takes its inventory
  # default — rain shell carried, trail runners worn.
  def create
    trip = Trip.find(params.expect(:trip_id))
    attrs = trip_item_params
    item = Item.find(attrs[:item_id])
    @trip_item = trip.trip_items.new({ worn: item.worn }.merge(attrs))

    if @trip_item.save
      respond_to do |format|
        format.html { redirect_to trip, notice: "Packed #{item.name}.", status: :see_other }
        format.json { render :show, status: :created }
      end
    else
      render_invalid(trip)
    end
  end

  def update
    if @trip_item.update(trip_item_params.except(:item_id))
      respond_to do |format|
        format.html { redirect_to @trip_item.trip, status: :see_other }
        format.json { render :show }
      end
    else
      render_invalid(@trip_item.trip)
    end
  end

  def destroy
    @trip_item.destroy!

    respond_to do |format|
      format.html { redirect_to @trip_item.trip, notice: "Unpacked #{@trip_item.item.name}.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private

  def set_trip_item
    @trip_item = TripItem.find(params.expect(:id))
  end

  def render_invalid(trip)
    respond_to do |format|
      format.html { redirect_to trip, alert: @trip_item.errors.full_messages.to_sentence, status: :see_other }
      format.json { render json: { errors: @trip_item.errors }, status: :unprocessable_entity }
    end
  end

  def trip_item_params
    params.expect(trip_item: [ :item_id, :quantity, :worn, :weight_grams_override, :notes ])
  end
end
