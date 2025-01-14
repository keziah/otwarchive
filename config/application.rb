require File.expand_path("boot", __dir__)

require "rails/all"

# If you have a Gemfile, require the gems listed there, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Otwarchive
  class Application < Rails::Application
    app_config = YAML.load_file(Rails.root.join("config/config.yml"))
    app_config.merge!(YAML.load_file(Rails.root.join("config/local.yml"))) if File.exist?(Rails.root.join("config/local.yml"))
    ::ArchiveConfig = OpenStruct.new(app_config)

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    # config.autoload_paths += %W(#{config.root}/extras)
    config.eager_load_paths += [Rails.root.join("lib")]
    config.autoload_paths += [Rails.root.join("app/sweepers")]
    %w[
      challenge_models
      tagset_models
      indexing
      search
      feedback_reporters
      potential_matcher
    ].each do |dir|
      config.autoload_paths << Rails.root.join("app/models/#{dir}")
    end

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]
    config.plugins = [:all]

    # I18n validation deprecation warning fix
    #

    I18n.config.enforce_available_locales = false
    I18n.config.available_locales = [
      :en, :af, :ar, :bg, :bn, :ca, :cs, :cy, :da, :de, :el, :es, :fa, :fi,
      :fil, :fr, :he, :hi, :hr, :hu, :id, :it, :ja, :ko, :ky, :lt, :lv, :mk,
      :mr, :ms, :nb, :nl, :pl, :"pt-BR", :"pt-PT", :ro, :ru, :sk, :sl, :sr, :sv,
      :th, :tr, :uk, :vi, :"zh-CN"
    ]

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'
    config.time_zone = "Eastern Time (US & Canada)"

    # The default locale is :en and all translations from config/locales/**/*.rb,yml are auto loaded.
    config.i18n.load_path += Dir[Rails.root.join("config/locales/**/*.{rb,yml}")]
    # config.i18n.default_locale = :de

    # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
    # the I18n.default_locale when a translation can not be found)
    config.i18n.fallbacks = true

    # JavaScript files you want as :defaults (application.js is always included).
    # config.action_view.javascript_expansions[:defaults] = %w(jquery rails)

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    config.action_view.automatically_disable_submit_tag = false

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:content, :password, :terms_of_service_non_production]

    # Disable dumping schemas after migrations.
    config.active_record.dump_schema_after_migration = false

    # Use SQL instead of Active Record's schema dumper when creating the test database.
    # This is necessary if your schema can't be completely dumped by the schema dumper,
    # like if you have constraints or database-specific column types
    config.active_record.schema_format = :sql

    # handle errors with custom error pages:
    config.exceptions_app = self.routes

    # Bring the log under control
    config.lograge.enabled = true

    # Only send referrer information to ourselves
    config.action_dispatch.default_headers = {
      "Referrer-Policy" => "strict-origin-when-cross-origin",
      "X-Frame-Options" => "SAMEORIGIN",
      "X-XSS-Protection" => "1; mode=block",
      "X-Content-Type-Options" => "nosniff",
      "X-Download-Options" => "noopen",
      "X-Permitted-Cross-Domain-Policies" => "none"
    }

    # Use Resque to run ActiveJobs (including sending delayed mail):
    config.active_job.queue_adapter = :resque

    config.action_mailer.default_url_options = { host: ArchiveConfig.APP_HOST }

    # Use "mailer" instead of "mailers" as the Resque queue for emails:
    config.action_mailer.deliver_later_queue_name = :mailer

    config.action_mailer.delivery_method = :smtp
    config.action_mailer.smtp_settings = {
      address: ArchiveConfig.SMTP_SERVER,
      domain: ArchiveConfig.SMTP_DOMAIN,
      port: ArchiveConfig.SMTP_PORT,
      enable_starttls_auto: ArchiveConfig.SMTP_ENABLE_STARTTLS_AUTO,
      openssl_verify_mode: ArchiveConfig.SMTP_OPENSSL_VERIFY_MODE
    }
    if ArchiveConfig.SMTP_AUTHENTICATION
      config.action_mailer.smtp_settings.merge!({
                                                  user_name: ArchiveConfig.SMTP_USER,
                                                  password: ArchiveConfig.SMTP_PASSWORD,
                                                  authentication: ArchiveConfig.SMTP_AUTHENTICATION
                                                })
    end

    # Use URL safe CSRF due to a bug in Rails v5.2.5 release.  See the v5.2.6 release notes:
    # https://github.com/rails/rails/blob/5-2-stable/actionpack/CHANGELOG.md
    config.action_controller.urlsafe_csrf_tokens = true
  end
end
