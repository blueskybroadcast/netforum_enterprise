module NetforumEnterprise
  class MapProducts
    attr_reader :authentication_token

    def initialize(authentication_token)
      @authentication_token = authentication_token
    end

    def get_event_list
      get_array('web_centralized_shopping_cart_get_event_list', {}, Event)
    end

    def get_full_event_list
      get_array('get_query', {
        'szObjectName' => 'Events @TOP -1',
        'szColumnList' => 'evt_key,evt_title,prc_key,prc_price',
        'szWhereClause' => '',
        'szOrderBy' => 'evt_title'
      }, Event, { output_subname: 'events_object' })
    end

    def get_full_product_list
      get_array('get_query', {
        'szObjectName' => 'Price_Merchandise @TOP -1',
        'szColumnList' => 'prc_price,prc_key,prd_key,prd_name',
        'szWhereClause' => '',
        'szOrderBy' => 'prd_name'
      }, Product, { output_subname: 'price_merchandise_object' })
    end

    def get_invoice_by_invoice_details_key(ivd_key:)
      get_object('get_query', {
        'szObjectName' => 'Invoice',
        'szColumnList' => 'inv_cst_key,ivd_key,ivd_add_date,ivd_prc_key,ivd_prc_prd_key',
        'szWhereClause' => "ivd_key='#{ivd_key}'",
        'szOrderBy' => ''
      }, Invoice, { output_subname: 'invoice_object' })
    end

    def get_product_list
      get_array('web_centralized_shopping_cart_get_product_list', {}, Product)
    end

    def get_purchased_events_by_customer(cst_key:)
      get_array('web_activity_get_purchased_events_by_customer', { 'CustomerKey' => cst_key }, Event)
    end

    def get_purchased_products_by_customer(cst_key:)
      get_array('web_activity_get_purchased_products_by_customer', { 'CustomerKey' => cst_key }, Product)
    end

    def get_registrant_events_by_reg_key(reg_key:)
      get_object('web_activity_get_registrant_events', { 'RegKey' => reg_key }, RegistrantEvent)
    end

    def get_events_registrant_by_event_key(evt_key:, cst_key: nil)
      where_clause = cst_key ? "reg_cst_key='#{cst_key}' and reg_evt_key='#{evt_key}'" : "reg_evt_key='#{evt_key}'"
      get_array('get_query', {
        'szObjectName' => 'EventsRegistrant',
        'szColumnList' => 'Registrant.reg_cst_key AS Registrant_reg_cst_key,Registrant.reg_evt_key AS Registrant_reg_evt_key,Registrant.reg_registration_date AS Registrant_reg_registration_date,CustomerInd.cst_id AS CustomerInd_cst_id',
        'szWhereClause' => "#{where_clause}",
        'szOrderBy' => ''
      }, Registrant, { output_subname: 'events_registrant_object' })
    end

    def get_user_by_cst_key(cst_key:)
      get_object('web_web_user_get', { 'cst_key' => cst_key }, User, { no_subname: true })
    end

    def write_event_completion(reg_key:, cst_key:, evt_key:, iso_datetime:)
      get_object('update_facade_object', {
        'szObjectName' => 'EventsRegistrant',
        'szObjectKey' => "#{reg_key}",
        'szWhereClause' => "reg_cst_key='#{cst_key}' and reg_evt_key='#{evt_key}'",
        'oNode' => { 'EventsRegistrantObjects' => { 'EventsRegistrantObject' => { 'reg_lms_attended_date_ext' => "#{iso_datetime}" } } }
      }, EventCompletionResponse, { output_subname: 'events_registrant_object' })
    end

    private

    def client
      options = Configuration.client_options.merge(soap_header: { 'tns:AuthorizationToken' => { 'tns:Token' => @authentication_token } })

      Savon.client(options) do |globals|
        globals.wsdl Configuration.wsdl
        # globals.log true
        # globals.logger Rails.logger
        # globals.log_level :debug
        # globals.pretty_print_xml true

        # override endpoint address so http schemes match what is in WSDL
        globals.endpoint Configuration.wsdl.gsub('?WSDL', '')
      end
    end

    def get_array(service, params, klass, options={})
      response = client.call(service.to_sym, message: params)
      set_auth_token(response)

      return_list = []
      no_subname = options[:no_subname] || false
      output_name = options[:output_name] || service
      output_subname = options[:output_subname] || 'result'

      if response.success? && response.body["#{output_name}_response".to_sym]["#{output_name}_result".to_sym]
        if no_subname
          results = response.body["#{output_name}_response".to_sym]["#{output_name}_result".to_sym] || []
        else
          results = response.body["#{output_name}_response".to_sym]["#{output_name}_result".to_sym][output_subname.pluralize.to_sym][output_subname.to_sym] || []
        end

        unless results.is_a?(Array)
          results = [results]
        end

        results.each do |result|
          return_list << klass.new(result)
        end
      end

      return_list
    rescue Savon::SOAPFault => error
      fault_code = error.to_hash[:fault][:faultcode]
      Rails.logger.error "!! NetforumEnterprise get_array error: #{fault_code}"
      []
    end

    def get_object(service, params, klass, options={})
      response = client.call(service.to_sym, message: params)
      set_auth_token(response)

      no_subname = options[:no_subname] || false
      output_name = options[:output_name] || service
      output_subname = options[:output_subname] || 'result'

      if response.success? && response.body["#{output_name}_response".to_sym]["#{output_name}_result".to_sym]
        if no_subname
          klass.new(response.body["#{output_name}_response".to_sym]["#{output_name}_result".to_sym])
        else
          klass.new(response.body["#{output_name}_response".to_sym]["#{output_name}_result".to_sym][output_subname.pluralize.to_sym][output_subname.to_sym])
        end
      else
        nil
      end
    rescue Savon::SOAPFault => error
      fault_code = error.to_hash[:fault][:faultcode]
      Rails.logger.error "!! NetforumEnterprise get_object error: #{fault_code}"
      nil
    end

    def set_auth_token(response)
      @authentication_token = response.header[:authorization_token][:token]
    end
  end
end
