require 'savon'
require 'httpclient'

module NetforumEnterprise
  class Authentication
    INVALID_CUSTOMER_KEY = '00000000-0000-0000-0000-000000000000'

    attr_reader :last_request, :last_response

    def initialize(username, password, configuration)
      @auth_token = nil
      @username = username
      @password = password
      @configuration = configuration
    end

    def authenticate
      begin
        operation = client(false).operation(:authenticate)
        response = operation.call(message: { 'userName' => @username, 'password' => @password })
        @last_request = operation.raw_request
        @last_response = operation.raw_response
        @auth_token = response.header[:authorization_token][:token] if response.header[:authorization_token][:token].length > 0
        true
      rescue Savon::SOAPFault => e
        @last_request ||= operation.raw_request
        @last_response = e.http
        @auth_token = nil
        false
      end
    end

    def authentication_token
      @auth_token
    end

    def get_individual_information(customer_key)
      if result = get_result('get_individual_information', { 'IndividualKey' => customer_key })
        result[:individual_objects][:individual_object]
      end
    end

    def get_customer_committees(customer_key)
      get_array('get_query', {
        'szObjectName' => 'Committee',
        'szColumnList' => 'cst_key,cmt_key,cmt_code,cmt_name',
        'szWhereClause' => "cst_key='#{customer_key}'",
        'szOrderBy' => ''
      }, Committee, { output_subnames: %w(committee_participation_e_web_object committees_object committee_object) })
    end

    def get_member_type_codes(customer_key)
      get_array('web_activity_get_purchased_memberships_by_customer',
                { 'CustomerKey' => customer_key, }, Committee)
    end

    def web_user_login(login, password)
      get_result('web_web_user_login', { 'LoginOrEmail' => login, 'password' => password })
    end

    def web_validate(login_auth_token)
      customer_key = get_result('web_validate', { authenticationToken: login_auth_token })
      customer_key unless customer_key == INVALID_CUSTOMER_KEY
    end

    private

    def client(with_auth_token = true)
      if with_auth_token
        options = @configuration.client_options.merge(soap_header: { 'tns:AuthorizationToken' => { 'tns:Token' => @auth_token } })
      else
        options = @configuration.client_options
      end
      Savon.client(options) do |globals|
        globals.wsdl @configuration.wsdl
      end
    end

    def get_result(service, params, options = {})
      begin
        operation = client.operation(service.to_sym,)
        response = operation.call(message: params)
        @last_request = operation.raw_request
        @last_response = operation.raw_response
        @auth_token = response.header[:authorization_token][:token] if response.header[:authorization_token][:token].length > 0
        output_name = options[:output_name] || service

        if response.success? && response.body["#{output_name}_response".to_sym]["#{output_name}_result".to_sym]
          response.body["#{output_name}_response".to_sym]["#{output_name}_result".to_sym]
        else
          nil
        end
      rescue Savon::SOAPFault => e
        @last_request ||= operation.raw_request
        @last_response = e.http
        nil
      end
    end

    def get_array(service, params, klass, options={})
      begin
        operation = client.operation(service.to_sym)
        response = operation.call(message: params)
        @last_request = operation.raw_request
        @last_response = operation.raw_response
        @auth_token = response.header[:authorization_token][:token] if response.header[:authorization_token][:token].length > 0

        return_list = []
        no_subname = options[:no_subname] || false
        output_name = options[:output_name] || service
        output_subname = options[:output_subname] || 'result'
        output_subnames = options[:output_subnames]

        if response.success?
          if response.body["#{output_name}_response".to_sym]["#{output_name}_result".to_sym]
            if no_subname
              results = response.body["#{output_name}_response".to_sym]["#{output_name}_result".to_sym] || []
            elsif output_subnames.present?
              results = output_subnames.map do |subname|
                response.body["#{output_name}_response".to_sym]["#{output_name}_result".to_sym][subname.pluralize.to_sym][subname.to_sym] || []
              end.reject(&:blank?).first
            else
              results = response.body["#{output_name}_response".to_sym]["#{output_name}_result".to_sym][output_subname.pluralize.to_sym][output_subname.to_sym] || []
            end
          end

          unless results.is_a?(Array)
            results = [results]
          end

          results.each do |result|
            return_list << klass.new(result)
          end
        end
        return_list
      rescue Savon::SOAPFault => e
        @last_request ||= operation.raw_request
        @last_response = e.http
        nil
      end
    end
  end
end
