module NetforumEnterprise
  class Client
    attr_accessor :configuration, :auth, :map

    def authenticate(username, password)
      @auth = Authentication.new(username, password, configuration)
      raise 'Unable to authenticate with Netforum Enterprise SOAP service.' unless @auth.authenticate
      yield @auth
    end

    def map_products
      @map = MapProducts.new(@auth.authentication_token, configuration)
      yield @map
    end
  end
end
