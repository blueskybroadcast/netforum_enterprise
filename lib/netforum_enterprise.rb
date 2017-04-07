require "netforum_enterprise/version"
require "netforum_enterprise/configuration"
require "netforum_enterprise/authentication"
require "netforum_enterprise/map_products"
require "netforum_enterprise/event_completion_response"
require "netforum_enterprise/certificate_completion_response"
require "netforum_enterprise/event"
require "netforum_enterprise/invoice"
require "netforum_enterprise/product"
require "netforum_enterprise/registrant_event"
require "netforum_enterprise/registrant"
require "netforum_enterprise/user"
require "netforum_enterprise/committee"

module NetforumEnterprise
  class << self
    attr_accessor :configuration, :auth, :map
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.reset
    @configuration = Configuration.new
  end

  def self.configure
    yield configuration
  end

  def self.authenticate username, password
    @auth = Authentication.new username, password
    raise 'Unable to authenticate with Netforum Enterprise SOAP service.' unless @auth.authenticate
    yield @auth
  end

  def self.map_products
    @map = MapProducts.new @auth.authentication_token
    yield @map
  end
end
