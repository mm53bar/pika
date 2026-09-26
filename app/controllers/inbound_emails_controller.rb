class InboundEmailsController < ApplicationController
  before_action :set_inbound_email, only: %i[ show add_items ignore retriage ]

  # The page shows what's waiting for review plus recent history. JSON takes
  # ?status= and otherwise returns everything captured.
  def index
    if request.format.html?
      @waiting = InboundEmail.awaiting_review.ordered
      @recent = InboundEmail.where.not(id: @waiting.select(:id)).ordered.limit(20)
    else
      @inbound_emails = InboundEmail.ordered
      @inbound_emails = @inbound_emails.where(status: params[:status]) if params.key?(:status)
    end
  end

  def show
  end

  # HTML posts the reviewed lines, with any edits and a per-line include flag.
  # JSON may post `items` the same way, or nothing to take the proposal as-is.
  def add_items
    return refuse("Already handled.") unless @inbound_email.status == "received"

    lines = submitted_lines || @inbound_email.proposal
    return refuse("Nothing selected to add.") if lines.empty?

    created = @inbound_email.add_items!(lines)
    respond_to do |format|
      format.html { redirect_to inbound_emails_path, notice: "Added #{created.size} #{"item".pluralize(created.size)} to your gear.", status: :see_other }
      format.json { render :show, status: :created }
    end
  rescue ActiveRecord::RecordInvalid => e
    refuse(e.record.errors.full_messages.to_sentence)
  end

  def ignore
    @inbound_email.ignore!
    respond_to do |format|
      format.html { redirect_to inbound_emails_path, notice: "Ignored.", status: :see_other }
      format.json { render :show }
    end
  end

  def retriage
    @inbound_email.retry_triage!
    triager = GearTriager.new(@inbound_email)
    result = triager.available? ? triager.triage : nil
    result ? @inbound_email.apply_triage!(result) : @inbound_email.record_triage_attempt!

    respond_to do |format|
      format.html { redirect_to @inbound_email, notice: result ? "Read again." : "The LLM couldn't read it.", status: :see_other }
      format.json { render :show }
    end
  rescue LlmClient::Unavailable
    @inbound_email.record_triage_attempt!
    refuse("The LLM is unreachable right now.")
  end

  private

  def set_inbound_email
    @inbound_email = InboundEmail.find(params.expect(:id))
  end

  def submitted_lines
    return unless params.key?(:items)

    # JSON sends an array; the form sends a hash keyed by line index.
    lines = params.expect(items: [ [ :include, :name, :manufacturer, :category, :weight_grams, :quantity, :worn, :consumable, :notes ] ])
    lines = lines.to_h.sort_by { |index, _| index.to_i }.map(&:last) unless lines.is_a?(Array)
    lines.map(&:to_h)
          .reject { |line| line.key?("include") && !ActiveModel::Type::Boolean.new.cast(line["include"]) }
          .map { |line| line.except("include") }
  end

  def refuse(message)
    respond_to do |format|
      format.html { redirect_to @inbound_email, alert: message, status: :see_other }
      format.json { render json: { errors: { base: [ message ] } }, status: :unprocessable_entity }
    end
  end
end
