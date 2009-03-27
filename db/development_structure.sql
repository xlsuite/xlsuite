CREATE TABLE `account_authorizations` (
  `id` int(11) NOT NULL auto_increment,
  `account_id` int(11) default NULL,
  `expires_at` datetime default NULL,
  `payment_id` int(11) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `account_module_subscriptions` (
  `id` int(11) NOT NULL auto_increment,
  `account_id` int(11) default NULL,
  `payment_id` int(11) default NULL,
  `minimum_subscription_fee_cents` int(11) default NULL,
  `minimum_subscription_fee_currency` varchar(255) default NULL,
  `options` text,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  `uuid` varchar(36) default NULL,
  `number` varchar(255) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `account_modules` (
  `id` int(11) NOT NULL auto_increment,
  `account_id` int(11) default NULL,
  `module` varchar(255) default NULL,
  `minimum_subscription_fee_cents` int(11) default NULL,
  `minimum_subscription_fee_currency` varchar(255) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `account_templates` (
  `id` int(11) NOT NULL auto_increment,
  `account_id` int(11) default '1',
  `trunk_account_id` int(11) default NULL,
  `stable_account_id` int(11) default NULL,
  `name` varchar(255) default NULL,
  `demo_url` varchar(255) default NULL,
  `setup_fee_cents` int(11) default NULL,
  `setup_fee_currency` varchar(255) default NULL,
  `subscription_markup_fee_cents` int(11) default NULL,
  `subscription_markup_fee_currency` varchar(255) default NULL,
  `period_length` int(11) default NULL,
  `period_unit` varchar(255) default NULL,
  `approved_at` datetime default NULL,
  `approved_by_id` int(11) default NULL,
  `previous_stables` text,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  `description` text,
  `f_blogs` tinyint(1) default '0',
  `f_directories` tinyint(1) default '0',
  `f_forums` tinyint(1) default '0',
  `f_product_catalog` tinyint(1) default '0',
  `f_profiles` tinyint(1) default '0',
  `f_real_estate_listings` tinyint(1) default '0',
  `f_rss_feeds` tinyint(1) default '0',
  `f_testimonials` tinyint(1) default '0',
  `f_cms` tinyint(1) default '0',
  `f_workflows` tinyint(1) default '0',
  `unapproved_at` datetime default NULL,
  `unapproved_by_id` int(11) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `accounts` (
  `id` int(11) NOT NULL auto_increment,
  `party_id` int(11) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  `expires_at` datetime default NULL,
  `options` text,
  `master` tinyint(1) NOT NULL default '0',
  `title` varchar(255) default NULL,
  `last_paid_at` datetime default NULL,
  `payment_plan_id` int(8) default NULL,
  `confirmation_token_expires_at` datetime default NULL,
  `confirmation_token` varchar(255) default NULL,
  `order_id` int(11) default NULL,
  `signup_account_id` int(11) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `affiliates` (
  `id` int(11) NOT NULL auto_increment,
  `target_url` varchar(1024) default NULL,
  `source_url` varchar(1024) default NULL,
  `party_id` int(11) default NULL,
  `account_id` int(11) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `api_keys` (
  `id` int(11) NOT NULL auto_increment,
  `account_id` int(11) default NULL,
  `party_id` int(11) default NULL,
  `key` varchar(255) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `asset_authorizations` (
  `id` int(11) NOT NULL auto_increment,
  `attachment_id` int(11) NOT NULL,
  `email` varchar(255) default NULL,
  `name` varchar(255) default NULL,
  `expires_at` datetime default NULL,
  `private_key` varchar(255) default NULL,
  `url_hash` varchar(255) NOT NULL default '',
  `cookie_hash` varchar(255) default NULL,
  `cookie_instantiation_count` int(11) NOT NULL default '0',
  `download_count` int(11) NOT NULL default '0',
  `unauthorized_access_attempts_count` int(11) NOT NULL default '0',
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `account_id` int(11) default NULL,
  `type` varchar(255) default NULL,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `by_cookie_hash` (`cookie_hash`),
  UNIQUE KEY `by_url_hash_and_email` (`url_hash`,`email`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `assets` (
  `id` int(11) NOT NULL auto_increment,
  `account_id` int(11) default NULL,
  `owner_id` int(11) default NULL,
  `parent_id` int(11) default NULL,
  `content_type` varchar(64) default NULL,
  `filename` varchar(255) default NULL,
  `thumbnail` varchar(255) default NULL,
  `size` int(11) default NULL,
  `width` int(11) default NULL,
  `height` int(11) default NULL,
  `title` varchar(255) default NULL,
  `description` text,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  `email_id` int(11) default NULL,
  `archive_id` int(11) default NULL,
  `folder_id` int(11) default NULL,
  `cache_timeout_in_seconds` int(11) default NULL,
  `cache_control_directive` varchar(255) default NULL,
  `etag` varchar(48) default NULL,
  `uuid` varchar(36) default NULL,
  `private` tinyint(1) default '0',
  PRIMARY KEY  (`id`),
  KEY `index_assets_on_account_id_and_filename` (`account_id`,`filename`),
  KEY `index_assets_on_account_id_and_title` (`account_id`,`title`),
  KEY `index_assets_on_parent_id_and_thumbnail` (`parent_id`,`thumbnail`),
  KEY `by_archive_filename` (`archive_id`,`filename`),
  KEY `by_folder_filename` (`folder_id`,`filename`),
  KEY `by_owner_parent` (`owner_id`,`parent_id`),
  KEY `by_account_id_uuid` (`account_id`,`uuid`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `assignees` (
  `id` int(11) NOT NULL auto_increment,
  `account_id` int(11) default NULL,
  `task_id` int(11) default NULL,
  `party_id` int(11) default NULL,
  `completed_at` datetime default NULL,
  `position` int(11) default '0',
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `attachments` (
  `id` int(11) NOT NULL auto_increment,
  `asset_id` int(11) default NULL,
  `email_id` int(11) default NULL,
  `uuid` varchar(255) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `authorizations` (
  `id` int(11) NOT NULL auto_increment,
  `type` varchar(255) default NULL,
  `object_type` varchar(255) default NULL,
  `object_id` int(11) default NULL,
  `group_id` int(11) default NULL,
  PRIMARY KEY  (`id`),
  KEY `by_type_and_object_and_group` (`type`,`object_type`,`object_id`,`group_id`),
  KEY `by_type_and_group` (`type`,`group_id`),
  KEY `by_object_and_group` (`object_type`,`object_id`,`group_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `blog_posts` (
  `id` int(11) NOT NULL auto_increment,
  `title` varchar(255) default NULL,
  `excerpt` text,
  `body` text,
  `published_at` datetime default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  `account_id` int(11) default NULL,
  `blog_id` int(11) default NULL,
  `author_id` int(11) default NULL,
  `editor_id` int(11) default NULL,
  `author_name` varchar(255) default NULL,
  `link` varchar(255) default '',
  `permalink` varchar(255) default NULL,
  `deactivate_commenting_on` date default NULL,
  `hide_comments` tinyint(1) default NULL,
  `average_rating` decimal(5,3) NOT NULL default '0.000',
  `domain_id` int(11) default NULL,
  PRIMARY KEY  (`id`),
  KEY `by_blog_published_at` (`blog_id`,`published_at`),
  KEY `by_account_blog_published_at` (`account_id`,`blog_id`,`published_at`),
  KEY `by_blog_id_published_at_updated_at` (`blog_id`,`published_at`,`updated_at`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `blogs` (
  `id` int(11) NOT NULL auto_increment,
  `title` varchar(255) default NULL,
  `subtitle` varchar(255) default NULL,
  `label` varchar(255) default NULL,
  `author_name` varchar(255) default NULL,
  `defensio_url` varchar(255) default NULL,
  `defensio_key` varchar(255) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  `account_id` int(11) default NULL,
  `comment_approval_method` varchar(255) default NULL,
  `created_by_id` int(11) default NULL,
  `updated_by_id` int(11) default NULL,
  `owner_id` int(11) default NULL,
  `private` tinyint(1) default '0',
  `domain_id` int(11) default NULL,
  PRIMARY KEY  (`id`),
  KEY `by_account_private` (`account_id`,`private`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `book_relations` (
  `id` int(11) NOT NULL auto_increment,
  `party_id` int(11) default NULL,
  `classification` varchar(255) default NULL,
  `book_id` int(11) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `books` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(255) default NULL,
  `genre` varchar(255) default NULL,
  `language` varchar(255) default NULL,
  `printing_number` int(11) default NULL,
  `printing_at` datetime default NULL,
  `isbn` varchar(30) default NULL,
  `cip_filed` varchar(255) default NULL,
  `copyright` varchar(255) default NULL,
  `edition` int(11) default NULL,
  `size` varchar(255) default NULL,
  `page_count` int(11) default NULL,
  `paper_color` varchar(255) default NULL,
  `paper_weight_lbs` int(11) default NULL,
  `binding` varchar(255) default NULL,
  `cover` varchar(255) default NULL,
  `cover_laminate` varchar(255) default NULL,
  `quantity` int(11) default NULL,
  `printing` varchar(255) default NULL,
  `is_manuscript` tinyint(1) default NULL,
  `text_prep_hours` decimal(12,2) default '0.00',
  `typeset_hours` decimal(12,2) default '0.00',
  `design_hours` decimal(12,2) default '0.00',
  `editing_hours` decimal(12,2) default '0.00',
  `proofing_hours` decimal(12,2) default '0.00',
  `indexing_hours` decimal(12,2) default '0.00',
  `misc_hours` decimal(12,2) default '0.00',
  `updated_at` datetime default NULL,
  `account_id` int(11) default NULL,
  `created_at` datetime default NULL,
  `creator_id` int(11) default NULL,
  `editor_id` int(11) default NULL,
  `creator_name` varchar(255) default NULL,
  `editor_name` varchar(255) default NULL,
  `domain_patterns` text,
  `is_paid` varchar(255) default NULL,
  `eta` datetime default NULL,
  `extra_fields` text,
  `notes` text,
  `printing_cost_cents` int(11) default NULL,
  `binding_cost_cents` int(11) default NULL,
  `manuscript_cost_cents` int(11) default NULL,
  `typeset_cost_cents` int(11) default NULL,
  `design_cost_cents` int(11) default NULL,
  `editing_cost_cents` int(11) default NULL,
  `proofing_cost_cents` int(11) default NULL,
  `indexing_cost_cents` int(11) default NULL,
  `misc_cost_cents` int(11) default NULL,
  `printing_hours` decimal(12,2) default '0.00',
  `binding_hours` decimal(12,2) default '0.00',
  `manuscript_hours` decimal(12,2) default '0.00',
  `cip_title_page_completed` varchar(255) default NULL,
  `cip_copyright_page_completed` varchar(255) default NULL,
  `cip_series_page_completed` varchar(255) default NULL,
  `cip_toc_completed` varchar(255) default NULL,
  `cip_preface_completed` varchar(255) default NULL,
  `cip_sample_chapters_completed` varchar(255) default NULL,
  `internal_id` varchar(255) default NULL,
  `text_prep_cost_cents` int(11) default NULL,
  `amount_printed` int(11) default '1',
  `production_cost_cents` int(11) default NULL,
  `cost_per_book_cents` int(11) default NULL,
  `indexing_cost_currency` varchar(4) default NULL,
  `proofing_cost_currency` varchar(4) default NULL,
  `typeset_cost_currency` varchar(4) default NULL,
  `text_prep_cost_currency` varchar(4) default NULL,
  `design_cost_currency` varchar(4) default NULL,
  `binding_cost_currency` varchar(4) default NULL,
  `editing_cost_currency` varchar(4) default NULL,
  `misc_cost_currency` varchar(4) default NULL,
  `manuscript_cost_currency` varchar(4) default NULL,
  `printing_cost_currency` varchar(4) default NULL,
  `production_cost_currency` varchar(4) default NULL,
  `cost_per_book_currency` varchar(4) default 'CAD',
  `working_title` varchar(255) default NULL,
  `name_hebrew` varchar(255) default NULL,
  `manuscript_cost_per_page_cents` int(11) default NULL,
  `manuscript_cost_per_page_currency` varchar(4) default 'CAD',
  `product_id` int(11) default NULL,
  `eight_pages_caliper` float default NULL,
  `source_location_cover` varchar(255) default NULL,
  `source_location_text` text,
  `book_weight_lbs` float default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `breadcrumbs` (
  `id` int(11) NOT NULL auto_increment,
  `url` varchar(255) NOT NULL,
  `display_name` varchar(255) NOT NULL,
  `updated_at` datetime NOT NULL,
  `target_id` int(11) default NULL,
  `target_type` varchar(255) default NULL,
  `owner_id` int(11) default NULL,
  `icon` varchar(30) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `cached_feed_items` (
  `id` int(11) NOT NULL auto_increment,
  `content` text,
  `summary` text,
  `published_at` datetime default NULL,
  `link` varchar(255) default NULL,
  `title` varchar(255) default NULL,
  `feed_item_id` varchar(255) default NULL,
  `cached_feed_id` int(11) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `cached_feeds` (
  `id` int(11) NOT NULL auto_increment,
  `href` varchar(255) default NULL,
  `title` varchar(255) default NULL,
  `link` varchar(255) default NULL,
  `feed_data` text,
  `feed_data_type` varchar(255) default NULL,
  `http_headers` text,
  `last_retrieved` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `cart_lines` (
  `id` int(11) NOT NULL auto_increment,
  `cart_id` int(11) default NULL,
  `product_id` int(11) default NULL,
  `quantity` decimal(12,4) default NULL,
  `sku` varchar(255) default NULL,
  `retail_price_cents` int(11) default NULL,
  `retail_price_currency` varchar(255) default NULL,
  `position` int(11) default '0',
  `pay_period_length` int(11) default NULL,
  `pay_period_unit` varchar(8) default NULL,
  `free_period_length` int(11) default NULL,
  `free_period_unit` varchar(8) default NULL,
  `description` varchar(255) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `carts` (
  `id` int(11) NOT NULL auto_increment,
  `invoice_to_id` int(11) default NULL,
  `account_id` int(11) default NULL,
  `updated_at` datetime default NULL,
  `care_of_id` int(11) default NULL,
  `voided_at` datetime default NULL,
  `voided_by_id` int(11) default NULL,
  `invoice_to_type` varchar(255) default NULL,
  `fst_active` tinyint(1) default NULL,
  `fst_name` varchar(8) default NULL,
  `fst_rate` decimal(5,3) default NULL,
  `apply_fst_on_products` tinyint(1) default NULL,
  `apply_fst_on_labor` tinyint(1) default NULL,
  `pst_active` tinyint(1) default NULL,
  `pst_name` varchar(8) default NULL,
  `pst_rate` decimal(5,3) default NULL,
  `apply_pst_on_products` tinyint(1) default NULL,
  `apply_pst_on_labor` tinyint(1) default NULL,
  `ship_to_id` int(11) default NULL,
  `ship_to_type` varchar(255) default NULL,
  `shipping_fee_cents` int(11) NOT NULL default '0',
  `shipping_fee_currency` varchar(4) NOT NULL default 'CAD',
  `transport_fee_cents` int(11) NOT NULL default '0',
  `transport_fee_currency` varchar(4) NOT NULL default 'CAD',
  `equipment_fee_cents` int(11) NOT NULL default '0',
  `equipment_fee_currency` varchar(4) NOT NULL default 'CAD',
  `domain_id` int(11) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `categories` (
  `id` int(11) NOT NULL auto_increment,
  `account_id` int(11) default NULL,
  `name` varchar(255) default NULL,
  `label` varchar(255) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  `avatar_id` int(11) default NULL,
  `description` text,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `categorizables` (
  `id` int(11) NOT NULL auto_increment,
  `category_id` int(11) default NULL,
  `subject_type` varchar(255) default NULL,
  `subject_id` int(11) default NULL,
  `created_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `comments` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(255) default NULL,
  `url` varchar(255) default NULL,
  `email` varchar(255) default NULL,
  `approved_at` datetime default NULL,
  `user_agent` varchar(255) default NULL,
  `referrer_url` varchar(255) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  `account_id` int(11) default NULL,
  `body` text,
  `rating` int(11) default NULL,
  `commentable_type` varchar(255) default NULL,
  `commentable_id` int(11) default NULL,
  `created_by_id` int(11) default NULL,
  `updated_by_id` int(11) default NULL,
  `private` tinyint(1) default NULL,
  `request_ip` varchar(255) default NULL,
  `spaminess` decimal(10,0) default NULL,
  `defensio_signature` varchar(255) default NULL,
  `spam` tinyint(1) default '1',
  `domain_id` int(11) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `configurations` (
  `id` int(11) NOT NULL auto_increment,
  `type` varchar(40) NOT NULL default '',
  `name` varchar(60) NOT NULL default '',
  `group_name` varchar(60) default NULL,
  `description` varchar(240) default NULL,
  `product_category_id` int(11) default NULL,
  `product_id` int(11) default NULL,
  `int_value` int(11) default NULL,
  `float_value` float default NULL,
  `str_value` varchar(240) default NULL,
  `party_id` int(11) default NULL,
  `account_id` int(11) default NULL,
  `account_wide` tinyint(1) default '1',
  `domain_patterns` text,
  `uuid` varchar(36) default NULL,
  PRIMARY KEY  (`id`),
  KEY `product_category_id` (`product_category_id`),
  KEY `product_id` (`product_id`),
  KEY `by_account_id_and_name` (`account_id`,`name`),
  KEY `by_account_id_and_group_name_and_name` (`account_id`,`group_name`,`name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `contact_request_recipients` (
  `party_id` int(11) default NULL,
  `contact_request_id` int(11) default NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `contact_requests` (
  `id` int(11) NOT NULL auto_increment,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `completed_at` datetime default NULL,
  `name` varchar(80) default NULL,
  `email` varchar(80) default NULL,
  `phone` varchar(30) default NULL,
  `time_to_call` varchar(80) default NULL,
  `subject` varchar(80) default NULL,
  `body` text,
  `account_id` int(11) default NULL,
  `party_id` int(11) default NULL,
  `request_ip` varchar(255) default NULL,
  `spaminess` decimal(5,3) default NULL,
  `defensio_signature` varchar(255) default NULL,
  `approved_at` datetime default NULL,
  `referrer_url` varchar(255) default NULL,
  `params` text,
  `affiliate_id` int(11) default NULL,
  `domain_id` int(11) default NULL,
  `add_party_to_database` tinyint(1) default '1',
  PRIMARY KEY  (`id`),
  KEY `contact_requests_created_at_index` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `contact_routes` (
  `id` int(11) NOT NULL auto_increment,
  `type` varchar(60) NOT NULL,
  `position` int(11) default '0',
  `routable_type` varchar(255) default NULL,
  `routable_id` int(11) default NULL,
  `name` varchar(255) NOT NULL,
  `number` varchar(255) default NULL,
  `extension` varchar(255) default NULL,
  `email_address` varchar(255) default NULL,
  `url` text,
  `line1` varchar(255) default NULL,
  `line2` varchar(255) default NULL,
  `line3` varchar(255) default NULL,
  `city` varchar(255) default NULL,
  `state` varchar(255) default NULL,
  `zip` varchar(255) default NULL,
  `country` varchar(255) default NULL,
  `account_id` int(11) default NULL,
  `latitude` float default NULL,
  `longitude` float default NULL,
  `uuid` varchar(36) default NULL,
  PRIMARY KEY  (`id`),
  KEY `by_account_routable` (`account_id`,`routable_type`,`routable_id`,`position`),
  KEY `by_account_type_routable` (`account_id`,`type`,`routable_type`,`routable_id`,`position`),
  KEY `by_routable_position` (`routable_type`,`routable_id`,`position`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `destinations` (
  `id` int(11) NOT NULL auto_increment,
  `country` varchar(255) default NULL,
  `state` varchar(255) default NULL,
  `cost_cents` int(11) default NULL,
  `account_id` int(11) default NULL,
  `cost_currency` varchar(4) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `domain_subscriptions` (
  `id` int(11) NOT NULL auto_increment,
  `started_at` datetime default NULL,
  `cancelled_at` datetime default NULL,
  `account_id` int(11) default NULL,
  `order_id` int(11) default NULL,
  `free_period_length` int(11) default NULL,
  `free_period_unit` varchar(8) default NULL,
  `pay_period_length` int(11) default NULL,
  `pay_period_unit` varchar(8) default NULL,
  `amount_cents` int(11) default NULL,
  `amount_currency` varchar(255) default NULL,
  `number_of_domains` int(11) default NULL,
  `paypal_subscription_id` varchar(255) default NULL,
  `bucket` int(11) default NULL,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `by_paypal_subscription_id` (`paypal_subscription_id`),
  KEY `by_account_id_started_at` (`account_id`,`started_at`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `domains` (
  `id` int(11) NOT NULL auto_increment,
  `account_id` int(11) default NULL,
  `name` varchar(255) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  `role` varchar(255) default 'browsing',
  `description` text,
  `price_cents` int(11) default '0',
  `price_currency` varchar(4) default 'CAD',
  `routes` text,
  `activated_at` datetime default NULL,
  `domain_subscription_id` int(11) default NULL,
  PRIMARY KEY  (`id`),
  KEY `name` (`name`),
  KEY `by_account` (`account_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `effective_permissions` (
  `party_id` int(11) default NULL,
  `permission_id` int(11) default NULL,
  UNIQUE KEY `by_party_permission` (`party_id`,`permission_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `email_accounts` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(255) default NULL,
  `type` varchar(255) default NULL,
  `server` varchar(255) default NULL,
  `port` int(11) NOT NULL,
  `username` varchar(255) default NULL,
  `password` varchar(255) default NULL,
  `last_queried_at` varchar(255) default NULL,
  `created_at` varchar(255) default NULL,
  `updated_at` varchar(255) default NULL,
  `account_id` int(8) default NULL,
  `party_id` int(8) default NULL,
  `error_message` text,
  `failures` int(11) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `email_labels` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(255) default NULL,
  `account_id` int(11) default NULL,
  `party_id` int(11) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `emails` (
  `id` int(11) NOT NULL auto_increment,
  `subject` varchar(255) default NULL,
  `body` text,
  `scheduled_at` datetime default NULL,
  `sent_at` datetime default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  `released_at` datetime default NULL,
  `bad_recipient_count` int(11) default NULL,
  `generate_password` tinyint(1) NOT NULL default '0',
  `unique_id_listing` varchar(255) default NULL,
  `received_at` datetime default NULL,
  `inline_attachments` tinyint(1) NOT NULL default '0',
  `about_type` varchar(255) default NULL,
  `about_id` int(11) default NULL,
  `account_id` int(11) default NULL,
  `message_id` varchar(255) NOT NULL default '',
  `return_to_url` varchar(255) default NULL,
  `tags_to_remove` varchar(255) default NULL,
  `opt_out_url` varchar(255) default NULL,
  `error` text,
  `backtrace` text,
  `error_count` int(11) NOT NULL default '0',
  `domain_id` int(11) default NULL,
  `mass_mail` tinyint(1) default NULL,
  `mail_type` varchar(12) default 'HTML+Plain',
  `parsed_subject` blob,
  `parsed_body` blob,
  PRIMARY KEY  (`id`),
  KEY `by_scheduled_sent_released` (`scheduled_at`,`sent_at`,`released_at`),
  KEY `by_account_uidl` (`account_id`,`unique_id_listing`),
  KEY `by_account_message` (`account_id`,`message_id`),
  KEY `by_released_sent_received` (`released_at`,`sent_at`,`received_at`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `emails_filters` (
  `filter_id` int(11) default NULL,
  `email_id` int(11) default NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `employees_schedules` (
  `employee_id` int(11) default NULL,
  `schedule_id` int(11) default NULL,
  KEY `employee_id` (`employee_id`),
  KEY `schedule_id` (`schedule_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `engine_schema_info` (
  `engine_name` varchar(255) default NULL,
  `version` int(11) default NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `entities` (
  `id` int(11) NOT NULL auto_increment,
  `classification` varchar(255) default NULL,
  `name` varchar(255) default NULL,
  `description` text,
  `parent_id` int(11) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  `creator_id` int(11) default NULL,
  `editor_id` int(11) default NULL,
  `creator_name` varchar(255) default NULL,
  `editor_name` varchar(255) default NULL,
  `account_id` int(11) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `entries` (
  `id` int(11) NOT NULL auto_increment,
  `content` text,
  `summary` text,
  `published_at` datetime default NULL,
  `link` varchar(255) default NULL,
  `title` varchar(255) default NULL,
  `feed_id` int(11) default NULL,
  `account_id` int(11) default NULL,
  PRIMARY KEY  (`id`),
  KEY `by_account_id_and_feed_id` (`account_id`,`feed_id`),
  KEY `by_account_id_and_published_at` (`account_id`,`published_at`),
  KEY `by_feed_published` (`feed_id`,`published_at`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `estimate_lines` (
  `id` int(11) NOT NULL auto_increment,
  `position` int(11) default '0',
  `estimate_id` int(11) NOT NULL default '0',
  `product_id` int(11) default NULL,
  `quantity` decimal(12,4) default NULL,
  `retail_price_cents` int(11) default '0',
  `comment` varchar(255) default NULL,
  `retail_price_currency` varchar(255) default 'CAD',
  `account_id` int(11) default NULL,
  `description` varchar(255) default NULL,
  `sku` varchar(255) default NULL,
  `pay_period_length` int(11) default NULL,
  `pay_period_unit` varchar(8) default NULL,
  `free_period_length` int(11) default NULL,
  `free_period_unit` varchar(8) default NULL,
  PRIMARY KEY  (`id`),
  KEY `product_id` (`product_id`),
  KEY `by_estimate_position` (`estimate_id`,`position`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `estimates` (
  `id` int(11) NOT NULL auto_increment,
  `fst_active` tinyint(1) default NULL,
  `fst_name` varchar(8) default NULL,
  `fst_rate` decimal(5,3) default NULL,
  `pst_active` tinyint(1) default NULL,
  `pst_name` varchar(8) default NULL,
  `pst_rate` decimal(5,3) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  `status` varchar(255) default NULL,
  `invoice_to_id` int(11) default NULL,
  `apply_fst_on_products` tinyint(1) default NULL,
  `apply_fst_on_labor` tinyint(1) default NULL,
  `apply_pst_on_products` tinyint(1) default NULL,
  `apply_pst_on_labor` tinyint(1) default NULL,
  `shipping_fee_cents` int(11) NOT NULL default '0',
  `shipping_method` varchar(255) default NULL,
  `notes` text,
  `care_of_id` int(11) default NULL,
  `uuid` varchar(255) default NULL,
  `account_id` int(11) default NULL,
  `shipping_fee_currency` varchar(4) NOT NULL default 'CAD',
  `updated_by_id` int(11) default NULL,
  `updated_by_name` varchar(255) default NULL,
  `completed_at` datetime default NULL,
  `completed_by_id` int(11) default NULL,
  `completed_by_name` varchar(255) default NULL,
  `confirmed_at` datetime default NULL,
  `confirmed_by_id` int(11) default NULL,
  `confirmed_by_name` varchar(255) default NULL,
  `created_by_id` int(11) default NULL,
  `created_by_name` varchar(255) default NULL,
  `date` date default NULL,
  `number` varchar(255) default NULL,
  `invoice_to_type` varchar(255) default NULL,
  `care_of_name` varchar(255) default NULL,
  `reference_id` int(11) default NULL,
  `reference_type` varchar(255) default NULL,
  `sent_at` datetime default NULL,
  `sent_by_id` int(11) default NULL,
  `sent_by_name` varchar(255) default NULL,
  `payment_term_id` int(11) default NULL,
  `ship_to_id` int(11) default NULL,
  `ship_to_type` varchar(255) default NULL,
  `info` text NOT NULL,
  `transport_fee_cents` int(11) NOT NULL default '0',
  `transport_fee_currency` varchar(4) NOT NULL default 'CAD',
  `equipment_fee_cents` int(11) NOT NULL default '0',
  `equipment_fee_currency` varchar(4) NOT NULL default 'CAD',
  `latitude` float default NULL,
  `longitude` float default NULL,
  `domain_id` int(11) default NULL,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `by_uuid` (`uuid`),
  KEY `estimates_customer_id_index` (`invoice_to_id`),
  KEY `by_updated_at` (`updated_at`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `expiring_party_items` (
  `id` int(11) NOT NULL auto_increment,
  `item_type` varchar(255) default NULL,
  `item_id` int(11) default NULL,
  `party_id` int(11) default NULL,
  `updated_by_type` varchar(255) default NULL,
  `updated_by_id` int(11) default NULL,
  `created_by_type` varchar(255) default NULL,
  `created_by_id` int(11) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  `started_at` datetime default NULL,
  `expired_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `feeds` (
  `id` int(11) NOT NULL auto_increment,
  `url` varchar(255) default NULL,
  `account_id` int(11) default NULL,
  `label` varchar(255) default NULL,
  `description` text,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  `refreshed_at` datetime default NULL,
  `title` varchar(255) default NULL,
  `subtitle` varchar(255) default NULL,
  `tagline` varchar(255) default NULL,
  `publisher` varchar(255) default NULL,
  `license` varchar(255) default NULL,
  `language` varchar(255) default NULL,
  `guid` varchar(255) default NULL,
  `copyright` varchar(255) default NULL,
  `abstract` varchar(255) default NULL,
  `author` varchar(255) default NULL,
  `categories` text,
  `published_at` datetime default NULL,
  `last_errored_at` datetime default NULL,
  `error_message` varchar(255) default NULL,
  `backtrace` text,
  `error_class` varchar(255) default NULL,
  `error_count` int(11) default '0',
  `created_by_id` int(11) default NULL,
  `updated_by_id` int(11) default NULL,
  PRIMARY KEY  (`id`),
  KEY `index_feeds_on_refreshed_at` (`refreshed_at`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `feeds_parties` (
  `party_id` int(11) default NULL,
  `feed_id` int(11) default NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `filter_lines` (
  `id` int(11) NOT NULL auto_increment,
  `field` varchar(40) default NULL,
  `operator` varchar(40) default NULL,
  `value` varchar(255) default NULL,
  `exclude` tinyint(1) default NULL,
  `filter_id` int(8) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `filters` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(255) default NULL,
  `description` varchar(255) default NULL,
  `party_id` int(11) default NULL,
  `account_id` int(11) default NULL,
  `email_label_id` int(11) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `folder_editors` (
  `folder_id` int(11) default NULL,
  `group_id` int(11) default NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `folder_viewers` (
  `folder_id` int(11) default NULL,
  `group_id` int(11) default NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `folders` (
  `id` int(11) NOT NULL auto_increment,
  `parent_id` int(11) default NULL,
  `lft` int(11) default NULL,
  `rgt` int(11) default NULL,
  `updated_at` datetime default NULL,
  `name` varchar(255) NOT NULL default '',
  `account_id` int(11) default NULL,
  `private` tinyint(1) default '0',
  `owner_id` int(11) default NULL,
  `description` text,
  `inherit` tinyint(1) default '0',
  `pass_on_attr` tinyint(1) default '0',
  `created_at` datetime default NULL,
  `uuid` varchar(36) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `forum_categories` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(100) NOT NULL,
  `description` varchar(255) default NULL,
  `account_id` int(11) NOT NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `forum_posts` (
  `id` int(11) NOT NULL auto_increment,
  `user_id` int(11) default NULL,
  `topic_id` int(11) default NULL,
  `body` text,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  `forum_id` int(11) default NULL,
  `account_id` int(11) default NULL,
  `forum_category_id` int(8) default NULL,
  `rendered_body` text,
  PRIMARY KEY  (`id`),
  KEY `index_posts_on_user_id` (`user_id`),
  KEY `index_posts_on_topic_id` (`topic_id`),
  KEY `created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `forum_topics` (
  `id` int(11) NOT NULL auto_increment,
  `forum_id` int(11) default NULL,
  `user_id` int(11) default NULL,
  `title` varchar(255) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  `hits` int(11) default '0',
  `sticky` int(11) default '0',
  `posts_count` int(11) default '0',
  `replied_at` datetime default NULL,
  `locked` tinyint(1) default '0',
  `replied_by` int(11) default NULL,
  `last_post_id` int(11) default NULL,
  `account_id` int(11) default NULL,
  `forum_category_id` int(8) default NULL,
  PRIMARY KEY  (`id`),
  KEY `index_topics_on_forum_id` (`forum_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `forums` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(255) default NULL,
  `description` varchar(255) default NULL,
  `topics_count` int(11) default '0',
  `posts_count` int(11) default '0',
  `position` int(11) default NULL,
  `account_id` int(11) default NULL,
  `forum_category_id` int(8) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `fulltext_rows` (
  `id` int(11) NOT NULL auto_increment,
  `account_id` int(11) default NULL,
  `subject_id` int(11) default NULL,
  `subject_type` varchar(255) default NULL,
  `subject_updated_at` datetime default NULL,
  `weight` int(11) default NULL,
  `label` varchar(255) default NULL,
  `body` text,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`),
  KEY `by_account_weight_subject` (`account_id`,`weight`,`subject_id`,`subject_type`),
  KEY `by_account_weight_updated_subject` (`account_id`,`weight`,`subject_updated_at`,`subject_id`,`subject_type`),
  KEY `by_account_subject` (`account_id`,`subject_type`,`subject_id`),
  KEY `by_subject` (`subject_type`,`subject_id`),
  FULLTEXT KEY `by_label_body` (`label`,`body`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE `futures` (
  `id` int(11) NOT NULL auto_increment,
  `type` varchar(255) default NULL,
  `account_id` int(11) default NULL,
  `owner_id` int(11) default NULL,
  `status` varchar(255) default 'unstarted',
  `autoclean` tinyint(1) default '0',
  `args` text,
  `results` text,
  `result_url` varchar(255) default NULL,
  `started_at` datetime default NULL,
  `ended_at` datetime default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  `interval` int(11) default NULL,
  `scheduled_at` datetime NOT NULL default '1970-01-01 00:00:00',
  `system` tinyint(1) default '0',
  `progress` int(11) NOT NULL default '0',
  `priority` int(11) NOT NULL default '100',
  PRIMARY KEY  (`id`),
  KEY `by_account_status_scheduled_created` (`account_id`,`status`,`scheduled_at`,`created_at`),
  KEY `by_type` (`type`),
  KEY `by_started_scheduled` (`started_at`,`scheduled_at`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `geocodes` (
  `id` int(11) NOT NULL auto_increment,
  `longitude` float default NULL,
  `latitude` float default NULL,
  `zip` varchar(255) default NULL,
  `city` varchar(255) default NULL,
  `state` varchar(255) default NULL,
  `country` varchar(255) default NULL,
  `zip_type` varchar(255) default NULL,
  `city_type` varchar(255) default NULL,
  `area_code` varchar(255) default NULL,
  PRIMARY KEY  (`id`),
  KEY `by_zip` (`zip`),
  KEY `by_country_and_state_and_zip` (`country`,`state`,`zip`),
  KEY `by_area_code` (`area_code`),
  KEY `by_longitude_and_latitude` (`longitude`,`latitude`),
  KEY `by_latitude_and_longitude` (`latitude`,`longitude`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `geopositions` (
  `id` int(11) NOT NULL auto_increment,
  `zip` varchar(255) default NULL,
  `zip_type` varchar(255) default NULL,
  `city_name` varchar(255) default NULL,
  `city_type` varchar(255) default NULL,
  `state_name` varchar(255) default NULL,
  `state_abbr` varchar(255) default NULL,
  `area_code` varchar(255) default NULL,
  `latitude` float default NULL,
  `longitude` float default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `group_items` (
  `id` int(11) NOT NULL auto_increment,
  `target_type` varchar(255) default NULL,
  `target_id` int(11) default NULL,
  `group_id` int(11) default NULL,
  `position` int(11) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `groups` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(255) default NULL,
  `parent_id` int(11) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  `created_by_id` int(11) default NULL,
  `updated_by_id` int(11) default NULL,
  `account_id` int(11) default NULL,
  `description` text,
  `avatar_id` int(11) default NULL,
  `label` varchar(255) default NULL,
  `web_copy` text,
  `private` tinyint(1) default '1',
  `private_description` text,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `imports` (
  `id` int(11) NOT NULL auto_increment,
  `account_id` int(8) NOT NULL,
  `party_id` int(11) NOT NULL,
  `csv` text,
  `import_errors` text,
  `imported_lines` text,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  `filename` varchar(255) default NULL,
  `force` tinyint(1) default NULL,
  `mappings` text,
  `state` varchar(255) default NULL,
  `scrape` tinyint(1) default '0',
  `last_scraped_url` varchar(255) default NULL,
  `imported_rows_count` int(11) NOT NULL default '0',
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `installed_account_templates` (
  `id` int(11) NOT NULL auto_increment,
  `account_id` int(11) default NULL,
  `account_template_id` int(11) default NULL,
  `domain_patterns` varchar(255) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  `setup_fee_cents` int(11) default NULL,
  `setup_fee_currency` varchar(255) default NULL,
  `subscription_markup_fee_cents` int(11) default NULL,
  `subscription_markup_fee_currency` varchar(255) default NULL,
  `account_module_subscription_id` int(11) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `interests` (
  `id` int(11) NOT NULL auto_increment,
  `party_id` int(11) default NULL,
  `listing_id` int(11) default NULL,
  `note` text,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `invoice_lines` (
  `id` int(11) NOT NULL auto_increment,
  `invoice_id` int(11) NOT NULL,
  `position` int(11) default '0',
  `product_id` int(11) default NULL,
  `quantity` decimal(12,4) default NULL,
  `retail_price_cents` int(11) default NULL,
  `comment` varchar(255) default NULL,
  `sku` varchar(255) default NULL,
  `retail_price_currency` varchar(4) default NULL,
  `description` varchar(255) default NULL,
  `account_id` int(11) default NULL,
  `pay_period_length` int(11) default NULL,
  `pay_period_unit` varchar(8) default NULL,
  `free_period_length` int(11) default NULL,
  `free_period_unit` varchar(8) default NULL,
  PRIMARY KEY  (`id`),
  KEY `invoice_lines_invoice_id_index` (`invoice_id`,`position`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `invoices` (
  `id` int(11) NOT NULL auto_increment,
  `invoice_to_id` int(11) default NULL,
  `number` int(11) default NULL,
  `date` date default NULL,
  `notes` text,
  `description` text,
  `transport_fee_cents` int(11) NOT NULL default '0',
  `equipment_fee_cents` int(11) NOT NULL default '0',
  `shipping_method` varchar(255) default NULL,
  `apply_fst_on_products` tinyint(1) default NULL,
  `apply_pst_on_products` tinyint(1) default NULL,
  `apply_fst_on_labor` tinyint(1) default NULL,
  `apply_pst_on_labor` tinyint(1) default NULL,
  `pst_active` tinyint(1) NOT NULL default '0',
  `pst_name` varchar(255) NOT NULL default '',
  `pst_rate` int(11) NOT NULL,
  `fst_active` tinyint(1) NOT NULL default '0',
  `fst_name` varchar(255) NOT NULL default '',
  `fst_rate` int(11) NOT NULL,
  `picture_id` int(11) default NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `phone_number` varchar(32) NOT NULL default '',
  `paid_in_full` tinyint(1) NOT NULL default '0',
  `voided_at` datetime default NULL,
  `voided_by_id` int(11) default NULL,
  `account_id` int(11) default NULL,
  `status` varchar(40) default NULL,
  `invoice_to_type` varchar(255) default NULL,
  `care_of_id` int(11) default NULL,
  `order_id` int(11) default NULL,
  `ship_to_id` int(11) default NULL,
  `ship_to_type` varchar(255) default NULL,
  `created_by_id` int(11) default NULL,
  `created_by_name` varchar(255) default NULL,
  `updated_by_id` int(11) default NULL,
  `updated_by_name` varchar(255) default NULL,
  `sent_at` datetime default NULL,
  `sent_by_id` int(11) default NULL,
  `sent_by_name` varchar(255) default NULL,
  `paid_at` datetime default NULL,
  `paid_by_id` int(11) default NULL,
  `paid_by_name` varchar(255) default NULL,
  `voided_by_name` varchar(255) default NULL,
  `shipping_fee_cents` int(11) NOT NULL default '0',
  `shipping_fee_currency` varchar(4) NOT NULL default 'CAD',
  `payment_term_id` int(11) default NULL,
  `uuid` varchar(255) default NULL,
  `care_of_name` varchar(255) default NULL,
  `transport_fee_currency` varchar(4) NOT NULL default 'CAD',
  `equipment_fee_currency` varchar(4) NOT NULL default 'CAD',
  `latitude` float default NULL,
  `longitude` float default NULL,
  `domain_id` int(11) default NULL,
  PRIMARY KEY  (`id`),
  KEY `invoices_no_index` (`number`),
  KEY `invoices_customer_id_index` (`invoice_to_id`),
  KEY `invoices_date_index` (`date`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `item_versions` (
  `id` int(11) NOT NULL auto_increment,
  `item_id` int(11) default NULL,
  `version` int(11) default NULL,
  `creator_id` int(11) default NULL,
  `title` varchar(255) default NULL,
  `body` text,
  `behavior` varchar(40) default 'plain_text',
  `uuid` varchar(36) default NULL,
  `published_at` datetime default NULL,
  `status` varchar(20) default 'draft',
  `updated_at` datetime default NULL,
  `account_id` int(11) default NULL,
  `fullslug` varchar(255) default NULL,
  `domain_patterns` text,
  `layout` varchar(255) default NULL,
  `cached_parsed_body` blob,
  `cached_parsed_title` blob,
  `require_ssl` tinyint(1) default '0',
  `requirements` text,
  `cache_timeout_in_seconds` int(11) default NULL,
  `cache_control_directive` varchar(255) default NULL,
  `meta_description` text,
  `meta_keywords` text,
  `versioned_type` varchar(255) default NULL,
  `modified` tinyint(1) default NULL,
  `http_code` int(11) default '200',
  `updator_id` int(11) default NULL,
  `no_update` tinyint(1) default '0',
  PRIMARY KEY  (`id`),
  KEY `index_item_versions_on_item_id` (`item_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `items` (
  `id` int(11) NOT NULL auto_increment,
  `creator_id` int(11) default NULL,
  `title` varchar(255) default NULL,
  `body` text,
  `behavior` varchar(40) default 'plain_text',
  `uuid` varchar(36) default NULL,
  `published_at` datetime default NULL,
  `status` varchar(20) default 'draft',
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  `account_id` int(11) default NULL,
  `type` varchar(255) default NULL,
  `fullslug` varchar(255) default NULL,
  `domain_patterns` text,
  `layout` varchar(255) default NULL,
  `cached_parsed_body` blob,
  `cached_parsed_title` blob,
  `require_ssl` tinyint(1) default '0',
  `requirements` text,
  `cache_timeout_in_seconds` int(11) default NULL,
  `cache_control_directive` varchar(255) default NULL,
  `meta_description` text,
  `meta_keywords` text,
  `version` int(11) default NULL,
  `modified` tinyint(1) default NULL,
  `http_code` int(11) default '200',
  `updator_id` int(11) default NULL,
  `no_update` tinyint(1) default NULL,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `by_account_uuid` (`account_id`,`uuid`),
  KEY `by_account_fullslug_status` (`account_id`,`fullslug`,`status`),
  KEY `by_account_type_title` (`account_id`,`type`,`title`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `job_slots_teams` (
  `job_slot_id` int(11) NOT NULL default '0',
  `team_id` int(11) NOT NULL default '0',
  KEY `team_id` (`team_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `layout_versions` (
  `id` int(11) NOT NULL auto_increment,
  `layout_id` int(11) default NULL,
  `version` int(11) default NULL,
  `title` varchar(255) default NULL,
  `body` text,
  `content_type` varchar(255) default 'text/html',
  `encoding` varchar(255) default 'UTF-8',
  `creator_id` int(11) default NULL,
  `updated_at` datetime default NULL,
  `account_id` int(11) default NULL,
  `domain_patterns` text,
  `cached_parsed_template` blob,
  `cache_timeout_in_seconds` int(11) default NULL,
  `cache_control_directive` varchar(255) default NULL,
  `uuid` varchar(36) default NULL,
  `modified` tinyint(1) default NULL,
  `updator_id` int(11) default NULL,
  `no_update` tinyint(1) default '0',
  PRIMARY KEY  (`id`),
  KEY `index_layout_versions_on_layout_id` (`layout_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `layouts` (
  `id` int(11) NOT NULL auto_increment,
  `title` varchar(255) NOT NULL,
  `body` text,
  `content_type` varchar(255) NOT NULL default 'text/html',
  `encoding` varchar(255) NOT NULL default 'UTF-8',
  `creator_id` int(11) default NULL,
  `updated_at` datetime default NULL,
  `account_id` int(11) default NULL,
  `domain_patterns` text,
  `cached_parsed_template` blob,
  `cache_timeout_in_seconds` int(11) default NULL,
  `cache_control_directive` varchar(255) default NULL,
  `version` int(11) default NULL,
  `uuid` varchar(36) default NULL,
  `modified` tinyint(1) default NULL,
  `updator_id` int(11) default NULL,
  `no_update` tinyint(1) default NULL,
  PRIMARY KEY  (`id`),
  KEY `by_account_title` (`account_id`,`title`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `link_categories` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(50) NOT NULL default '',
  `description` varchar(200) default '',
  `account_id` int(11) default NULL,
  `parent_id` int(11) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `link_categories_links` (
  `link_category_id` int(11) default NULL,
  `link_id` int(11) default NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `links` (
  `id` int(11) NOT NULL auto_increment,
  `title` varchar(240) NOT NULL default '',
  `description` text,
  `url` varchar(240) default NULL,
  `active_at` datetime default NULL,
  `inactive_at` datetime default NULL,
  `updated_at` datetime default NULL,
  `account_id` int(11) default NULL,
  `approved` tinyint(1) default '0',
  `created_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `listings` (
  `id` int(11) NOT NULL auto_increment,
  `address_id` int(11) NOT NULL default '0',
  `realtor_id` int(11) default NULL,
  `mls_no` varchar(12) default NULL,
  `house_size` float NOT NULL default '0',
  `house_size_unit` varchar(255) NOT NULL default '',
  `lot_size` float NOT NULL default '0',
  `lot_size_unit` varchar(255) NOT NULL default '',
  `features` text,
  `description` text,
  `price_cents` int(11) default '0',
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `uuid` varchar(255) default NULL,
  `public` tinyint(1) NOT NULL default '1',
  `account_id` int(11) default NULL,
  `external_id` varchar(255) default NULL,
  `raw_property_data` text,
  `extras` text,
  `rets_resource` varchar(255) default NULL,
  `rets_class` varchar(255) default NULL,
  `rets_property` text,
  `price_currency` varchar(4) default 'CAD',
  `status` varchar(255) default NULL,
  `region` varchar(255) default NULL,
  `area` varchar(255) default NULL,
  `contact_email` varchar(255) default NULL,
  `list_date` varchar(255) default NULL,
  `open_house_text` text,
  `type` varchar(255) default NULL,
  `meta_description` text,
  `meta_keywords` text,
  `average_rating` decimal(5,3) NOT NULL default '0.000',
  `hide_comments` tinyint(1) default '0',
  `deactivate_commenting_on` date default NULL,
  `latitude` float default NULL,
  `longitude` float default NULL,
  `creator_id` int(11) default NULL,
  `comment_approval_method` varchar(255) default NULL,
  `open_house` tinyint(1) default '0',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `by_account_ext_id` (`account_id`,`external_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `mappers` (
  `id` int(11) NOT NULL auto_increment,
  `account_id` int(8) default NULL,
  `mappings` text,
  `name` varchar(63) default NULL,
  `description` varchar(255) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `memberships` (
  `party_id` int(11) default NULL,
  `group_id` int(11) default NULL,
  `id` int(10) unsigned NOT NULL auto_increment,
  `created_at` datetime default NULL,
  PRIMARY KEY  (`id`),
  KEY `by_party` (`party_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `migrations_info` (
  `id` int(11) NOT NULL default '0',
  `created_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `order_lines` (
  `id` int(11) NOT NULL auto_increment,
  `account_id` int(11) default NULL,
  `order_id` int(11) default NULL,
  `position` int(11) default '0',
  `product_id` int(11) default NULL,
  `quantity` decimal(12,4) default NULL,
  `quantity_shipped` decimal(12,4) default '0.0000',
  `retail_price_cents` int(11) default NULL,
  `retail_price_currency` varchar(255) default NULL,
  `description` varchar(255) default NULL,
  `sku` varchar(255) default NULL,
  `comment` varchar(255) default NULL,
  `pay_period_length` int(11) default NULL,
  `pay_period_unit` varchar(8) default NULL,
  `free_period_length` int(11) default NULL,
  `free_period_unit` varchar(8) default NULL,
  `quantity_invoiced` decimal(12,4) default '0.0000',
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `orders` (
  `id` int(11) NOT NULL auto_increment,
  `account_id` int(11) default NULL,
  `invoice_to_type` varchar(255) default NULL,
  `invoice_to_id` int(11) default NULL,
  `care_of_id` int(11) default NULL,
  `care_of_name` varchar(255) default NULL,
  `number` varchar(255) default NULL,
  `date` date default NULL,
  `notes` text,
  `fst_active` tinyint(1) default NULL,
  `fst_name` varchar(8) default NULL,
  `fst_rate` decimal(5,3) default NULL,
  `apply_fst_on_products` tinyint(1) default NULL,
  `apply_fst_on_labor` tinyint(1) default NULL,
  `pst_active` tinyint(1) default NULL,
  `pst_name` varchar(8) default NULL,
  `pst_rate` decimal(5,3) default NULL,
  `apply_pst_on_products` tinyint(1) default NULL,
  `apply_pst_on_labor` tinyint(1) default NULL,
  `shipping_method` varchar(255) default NULL,
  `status` varchar(255) default NULL,
  `created_at` datetime default NULL,
  `created_by_id` int(11) default NULL,
  `created_by_name` varchar(255) default NULL,
  `updated_at` datetime default NULL,
  `updated_by_id` int(11) default NULL,
  `updated_by_name` varchar(255) default NULL,
  `sent_at` datetime default NULL,
  `sent_by_id` int(11) default NULL,
  `sent_by_name` varchar(255) default NULL,
  `confirmed_at` datetime default NULL,
  `confirmed_by_id` int(11) default NULL,
  `confirmed_by_name` varchar(255) default NULL,
  `completed_at` datetime default NULL,
  `completed_by_id` int(11) default NULL,
  `completed_by_name` varchar(255) default NULL,
  `voided_at` datetime default NULL,
  `voided_by_id` int(11) default NULL,
  `ship_to_id` int(11) default NULL,
  `ship_to_type` varchar(255) default NULL,
  `voided_by_name` varchar(255) default NULL,
  `uuid` varchar(255) default NULL,
  `shipping_fee_cents` int(11) NOT NULL default '0',
  `shipping_fee_currency` varchar(4) NOT NULL default 'CAD',
  `payment_term_id` int(11) default NULL,
  `reference_type` varchar(255) default NULL,
  `reference_id` int(11) default NULL,
  `paid_in_full` tinyint(1) NOT NULL default '0',
  `equipment_fee_cents` int(11) NOT NULL default '0',
  `equipment_fee_currency` varchar(4) NOT NULL default 'CAD',
  `transport_fee_cents` int(11) NOT NULL default '0',
  `transport_fee_currency` varchar(4) NOT NULL default 'CAD',
  `latitude` float default NULL,
  `longitude` float default NULL,
  `domain_id` int(11) default NULL,
  `paid_in_full_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `parties` (
  `id` int(11) NOT NULL auto_increment,
  `company_name` varchar(60) default NULL,
  `last_name` varchar(40) default NULL,
  `middle_name` varchar(40) default NULL,
  `first_name` varchar(40) default NULL,
  `honorific` varchar(20) default NULL,
  `referal` text,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  `archived_at` datetime default NULL,
  `login` varchar(32) default NULL,
  `password_hash` varchar(40) default NULL,
  `website_url` varchar(240) default NULL,
  `dropship_email` varchar(120) default NULL,
  `send_email_on_order` tinyint(1) NOT NULL default '0',
  `order_type` varchar(30) default NULL,
  `climbing_experience` varchar(20) default NULL,
  `rope_work_safety_gear_experience` varchar(20) default NULL,
  `outdoor_gear` tinyint(1) NOT NULL default '0',
  `vehicle_type` varchar(20) default NULL,
  `vehicle_roof_rack` tinyint(1) NOT NULL default '0',
  `team_manager` tinyint(1) NOT NULL default '0',
  `staff_agreement_date` datetime default NULL,
  `staff_agreement_version` int(11) default NULL,
  `on_tour` tinyint(1) NOT NULL default '0',
  `allow_mail_in` tinyint(1) NOT NULL default '0',
  `uuid` varchar(255) default NULL,
  `display_name` varchar(255) NOT NULL default '',
  `posts_count` int(11) NOT NULL default '0',
  `token` varchar(255) default NULL,
  `position` varchar(255) default NULL,
  `account_id` int(11) default NULL,
  `superuser` tinyint(1) NOT NULL default '0',
  `signature` text,
  `password_salt` varchar(40) default NULL,
  `token_expires_at` datetime default NULL,
  `last_logged_in_at` datetime default NULL,
  `created_by_id` int(11) default NULL,
  `updated_by_id` int(11) default NULL,
  `referred_by_id` int(11) default NULL,
  `confirmation_token` varchar(255) default NULL,
  `confirmation_token_expires_at` datetime default NULL,
  `avatar_id` int(11) default NULL,
  `forum_alias` varchar(255) default NULL,
  `timezone` varchar(255) default 'America/Vancouver',
  `biography` text,
  `date_format` varchar(255) default '%Y-%m-%d',
  `time_format` varchar(255) default '%H:%M',
  `info` text,
  `birthdate_day` int(11) default NULL,
  `birthdate_month` int(11) default NULL,
  `birthdate_year` int(11) default NULL,
  `profile_id` int(11) default NULL,
  `confirmed` tinyint(1) default '0',
  `own_point` int(11) default '0',
  `referrals_point` int(11) default '0',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `by_account_token` (`account_id`,`token`),
  UNIQUE KEY `by_profile` (`profile_id`),
  KEY `by_account_display` (`account_id`,`display_name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `parties_product_categories` (
  `party_id` int(11) default NULL,
  `product_category_id` int(11) default NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `party_domain_points` (
  `id` int(11) NOT NULL auto_increment,
  `account_id` int(11) default NULL,
  `domain_id` int(11) default NULL,
  `party_id` int(11) default NULL,
  `own_point` int(11) default '0',
  `referrals_point` int(11) default '0',
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `payables` (
  `id` int(11) NOT NULL auto_increment,
  `account_id` int(11) default NULL,
  `payment_id` int(11) default NULL,
  `subject_id` int(11) default NULL,
  `subject_type` varchar(255) default NULL,
  `amount_cents` int(11) default NULL,
  `amount_currency` varchar(4) default NULL,
  `created_at` datetime default NULL,
  `created_by_id` int(11) default NULL,
  `created_by_name` varchar(255) default NULL,
  `updated_at` datetime default NULL,
  `updated_by_id` int(11) default NULL,
  `updated_by_name` varchar(255) default NULL,
  `voided_at` datetime default NULL,
  `voided_by_id` int(11) default NULL,
  `voided_by_name` varchar(255) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `payment_plans` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(100) default NULL,
  `description` varchar(255) default NULL,
  `duration_in_seconds` int(8) default NULL,
  `amount_in_cents` int(8) default NULL,
  `disabled_at` datetime default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `payment_terms` (
  `id` int(11) NOT NULL auto_increment,
  `account_id` int(11) default NULL,
  `parent_id` int(11) default NULL,
  `percent` int(11) default NULL,
  `days` int(11) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `payment_transitions` (
  `id` int(11) NOT NULL auto_increment,
  `account_id` int(11) default NULL,
  `payment_id` int(11) default NULL,
  `action` varchar(255) default NULL,
  `success` tinyint(1) default NULL,
  `external_reference_number` varchar(255) default NULL,
  `response_message` text,
  `response_data` text,
  `ipn_request_headers` text,
  `ipn_request_parameters` text,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  `created_by_id` int(11) default NULL,
  `created_by_name` varchar(255) default NULL,
  `from_state` varchar(255) default NULL,
  `to_state` varchar(255) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `payments` (
  `id` int(11) NOT NULL auto_increment,
  `amount_cents` int(11) default NULL,
  `ever_failed` tinyint(1) NOT NULL default '0',
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  `account_id` int(11) default NULL,
  `amount_currency` varchar(4) default NULL,
  `payment_method` varchar(255) default NULL,
  `description` varchar(255) default NULL,
  `state` varchar(255) default 'pending',
  `payer_id` int(11) default NULL,
  PRIMARY KEY  (`id`),
  KEY `by_invoice_timeline` (`created_at`),
  KEY `by_timeline` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `permission_denials` (
  `id` int(11) NOT NULL auto_increment,
  `subject_id` int(11) default NULL,
  `subject_type` varchar(255) default NULL,
  `assignee_id` int(11) default NULL,
  `assignee_type` varchar(255) default NULL,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `by_assignee_subject` (`assignee_type`,`assignee_id`,`subject_type`,`subject_id`),
  UNIQUE KEY `by_subject_assignee` (`subject_type`,`subject_id`,`assignee_type`,`assignee_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `permission_grants` (
  `assignee_id` int(11) default NULL,
  `subject_id` int(11) default NULL,
  `assignee_type` varchar(255) default NULL,
  `id` int(11) NOT NULL auto_increment,
  `subject_type` varchar(255) default NULL,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `by_assignee_subject` (`assignee_type`,`assignee_id`,`subject_type`,`subject_id`),
  UNIQUE KEY `by_subject_assignee` (`subject_type`,`subject_id`,`assignee_type`,`assignee_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `permissions` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(80) default '',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `permissions_name_index` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `polygons` (
  `id` int(11) NOT NULL auto_increment,
  `account_id` int(11) default NULL,
  `owner_id` int(11) default NULL,
  `points` text,
  `name` varchar(255) default NULL,
  `description` text,
  `updated_at` datetime default NULL,
  `owner_type` varchar(255) default NULL,
  `open` tinyint(1) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `product_categories` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(60) default NULL,
  `parent_id` int(11) default NULL,
  `avatar_id` int(11) default NULL,
  `account_id` int(11) default NULL,
  `description` text,
  `web_copy` text,
  `private` tinyint(1) default '0',
  `label` varchar(255) default NULL,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `parent_id` (`parent_id`,`name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `product_categories_products` (
  `product_id` int(11) NOT NULL default '0',
  `product_category_id` int(11) NOT NULL default '0',
  UNIQUE KEY `product_categories_products_product_id_index` (`product_id`,`product_category_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `product_items` (
  `id` int(11) NOT NULL auto_increment,
  `item_type` varchar(255) default NULL,
  `item_id` int(11) default NULL,
  `product_id` int(11) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `products` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(255) default '',
  `description` text,
  `wholesale_price_cents` int(11) default NULL,
  `account_id` int(11) default NULL,
  `retail_price_cents` int(11) default NULL,
  `in_stock` int(11) default '0',
  `last_ordered_at` datetime default NULL,
  `model` varchar(30) default NULL,
  `upc` varchar(30) default NULL,
  `isbn` varchar(30) default NULL,
  `rfid` varchar(30) default NULL,
  `margin` decimal(6,3) default '0.000',
  `sold_to_date` int(11) default '0',
  `most_recent_supplier_id` int(11) default NULL,
  `on_order` int(11) default '0',
  `web_copy` text,
  `use_db_data` tinyint(1) default '0',
  `add_relations` tinyint(1) default '0',
  `show_discount` tinyint(1) default '0',
  `bulk_rates` text,
  `auto_generate_po_at_threshold` tinyint(1) default '0',
  `auto_generate_po_mode` varchar(255) default NULL,
  `threshold` int(11) default NULL,
  `wholesale_peak_price_cents` int(11) default NULL,
  `wholesale_low_price_cents` int(11) default NULL,
  `created_at` datetime default NULL,
  `creator_id` int(11) default NULL,
  `creator_name` varchar(255) default NULL,
  `updated_at` datetime default NULL,
  `editor_id` int(11) default NULL,
  `editor_name` varchar(255) default NULL,
  `domain_patterns` varchar(255) default NULL,
  `most_recent_supplier_name` varchar(255) default NULL,
  `discount_internet_orders` tinyint(1) default '0',
  `internet_discount` decimal(6,3) default '0.000',
  `sku` varchar(255) default NULL,
  `retail_price_currency` varchar(255) default NULL,
  `wholesale_price_currency` varchar(255) default NULL,
  `wholesale_peak_price_currency` varchar(255) default NULL,
  `wholesale_low_price_currency` varchar(255) default NULL,
  `free_period_length` int(11) default NULL,
  `free_period_unit` varchar(8) default NULL,
  `pay_period_length` int(11) default NULL,
  `pay_period_unit` varchar(8) default NULL,
  `classification` varchar(20) default 'product',
  `average_rating` decimal(5,3) NOT NULL default '0.000',
  `hide_comments` tinyint(1) default '0',
  `deactivate_commenting_on` date default NULL,
  `comment_approval_method` varchar(255) default NULL,
  `owner_id` int(11) default NULL,
  `private` tinyint(1) default '0',
  PRIMARY KEY  (`id`),
  KEY `by_account_sku` (`account_id`,`sku`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `profile_requests` (
  `id` int(11) NOT NULL auto_increment,
  `first_name` varchar(255) default NULL,
  `middle_name` varchar(255) default NULL,
  `last_name` varchar(255) default NULL,
  `company_name` varchar(255) default NULL,
  `position` varchar(255) default NULL,
  `honorific` varchar(255) default NULL,
  `avatar_id` int(11) default NULL,
  `created_at` datetime default NULL,
  `account_id` int(11) default NULL,
  `info` text,
  `type` varchar(255) default NULL,
  `approved_at` datetime default NULL,
  `profile_id` int(11) default NULL,
  `created_by_id` int(11) default NULL,
  `group_ids` varchar(255) default NULL,
  `confirmation_url` varchar(255) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `profiles` (
  `id` int(11) NOT NULL auto_increment,
  `first_name` varchar(255) default NULL,
  `middle_name` varchar(255) default NULL,
  `last_name` varchar(255) default NULL,
  `display_name` varchar(255) default NULL,
  `company_name` varchar(255) default NULL,
  `position` varchar(255) default NULL,
  `honorific` varchar(255) default NULL,
  `alias` varchar(255) default NULL,
  `signature` text,
  `avatar_id` int(11) default NULL,
  `birthdate_day` int(11) default NULL,
  `birthdate_month` int(11) default NULL,
  `birthdate_year` int(11) default NULL,
  `info` text,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  `account_id` int(11) default NULL,
  `average_rating` decimal(5,3) NOT NULL default '0.000',
  `hide_comments` tinyint(1) default '0',
  `deactivate_commenting_on` date default NULL,
  `comment_approval_method` varchar(255) default NULL,
  `claimable` tinyint(1) default '0',
  `owner_id` int(11) default NULL,
  `custom_url` varchar(255) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `providers` (
  `id` int(11) NOT NULL auto_increment,
  `supplier_id` int(11) default NULL,
  `product_id` int(11) default NULL,
  `last_po_at` datetime default NULL,
  `sku` varchar(255) default NULL,
  `wholesale_price_cents` int(11) default NULL,
  `account_id` int(11) default NULL,
  `wholesale_price_currency` varchar(255) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `recipients` (
  `id` int(11) NOT NULL auto_increment,
  `email_id` int(11) default NULL,
  `party_id` int(11) default NULL,
  `sent_at` datetime default NULL,
  `read_at` datetime default NULL,
  `address` varchar(255) default NULL,
  `extras` text,
  `generated_subject` varchar(255) default NULL,
  `generated_body` text,
  `account_id` int(11) default NULL,
  `name` varchar(512) default NULL,
  `type` varchar(255) default NULL,
  `recipient_builder_id` int(11) default NULL,
  `recipient_builder_type` varchar(255) default NULL,
  `tag_syntax` varchar(255) default NULL,
  `uuid` varchar(40) default NULL,
  `errored_at` datetime default NULL,
  `error_count` int(11) default '0',
  `error_backtrace` text,
  `inactive` tinyint(1) default '0',
  PRIMARY KEY  (`id`),
  KEY `by_party_type_email` (`party_id`,`type`,`email_id`),
  KEY `by_email_type` (`email_id`,`type`),
  KEY `by_party_read_email` (`party_id`,`read_at`,`email_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `referrals` (
  `id` int(11) NOT NULL auto_increment,
  `account_id` int(11) default NULL,
  `email_id` int(11) default NULL,
  `parent_id` int(11) default NULL,
  `party_id` int(11) default NULL,
  `uuid` varchar(255) default NULL,
  `created_at` datetime default NULL,
  `referral_url` varchar(255) default NULL,
  `reference_id` int(11) default NULL,
  `reference_type` varchar(255) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `reports` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(255) default NULL,
  `description` varchar(255) default NULL,
  `model` varchar(40) default NULL,
  `saved_at` datetime default NULL,
  `lines` text,
  `owner_id` int(11) default NULL,
  `account_id` int(11) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `rets_metadatas` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(255) default NULL,
  `version` varchar(20) default NULL,
  `date` date default NULL,
  `values` longtext,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `index_rets_metadatas_on_name_and_date_and_version` (`name`,`date`,`version`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `roles` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(255) default NULL,
  `parent_id` int(11) default NULL,
  `created_at` datetime default NULL,
  `created_by_id` int(11) default NULL,
  `updated_at` datetime default NULL,
  `updated_by_id` int(11) default NULL,
  `account_id` int(11) NOT NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `sale_event_items` (
  `id` int(11) NOT NULL auto_increment,
  `sale_event_id` int(11) default NULL,
  `discount` decimal(6,3) default '0.000',
  `margin` decimal(6,3) default '0.000',
  `item_type` varchar(255) default NULL,
  `item_id` int(11) default NULL,
  `type` varchar(255) default NULL,
  `account_id` int(11) default NULL,
  `sale_price_cents` int(11) default '0',
  `sale_price_currency` varchar(4) default 'CAD',
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `sale_events` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(255) default NULL,
  `description` text,
  `web_copy` text,
  `starts_at` datetime default NULL,
  `ends_at` datetime default NULL,
  `average_discount` decimal(6,3) default '0.000',
  `average_margin` decimal(6,3) default '0.000',
  `total_sales` int(11) default '0',
  `total_profit` int(11) default '0',
  `total_products` int(11) default '0',
  `affiliate_stack` tinyint(1) default '0',
  `use_db_data` tinyint(1) default '0',
  `apply_to_internet` tinyint(1) default '0',
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  `creator_id` int(11) default NULL,
  `editor_id` int(11) default NULL,
  `creator_name` varchar(255) default NULL,
  `editor_name` varchar(255) default NULL,
  `account_id` int(11) default NULL,
  `domain_patterns` text,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `schema_migrations` (
  `version` varchar(255) NOT NULL,
  UNIQUE KEY `unique_schema_migrations` (`version`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `search_lines` (
  `id` int(11) NOT NULL auto_increment,
  `subject_name` varchar(40) default NULL,
  `subject_option` varchar(40) default NULL,
  `subject_value` varchar(40) default NULL,
  `subject_exclude` tinyint(1) default NULL,
  `priority` int(8) default NULL,
  `search_id` int(8) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `searches` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(40) default NULL,
  `description` varchar(200) default NULL,
  `party_id` int(8) default NULL,
  `account_id` int(11) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `sessions` (
  `id` int(11) NOT NULL auto_increment,
  `sessid` varchar(32) NOT NULL default '',
  `data` text,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `sessid` (`sessid`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `sort_lines` (
  `id` int(11) NOT NULL auto_increment,
  `order_name` varchar(40) default NULL,
  `order_mode` varchar(5) default NULL,
  `priority` int(8) default NULL,
  `search_id` int(8) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `steps` (
  `id` int(11) NOT NULL auto_increment,
  `account_id` int(11) default NULL,
  `workflow_id` int(11) default NULL,
  `title` varchar(255) default NULL,
  `description` text,
  `position` int(11) default '0',
  `model_class_name` varchar(80) default NULL,
  `lines` text,
  `last_run_at` datetime NOT NULL default '1970-01-01 00:00:00',
  `interval_length` int(11) NOT NULL default '5',
  `interval_unit` varchar(8) NOT NULL default 'minutes',
  `activated_at` datetime default NULL,
  `disabled_at` datetime default NULL,
  `uuid` varchar(36) default NULL,
  PRIMARY KEY  (`id`),
  KEY `by_last_run_at` (`last_run_at`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `subscriptions` (
  `id` int(11) NOT NULL auto_increment,
  `next_renewal_at` datetime default NULL,
  `renewal_period_unit` varchar(255) default NULL,
  `renewal_period_length` int(11) default NULL,
  `account_id` int(11) default NULL,
  `payer_id` int(11) default NULL,
  `subject_type` varchar(255) default NULL,
  `subject_id` int(11) default NULL,
  `authorization_code` varchar(255) default NULL,
  `payment_method` varchar(255) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `suppliers` (
  `id` int(11) NOT NULL auto_increment,
  `entity_id` int(11) default NULL,
  `average_delivery_time` int(11) default NULL,
  `average_margin` decimal(6,3) default '0.000',
  `last_order_at` datetime default NULL,
  `last_delivery_at` datetime default NULL,
  `threshold_products` int(11) default NULL,
  `current_po_status` varchar(255) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  `creator_id` int(11) default NULL,
  `editor_id` int(11) default NULL,
  `creator_name` varchar(255) default NULL,
  `editor_name` varchar(255) default NULL,
  `account_id` int(11) default NULL,
  `total_products` int(11) default '0',
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `taggings` (
  `id` int(11) NOT NULL auto_increment,
  `tag_id` int(11) NOT NULL,
  `taggable_type` varchar(255) NOT NULL default '',
  `taggable_id` int(11) NOT NULL,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `taggings_tag_id_index` (`tag_id`,`taggable_type`,`taggable_id`),
  UNIQUE KEY `taggings_taggable_type_index` (`taggable_type`,`taggable_id`,`tag_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `tags` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(80) NOT NULL default '',
  `account_id` int(11) default NULL,
  `system` tinyint(1) default '0',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `by_account_name` (`account_id`,`name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `tasks` (
  `id` int(11) NOT NULL auto_increment,
  `account_id` int(11) default NULL,
  `step_id` int(11) default NULL,
  `type` varchar(255) default NULL,
  `data` text,
  `position` int(11) default '0',
  `uuid` varchar(36) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `teams` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(40) NOT NULL default '',
  `account_id` int(11) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `templates` (
  `id` int(11) NOT NULL auto_increment,
  `subject` varchar(255) default NULL,
  `body` text,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  `party_id` int(11) default NULL,
  `account_id` int(11) default NULL,
  `label` varchar(255) default NULL,
  `description` varchar(255) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `testimonials` (
  `id` int(11) NOT NULL auto_increment,
  `author_id` int(11) default NULL,
  `testified_at` datetime default NULL,
  `body` text,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `approved_at` datetime default NULL,
  `rejected_at` datetime default NULL,
  `account_id` int(11) default NULL,
  `domain_patterns` varchar(255) default NULL,
  `created_by_id` int(11) default NULL,
  `updated_by_id` int(11) default NULL,
  `approved_by_id` int(11) default NULL,
  `rejected_by_id` int(11) default NULL,
  `phone_number` varchar(255) default NULL,
  `website_url` varchar(255) default NULL,
  `email_address` varchar(255) default NULL,
  `author_name` varchar(255) default NULL,
  `author_company_name` varchar(255) default NULL,
  `avatar_id` int(11) default NULL,
  `show_avatar` tinyint(1) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `timelines` (
  `id` int(11) NOT NULL auto_increment,
  `account_id` int(11) default NULL,
  `subject_type` varchar(60) default NULL,
  `subject_id` int(11) default NULL,
  `action` varchar(20) default NULL,
  `created_at` datetime default NULL,
  PRIMARY KEY  (`id`),
  KEY `by_account_created_subject` (`account_id`,`created_at`,`subject_type`,`subject_id`),
  KEY `by_account_subject_created` (`account_id`,`subject_type`,`subject_id`,`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `views` (
  `id` int(11) NOT NULL auto_increment,
  `attachable_id` int(11) default NULL,
  `position` int(11) default NULL,
  `name` varchar(255) default NULL,
  `description` text,
  `asset_id` int(11) default NULL,
  `attachable_type` varchar(255) default NULL,
  `classification` varchar(255) default 'Image',
  PRIMARY KEY  (`id`),
  KEY `by_attachable_classification_position` (`attachable_type`,`attachable_id`,`classification`,`position`),
  KEY `by_asset_attachable` (`asset_id`,`attachable_type`,`attachable_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `workflows` (
  `id` int(11) NOT NULL auto_increment,
  `account_id` int(11) default NULL,
  `title` varchar(255) default NULL,
  `description` text,
  `creator_id` int(11) default NULL,
  `updator_id` int(11) default NULL,
  `uuid` varchar(36) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

INSERT INTO schema_migrations (version) VALUES ('1218126998');

INSERT INTO schema_migrations (version) VALUES ('1218227435');

INSERT INTO schema_migrations (version) VALUES ('1218230628');

INSERT INTO schema_migrations (version) VALUES ('1218481066');

INSERT INTO schema_migrations (version) VALUES ('1218483777');

INSERT INTO schema_migrations (version) VALUES ('1218495194');

INSERT INTO schema_migrations (version) VALUES ('1218565841');

INSERT INTO schema_migrations (version) VALUES ('1222983535');

INSERT INTO schema_migrations (version) VALUES ('1223072025');

INSERT INTO schema_migrations (version) VALUES ('20081002193856');

INSERT INTO schema_migrations (version) VALUES ('20081006181906');

INSERT INTO schema_migrations (version) VALUES ('20081006182459');

INSERT INTO schema_migrations (version) VALUES ('20081009210216');

INSERT INTO schema_migrations (version) VALUES ('20081010222116');

INSERT INTO schema_migrations (version) VALUES ('20081011000716');

INSERT INTO schema_migrations (version) VALUES ('20081015005724');

INSERT INTO schema_migrations (version) VALUES ('20081017003908');

INSERT INTO schema_migrations (version) VALUES ('20081017004936');

INSERT INTO schema_migrations (version) VALUES ('20081017223916');

INSERT INTO schema_migrations (version) VALUES ('20081018000052');

INSERT INTO schema_migrations (version) VALUES ('20081018003537');

INSERT INTO schema_migrations (version) VALUES ('20081018004825');

INSERT INTO schema_migrations (version) VALUES ('20081021184643');

INSERT INTO schema_migrations (version) VALUES ('20081022204658');

INSERT INTO schema_migrations (version) VALUES ('20081022214114');

INSERT INTO schema_migrations (version) VALUES ('20081022222708');

INSERT INTO schema_migrations (version) VALUES ('20081023005526');

INSERT INTO schema_migrations (version) VALUES ('20081023181121');

INSERT INTO schema_migrations (version) VALUES ('20081023185816');

INSERT INTO schema_migrations (version) VALUES ('20081023192945');

INSERT INTO schema_migrations (version) VALUES ('20081023193418');

INSERT INTO schema_migrations (version) VALUES ('20081023194324');

INSERT INTO schema_migrations (version) VALUES ('20081023210055');

INSERT INTO schema_migrations (version) VALUES ('20081023211438');

INSERT INTO schema_migrations (version) VALUES ('20081023211828');

INSERT INTO schema_migrations (version) VALUES ('20081023212837');

INSERT INTO schema_migrations (version) VALUES ('20081024012423');

INSERT INTO schema_migrations (version) VALUES ('20081024133524');

INSERT INTO schema_migrations (version) VALUES ('20081024133711');

INSERT INTO schema_migrations (version) VALUES ('20081024174344');

INSERT INTO schema_migrations (version) VALUES ('20081024180436');

INSERT INTO schema_migrations (version) VALUES ('20081024214427');

INSERT INTO schema_migrations (version) VALUES ('20081025013011');

INSERT INTO schema_migrations (version) VALUES ('20081025013202');

INSERT INTO schema_migrations (version) VALUES ('20081028011247');

INSERT INTO schema_migrations (version) VALUES ('20081028184103');

INSERT INTO schema_migrations (version) VALUES ('20081028224443');

INSERT INTO schema_migrations (version) VALUES ('20081029003634');

INSERT INTO schema_migrations (version) VALUES ('20081029055246');

INSERT INTO schema_migrations (version) VALUES ('20081029183130');

INSERT INTO schema_migrations (version) VALUES ('20081029185009');

INSERT INTO schema_migrations (version) VALUES ('20081029214403');

INSERT INTO schema_migrations (version) VALUES ('20081029220720');

INSERT INTO schema_migrations (version) VALUES ('20081030013609');

INSERT INTO schema_migrations (version) VALUES ('20081104214535');

INSERT INTO schema_migrations (version) VALUES ('20081106005906');

INSERT INTO schema_migrations (version) VALUES ('20081106213538');

INSERT INTO schema_migrations (version) VALUES ('20081106222140');

INSERT INTO schema_migrations (version) VALUES ('20081106232958');

INSERT INTO schema_migrations (version) VALUES ('20081106235943');

INSERT INTO schema_migrations (version) VALUES ('20081108013212');

INSERT INTO schema_migrations (version) VALUES ('20081108020528');

INSERT INTO schema_migrations (version) VALUES ('20081113202912');

INSERT INTO schema_migrations (version) VALUES ('20081113211556');

INSERT INTO schema_migrations (version) VALUES ('20081113214658');

INSERT INTO schema_migrations (version) VALUES ('20081115015126');

INSERT INTO schema_migrations (version) VALUES ('20081117192950');

INSERT INTO schema_migrations (version) VALUES ('20081119163753');

INSERT INTO schema_migrations (version) VALUES ('20081120005756');

INSERT INTO schema_migrations (version) VALUES ('20081121001029');

INSERT INTO schema_migrations (version) VALUES ('20081121002447');

INSERT INTO schema_migrations (version) VALUES ('20081121194733');

INSERT INTO schema_migrations (version) VALUES ('20081121195344');

INSERT INTO schema_migrations (version) VALUES ('20081124214512');

INSERT INTO schema_migrations (version) VALUES ('20081125014150');

INSERT INTO schema_migrations (version) VALUES ('20081125030022');

INSERT INTO schema_migrations (version) VALUES ('20081125231035');

INSERT INTO schema_migrations (version) VALUES ('20081125232632');

INSERT INTO schema_migrations (version) VALUES ('20081125235330');

INSERT INTO schema_migrations (version) VALUES ('20081126001155');

INSERT INTO schema_migrations (version) VALUES ('20081126004328');

INSERT INTO schema_migrations (version) VALUES ('20081126222051');

INSERT INTO schema_migrations (version) VALUES ('20081127020513');

INSERT INTO schema_migrations (version) VALUES ('20081127022629');

INSERT INTO schema_migrations (version) VALUES ('20081127204014');

INSERT INTO schema_migrations (version) VALUES ('20081128205421');

INSERT INTO schema_migrations (version) VALUES ('20081128214110');

INSERT INTO schema_migrations (version) VALUES ('20081128221610');

INSERT INTO schema_migrations (version) VALUES ('20081128223859');

INSERT INTO schema_migrations (version) VALUES ('20081202223739');

INSERT INTO schema_migrations (version) VALUES ('20081202225821');

INSERT INTO schema_migrations (version) VALUES ('20081208235252');

INSERT INTO schema_migrations (version) VALUES ('20081209194737');

INSERT INTO schema_migrations (version) VALUES ('20081209232051');

INSERT INTO schema_migrations (version) VALUES ('20081210024608');

INSERT INTO schema_migrations (version) VALUES ('20081216221601');

INSERT INTO schema_migrations (version) VALUES ('20081216223737');

INSERT INTO schema_migrations (version) VALUES ('20081217013436');

INSERT INTO schema_migrations (version) VALUES ('20081217031213');

INSERT INTO schema_migrations (version) VALUES ('20090107010636');

INSERT INTO schema_migrations (version) VALUES ('20090107195147');

INSERT INTO schema_migrations (version) VALUES ('20090108221122');

INSERT INTO schema_migrations (version) VALUES ('20090113211224');

INSERT INTO schema_migrations (version) VALUES ('20090117004730');

INSERT INTO schema_migrations (version) VALUES ('20090120013212');

INSERT INTO schema_migrations (version) VALUES ('20090122013019');

INSERT INTO schema_migrations (version) VALUES ('20090122214535');

INSERT INTO schema_migrations (version) VALUES ('20090123014136');

INSERT INTO schema_migrations (version) VALUES ('20090123014534');

INSERT INTO schema_migrations (version) VALUES ('20090123015151');

INSERT INTO schema_migrations (version) VALUES ('20090123020000');

INSERT INTO schema_migrations (version) VALUES ('20090123021742');

INSERT INTO schema_migrations (version) VALUES ('20090123200335');

INSERT INTO schema_migrations (version) VALUES ('20090124032908');

INSERT INTO schema_migrations (version) VALUES ('20090126215437');

INSERT INTO schema_migrations (version) VALUES ('20090128020200');

INSERT INTO schema_migrations (version) VALUES ('20090128021359');

INSERT INTO schema_migrations (version) VALUES ('20090128023709');

INSERT INTO schema_migrations (version) VALUES ('20090128031657');

INSERT INTO schema_migrations (version) VALUES ('20090128232952');

INSERT INTO schema_migrations (version) VALUES ('20090128233501');

INSERT INTO schema_migrations (version) VALUES ('20090128234259');

INSERT INTO schema_migrations (version) VALUES ('20090128235946');

INSERT INTO schema_migrations (version) VALUES ('20090129001745');

INSERT INTO schema_migrations (version) VALUES ('20090130012655');

INSERT INTO schema_migrations (version) VALUES ('20090130200238');

INSERT INTO schema_migrations (version) VALUES ('20090130200921');

INSERT INTO schema_migrations (version) VALUES ('20090131010205');

INSERT INTO schema_migrations (version) VALUES ('20090131011024');

INSERT INTO schema_migrations (version) VALUES ('20090202223747');

INSERT INTO schema_migrations (version) VALUES ('20090203225141');

INSERT INTO schema_migrations (version) VALUES ('20090204004543');

INSERT INTO schema_migrations (version) VALUES ('20090205012831');

INSERT INTO schema_migrations (version) VALUES ('20090206232135');

INSERT INTO schema_migrations (version) VALUES ('20090206233240');

INSERT INTO schema_migrations (version) VALUES ('20090207030015');

INSERT INTO schema_migrations (version) VALUES ('20090210011853');

INSERT INTO schema_migrations (version) VALUES ('20090210020042');

INSERT INTO schema_migrations (version) VALUES ('20090210032328');

INSERT INTO schema_migrations (version) VALUES ('20090210225259');

INSERT INTO schema_migrations (version) VALUES ('20090214021609');

INSERT INTO schema_migrations (version) VALUES ('20090214023103');

INSERT INTO schema_migrations (version) VALUES ('20090214025154');

INSERT INTO schema_migrations (version) VALUES ('20090216224845');

INSERT INTO schema_migrations (version) VALUES ('20090218023301');

INSERT INTO schema_migrations (version) VALUES ('20090218024250');

INSERT INTO schema_migrations (version) VALUES ('20090218212658');

INSERT INTO schema_migrations (version) VALUES ('20090218214721');

INSERT INTO schema_migrations (version) VALUES ('20090218234431');

INSERT INTO schema_migrations (version) VALUES ('20090220213223');

INSERT INTO schema_migrations (version) VALUES ('20090220230041');

INSERT INTO schema_migrations (version) VALUES ('20090221014507');

INSERT INTO schema_migrations (version) VALUES ('20090221015919');

INSERT INTO schema_migrations (version) VALUES ('20090225235741');

INSERT INTO schema_migrations (version) VALUES ('20090227005854');

INSERT INTO schema_migrations (version) VALUES ('20090227222622');

INSERT INTO schema_migrations (version) VALUES ('20090228022633');

INSERT INTO schema_migrations (version) VALUES ('20090303083314');

INSERT INTO schema_migrations (version) VALUES ('20090303220116');

INSERT INTO schema_migrations (version) VALUES ('20090307011522');

INSERT INTO schema_migrations (version) VALUES ('20090307020749');

INSERT INTO schema_migrations (version) VALUES ('20090307020902');

INSERT INTO schema_migrations (version) VALUES ('20090307023541');

INSERT INTO schema_migrations (version) VALUES ('20090307023649');

INSERT INTO schema_migrations (version) VALUES ('20090309193850');

INSERT INTO schema_migrations (version) VALUES ('20090311202847');

INSERT INTO schema_migrations (version) VALUES ('20090318231709');

INSERT INTO schema_migrations (version) VALUES ('20090318235548');

INSERT INTO schema_migrations (version) VALUES ('20090319004439');

INSERT INTO schema_migrations (version) VALUES ('20090319215310');

INSERT INTO schema_migrations (version) VALUES ('20090319224202');

INSERT INTO schema_migrations (version) VALUES ('20090319225335');

INSERT INTO schema_migrations (version) VALUES ('20090319225625');

INSERT INTO schema_migrations (version) VALUES ('20090319225957');

INSERT INTO schema_migrations (version) VALUES ('20090320004305');

INSERT INTO schema_migrations (version) VALUES ('20090320005139');

INSERT INTO schema_migrations (version) VALUES ('20090320232259');

INSERT INTO schema_migrations (version) VALUES ('20090320234347');

INSERT INTO schema_migrations (version) VALUES ('20090321012653');

INSERT INTO schema_migrations (version) VALUES ('20090323224839');

INSERT INTO schema_migrations (version) VALUES ('20090324005956');

INSERT INTO schema_migrations (version) VALUES ('20090326235757');