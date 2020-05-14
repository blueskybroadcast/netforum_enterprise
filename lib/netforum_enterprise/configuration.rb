module NetforumEnterprise
  class Configuration
    attr_accessor :provider, :client_options
    attr_writer :wsdl, :use_execute_method

    def initialize
      logger = defined?(Rails) ? Rails.logger : Logger.new(STDOUT)
      @provider = nil
      @wsdl = nil
      @use_execute_method = false
      @client_options = { log: true, log_level: :debug, logger: logger, pretty_print_xml: true }
    end

    def wsdl
      @wsdl.presence || @provider.wsdl_url
    end

    def use_execute_method?
      @provider.settings&.dig('use_execute_method').present? || @use_execute_method
    end
  end
end
