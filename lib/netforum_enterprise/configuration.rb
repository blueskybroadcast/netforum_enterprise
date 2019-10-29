module NetforumEnterprise
  class Configuration
    attr_accessor :wsdl, :client_options, :use_execute_method

    def initialize
      logger = defined?(Rails) ? Rails.logger : Logger.new(STDOUT)
      @wsdl = nil
      @use_execute_method = false
      @client_options = { log: true, log_level: :debug, logger: logger, pretty_print_xml: true }
    end
  end
end
