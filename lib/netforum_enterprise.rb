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
require "netforum_enterprise/client"

module NetforumEnterprise
  def self.configure
    client = Client.new
    client.configuration = Configuration.new
    yield client.configuration
    client
  end
end
