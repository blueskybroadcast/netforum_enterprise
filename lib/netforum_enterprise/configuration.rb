module NetforumEnterprise
  class Configuration
    DEFAULT_NAMES = {
      service_name: 'CASDIIntegration',
      event_sync_method_name: 'GetEventRegistrants',
      product_sync_method_name: 'GetInvoiceDetails',
      demo_sync_method_name: 'ADAWebServices',
      cdr_service_name: 'CDRpathlmsgetcust'
    }.freeze

    attr_accessor :provider
    attr_writer :wsdl, :use_execute_method, :client_options

    def initialize
      logger = defined?(Rails) ? Rails.logger : Logger.new(STDOUT)
      @provider = nil
      @wsdl = nil
      @use_execute_method = false
      @retry_login_with_another_method = false
      @client_options = { log: true, log_level: :debug, logger: logger, pretty_print_xml: true }
    end

    def client_options
      @client_options[:proxy] = proxy_url if @client_options[:proxy].blank? && use_proxy? && proxy_url
      @client_options
    end

    def wsdl
      @wsdl.presence || @provider&.wsdl_url
    end

    def retry_login_with_another_method?
      @retry_login_with_another_method || provider_settings['retry_login_with_another_method'].present?
    end

    def use_execute_method?
      @use_execute_method || provider_settings['use_execute_method'].present?
    end

    def product_sync_method_name
      @product_sync_method_name || provider_settings['product_sync_method_name']&.strip || DEFAULT_NAMES[:product_sync_method_name]
    end

    def event_sync_method_name
      @event_sync_method_name || provider_settings['event_sync_method_name']&.strip || DEFAULT_NAMES[:event_sync_method_name]
    end

    def demo_sync_method_name
      @demo_sync_method_name || provider_settings['demo_sync_method_name']&.strip || DEFAULT_NAMES[:demo_sync_method_name]
    end

    def service_name
      @service_name || provider_settings['service_name']&.strip || DEFAULT_NAMES[:service_name]
    end

    def cdr_service_name
      @cdr_service_name || provider_settings['cdr_service_name']&.strip || DEFAULT_NAMES[:cdr_service_name]
    end

    private

    def proxy_url
      @proxy_url ||= case provider_settings['global_proxy']
                     when 'fixie'
                       ENV['FIXIE_URL'] if ProxyUrlService.use_fixie?
                     when 'proximo'
                       ENV['PROXIMO_URL'] if ProxyUrlService.use_proximo?
                     when 'custom'
                       provider_settings['global_proxy_custom_value']
                     else
                       ENV['NETFORUM_ENTERPRISE_PROXY_URL'].presence ||
                         (ProxyUrlService.use_fixie? && ENV['FIXIE_URL'])
                     end
    end

    def use_proxy?
      @use_proxy ||= provider_settings['use_proxy'].present? ||
        (provider_settings.key?('global_proxy') && provider_settings['global_proxy'] != 'disabled')
    end

    def provider_settings
      @provider_settings ||= @provider&.settings.presence || {}
    end
  end
end
