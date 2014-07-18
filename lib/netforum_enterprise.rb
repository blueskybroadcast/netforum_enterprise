require "netforum_enterprise/version"
require "netforum_enterprise/configuration"
require "netforum_enterprise/service"

module NetforumEnterprise
  def self.configure(&block)
    Configuration.class_eval(&block)
  end

  def self.authenticate(username, password)
    service = Service.new(username, password)
    if service.authenticate
      service
    else
      nil
    end
  end
end
