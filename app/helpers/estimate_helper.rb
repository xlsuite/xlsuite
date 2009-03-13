#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module EstimateHelper
  # Creates a bunch of instance variables that the shared/estimate/details partial
  # expect exist.
  def setup_drop_choices
    @light_choices            = Configuration.get(:lights_product_category)
    @tree_light_choices       = Configuration.get(:tree_lights_product_category)
    @animate_choices          = Configuration.get(:animate_product_category)
    @inflatables_choices      = Configuration.get(:inflatables_product_category)
    @light_sculptures_choices = Configuration.get(:ropelight_sculptures_product_category)
    @garlands_choices         = Configuration.get(:garlands_product_category)
    @wreaths_choices          = Configuration.get(:wreaths_product_category)

    @roof_slope_choices = Estimate::RoofSlopeChoices
    @roof_material_choices = Estimate::RoofMaterialChoices
    @color_choices = Estimate::ColorChoices
    @style_choices = Configuration.get(:styles_master_category).children
    @tree_size_choices = Estimate::TreeSizeChoices
    @residential_building_style_choices = Estimate::ResidentialBuildingStyleChoices
    @commercial_building_style_choices = Estimate::CommercialBuildingStyleChoices
    @measurement_option_choices = Estimate::MeasurementOptionChoices
    @lot_style_choices = Estimate::LotStyleChoices
    @bush_size_choices = Estimate::BushSizeChoices
  end
end
