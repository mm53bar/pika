class MealsController < ApplicationController
  before_action :set_meal, only: %i[ show edit update destroy ]

  def index
    @meals = Meal.ordered
  end

  def show
  end

  def new
    @meal = Meal.new
  end

  def edit
  end

  def create
    @meal = Meal.new(meal_params)

    if @meal.save
      respond_to do |format|
        format.html { redirect_to @meal, notice: "#{@meal.name} added." }
        format.json { render :show, status: :created, location: @meal }
      end
    else
      render_invalid(:new)
    end
  end

  def update
    if @meal.update(meal_params)
      respond_to do |format|
        format.html { redirect_to @meal, notice: "#{@meal.name} updated.", status: :see_other }
        format.json { render :show }
      end
    else
      render_invalid(:edit)
    end
  end

  def destroy
    @meal.destroy!

    respond_to do |format|
      format.html { redirect_to meals_path, notice: "#{@meal.name} removed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private

  def set_meal
    @meal = Meal.find(params.expect(:id))
  end

  def render_invalid(template)
    respond_to do |format|
      format.html { render template, status: :unprocessable_entity }
      format.json { render json: { errors: @meal.errors }, status: :unprocessable_entity }
    end
  end

  def meal_params
    params.expect(meal: [ :name, :brand, :meal_type, :calories, :weight_grams, :rating, :would_buy_again, :notes ])
  end
end
