require "netforum_enterprise/version"
require "netforum_enterprise/configuration"
require "netforum_enterprise/authentication"
require "netforum_enterprise/map_products"
require "netforum_enterprise/event_completion_response"
require "netforum_enterprise/event"
require "netforum_enterprise/invoice"
require "netforum_enterprise/product"
require "netforum_enterprise/registrant_event"
require "netforum_enterprise/registrant"
require "netforum_enterprise/user"

module NetforumEnterprise
  def self.configure(&block)
    Configuration.class_eval(&block)
  end

  def self.authenticate(username, password)
    auth = Authentication.new(username, password)
    if auth.authenticate
      auth
    else
      nil
    end
  end

  def self.map_products(authentication_token)
    MapProducts.new(authentication_token)
  end
end
