SushiFabric::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # Code is not reloaded between requests
  config.cache_classes = true

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local       = false
  config.action_controller ||= ActiveSupport::OrderedOptions.new
  config.action_controller.perform_caching = true

  # Disable Rails's static asset server (Apache or nginx will already do this)
  #config.serve_static_assets = false
  #config.serve_static_assets = true
  config.serve_static_files = true

  # Compress JavaScripts and CSS
  # config.assets.compress = true

  # Don't fallback to assets pipeline if a precompiled asset is missed
  # config.assets.compile = true

  # Generate digests for assets URLs
  # config.assets.digest = true

  # Defaults to nil and saved in location specified by config.assets.prefix
  # config.assets.manifest = YOUR_PATH

  # Specifies the header that your server uses for sending files
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for nginx

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # config.force_ssl = true

  # See everything in the log (default is :info)
  # config.log_level = :debug

  # Prepend all log lines with the following tags
  # config.log_tags = [ :subdomain, :uuid ]

  # Use a different logger for distributed setups
  # config.logger = ActiveSupport::TaggedLogging.new(SyslogLogger.new)

  # Use a different cache store in production
  # config.cache_store = :mem_cache_store
  config.cache_store = :memory_store, { size: 64 * 1024 * 1024 }

  # Enable serving of images, stylesheets, and JavaScripts from an asset server
  # config.action_controller.asset_host = "http://assets.example.com"

  # Precompile additional assets (application.js, application.css, and all non-JS/CSS are already added)
  # config.assets.precompile += %w( search.js )

  # Disable delivery errors, bad email addresses will be ignored
  # config.action_mailer.raise_delivery_errors = false

  # Enable threaded mode
  # config.threadsafe!

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify

  # Log the query plan for queries taking more than this (works
  # with SQLite, MySQL, and PostgreSQL)
  # config.active_record.auto_explain_threshold_in_seconds = 0.5

  config.logger = Logger.new("log/production.log", 5, 10 * 1024 * 1024)
  config.logger.level = Logger::ERROR
  config.log_level = :info
  config.eager_load = true

  def config.fgcz?
    @fgcz ||= (`hostname`.chomp =~ /fgcz/)
  end

  # fgcz
  if config.fgcz?
    #config.workflow_manager = "druby://fgcz-h-036.fgcz-net.unizh.ch:40001" # production, test
    #config.workflow_manager = "druby://fgcz-h-035.fgcz-net.unizh.ch:40001" # demo, course
    config.scratch_dir = "/scratch"
    config.gstore_dir = "/srv/gstore/projects" # production, test
    #config.gstore_dir = "/srv/GT/analysis/course_sushi/public/gstore/projects" # demo, course
    config.sushi_app_dir = Dir.pwd
    config.module_source = "/usr/local/ngseq/etc/lmod_profile"
    config.course_mode = false  # production, demo, test
    #config.course_mode = true   # course
    #config.rails_host = "https://fgcz-sushi.uzh.ch"         # production
    #config.rails_host = "https://fgcz-sushi-demo.uzh.ch"    # demo
    #config.rails_host = "https://fgcz-course1.bfabric.org"  # course1
    #config.rails_host = "https://fgcz-course2.bfabric.org"  # course2
    #config.rails_host = "http://fgcz-h-037.fgcz-net.unizh.ch:4000"  # test
    config.copy_command = "g-req copy"
    config.sushi_server_class = "SushiFabric::TestSushi"
  end

end
