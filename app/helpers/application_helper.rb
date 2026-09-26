module ApplicationHelper
  def nav_link_to(text, path)
    classes =
      if current_page?(path)
        "font-medium text-teal-800 underline underline-offset-4"
      else
        "text-stone-600 hover:text-teal-800"
      end

    link_to text, path, class: classes
  end

  # Grams below a kilo, kilos above — how gear lists are read.
  def weight(grams)
    return "—" if grams.nil?

    grams < 1000 ? "#{number_with_precision(grams, precision: 1, strip_insignificant_zeros: true)} g" : "#{number_with_precision(grams / 1000.0, precision: 2)} kg"
  end

  def badge(text, style = :neutral)
    styles = {
      neutral: "border-stone-300 bg-white text-stone-600",
      worn: "border-sky-300 bg-sky-50 text-sky-900",
      consumable: "border-amber-300 bg-amber-50 text-amber-900",
      measured: "border-teal-300 bg-teal-50 text-teal-900",
      override: "border-violet-300 bg-violet-50 text-violet-900"
    }
    tag.span text, class: "inline-block rounded-full border px-2 py-0.5 text-xs font-medium #{styles.fetch(style)}"
  end

  def item_badges(item, worn: item.worn?)
    safe_join([
      (badge("worn", :worn) if worn),
      (badge("consumable", :consumable) if item.consumable?),
      (badge("weighed", :measured) if item.measured?),
      (badge("#{weight(item.unit_weight_grams)}/#{item.unit_label.presence || "unit"}") if item.per_unit?),
      (badge(item.status) unless item.status == "owned"),
      (badge("retired") if item.retired?)
    ].compact, " ")
  end

  def button_classes(style = :primary)
    base = "inline-block rounded-md px-3 py-1.5 text-sm font-medium cursor-pointer"

    case style
    when :primary then "#{base} bg-teal-700 text-white hover:bg-teal-800"
    when :secondary then "#{base} border border-stone-300 bg-white text-stone-700 hover:bg-stone-50"
    when :danger then "#{base} border border-red-300 bg-white text-red-700 hover:bg-red-50"
    end
  end

  def field_classes = "mt-1 w-full rounded-md border border-stone-300 px-3 py-2"

  def label_classes = "block text-sm font-medium text-stone-700"
end
