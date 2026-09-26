class ItemsController < ApplicationController
  before_action :set_item, only: %i[ show edit update destroy ]

  # ?status=owned|wishlist|considering, ?retired=1|0. The page defaults to owned,
  # active gear. JSON applies only the filters given, so an unfiltered call sees
  # the whole inventory.
  def index
    @status = Item::STATUSES.include?(params[:status]) ? params[:status] : "owned"
    @retired = params[:retired] == "1"
    @items = Item.ordered

    if request.format.json?
      @items = @items.where(status: params[:status]) if params.key?(:status)
      @items = @items.where(retired: @retired) if params.key?(:retired)
    else
      @items = @items.where(status: @status, retired: @retired)
    end
  end


  def show
    @trips = Trip.joins(:trip_items).where(trip_items: { item_id: @item.id }).ordered
  end

  def new
    @item = Item.new
  end

  def edit
  end

  def create
    @item = Item.new(item_params)

    if @item.save
      respond_to do |format|
        format.html { redirect_to @item, notice: "#{@item.name} added." }
        format.json { render :show, status: :created, location: @item }
      end
    else
      render_invalid(:new)
    end
  end

  def update
    if @item.update(item_params)
      respond_to do |format|
        format.html { redirect_to @item, notice: "#{@item.name} updated.", status: :see_other }
        format.json { render :show }
      end
    else
      render_invalid(:edit)
    end
  end

  def destroy
    @item.destroy!

    respond_to do |format|
      format.html { redirect_to items_path, notice: "#{@item.name} removed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private

  def set_item
    @item = Item.find(params.expect(:id))
  end

  def render_invalid(template)
    respond_to do |format|
      format.html { render template, status: :unprocessable_entity }
      format.json { render json: { errors: @item.errors }, status: :unprocessable_entity }
    end
  end

  def item_params
    params.expect(item: [
      :name, :manufacturer, :category, :weight_grams, :measured_weight_grams,
      :unit_weight_grams, :unit_label, :status, :worn, :consumable, :retired, :notes, :purchased_on
    ])
  end
end
