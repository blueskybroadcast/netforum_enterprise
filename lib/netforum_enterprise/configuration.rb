module NetforumEnterprise
  class Configuration
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
      @client_options[:proxy] = proxy_url if @client_options[:proxy].blank? && use_proxy?
      @client_options
    end

    def wsdl
      @wsdl.presence || @provider&.wsdl_url
    end

    def retry_login_with_another_method?
      @retry_login_with_another_method || @provider&.settings&.dig('retry_login_with_another_method').present?
    end

    def use_execute_method?
      @use_execute_method || @provider&.settings&.dig('use_execute_method').present?
    end

    def product_sync_method_name
      @product_sync_method_name || @provider&.settings&.dig('product_sync_method_name').strip
    end

    def event_sync_method_name
      @event_sync_method_name || @provider&.settings&.dig('event_sync_method_name').strip
    end

    def service_name
      @service_name || @provider&.settings&.dig('service_name').strip
    end

    private

    def proxy_url
      ENV['NETFORUM_ENTERPRISE_PROXY_URL'].presence || ENV['FIXIE_URL']
    end

    def use_proxy?
      @use_proxy ||= @provider&.settings&.dig('use_proxy').present?
    end
  end
end
