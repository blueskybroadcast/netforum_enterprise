module NetforumEnterprise
  class Configuration
    attr_accessor :wsdl, :client_options

    def initialize
      @wsdl = nil
      @client_options = { log: true, log_level: :info, logger: Rails.logger, pretty_print_xml: true }
    end
  end
end
