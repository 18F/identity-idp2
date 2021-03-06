class IdentityConfig
  class << self
    attr_reader :store
  end

  CONVERTERS = {
    string: proc { |value| value.to_s },
    comma_separated_string_list: proc do |value|
      value.split(',')
    end,
    integer: proc do |value|
      Integer(value)
    end,
    json: proc do |value, options: {}|
      JSON.parse(value, symbolize_names: options[:symbolize_names])
    end,
    boolean: proc do |value|
      case value
      when 'true', true
        true
      when 'false', false
        false
      else
        raise 'invalid boolean value'
      end
    end,
    date: proc { |value| Date.parse(value) if value },
    timestamp: proc do |value|
      # When the store is built `Time.zone` is not set resulting in a NoMethodError
      # if Time.zone.parse is called
      #
      # rubocop:disable Rails/TimeZone
      Time.parse(value)
      # rubocop:enable Rails/TimeZone
    end,
  }

  def initialize(read_env)
    @read_env = read_env
    @written_env = {}
  end

  def add(key, type: :string, is_sensitive: false, allow_nil: false, options: {})
    value = @read_env[key]

    converted_value = CONVERTERS.fetch(type).call(value, options: options) if !value.nil?
    raise "#{key} is required but is not present" if converted_value.nil? && !allow_nil

    @written_env[key] = converted_value
    @written_env
  end

  attr_reader :written_env

  def self.build_store(config_map)
    config = IdentityConfig.new(config_map)
    config.add(:aamva_auth_request_timeout, type: :integer)
    config.add(:aamva_auth_url, type: :string)
    config.add(:aamva_cert_enabled, type: :boolean)
    config.add(:aamva_private_key, type: :string)
    config.add(:aamva_public_key, type: :string)
    config.add(:aamva_sp_banlist_issuers, type: :json)
    config.add(:aamva_verification_request_timeout, type: :integer)
    config.add(:aamva_verification_url)
    config.add(:account_reset_token_valid_for_days, type: :integer)
    config.add(:account_reset_wait_period_days, type: :integer)
    config.add(:acuant_maintenance_window_start, type: :timestamp, allow_nil: true)
    config.add(:acuant_maintenance_window_finish, type: :timestamp, allow_nil: true)
    config.add(:acuant_assure_id_password)
    config.add(:acuant_assure_id_username)
    config.add(:acuant_assure_id_subscription_id)
    config.add(:acuant_assure_id_url)
    config.add(:acuant_attempt_window_in_minutes, type: :integer)
    config.add(:acuant_facial_match_url)
    config.add(:acuant_max_attempts, type: :integer)
    config.add(:acuant_passlive_url)
    config.add(:acuant_sdk_initialization_creds)
    config.add(:acuant_sdk_initialization_endpoint)
    config.add(:acuant_timeout, type: :integer)
    config.add(:add_email_link_valid_for_hours, type: :integer)
    config.add(:asset_host, type: :string)
    config.add(:async_wait_timeout_seconds, type: :integer)
    config.add(:attribute_encryption_key, type: :string)
    config.add(:attribute_encryption_key_queue, type: :json)
    config.add(:aws_http_retry_limit, type: :integer)
    config.add(:aws_http_retry_max_delay, type: :integer)
    config.add(:aws_http_timeout, type: :integer)
    config.add(:aws_kms_key_id, type: :string)
    config.add(:aws_kms_multi_region_enabled, type: :boolean)
    config.add(:aws_kms_regions, type: :json)
    config.add(:aws_logo_bucket, type: :string)
    config.add(:aws_region, type: :string)
    config.add(:backup_code_cost, type: :string)
    config.add(:backup_code_skip_symmetric_encryption, type: :boolean)
    config.add(:dashboard_api_token, type: :string)
    config.add(:dashboard_url, type: :string)
    config.add(:database_host, type: :string)
    config.add(:database_name, type: :string)
    config.add(:database_readonly_password, type: :string)
    config.add(:database_readonly_username, type: :string)
    config.add(:database_read_replica_host, type: :string)
    config.add(:database_password, type: :string)
    config.add(:database_pool_idp, type: :integer)
    config.add(:database_statement_timeout, type: :integer)
    config.add(:database_timeout, type: :integer)
    config.add(:database_username, type: :string)
    config.add(:deleted_user_accounts_report_configs, type: :json)
    config.add(:disable_email_sending, type: :boolean)
    config.add(:disallow_all_web_crawlers, type: :boolean)
    config.add(:doc_auth_enable_presigned_s3_urls, type: :boolean)
    config.add(:doc_auth_error_dpi_threshold, type: :integer)
    config.add(:doc_auth_error_sharpness_threshold, type: :integer)
    config.add(:doc_auth_error_glare_threshold, type: :integer)
    config.add(:doc_auth_extend_timeout_by_minutes, type: :integer)
    config.add(:doc_auth_vendor, type: :string)
    config.add(:doc_capture_polling_enabled, type: :boolean)
    config.add(:doc_capture_request_valid_for_minutes, type: :integer)
    config.add(:domain_name, type: :string)
    config.add(:email_from, type: :string)
    config.add(:email_from_display_name, type: :string)
    config.add(:enable_load_testing_mode, type: :boolean)
    config.add(:enable_partner_api, type: :boolean)
    config.add(:enable_rate_limiting, type: :boolean)
    config.add(:enable_test_routes, type: :boolean)
    config.add(:enable_usps_verification, type: :boolean)
    config.add(:event_disavowal_expiration_hours, type: :integer)
    config.add(:exception_recipients, type: :comma_separated_string_list)
    config.add(:geo_data_file_path, type: :string)
    config.add(:gpo_designated_receiver_pii, type: :json, options: { symbolize_names: true })
    config.add(:hide_phone_mfa_signup, type: :boolean)
    config.add(:hmac_fingerprinter_key, type: :string)
    config.add(:hmac_fingerprinter_key_queue, type: :json)
    config.add(:identity_pki_disabled, type: :boolean)
    config.add(:identity_pki_local_dev, type: :boolean)
    config.add(:idv_attempt_window_in_hours, type: :integer)
    config.add(:idv_max_attempts, type: :integer)
    config.add(:idv_min_age_years, type: :integer)
    config.add(:idv_send_link_attempt_window_in_minutes, type: :integer)
    config.add(:idv_send_link_max_attempts, type: :integer)
    config.add(:issuers_with_email_nameid_format, type: :comma_separated_string_list)
    config.add(:job_run_healthchecks_enabled, type: :boolean)
    config.add(:lexisnexis_base_url, type: :string)
    config.add(:lexisnexis_request_mode, type: :string)
    config.add(:lexisnexis_account_id, type: :string)
    config.add(:lexisnexis_username, type: :string)
    config.add(:lexisnexis_password, type: :string)
    config.add(:lexisnexis_phone_finder_workflow, type: :string)
    config.add(:lexisnexis_instant_verify_workflow, type: :string)
    config.add(:lexisnexis_timeout, type: :integer)
    config.add(:lexisnexis_trueid_account_id, type: :string)
    config.add(:lexisnexis_trueid_username, type: :string)
    config.add(:lexisnexis_trueid_password, type: :string)
    config.add(:lexisnexis_trueid_liveness_workflow, type: :string)
    config.add(:lexisnexis_trueid_noliveness_workflow, type: :string)
    config.add(:liveness_checking_enabled, type: :boolean)
    config.add(:lockout_period_in_minutes, type: :integer)
    config.add(:log_to_stdout, type: :boolean)
    config.add(:logins_per_email_and_ip_bantime, type: :integer)
    config.add(:logins_per_email_and_ip_limit, type: :integer)
    config.add(:logins_per_email_and_ip_period, type: :integer)
    config.add(:logins_per_ip_limit, type: :integer)
    config.add(:logins_per_ip_period, type: :integer)
    config.add(:logins_per_ip_track_only_mode, type: :boolean)
    config.add(:logo_upload_enabled, type: :boolean)
    config.add(:newrelic_browser_app_id, type: :string)
    config.add(:newrelic_browser_key, type: :string)
    config.add(:newrelic_license_key, type: :string)
    config.add(:mailer_domain_name)
    config.add(:max_auth_apps_per_account, type: :integer)
    config.add(:max_emails_per_account, type: :integer)
    config.add(:max_mail_events, type: :integer)
    config.add(:max_mail_events_window_in_days, type: :integer)
    config.add(:max_piv_cac_per_account, type: :integer)
    config.add(:min_password_score, type: :integer)
    config.add(:mx_timeout, type: :integer)
    config.add(:no_sp_campaigns_whitelist, type: :json)
    config.add(:nonessential_email_banlist, type: :json)
    config.add(:otp_delivery_blocklist_findtime, type: :integer)
    config.add(:otp_delivery_blocklist_maxretry, type: :integer)
    config.add(:otp_valid_for, type: :integer)
    config.add(:otps_per_ip_limit, type: :integer)
    config.add(:otps_per_ip_period, type: :integer)
    config.add(:otps_per_ip_track_only_mode, type: :boolean)
    config.add(:outbound_connection_check_url)
    config.add(:participate_in_dap, type: :boolean)
    config.add(:partner_api_bucket_prefix, type: :string)
    config.add(:password_max_attempts, type: :integer)
    config.add(:password_pepper, type: :string)
    config.add(:personal_key_retired, type: :boolean)
    config.add(:phone_setups_per_ip_limit, type: :integer)
    config.add(:phone_setups_per_ip_period, type: :integer)
    config.add(:pii_lock_timeout_in_minutes, type: :integer)
    config.add(:pinpoint_sms_configs, type: :json)
    config.add(:pinpoint_voice_configs, type: :json)
    config.add(:piv_cac_service_url)
    config.add(:piv_cac_verify_token_secret)
    config.add(:piv_cac_verify_token_url)
    config.add(:phone_setups_per_ip_track_only_mode, type: :boolean)
    config.add(:poll_rate_for_verify_in_seconds, type: :integer)
    config.add(:proofer_mock_fallback, type: :boolean)
    config.add(:proofing_allow_expired_license, type: :boolean)
    config.add(:proofing_expired_license_after, type: :date)
    config.add(:proofing_expired_license_reproof_at, type: :date)
    config.add(:proofing_send_partial_dob, type: :boolean)
    config.add(:push_notifications_enabled, type: :boolean)
    config.add(:pwned_passwords_file_path, type: :string)
    config.add(:rack_mini_profiler, type: :boolean)
    config.add(:rack_timeout_service_timeout_seconds, type: :integer)
    config.add(:reauthn_window, type: :integer)
    config.add(:recovery_code_length, type: :integer)
    config.add(:recurring_jobs_disabled_names, type: :json)
    config.add(:redis_throttle_url)
    config.add(:redis_url)
    config.add(:reg_confirmed_email_max_attempts, type: :integer)
    config.add(:reg_confirmed_email_window_in_minutes, type: :integer)
    config.add(:reg_unconfirmed_email_max_attempts, type: :integer)
    config.add(:reg_unconfirmed_email_window_in_minutes, type: :integer)
    config.add(:remember_device_expiration_hours_aal_1, type: :integer)
    config.add(:remember_device_expiration_hours_aal_2, type: :integer)
    config.add(:report_timeout, type: :integer)
    config.add(:requests_per_ip_limit, type: :integer)
    config.add(:requests_per_ip_period, type: :integer)
    config.add(:requests_per_ip_track_only_mode, type: :boolean)
    config.add(:reset_password_email_max_attempts, type: :integer)
    config.add(:reset_password_email_window_in_minutes, type: :integer)
    config.add(:risc_notifications_local_enabled, type: :boolean)
    config.add(:risc_notifications_eventbridge_enabled, type: :boolean)
    config.add(:ruby_workers_enabled, type: :boolean)
    config.add(:s3_report_bucket_prefix, type: :string)
    config.add(:s3_reports_enabled, type: :boolean)
    config.add(:saml_endpoint_configs, type: :json, options: { symbolize_names: true })
    config.add(:saml_secret_rotation_enabled, type: :boolean)
    config.add(:scrypt_cost, type: :string)
    config.add(:secret_key_base, type: :string)
    config.add(:service_provider_request_ttl_hours, type: :integer)
    config.add(:session_check_delay, type: :integer)
    config.add(:session_check_frequency, type: :integer)
    config.add(:session_encryption_key, type: :string)
    config.add(:session_timeout_in_minutes, type: :integer)
    config.add(:session_timeout_warning_seconds, type: :integer)
    config.add(:session_total_duration_timeout_in_minutes, type: :integer)
    config.add(:show_user_attribute_deprecation_warnings, type: :boolean)
    config.add(:skip_encryption_allowed_list, type: :json)
    config.add(:sp_context_needed_environment, type: :string)
    config.add(:sp_handoff_bounce_max_seconds, type: :integer)
    config.add(:sps_over_quota_limit_notify_email_list, type: :json)
    config.add(:state_tracking_enabled, type: :boolean)
    config.add(:telephony_adapter, type: :string)
    config.add(:unauthorized_scope_enabled, type: :boolean)
    config.add(:use_dashboard_service_providers, type: :boolean)
    config.add(:use_kms, type: :boolean)
    config.add(:usps_confirmation_max_days, type: :integer)
    config.add(:usps_ipp_password, type: :string)
    config.add(:usps_ipp_root_url, type: :string)
    config.add(:usps_ipp_sponsor_id, type: :string)
    config.add(:usps_ipp_username, type: :string)
    config.add(:usps_upload_enabled, type: :boolean)
    config.add(:usps_upload_sftp_directory, type: :string)
    config.add(:usps_upload_sftp_host, type: :string)
    config.add(:usps_upload_sftp_password, type: :string)
    config.add(:usps_upload_sftp_timeout, type: :integer)
    config.add(:usps_upload_sftp_username, type: :string)
    config.add(:valid_authn_contexts, type: :json)
    config.add(:verify_gpo_key_attempt_window_in_minutes, type: :integer)
    config.add(:verify_gpo_key_max_attempts, type: :integer)
    config.add(:verify_personal_key_attempt_window_in_minutes, type: :integer)
    config.add(:verify_personal_key_max_attempts, type: :integer)
    config.add(:voip_allowed_phones, type: :json)
    config.add(:voip_block, type: :boolean)
    config.add(:voip_check, type: :boolean)

    @store = RedactedStruct.new('IdentityConfig', *config.written_env.keys, keyword_init: true).
      new(**config.written_env)
  end
end
