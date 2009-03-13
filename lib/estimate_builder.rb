#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

require 'yaml'

class EstimateBuilder
  SectionsWithMountingHardware = [:roof_lines, :roof_top, :eaves,
                                  :windows, :garage_doors, :paths].freeze
  @@logger = RAILS_DEFAULT_LOGGER
  def self.logger() @@logger; end
  def logger() @@logger; end

  def self.build(estimate)
    EstimateBuilder.new(estimate).build
  end

  def initialize(estimate)
    @estimate = estimate

    @num_cords = 0
    @add_final_extension_cord = false
    @fudge_factor = Configuration.get(:overall_fudge_factor)
    raise "No fudge factor defined" unless @fudge_factor
    @base_price = Configuration.get(:base_install_cost_per_foot)
  end

  def build
    @estimate.class.transaction do
      @estimate.destroy_lines

      %w( roof_lines roof_top eaves paths fences_and_gates
          windows garage_doors wreaths garlands inflatables
          ropelight_sculptures trees bushes animate).each do |section|
        build_section(section.to_sym)
      end

      add_final_extension_cord
    end
  end

private
  def add_final_extension_cord()
    return unless @add_final_extension_cord

    @estimate.add_comment('Extension Cords (Power Cords)')
    @estimate.add_product(@estimate.long_cord_product_id, 1)   if @num_cords > 0
  end

  def build_section_ropelight_sculptures
    return if @estimate.ropelight_sculptures_product_id.blank?
    @add_final_extension_cord = true

    @estimate.add_product(  @estimate.ropelight_sculptures_product_id,
                            @estimate.ropelight_sculptures_qty)
    @estimate.add_product(  @estimate.med_cord_product_id,
                            @estimate.ropelight_sculptures_qty)
  end

  def build_section_inflatables
    return if @estimate.inflatables_product_id.blank?
    @add_final_extension_cord = true

    @estimate.add_product(  @estimate.inflatables_product_id,
                            @estimate.inflatables_qty)
    @estimate.add_product(  @estimate.med_cord_product_id,
                            @estimate.inflatables_qty)
  end

  def build_section_wreaths
    return if @estimate.wreaths_product_id.blank?
    @estimate.add_product(  @estimate.wreaths_product_id,
                            @estimate.wreaths_qty)
  end

  def build_section_paths
    return if @estimate.paths_product_id.blank?
    @estimate.add_product(  @estimate.paths_product_id,
                            calc_section_quantity(:paths))
    @estimate.add_product(  Configuration.get(:mounting_hardware_paths),
                            calc_section_quantity(:paths))
    add_section_extension_cords(:paths)
  end

  def build_section_animate
    return if @estimate.animate_product_id.blank?
    @add_final_extension_cord = true

    @estimate.add_product(@estimate.animate_product_id, 1)
    @estimate.add_product(@estimate.med_cord_product_id, 1)

    return if @estimate.no_labor?
  end

  def build_section(section)
    return unless install?(section)
    return if @estimate.send("#{section}_product_id").blank?

    add_section_header(section)

    unless @estimate.no_supplies? then
      case section
      when :wreaths, :animate, :ropelight_sculptures, :inflatables, :paths
        self.send("build_section_#{section}")
      else
        add_section_supplies(section)
      end
    end

    add_labour(section) unless @estimate.no_labor?
  end

  def add_section_supplies(section)
    add_section_product(section)
    add_section_mounting_hardware(section) if SectionsWithMountingHardware.include?(section)
    add_section_extension_cords(section)
  end

  def add_section_product(section)
    @estimate.add_product(find_section_product(section),
                          calc_section_quantity(section))
  end

  def calc_section_quantity(section)
    base_qty = calc_section_fudged_quantity(section)
    product = find_section_product(section)
    return base_qty unless product.base_length
    (base_qty.to_f / product.base_length).ceil
  end

  def add_section_mounting_hardware(section)
    product = find_section_product(section)
    type =  case
            when ropelight?(product): :mounting_hardware_ropelight
            when cliplight?(product): :mounting_hardware_cliplight
            else                      :mounting_hardware_regular
            end
    prod = Configuration.get(type)
    return unless prod
    quantity = (calc_section_quantity(section) * (product.base_length.nil? ? 1 : product.base_length)).to_f
    quantity /= (prod.base_length.nil? ? 1 : prod.base_length)
    @estimate.add_product(prod, quantity.ceil)
  end

  def find_section_product(section)
    Product.find(@estimate.send("#{section}_product_id"))
  end

  def calc_section_fudged_quantity(section)
    if @estimate.respond_to?("#{section}_length") then
      @estimate.send("#{section}_length") * @fudge_factor
    elsif @estimate.respond_to?("#{section}_qty") then
      @estimate.send("#{section}_qty")
    else
      raise "Don't know how to return the quantity for section '#{section}' - is there a #{section}_length or #{section}_qty method ?"
    end
  end

  def add_section_header(section)
    comment = section.to_s.humanize.split(/\s+/).map {|w|
                w.downcase == 'and' ? w.downcase : w.capitalize
              }.join(' ')
    if @estimate.respond_to?("#{section}_qty") then
      qty = @estimate.send("#{section}_qty")
      comment = "#{qty} #{qty < 2 ? comment.singularize : comment}"
    elsif @estimate.respond_to?("#{section}_length") then
      length = @estimate.send("#{section}_length")
      comment = "#{comment} (#{length} #{MeasurementUnit.to_name(@estimate.measurement_option.to_sym, :short_name, :maxi)})"
    end

    @estimate.add_comment(comment)
  end

  def add_section_extension_cords(section)
    @add_final_extension_cord = true

    num_long    = num_short = 0
    num_medium  = 1

    case section.to_sym
    when :trees
      num_long    += 1

    when :bushes
      num_long    += 1
      num_medium  += @estimate.bushes_qty - 1

    when :fences_and_gates, :paths
      num_long    += 1

    when :windows
      num_short   += @estimate.windows_qty

    when :garage_doors
      num_short   += @estimate.garage_doors_qty
    end

    @estimate.add_product(@estimate.long_cord_product_id, num_long)   if num_long > 0
    @estimate.add_product(@estimate.med_cord_product_id, num_medium)  if num_medium > 0
    @estimate.add_product(@estimate.short_cord_product_id, num_short) if num_short > 0

    @num_cords += num_long
    @num_cords += num_medium
    @num_cords += num_short
  end

  def calc_labour_for_roof(section)
    product = find_section_product(section)
    base_qty = calc_section_fudged_quantity(section)

    total_roof_factor = (@estimate.flat_pct + @estimate.moderate_pct + @estimate.steep_pct).to_f
    flat_pct      = @estimate.flat_pct / total_roof_factor
    moderate_pct  = @estimate.moderate_pct / total_roof_factor
    steep_pct     = @estimate.steep_pct / total_roof_factor

    height_factor = case @estimate.number_of_floors
                    when 0, 1
                      Configuration.get(:roof_factor_low)
                    when 2
                      Configuration.get(:roof_factor_medium)
                    else
                      Configuration.get(:roof_factor_high)
                    end
    height_factor += Configuration.get("roof_factor_walk_#{@estimate.roof_walking_allowed? ? 'yes' : 'no'}")

    if flat_pct > 0.0 then
      factor = Configuration.get(:roof_factor_flat)
      factor += height_factor
      factor += Configuration.get(:roof_factor_ropelight) if ropelight?(product)
      unit_price = (@base_price * factor).to_money
      @estimate.add_manhours('Installation (flat section)', (base_qty * flat_pct).ceil, unit_price)
    end

    if moderate_pct > 0.0 then
      factor = Configuration.get(:roof_factor_moderate)
      factor += height_factor
      factor += Configuration.get(:roof_factor_ropelight) if ropelight?(product)
      unit_price = (@base_price * factor).to_money
      @estimate.add_manhours('Installation (moderate section)', (base_qty * moderate_pct).ceil, unit_price)
    end

    if steep_pct > 0.0 then
      factor = Configuration.get(:roof_factor_steep)
      factor += height_factor
      factor += Configuration.get(:roof_factor_ropelight) if ropelight?(product)
      unit_price = (@base_price * factor).to_money
      @estimate.add_manhours('Installation (steep section)', (base_qty * steep_pct).ceil, unit_price)
    end
  end

  def add_labour(section)
    case section
    when :roof_lines, :roof_top, :eaves
      calc_labour_for_roof(section)
    when :animate
      @estimate.add_manhours('Programming (hourly cost)', 0,
          Configuration.get(:base_install_cost_animate).to_money)
    else
      @estimate.add_manhours('Installation (per ft)',
          calc_section_fudged_quantity(section),
          Configuration.get("base_install_cost_#{section}").to_money)
    end
  end

  def ropelight?(product)
    product.name_matches?(/ropelight/i)
  end

  def cliplight?(product)
    product.name_matches?(/clip\s*light/i)
  end

  def install?(section)
    return false unless @estimate.send("#{section}?")

    if @estimate.respond_to?("#{section}_length")
      length = @estimate.send("#{section}_length")
      length ? length > 0 : false
    elsif @estimate.respond_to?("#{section}_qty")
      qty = @estimate.send("#{section}_qty")
      qty ? qty > 0 : false
    else
      true
    end
  end
end
