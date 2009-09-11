# Backwards compatibility with old ; delimited routes
ActionController::Routing::SEPARATORS.concat %w( ; ) 

ActionController::Routing::Routes.draw do |map|
  map.resources :profile_requests, :path_prefix => "/admin", 
    :collection => {:create_add => :post, :create_claim => :post, :destroy_collection => :delete, :approve_collection => :post}
    
  map.resources :public_flaggings, :path_prefix => "/admin/public", :as => "flaggings", :controller => "public/flaggings"
  
  map.resources :flaggings, :path_prefix => "/admin", 
    :collection => {:unapprove_collection => :post, :destroy_collection => :post, :approve_collection => :post}
  
  map.resources :public_domains, :path_prefix => "/admin/public", :as => "domains", :controller => "public/domains",
    :collection => {:check => :post}

  map.resources :public_suites, :path_prefix => "/admin/public", :as => "suites", :controller => "public/suites",
    :collection => {:industries => :get, :main_themes => :get, :tag_list => :get}
  
  map.resources :public_affiliates, :path_prefix => "/admin/public", :as => "affiliates", :controller => "public/affiliates"
  
  map.resources :public_products, :path_prefix => "/admin/public", :as => "products", :controller => "public/products",
    :member => {:add_to_categories => :post, :remove_from_categories => :delete}
  
  map.resources :public_profiles, :path_prefix => "/admin/public", :as => "profiles", :controller => "public/profiles",
    :member => {:attach_product_categories => :post, :detach_product_categories => :delete, :change_password => :post, :embed_code => :get},
    :collection => {:check_alias => :get, :check_custom_url => :get, :auto_complete => :get}
  
  map.resources :domain_available_items, :path_prefix => "/admin", :collection => {:destroy_collection => :delete, :add_collection => :post}
  
  map.resources :product_items, :path_prefix => "/admin", :collection => {:destroy_collection => :delete}
  
  map.resources :product_grants, :path_prefix => "/admin", :collection => {:destroy_collection => :delete}
  
  map.resources :suites, :path_prefix => "/admin",
    :collection => {:approve_collection => :put, :unapprove_collection => :put, :embed_code => :get,
        :destroy_collection => :delete, :install => :get}
    
  map.resources :account_modules, :path_prefix => "/admin"
  map.resources :affiliate_setup_lines, :path_prefix => "/admin", :collection => {:destroy_collection => :delete}
  
  map.resource :gigya, :member => {:login => :any, :signup => :any, :authenticate => :any, :authorize => :any}, 
    :controller => "gigya", :path_prefix => "/admin"
  
  map.resources :action_handlers, :path_prefix => "/admin", :collection => {:destroy_collection => :delete} do |action_handler|
    action_handler.resources :action_handler_sequences, :collection => {:destroy_collection => :delete, :update_ordering => :put}
  end
  
  map.resources :account_module_subscriptions, :path_prefix => "/admin",
    :collection => {:ipn => :post, :ipn_cancel => :post},
    :member => {:pay => :post, :cancel => :put}
  
  map.resources :installed_account_templates, :path_prefix => "/admin",
    :member => {:refresh => :post, :changed_items => :get, :no_update_items => :get}
  
  map.resources :public_account_templates, :path_prefix => "/admin/public", :as => "account_templates", :controller => "public/account_templates"
  
  map.resources :categories, :path_prefix => "/admin",
    :collection => {:destroy_collection => :delete}
  
  map.resources :sitemaps, :path_prefix => "/admin"
  
  map.resources :public_interests, :path_prefix => "/admin/public", :as => "interests", :controller => "public/interests", 
    :collection => {:destroy_collection => :delete}
  map.resources :public_groups, :path_prefix => "/admin/public", :as => "groups", :controller => "public/groups", 
    :member => {:join => :post, :leave => :post}
  map.resources :public_listings, :path_prefix => "/admin/public", :as => "listings", :controller => "public/listings",
    :member => {:embed_code => :get}
  map.resources :public_blogs, :path_prefix => "/admin/public", :as => "blogs", :controller => "public/blogs",
    :collection => {:validate_label => :post}
  map.resources :public_blog_posts, :path_prefix => "/admin/public", :as => "blog_posts", :controller => "public/blog_posts"

  map.resources :shared_email_accounts, :path_prefix => "/admin",
    :collection => {:roles_tree => :get, :remove => :delete, :parties => :get, :remove_collection => :delete}
  
  map.resources :account_templates, :path_prefix => "/admin",
    :member => {:push => :post, :images => :get, :multimedia => :get, :other_files => :get, :upload_file => :post}

  map.connect "/admin/xmlrpc/api", :controller => "xmlrpc", :action => "api"
  map.resources :public_testimonials, :path_prefix => "/admin/public", :as => "testimonials", :controller => "public/testimonials"
  
  map.resources :testimonials, :path_prefix => "/admin",
    :collection => {:destroy_collection => :delete, :approve_collection => :put, 
      :reject_collection => :put, :create_contacts => :post, :embed_code => :get}
  
  map.resources :estimates, :name_prefix => :api_, :path_prefix => "/admin/api", :controller => "api/estimates"

  map.resources :domain_subscriptions, :path_prefix => "/admin",
      :collection => {:ipn => :post},
      :member => {:pay => :post}

  map.resources :affiliate_account_trackings, :path_prefix => "/admin"

  map.resource :affiliate_account, :path_prefix => "/admin", :member => {:login => :any, :logout => :any,
    :change_password => :put, :forgot_password => :any, :referred_item_lines => :any, :activate => :put,
    :tracking_lines => :get, :referred_affiliate_accounts => :get}
  
  map.resource :product_catalog, :path_prefix => "/admin",
      :member => {:add_product => :post, :remove_product => :post, :create_category => :post, :delete_category => :post}

  map.resources :workflows, :path_prefix => "/admin", :collection => {:destroy_collection => :delete} do |workflow|
    workflow.resources :steps, :member => {:lines => :get, :update_line => :put, :create_line => :post, :destroy_line => :delete,  :async_edit => :get}, :collection => {:destroy_collection => :delete, :reposition => :post, :copy_step_index => :get, :copy_from => :get} do |step|
      step.resources :tasks, :member => {:update_action => :put}, :collection => {:destroy_collection => :delete, :reposition => :post} do |task|
        task.resources :actions, :collection => {:destroy_collection => :delete}
        task.resources :assignees, :path_prefix => "/admin", :collection => {:create_collection => :post, :destroy_collection => :delete, :mark_completed => :post, :unmark_completed => :post, :reposition => :post}
      end
    end  
  end

  map.resources :assignees, :path_prefix => "/admin", :collection => {:create_collection => :post, :destroy_collection => :delete,  :mark_completed => :post, :unmark_completed => :post, :reposition => :post}

  map.resources :api_keys, :path_prefix => "/admin",
      :collection => {:destroy_collection => :delete}

  map.resources :assignees, :path_prefix => "/admin",
      :collection => {:destroy_collection => :delete, :mark_completed => :post, :unmark_completed => :post}
  
  map.resources :triggers, :path_prefix => "/admin",
      :collection => {:destroy_collection => :delete}
  
  map.resources :links, :path_prefix => "/admin",
      :collection => {:destroy_collection => :post},
      :member => {:images => :get, :upload_image => :post }
  
  map.resources :blog_posts, :path_prefix => "/admin",
      :collection => {:destroy_collection => :post} do |blog_post|
  end
  
  map.resources :comments, :path_prefix => "/admin",
      :collection => {:destroy_collection => :post, :approve_collection => :post, :unapprove_collection => :post,
                      :mark_as_ham => :post, :mark_as_spam => :post}

  map.resource :polygons, :path_prefix => "/admin"
  
  map.resources :blogs, :path_prefix => "/admin",
      :member => {:approve_comments => :post, :read_access_groups => :get},
      :collection => {:destroy_collection => :post}
  
  map.resource :cms, :path_prefix => "/admin",
    :member => {:refresh_collection => :get, :do_refresh_collection => :post, :create_listings_website => :post,
                :create_listings_website_templates_chooser => :get, :do_create_listings_website => :post, 
                :create_website_success => :get, :save_google_map_api => :post}

  map.resources :site_imports, :path_prefix => "/admin"
  
  map.resources :payables, :path_prefix => "/admin"
  
  map.resource :ipn, :path_prefix => "/admin"
  
  map.resources :payments, :path_prefix => "/admin",
      :collection => { :tagged_collection => :post }

  map.resources :cart_lines, :path_prefix => "/admin",
      :collection => { :destroy_collection => :post }
  
  map.resource :cart, :path_prefix => "/admin", :member => {:buy => :post, :confirm => :post, :checkout => :post, :from_estimate => :post}

  map.resources :destinations, :path_prefix => "/admin", 
      :collection => { :destroy_collection => :post }

    map.resources :estimates, :path_prefix => "/admin", 
        :member => { :tax_fields => :get, :get_totals => :get },
        :collection => {:destroy_collection => :post, :auto_complete_tag => :get, 
                        :get_send_estimate_template => :get, :buy => :post, :pay => :post } do |estimate|
      estimate.resources :estimate_lines, :member => { :update => :put }, 
            :collection => {:destroy_collection => :post, :reposition_lines => :post}
    end

    map.resources :orders, :path_prefix => "/admin", 
        :member => { :tax_fields => :get, :get_totals => :get },
        :collection => {:destroy_collection => :post, :auto_complete_tag => :get, :view => :get, 
                        :get_send_order_template => :get, :buy => :post, :pay => :post } do |order|
      order.resources :order_lines, :member => { :update => :put }, 
            :collection => {:destroy_collection => :post, :reposition_lines => :post}
    end

  map.resources :product_categories, :path_prefix => "/admin",
    :member => { :async_update => :put, :async_upload_image => :post, :destroy => :delete },
    :collection => { :tree_json => :get, :async_create => :post }
  
  map.resources :providers, :path_prefix => "/admin",
      :member => { :create => :post, :update => :put },
      :collection => { :destroy_collection => :post, :async_get_formatted_all_suppliers => :get }

  map.resources :books, :path_prefix => "/admin",
      :member => { :show => :get, :update => :put, :duplicate => :post,
        :async_remove_relations_by_ids => :post, :async_add_relation => :post,
        :async_get_image_ids => :get, :async_destroy_image => :post, :async_upload_image => :post,
        :async_get_relation => :get },
      :collection => {
        :async_get_party_names_for_company_name => :get,
        :async_get_company_names => :get, :destroy_collection => :post,
        :tagged_collection => :post, :async_auto_complete => :get,
        :edit_test => :get, :async_add_party => :post,
        :async_get_options_for_field_name => :get, :async_create => :post,
        :publishings_view => :get
      }

  map.resources :suppliers, :path_prefix => "/admin",
      :member => { :async_update => :put, :async_get_attribute => :get, :async_get_group_auths_json => :get },
      :collection => { :destroy_collection => :post, :tagged_collection => :post, :async_create => :post }
  
  map.resources :sale_event_items, :path_prefix => "/admin",
      :collection => {:destroy_collection => :post, :set_attribute_collection => :post}
  
  map.resources :sale_events, :path_prefix => "/admin",
      :collection => {:destroy_collection => :post, :tagged_collection => :post, :auto_complete => :get}

  map.resources :entities, :path_prefix => "/admin",
      :member => { :new_link => :get, :new_email => :get, :new_phone => :get, :new_address => :get, 
                   :create_link => :post, :create_phone => :post, :create_email => :post, :create_address => :post},
      :collection => {:destroy_collection => :post, :tagged_collection => :post}
  
  map.resources :products, :path_prefix => "/admin",
      :member => {
        :async_get_image_ids => :get, :async_upload_image => :post, :display_info => :get,
        :discounts => :get, :sale_events => :get, :supply => :get, :async_update => :put,
        :async_get_main_image => :get, :attach_assets => :post, :detach_assets => :post,
        :embed_code => :get
      }, :collection => {:destroy_collection => :post, :tagged_collection => :post}
  
  map.resources :reports, :path_prefix => "/admin",
      :collection => {:field_auto_complete => :get}
  
  map.opt_out_unsubscribed "/admin/opt-out/unsubscribed", :controller => "opt_outs", :action => "unsubscribed"
  map.opt_out_unsubscribe "/admin/opt-out/unsubscribe", :controller => "opt_outs", :action => "unsubscribe", :method => :post
  map.opt_out "/admin/opt-out", :controller => "opt_outs", :action => "show"

  # TODO : change this later
  map.blank_landing "/admin", :controller => "dashboard", :action => "blank_landing" 
  map.landing_page "/admin/landing_page", :controller => "dashboard", :action => "landing_page"
  
  map.resources :profiles, :path_prefix => "/admin",
      :member => {:create_profile_from_party => :post, :show_feed => :get, :validate_forum_alias => :get, :validate_alias => :get, :confirm => :post},
      :collection => {:validate_feed => :get, :login => :post, :auto_complete_city => :post, :auto_complete_state => :post, :tagged_collection => :post, 
                :destroy_collection => :delete} do |profiles|

    profiles.resources :addresses, :controller => "address_contact_routes", :name_prefix => :profile_, 
        :member => {:update_new => :put},
        :collection => {:create_new => :post, :destroy_collection => :post}
    profiles.resources :phones, :controller => "phone_contact_routes", :name_prefix => :profile_,
        :member => {:update_new => :put},
        :collection => {:create_new => :post, :destroy_collection => :post}
    profiles.resources :links, :controller => "link_contact_routes", :name_prefix => :profile_,
        :member => {:update_new => :put},
        :collection => {:create_new => :post, :destroy_collection => :post}
    profiles.resources :emails, :controller => "email_contact_routes", :name_prefix => :profile_,
        :member => {:update_new => :put},
        :collection => {:create_new => :post, :destroy_collection => :post}
  end      
  
  map.resources :email_labels, :path_prefix => "/admin", 
      :collection => {:destroy_collection => :post }
  
  map.resources :filters, :path_prefix => "/admin",
      :collection => {:test_data => :get, :empty_grid => :get}
  
  map.resources :quick_entries, 
      :collection => { :auto_complete => :get, :auto_complete_save_to_field => :post, 
          :auto_complete_for_field => :post, :new => :post}
  
  map.resources :referrals, 
      :collection => { :contact => :get }
  
  map.resources :folders, :path_prefix => "/admin",
      :collection => {:destroy_collection => :post, :auto_complete_tag => :get, :filetree => :post},
      :member => {:display_new_folder_window => :get}
      
  map.ui "admin/ui/*path", :controller => "ui", :action => "connect"

  map.resources :payment_configurations, :path_prefix => "/admin"
  
  map.resources :configurations, :path_prefix => "/admin",
      :collection => {:destroy_collection => :post}
  
  map.resources :templates, :path_prefix => "/admin",
      :collection => {:destroy_collection => :post}

  map.resources :imports, :path_prefix => "/admin",
      :collection => {:destroy_all => :post, :summaries => :post, :new_scrape => :get, :scrape => :post},
      :member => {:go => :post, :save => :post, :summary => :get}
  map.resources :mappers, :path_prefix => "/admin"
  
  map.resources :layouts, :path_prefix => "/admin",
      :member => {:revisions => :get, :revision => :get}, 
      :collection => {:destroy_collection => :post, :async_get_selection => :get}
  map.resources :pages, :path_prefix => "/admin",
      :member => {:behavior => :get, :embed_code => :get, :revisions => :get, :revision => :get}, :new => {:behavior => :get},
      :collection => {:sandbox => :get, :find_pages_json => :get, :destroy_collection => :post, :convert_to_snippet => :post,
        :refresh_cached_pages => :post}
  
  map.resources :redirects, :path_prefix => "/admin", 
    :collection => {:destroy_collection => :post, :update_collection => :put, :import => :post}
    
  map.resources :snippets, :path_prefix => "/admin",
      :member => {:behavior => :get, :revisions => :get, :revision => :get}, :new => {:behavior => :get},
      :collection => {:destroy_collection => :post, :update_collection => :post}

  map.resources :payment_plans, :path_prefix => "/admin"

  map.resources :forum_categories, :path_prefix => "/admin" do |forum_category|  
    forum_category.resources :forums do |forum|
      forum.resources :topics do |topic|
        topic.resources :posts
      end
    end
  end

  map.resources :feeds, :path_prefix => "/admin",
      :member => {:refresh => :get},
      :collection => {:auto_complete_tag => :get, :refresh_all => :get, :show_feeds => :get, :refresh_my_feeds => :get}

  map.resources :assets, :path_prefix => "/admin",
      :member => {:download => :get, :display_edit => :get, :display_new_file_window => :get, :update_permissions => :get,
                  :images => :get, :upload_image => :post},
      :collection => {:auto_complete_tag => :get, :show_all_records_files => :get, :image_picker => :get, :destroy_collection => :post, 
                      :tagged_collection => :post, :image_picker_upload => :post}
  map.connect "/assets/download/:filename", :controller => "assets", :action => "download", :filename => /[-.\w]+/
  map.z_download "/z/:filename", :controller => "assets", :action => "download", :filename => /[-.\w]+/
  map.connect "/z/:folder/:filename", :controller => "assets", :action => "download", :folder => /[-\.\w\s\/\%]+/, :filename => /[-.\w]+/

  map.resources :rets, :path_prefix => "/admin",
      :collection => {:results => :get, :search => :get, :do_search => :post, :import => :get, :resources => :get, 
          :do_listings_import => :post, :do_listings_search => :post, :listings_search => :get,  
          :classes => :get, :fields => :get, :lookup => :get, :listings_import => :get, :new_search_line => :post, :destroy_collection => :post, 
          :suspend_collection => :post, :resume_collection => :post},
      :member => {:done => :get, :get_photos => :post, :refresh_photos => :get, :do_import => :post, :edit_listings_search => :get, :update_listings_search => :put}

  map.resources :posts, :name_prefix => "topic_", :path_prefix => "/admin/forum_categories/:forum_category_id/forums/:forum_id/topics/:topic_id"
  map.resources :posts, :name_prefix => "forum_", :path_prefix => "/admin/forum_categories/:forum_category_id/forums/:forum_id"
  map.resources :posts, :name_prefix => "forum_category_", :path_prefix => "/admin/forum_categories/:forum_category_id"
  map.resources :posts, :name_prefix => 'all_', :path_prefix => "/admin", :collection => { :search => :get }
  
  map.resources :parties, :path_prefix => "/admin",
      :collection => {:extjs_auto_complete => :get, :auto_complete => :get, :forgot_password => :get, :reset_password => :post, 
          :import_load => :post, :import => :get, :plaxo => :get, :address_book => :get,
          :register => :get, :signup => :post, :destroy_collection => :post, :reset_collection_password => :post,
          :tagged_collection => :post, :add_collection_to_group => :post, :async_tag_parties => :post,
          :async_get_tag_name_id_hashes => :get, :publish_profiles => :post, :create_from_email_addresses => :post
      }, :member => {:general => :get, :profile => :get, :tags => :get, :network => :get,
          :security => :get, :staff => :get, :testimonials => :get, :archive => :put,
          :confirm => :get, :authorize => :put, :refresh_inbox => :get, :effective_permissions => :get, 
          :send_new_password => :get, :update_feeds => :put, :images => :get, :pictures => :get, :upload_image => :post, 
          :multimedia => :get , :other_files => :get, :change_password => :put, :subscribe => :get} do |parties|
    parties.resources :addresses, :controller => "address_contact_routes", :name_prefix => :party_, 
        :member => {:update_new => :put},
        :collection => {:create_new => :post, :destroy_collection => :post}
    parties.resources :phones, :controller => "phone_contact_routes", :name_prefix => :party_,
        :member => {:update_new => :put},
        :collection => {:create_new => :post, :destroy_collection => :post}
    parties.resources :links, :controller => "link_contact_routes", :name_prefix => :party_,
        :member => {:update_new => :put},
        :collection => {:create_new => :post, :destroy_collection => :post}
    parties.resources :emails, :controller => "email_contact_routes", :name_prefix => :party_,
        :member => {:update_new => :put},
        :collection => {:create_new => :post, :destroy_collection => :post}
    parties.resources :email_accounts, :controller => "email_accounts", :name_prefix => :party_,
        :member => {:test => :get}
    parties.resources :notes, :name_prefix => :party_
    map.with_options(:controller => "email_contact_routes", :action => "validate", :party_id => /\d+/) do |m|
      m.validate_emails "/admin/parties/:party_id/emails;validate"
      m.validate_email "/admin/parties/:party_id/emails/:id;validate", :id => /\d+/
    end
    parties.resources :attachments, :name_prefix => :party
    parties.resources :testimonials, :name_prefix => :party_,
        :member => {:approve => :put, :reject => :put}
  end
  
  map.resources :views, :path_prefix => "/admin",
    :collection => {:reposition => :post, :remove => :post, :add => :post, :upload => :post}

  map.resources :listings, :path_prefix => "/admin",
  :collection => {
      :import => :post, :auto_complete_tag => :get, 
      :remove_duplicate_views => :get, :destroy_collection => :post,
      :old => :get, :async_destroy_collection => :post, 
      :async_mark_as_sold => :post, :add_listings_to_parties => :post, 
      :auto_complete_party_field => :get, :async_tag_collection => :post, 
      :auto_complete_remove_party_field => :get, :remove_listings_from_parties => :post
  }, :member => {:images => :get, :pictures => :get, :main_image => :get, :upload_image => :post, 
      :update_main_image => :put, :multimedia => :get , :other_files => :get} do |listings|
    #listings.resources :views, :collection => {:import => :post, :upload => :post}
    listings.resources :interests
  end

  map.resources :futures, :path_prefix => "/admin", :collection => {:show_collection => :get, :async_get_futures_as_json => :get}, :member => { :async_get_future_as_json => :get }
  
  map.thumb_picture 'pictures/:id/thumbnail.jpg', :controller => 'pictures', :action => 'thumbnail',
                                          :format => 'JPEG', :mime_type => 'image/jpeg'
  map.picture 'pictures/:id/image.jpg', :controller => 'pictures', :action => 'retrieve',
                                          :format => 'JPEG', :mime_type => 'image/jpeg'
  
  map.with_options(:action => "update") do |m|
    m.memberships "/admin/memberships", :controller => "memberships"
  end
  
  map.resources :permission_grants, :path_prefix => "/admin",
    :collection => { :destroy_collection => :delete }
  map.resources :permission_denials, :path_prefix => "/admin",
    :collection => { :destroy_collection => :delete }

  map.resources :groups, :path_prefix => "/admin",
    :member => { :effective_permissions => :get, :join => :post, :leave => :delete },
    :collection => {
      :async_get_name_id_hashes => :get,
      :async_add_parties_or_create => :post,
      :destroy_collection => :delete,
      :reorder => :post
    }
    
  map.resources :roles, :path_prefix => "/admin", 
    :collection => {:destroy_collection => :delete},
    :member => {:effective_permissions => :get}
  map.resources :addresses, :controller => "address_contact_routes", :path_prefix => "/admin"
  map.resources :phones, :controller => "phone_contact_routes", :path_prefix => "/admin"
  
  map.resources :mass_emails, :path_prefix => "/admin",
    :collection => {:save => :post},
    :member => {:preview => :get, :release => :put, :unrelease => :get, :show_recipient => :get}

  map.resources :emails, :path_prefix => "/admin",
    :collection => {
      :show_unread_emails => :get, :show_sent_and_read_emails => :get, 
      :show_all_emails => :get, :async_destroy_collection => :post,
      :sandbox_new => :get, :async_get_account_addresses => :get,
      :async_get_mailbox_emails => :get, :async_get_email => :get,
      :sandbox => :get, :async_send => :post, :async_get_template_label_id_hashes => :get,
      :async_get_tags => :get, :async_get_searches => :get, :async_get_page_urls => :get, 
      :save => :post, :update_west_console => :get, :conversations_with => :get
    }, :member => {
      :reply => :get, :reply_all => :get, :forward => :get, :release => :put, :async_mass_recipients_count => :get
    } do |email|
    email.resources :attachments
    email.resources :recipients, 
      :collection => { :destroy_collection => :delete, :rebuild => :post}
  end
  
  map.connect "/admin/a/:attachment_uuid/:recipient_uuid", :controller => "attachments", :action => "show", :attachment_uuid => /[-A-Fa-f0-9]{36}/, :recipient_uuid => /[-A-Fa-f0-9]{36}/

  map.with_options(:controller => "email_contact_routes", :action => "validate") do |m|
    m.validate_emails "/admin/emails;validate"
    m.validate_email "/admin/emails/:id;validate", :id => /\d+/
  end
  
  map.resources :testimonials, :path_prefix => "/admin", :member => {:approve => :put, :reject => :put}
  map.resources :contact_requests, :path_prefix => "/admin", :member => {:complete => :put},
    :collection => {:bugs => :post, :bug_buster => :get, :destroy_collection => :post, :tagged_collection => :post,
                    :mark_as_ham => :post, :mark_as_spam => :post}

  map.resources :accounts, :path_prefix => "/admin",
      :collection => {:confirm => :get, :activate => :post, :destroy_collection => :post,
                      :resend_confirmation => :post} do |accounts|
    accounts.resources :domains
  end

  map.resources :domains, :path_prefix => "/admin", :collection => {:validate_name => [:post, :get]},
    :member => {:bypass => :put}

  # Authentication
  map.logout "sessions/destroy", :controller => "sessions", :action => "destroy"
  map.resources :sessions, :new => {:google => :get}
  map.register "/register", :controller => "parties", :action => "register"

  map.public_contents 'contents/:year/:month/:day', :controller => 'articles',
      :year => nil, :month => nil, :day => nil,
      :requirements => {:year => /\d{4}/, :month => /\d{1,2}/, :day => /\d{1,2}/}
  map.public_read_content 'archives/:title', :controller => 'articles', :action => 'permalink', :title => /.+/

  map.picture_zoom 'pictures/zoom/:id/image.jpg', :controller => 'pictures', :action => 'view'
  map.thumb_picture 'pictures/:id/thumbnail.jpg', :controller => 'pictures', :action => 'thumbnail',
                                        :format => 'JPEG', :mime_type => 'image/jpeg'
  map.picture 'pictures/:id/image.jpg', :controller => 'pictures', :action => 'retrieve',
                                        :format => 'JPEG', :mime_type => 'image/jpeg'
  map.connect 'pictures/:id/image.gif', :controller => 'pictures', :action => 'retrieve',
                                            :format => 'GIF', :mime_type => 'image/gif'
  map.connect 'pictures/:id/image.png', :controller => 'pictures', :action => 'retrieve',
                                            :format => 'PNG', :mime_type => 'image/png'
  map.picture_view 'admin/pictures/:id', :controller => 'pictures', :action => 'view'

  map.thanks 'payment/thanks/:id', :controller => 'payment', :action => 'thanks'

  map.connect 'policies', :controller => 'policies', :action => 'privacy'

  map.attachment_download 'document/:attachment/:url_hash', :controller => 'attachments', :action => 'download', :requirements => {:url_hash => /[a-z0-9]{40}/, :attachment => /\d+/}

  map.properties_feed 'feeds/properties/:area/atom.rss', :controller => 'feeds', :action => 'properties', :area => /[-\s\w+]+/i
  map.interest_feed 'feeds/interest/:id/atom.rss', :controller => 'feeds', :action => 'interests'
  map.news_feed 'feeds/news/atom.rss', :controller => 'feeds', :action => 'news'
  map.picks_feed 'feeds/picks/:tag/atom.rss', :controller => 'feeds', :action => 'properties_by_tag', :tag => /[-\w]+/i

  map.page_under_construction 'admin/page-under-construction', :controller => 'system'

  map.with_options(:controller => "search") do |m|
    m.remove_saved_search 'admin/search/:action/:id'
    m.perform_advanced_search "/admin/search/perform_advanced_search", :action => "perform_advanced_search"
    m.connect 'admin/search/:action'
    m.async_get_name_id_hashes '/admin/search/async_get_name_id_hashes', :action => 'async_get_name_id_hashes'
  end
  
  # "Alias" routes
  map.redirect "/login", :new_session
  map.redirect "/forums", :forum_categories

  # Backwards compatibility with old ; delimited routes
  map.connect ":controller;:action"
  map.connect ":controller/:id;:action" 
  map.connect "admin/:controller;:action"
  map.connect "admin/:controller/:id;:action" 
  
  map.connect "robots.txt", :controller => "pages", :action => "robots"

  map.with_options(:controller => "pages") do |m|
    m.home "/", :action => "show"
    m.connect '*path', :action => 'show'
  end

  # These routes will be hidden, since the *path route above is a catch-all
  # This is temporary, until all code has been move where it really belongs
  map.connect "/home", :controller => "welcome", :action => "index"
  map.connect "/:controller/:action/:id"
end
