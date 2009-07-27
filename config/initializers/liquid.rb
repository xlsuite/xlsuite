Liquid::Template.register_tag('render_feed', XlSuite::RenderFeed)
Liquid::Template.register_tag('render_feeds', XlSuite::RenderFeed)
Liquid::Template.register_tag('download_link', XlSuite::DownloadLink)
Liquid::Template.register_tag('image', XlSuite::Image)
Liquid::Template.register_tag('include_any', XlSuite::IncludeAny)
Liquid::Template.register_tag('listings', XlSuite::Listings)
Liquid::Template.register_tag('render_listing', XlSuite::RenderListings)
Liquid::Template.register_tag('render_listings', XlSuite::RenderListings)
Liquid::Template.register_tag('render_snippet', XlSuite::RenderSnippet)
Liquid::Template.register_tag('render_snippets', XlSuite::RenderSnippet)
Liquid::Template.register_tag('render_date', XlSuite::RenderDate)
Liquid::Template.register_tag('google_analytics', XlSuite::GoogleAnalytics)
Liquid::Template.register_tag('flash', XlSuite::Flash)
Liquid::Template.register_tag('opt_out_url', XlSuite::OptOutUrl)
Liquid::Template.register_tag('params', XlSuite::Params)
Liquid::Template.register_tag('asset_url', XlSuite::AssetUrl)
Liquid::Template.register_tag('load_affiliate', XlSuite::LoadAffiliate)
Liquid::Template.register_tag('load_account_modules', XlSuite::LoadAccountModules)
Liquid::Template.register_tag('load_assets', XlSuite::LoadAssets)
Liquid::Template.register_tag('load_folder', XlSuite::LoadFolder)
Liquid::Template.register_tag('load_folders', XlSuite::LoadFolders)
Liquid::Template.register_tag('load_groups', XlSuite::LoadGroups)
Liquid::Template.register_tag('load_group', XlSuite::LoadGroup)
Liquid::Template.register_tag('load_links', XlSuite::LoadLinks)
Liquid::Template.register_tag('load_listing', XlSuite::LoadListing)
Liquid::Template.register_tag('load_listings', XlSuite::LoadListings)
Liquid::Template.register_tag('load_rents', XlSuite::LoadRents)
Liquid::Template.register_tag('load_profiles', XlSuite::LoadProfiles)
Liquid::Template.register_tag('load_profile', XlSuite::LoadProfile)
Liquid::Template.register_tag('load_party', XlSuite::LoadParty)
Liquid::Template.register_tag('load_products', XlSuite::LoadProducts)
Liquid::Template.register_tag('load_product', XlSuite::LoadProduct)
Liquid::Template.register_tag('load_product_categories', XlSuite::LoadProductCategories)
Liquid::Template.register_tag('load_product_category', XlSuite::LoadProductCategory)
Liquid::Template.register_tag('load_order', XlSuite::LoadOrder)
Liquid::Template.register_tag('load_invoice', XlSuite::LoadInvoice)
Liquid::Template.register_tag('load_tag', XlSuite::LoadTag)
Liquid::Template.register_tag('media_player', XlSuite::MediaPlayer)
Liquid::Template.register_tag('load_blogs', XlSuite::LoadBlogs)
Liquid::Template.register_tag('load_blog', XlSuite::LoadBlog)
Liquid::Template.register_tag('load_blog_posts', XlSuite::LoadBlogPosts)
Liquid::Template.register_tag('load_comments', XlSuite::LoadComments)
Liquid::Template.register_tag('load_contact_requests', XlSuite::LoadContactRequests)
Liquid::Template.register_tag('load_blog_post', XlSuite::LoadBlogPost)
Liquid::Template.register_tag('load_snippet', XlSuite::LoadSnippet)
Liquid::Template.register_tag('load_snippets', XlSuite::LoadSnippets)
Liquid::Template.register_tag('load_testimonials', XlSuite::LoadTestimonials)
Liquid::Template.register_tag('load_tags', XlSuite::LoadTags)
Liquid::Template.register_tag('paginate', XlSuite::Paginate)
Liquid::Template.register_tag('render_sitemap_index', XlSuite::RenderSitemapIndex)

Liquid::Template.register_tag('load_xlsuite_public_images', XlSuite::LoadXlsuitePublicImages)

Liquid::Strainer.send :include, Textilize
Liquid::Strainer.send :include, Whitelist

Liquid::Context.send :include, XlSuite::Liquid::ContextHelpers
Liquid::StandardFilters.send :include, XlSuite::Liquid::StandardFiltersExtra
Liquid::Tag.send :include, XlSuite::LoggerHelper

class Money
  def to_liquid
    MoneyDrop.new(self)
  end
end

class Liquid::Drop
  attr_reader :context
end
