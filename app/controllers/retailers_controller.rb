class RetailersController < ApplicationController
  before_action :set_retailer, only: %i[ update destroy ]

  def index
    @retailers = Retailer.ordered
    @retailer = Retailer.new
  end

  def create
    @retailer = Retailer.new(retailer_params)

    if @retailer.save
      respond_to do |format|
        format.html { redirect_to retailers_path, notice: "#{@retailer.value} added.", status: :see_other }
        format.json { render :show, status: :created }
      end
    else
      respond_to do |format|
        format.html { redirect_to retailers_path, alert: @retailer.errors.full_messages.to_sentence, status: :see_other }
        format.json { render json: { errors: @retailer.errors }, status: :unprocessable_entity }
      end
    end
  end

  def update
    if @retailer.update(retailer_params)
      respond_to do |format|
        format.html { redirect_to retailers_path, status: :see_other }
        format.json { render :show }
      end
    else
      respond_to do |format|
        format.html { redirect_to retailers_path, alert: @retailer.errors.full_messages.to_sentence, status: :see_other }
        format.json { render json: { errors: @retailer.errors }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @retailer.destroy!

    respond_to do |format|
      format.html { redirect_to retailers_path, notice: "#{@retailer.value} removed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private

  def set_retailer
    @retailer = Retailer.find(params.expect(:id))
  end

  def retailer_params
    params.expect(retailer: [ :value, :name, :active ])
  end
end
