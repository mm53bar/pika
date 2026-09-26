class ReferenceItemsController < ApplicationController
  before_action :set_reference_item, only: %i[ update destroy ]

  def create
    list = ReferenceList.find(params.expect(:reference_list_id))
    @reference_item = list.reference_items.new(reference_item_params)

    if @reference_item.save
      respond_to do |format|
        format.html { redirect_to list, notice: "Added #{@reference_item.name}.", status: :see_other }
        format.json { render :show, status: :created }
      end
    else
      render_invalid(list)
    end
  end

  def update
    if @reference_item.update(reference_item_params)
      respond_to do |format|
        format.html { redirect_to @reference_item.reference_list, status: :see_other }
        format.json { render :show }
      end
    else
      render_invalid(@reference_item.reference_list)
    end
  end

  def destroy
    @reference_item.destroy!

    respond_to do |format|
      format.html { redirect_to @reference_item.reference_list, notice: "Removed #{@reference_item.name}.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private

  def set_reference_item
    @reference_item = ReferenceItem.find(params.expect(:id))
  end

  def render_invalid(list)
    respond_to do |format|
      format.html { redirect_to list, alert: @reference_item.errors.full_messages.to_sentence, status: :see_other }
      format.json { render json: { errors: @reference_item.errors }, status: :unprocessable_entity }
    end
  end

  def reference_item_params
    params.expect(reference_item: [ :name, :manufacturer, :category, :weight_grams, :quantity, :worn, :consumable, :notes ])
  end
end
