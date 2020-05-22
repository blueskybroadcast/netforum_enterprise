module NetforumEnterprise
  class Configuration
    attr_accessor :provider
    attr_writer :wsdl, :use_execute_method, :client_options

    def initialize
      logger = defined?(Rails) ? Rails.logger : Logger.new(STDOUT)
      @provider = nil
      @wsdl = nil
      @use_execute_method = false
      @use_web_user_validate_login = false
      @client_options = { log: true, log_level: :debug, logger: logger, pretty_print_xml: true }
    end

    def client_options
      @client_options[:proxy] = proxy_url if @client_options[:proxy].blank? && use_proxy?
      @client_options
    end

    def wsdl
      @wsdl.presence || @provider&.wsdl_url
    end

    def use_web_user_validate_login?
      @use_web_user_validate_login || @provider&.settings&.dig('use_web_user_validate_login').present?
    end

    def use_execute_method?
      @use_execute_method || @provider&.settings&.dig('use_execute_method').present?
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
