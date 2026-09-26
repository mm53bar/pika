class KitsController < ApplicationController
  before_action :set_kit, only: %i[ show edit update destroy ]

  def index
    @kits = Kit.ordered
  end

  def show
  end

  def new
    @kit = Kit.new
  end

  def edit
  end

  def create
    @kit = Kit.new(kit_params)

    if @kit.save
      respond_to do |format|
        format.html { redirect_to @kit, notice: "#{@kit.name} added." }
        format.json { render :show, status: :created, location: @kit }
      end
    else
      render_invalid(:new)
    end
  end

  def update
    if @kit.update(kit_params)
      respond_to do |format|
        format.html { redirect_to @kit, notice: "#{@kit.name} updated.", status: :see_other }
        format.json { render :show }
      end
    else
      render_invalid(:edit)
    end
  end

  def destroy
    @kit.destroy!

    respond_to do |format|
      format.html { redirect_to kits_path, notice: "#{@kit.name} removed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private

  def set_kit
    @kit = Kit.find(params.expect(:id))
  end

  def render_invalid(template)
    respond_to do |format|
      format.html { render template, status: :unprocessable_entity }
      format.json { render json: { errors: @kit.errors }, status: :unprocessable_entity }
    end
  end

  def kit_params
    params.expect(kit: [ :name, :description, :season ])
  end
end
