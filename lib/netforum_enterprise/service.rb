require 'savon'
require 'httpclient'

module NetforumEnterprise
  class Service
    INVALID_CUSTOMER_KEY = '00000000-0000-0000-0000-000000000000'

    def initialize(username, password)
      @auth_token = nil
      @username = username
      @password = password
    end

    def authenticate
      begin
        response = client(false).call(:authenticate, message: {'userName' => @username, 'password' => @password})
        @auth_token = response.header[:authorization_token][:token]
        true
      rescue Savon::SOAPFault => e
        @auth_token = nil
        false
      end
    end

    def authenticated?
      !@auth_token.nil?
    end

    def authentication_token
      authenticate unless authenticated?
      @auth_token
    end

    def get_individual_information(customer_key)
      if result = get_result('get_individual_information', { 'IndividualKey' => customer_key })
        result[:individual_objects][:individual_object]
      end
    end

    def web_user_login(login, password)
      get_result('web_web_user_login', { 'LoginOrEmail' => login, 'password' => password })
    end

    def web_validate(login_auth_token)
      customer_key = get_result('web_validate', { authenticationToken: login_auth_token })
      customer_key unless customer_key == INVALID_CUSTOMER_KEY
    end

    private

    def client(with_auth_token=true)
      if with_auth_token
        options = Configuration.client_options.merge(soap_header: {'tns:AuthorizationToken' => {'tns:Token' => authentication_token}})
      else
        options = Configuration.client_options
      end

      Savon.client(options) do |globals|
        globals.wsdl Configuration.wsdl
      end
    end

    def get_result(service, params, options={})
      begin
        response = client.call(service.to_sym, message: params)

        output_name = options[:output_name] || service

        if response.success? && response.body["#{output_name}_response".to_sym]["#{output_name}_result".to_sym]
          response.body["#{output_name}_response".to_sym]["#{output_name}_result".to_sym]
        else
          nil
        end
      rescue Savon::SOAPFault => e
        nil
      end
    end
  end
end
