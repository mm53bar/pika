class ReferenceListsController < ApplicationController
  before_action :set_reference_list, only: %i[ show edit update destroy ]

  def index
    @reference_lists = ReferenceList.ordered
  end

  def show
  end

  def new
    @reference_list = ReferenceList.new
  end

  def edit
  end

  def create
    @reference_list = ReferenceList.new(reference_list_params)

    if @reference_list.save
      respond_to do |format|
        format.html { redirect_to @reference_list, notice: "#{@reference_list.name} added." }
        format.json { render :show, status: :created, location: @reference_list }
      end
    else
      render_invalid(:new)
    end
  end

  def update
    if @reference_list.update(reference_list_params)
      respond_to do |format|
        format.html { redirect_to @reference_list, notice: "#{@reference_list.name} updated.", status: :see_other }
        format.json { render :show }
      end
    else
      render_invalid(:edit)
    end
  end

  def destroy
    @reference_list.destroy!

    respond_to do |format|
      format.html { redirect_to reference_lists_path, notice: "#{@reference_list.name} removed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private

  def set_reference_list
    @reference_list = ReferenceList.find(params.expect(:id))
  end

  def render_invalid(template)
    respond_to do |format|
      format.html { render template, status: :unprocessable_entity }
      format.json { render json: { errors: @reference_list.errors }, status: :unprocessable_entity }
    end
  end

  def reference_list_params
    params.expect(reference_list: [ :name, :author, :source_url, :notes ])
  end
end
