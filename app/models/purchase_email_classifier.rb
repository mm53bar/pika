# A cheap first pass over the shared inbox: could this message be a gear order,
# receipt or shipping notice? It only decides what is worth an LLM call. The
# LLM's answer (GearTriager) is what decides whether Pika claims the message, so
# a travel receipt that trips these signals is still left for another app.
#
# Every check runs over the header AND the body, because orders are usually
# forwarded and the store's details are in the body.
class PurchaseEmailClassifier
  Result = Data.define(:purchase?, :score, :signals)

  STRONG = [
    "order confirmation", "order confirmed", "your order", "order number", "order #",
    "order no", "thank you for your order", "thanks for your order", "has shipped",
    "have shipped", "shipping confirmation", "shipment", "your receipt", "order summary",
    "purchase confirmation", "order details"
  ].freeze

  WEAK = %w[ order shipped subtotal qty quantity sku item items tracking ].freeze

  THRESHOLD = 3

  def initialize(from:, subject:, body:, retailers: Retailer.match_values)
    @subject = subject.to_s.downcase
    @body = body.to_s.downcase
    @haystack = "#{from.to_s.downcase}\n#{@subject}\n#{@body}"
    @retailers = retailers
  end

  def result
    signals = []
    score = 0

    if (hit = @retailers.find { |r| r.present? && @haystack.include?(r) })
      signals << "retailer:#{hit}"
      score += 3
    end

    STRONG.each do |phrase|
      if @subject.include?(phrase)
        signals << "subject:#{phrase}"
        score += 2
      elsif @body.include?(phrase)
        signals << "body:#{phrase}"
        score += 2
      end
    end

    WEAK.each do |word|
      if @haystack.match?(/\b#{Regexp.escape(word)}\b/)
        signals << "word:#{word}"
        score += 1
      end
    end

    Result.new(purchase?: score >= THRESHOLD, score: score, signals: signals.uniq)
  end
end
