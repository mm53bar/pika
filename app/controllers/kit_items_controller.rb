class KitItemsController < ApplicationController
  before_action :set_kit_item, only: %i[ update destroy ]

  def create
    kit = Kit.find(params.expect(:kit_id))
    attrs = kit_item_params
    item = Item.find(attrs[:item_id])
    @kit_item = kit.kit_items.new({ worn: item.worn }.merge(attrs))

    if @kit_item.save
      respond_to do |format|
        format.html { redirect_to kit, notice: "Added #{item.name}.", status: :see_other }
        format.json { render :show, status: :created }
      end
    else
      render_invalid(kit)
    end
  end

  def update
    if @kit_item.update(kit_item_params.except(:item_id))
      respond_to do |format|
        format.html { redirect_to @kit_item.kit, status: :see_other }
        format.json { render :show }
      end
    else
      render_invalid(@kit_item.kit)
    end
  end

  def destroy
    @kit_item.destroy!

    respond_to do |format|
      format.html { redirect_to @kit_item.kit, notice: "Removed #{@kit_item.item.name}.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private

  def set_kit_item
    @kit_item = KitItem.find(params.expect(:id))
  end

  def render_invalid(kit)
    respond_to do |format|
      format.html { redirect_to kit, alert: @kit_item.errors.full_messages.to_sentence, status: :see_other }
      format.json { render json: { errors: @kit_item.errors }, status: :unprocessable_entity }
    end
  end

  def kit_item_params
    params.expect(kit_item: [ :item_id, :quantity, :worn, :notes ])
  end
end
