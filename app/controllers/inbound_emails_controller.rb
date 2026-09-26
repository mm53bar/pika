class InboundEmailsController < ApplicationController
  before_action :set_inbound_email, only: %i[ show add_items ignore retriage ]

  # The page shows what's waiting for review plus recent history. JSON takes
  # ?status= and otherwise returns everything captured.
  def index
    if request.format.json?
      @inbound_emails = InboundEmail.ordered
      @inbound_emails = @inbound_emails.where(status: params[:status]) if params.key?(:status)
    else
      @waiting = InboundEmail.awaiting_review.ordered
      @recent = InboundEmail.where.not(id: @waiting.select(:id)).ordered.limit(20)
    end
  end

  def show
  end

  # Posts the reviewed lines: each with an `action` (add, link, skip), `item_id`
  # for a link, and any edits. JSON may post nothing to take the default review.
  def add_items
    return refuse("Already handled.") unless @inbound_email.status == "received"

    touched = @inbound_email.review!(submitted_lines || @inbound_email.default_review)
    respond_to do |format|
      format.html { redirect_to inbound_emails_path, notice: "Updated #{touched.size} #{"item".pluralize(touched.size)} in your gear.", status: :see_other }
      format.json { render :show, status: :created }
    end
  rescue ArgumentError => e
    refuse(e.message)
  rescue ActiveRecord::RecordInvalid => e
    refuse(e.record.errors.full_messages.to_sentence)
  rescue ActiveRecord::RecordNotFound
    refuse("That item no longer exists.")
  end

  def ignore
    @inbound_email.ignore!
    respond_to do |format|
      format.html { redirect_to inbound_emails_path, notice: "Ignored.", status: :see_other }
      format.json { render :show }
    end
  end

  def retriage
    return refuse("Already handled.") unless @inbound_email.retriageable?

    @inbound_email.retry_triage!
    triager = GearTriager.new(@inbound_email)
    result = triager.available? ? triager.triage : nil
    result ? @inbound_email.apply_triage!(result) : @inbound_email.record_triage_attempt!

    respond_to do |format|
      format.html { redirect_to @inbound_email, notice: result ? "Read again." : "The LLM couldn't read it.", status: :see_other }
      format.json { render :show }
    end
  rescue LlmClient::Unavailable
    refuse("The LLM is unreachable or busy right now. Try again shortly.")
  end

  private

  def set_inbound_email
    @inbound_email = InboundEmail.find(params.expect(:id))
  end

  def submitted_lines
    return unless params.key?(:items)

    # JSON sends an array; the form sends a hash keyed by line index.
    lines = params.expect(items: [ [ :action, :item_id, :name, :manufacturer, :category, :weight_grams, :quantity, :worn, :consumable, :notes ] ])
    lines = lines.to_h.sort_by { |index, _| index.to_i }.map(&:last) unless lines.is_a?(Array)
    lines.map(&:to_h).map { |line| line.merge("action" => InboundEmail::ACTIONS.include?(line["action"]) ? line["action"] : "add") }
  end

  def refuse(message)
    respond_to do |format|
      format.html { redirect_to @inbound_email, alert: message, status: :see_other }
      format.json { render json: { errors: { base: [ message ] } }, status: :unprocessable_entity }
    end
  end
end
