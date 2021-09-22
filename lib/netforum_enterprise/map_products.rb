module NetforumEnterprise
  class MapProducts
    attr_reader :authentication_token, :last_request, :last_response
    attr_accessor :read_timeout, :open_timeout

    def initialize(authentication_token, configuration)
      @authentication_token = authentication_token
      @configuration = configuration
      @read_timeout = nil
      @open_timeout = nil
    end

    def get_event_list
      get_array('web_centralized_shopping_cart_get_event_list', {}, Event)
    end

    def get_full_event_list(months_limit = nil, exclude_prc_columns = true)
      where_clause = if months_limit
                       "evt_start_date > \'#{months_limit.to_i.months.ago.strftime('%Y-%m-01')}\'"
                     else
                       ''
                     end

      column_list = 'evt_key,evt_title,evt_code,evt_start_date'
      column_list << ',prc_key,prc_price' unless exclude_prc_columns

      get_array('get_query', {
        'szObjectName' => 'Events @TOP -1',
        'szColumnList' => column_list,
        'szWhereClause' => where_clause,
        'szOrderBy' => 'evt_title'
      }, Event, { output_subname: 'events_object' })
    end

    def get_full_product_list(months_limit = nil)
      where_clause = if months_limit
                       "prd_start_date > \'#{months_limit.to_i.months.ago.strftime('%Y-%m-01')}\'"
                     else
                       ''
                     end

      get_array('get_query', {
        'szObjectName' => 'Price_Merchandise @TOP -1',
        'szColumnList' => 'prc_price,prc_key,prd_key,prd_name,prd_code,prd_start_date',
        'szWhereClause' => where_clause,
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

    def get_invoice_array_by_invoice_details_keys(products_with_ivd_key:)
      get_array('get_query', {
        'szObjectName' => 'Invoice',
        'szColumnList' => 'inv_cst_key,ivd_key,ivd_add_date,ivd_prc_key,ivd_prc_prd_key',
        'szWhereClause' => "ivd_key IN (#{ivd_key_list(products_with_ivd_key)})",
        'szOrderBy' => ''
      }, Invoice, { output_subname: 'invoice_object' })
    end

    def get_invoice_details_by_cst_key(cst_key:, ivd_prc_prd_keys:)
      if @configuration.use_execute_method?
        get_array('execute_method', {
          'serviceName' => "#{@configuration.service_name}",
          'methodName' => "#{@configuration.product_sync_method_name}",
          'parameters' => {
            'Parameter' => [
              { 'Name' => 'cst_key', 'Value' => cst_key },
              { 'Name' => 'prd_key_list', 'Value' => ivd_prc_prd_keys.join(',') }
            ]
          },
        }, InvoiceDetail, { output_subname: 'invoice_detail_object' })
      else
        where_clause = "cst_key='#{cst_key}'"
        where_clause << " and ivd_prc_prd_key IN (#{key_list(ivd_prc_prd_keys)})" if ivd_prc_prd_keys
        get_array('get_query', {
          'szObjectName' => 'InvoiceDetail',
          'szColumnList' => 'cst_key,ivd_key,ivd_add_date,ivd_prc_key,ivd_prc_prd_key,ivd_price,ivd_delete_flag,ivd_void_date',
          'szWhereClause' => where_clause,
          'szOrderBy' => 'ivd_add_date DESC'
        }, InvoiceDetail, { output_subname: 'invoice_detail_object' })
      end
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

    def get_events_registrant_by_event_key(evt_key:, cst_id: nil, cst_key: nil, return_list: nil, search_for_actual_events: false)
      if @configuration.use_execute_method? && cst_id.nil? && return_list.nil?
        get_array('execute_method', {
          'serviceName' => "#{@configuration.service_name}",
          'methodName' => "#{@configuration.event_sync_method_name}",
          'parameters' => {
            'Parameter' => [
              { 'Name' => 'cst_key', 'Value' => cst_key },
              { 'Name' => 'evt_key_list', 'Value' => evt_key }
            ]
          },
        }, Registrant, { output_subname: 'events_registrant_object' })
      else
        where_clause = "reg_evt_key='#{evt_key}'"
        where_clause << if cst_key
                          " and reg_cst_key='#{cst_key}'"
                        elsif cst_id
                          " and cst_id='#{cst_id}'"
                        else
                          ''
                        end
        where_clause << " and reg_cancel_date is null and reg_delete_flag='0'" if search_for_actual_events
        get_array('get_query', {
          'szObjectName' => 'EventsRegistrant',
          'szColumnList' => return_list || "ivd_key,cst_id,Registrant.reg_cancel_date AS Registrant_reg_cancel_date,Registrant.reg_cst_key AS Registrant_reg_cst_key,Registrant.reg_evt_key AS Registrant_reg_evt_key,Registrant.reg_registration_date AS Registrant_reg_registration_date,Registrant.reg_add_date AS Registrant_reg_add_date",
          'szWhereClause' => "#{where_clause}",
          'szOrderBy' => 'Registrant.reg_add_date DESC'
        }, Registrant, { output_subname: 'events_registrant_object' })
      end
    end

    def get_events_by_customer_key(cst_key:, registrant_reg_evt_keys:)
      if @configuration.use_execute_method?
        get_array('execute_method', {
          'serviceName' => "#{@configuration.service_name}",
          'methodName' => "#{@configuration.event_sync_method_name}",
          'parameters' => {
            'Parameter' => [
              { 'Name' => 'cst_key', 'Value' => cst_key },
              { 'Name' => 'evt_key_list', 'Value' => registrant_reg_evt_keys.join(',') }
            ]
          },
        }, Registrant, { output_subname: 'events_registrant_object' })
      else
        where_clause = "reg_cst_key='#{cst_key}'"
        where_clause << " and Registrant.reg_evt_key IN (#{key_list(registrant_reg_evt_keys)})" if registrant_reg_evt_keys
        get_array('get_query', {
          'szObjectName' => 'EventsRegistrant',
          'szColumnList' => 'ivd_key,Registrant.reg_cancel_date AS Registrant_reg_cancel_date,Registrant.reg_key AS Registrant_reg_key,Registrant.reg_cst_key AS Registrant_reg_cst_key,Registrant.reg_evt_key AS Registrant_reg_evt_key,Registrant.reg_registration_date AS Registrant_reg_registration_date,Registrant.reg_add_date AS Registrant_reg_add_date',
          'szWhereClause' => "#{where_clause}",
          'szOrderBy' => 'Registrant.reg_add_date DESC'
        }, Registrant, { output_subname: 'events_registrant_object' })
      end
    end

    def get_user_by_cst_key(cst_key:)
      get_object('web_web_user_get', { 'cst_key' => cst_key }, User, { no_subname: true })
    end

    def get_certificate_details_by_prd_key(prd_key:)
      get_array('get_query', {
        'szObjectName' => 'ProductCredit',
        'szColumnList' => 'cpp_key,cpp_cet_key,cpp_credit',
        'szWhereClause' => "cpp_prd_key='#{prd_key}'",
        'szOrderBy' => ''
      }, StandardResponse, { output_subname: 'product_credit_object' })
    end

    def get_ceu_credits(prd_key:)
      get_array('get_query', {
        'szObjectName' => 'CEUCredit',
        'szColumnList' => 'cpp_key,cpp_cet_key,ceu_key,cpp_credit',
        'szWhereClause' => "cpp_prd_key='#{prd_key}'",
        'szOrderBy' => ''
      }, StandardResponse, { output_subname: 'ceu_credit_object' })
    end

    def write_event_completion(reg_key:, cst_key:, evt_key:, iso_datetime:)
      get_object('update_facade_object', {
        'szObjectName' => 'EventsRegistrant',
        'szObjectKey' => "#{reg_key}",
        'szWhereClause' => "reg_cst_key='#{cst_key}' and reg_evt_key='#{evt_key}'",
        'oNode' => { 'EventsRegistrantObjects' => { 'EventsRegistrantObject' => { 'reg_lms_attended_date_ext' => "#{iso_datetime}" } } }
      }, StandardResponse, { output_subname: 'events_registrant_object' })
    end

    def write_certificate_completion(cst_key:, evt_key:, date_string:, credit_value:)
      get_object('execute_method', {
        'serviceName' => 'NACCHOWebServices',
        'methodName' => 'BSBUpdateCourseCompletion',
        'parameters' => {
          'Parameter' => [
            { 'Name' => 'CustomerKey', 'Value' => "#{cst_key}" },
            { 'Name' => 'EventKey', 'Value' => "#{evt_key}" },
            { 'Name' => 'Result', 'Value' => 'Pass' },
            { 'Name' => 'CompletionDate', 'Value' => "#{date_string}" },
            { 'Name' => 'Credit', 'Value' => "#{credit_value}" }
          ]
        }
      }, StandardResponse, { no_subname: true })
    end

    def write_apdt_course_purchase(uid:, path_course_id:, path_course_name:, start_date:, end_date:)
      get_object('insert_facade_object', {
        'szObjectName' => 'APDTLMSCourse',
        'oNode' => {
          'APDTLMSCourses' => {
            'APDTLMSCourse' => {
              'a07_cst_key' => uid.to_s,
              'a07_course_ID' => path_course_id.to_s,
              'a07_course_description' => path_course_name.to_s,
              'a07_start_date' => start_date,
              'a07_end_date' => end_date
            }
          }
        }
      }, StandardResponse, { output_subname: 'apdtlms_course_object' })
    end

    def write_apdt_course_revoke(purchase_key:)
      get_object('update_facade_object', {
        'szObjectName' => 'APDTLMSCourse',
        'szObjectKey' => "#{purchase_key}",
        'oNode' => { 'APDTLMSCourses' => { 'APDTLMSCourse' => { 'a07_delete_flag' => '1' } } }
      }, StandardResponse, { output_subname: 'apdtlms_course_object' })
    end

    def find_credit_key(ece_key:)
      service_name = @configuration.provider&.settings&.dig('service_name')&.strip.presence || 'LMSWeb'
      get_array('execute_method', {
        'serviceName' => service_name,
        'methodName' => 'getCETKey',
        'parameters' => {
          'Parameter' => [
            { 'Name' => 'ece_key', 'Value' => ece_key },
          ]
        },
      }, StandardResponse, { output_subname: 'credit_type' })
    end

    def write_ceu_credit_earned(user_cst_key:, credit_key_data:, credits_earned:, earned_date:, ceu_cet_key:, writeback_time:, ceu_delete_flag: nil, ceu_add_user: nil)
      ceu_credit_data = {
        'ceu_ind_cst_key' => user_cst_key,
        'ceu_credit' => credits_earned.to_s,
        'ceu_add_date' => writeback_time,
        'ceu_earned_date' => earned_date,
        'ceu_cet_key' => ceu_cet_key
      }
      ceu_credit_data['ceu_delete_flag'] = ceu_delete_flag if ceu_delete_flag
      ceu_credit_data['ceu_add_user'] = ceu_add_user if ceu_add_user
      ceu_credit_data.merge!(credit_key_data)

      get_object('insert_facade_object', {
        'szObjectName' => 'CEUCredit',
        'oNode' => {
          'CEUCredits' => {
            'CEUCredit' => ceu_credit_data
          }
        }
      }, StandardResponse, { output_subname: 'ceu_credit_object' })
    end

    def write_self_report_credit(user_cst_key:, course_name:, credits_earned:, earned_date:, sce_cet_key:, sce_status:, sce_program:)
      get_object('insert_facade_object', {
        'szObjectName' => 'SelfReportCredit',
        'oNode' => {
          'SelfReportCreditObjects' => {
            'SelfReportCreditObject' => {
              'sce_credit' => credits_earned,
              'sce_program' => sce_program,
              'sce_course' => course_name,
              'sce_cet_key' => sce_cet_key,
              'sce_ind_cst_key' => user_cst_key,
              'sce_activity_date' => earned_date,
              'sce_status' => sce_status
            }
          }
        }
      }, StandardResponse, { output_subname: 'self_report_credit_object' })
    end

    def register_user_for_event(cst_key:, event_key:)
      get_object('insert_facade_object', {
        'szObjectName' => 'EventsRegistrant',
        'oNode' => {
          'EventsRegistrant' => {
            'Registrant' => {
              'reg_cst_key' => cst_key,
              'reg_evt_key' => event_key
            }
          }
        }
      }, StandardResponse, { output_subname: 'events_registrant_object' })
    end

    def write_event_registrant_attendance(user_cst_key: , reg_key: , grade: , completion_date:)
      get_object('update_facade_object', {
        'szObjectName' => 'EventsRegistrant',
        'oNode' => { 'EventsRegistrant' => { 'Registrant' => {
          'reg_key' => reg_key,
          'reg_cst_key' => user_cst_key,
          'reg_grade_ext' => grade,
          'reg_completion_date_ext' => completion_date
        } } }
      }, StandardResponse, { output_subname: 'events_registrant_object' })
    end

    private

    def client
      return @client if defined?(@client)

      raise 'Undefined global configuration option "wsdl". Use NetforumEnterprise.configure { |config| config.wsdl = "value" } to set this.' unless @configuration.wsdl
      options = @configuration.client_options.merge(soap_header: { 'tns:AuthorizationToken' => { 'tns:Token' => @authentication_token } })
      options[:read_timeout] = read_timeout if read_timeout.present?
      options[:open_timeout] = open_timeout if open_timeout.present?

      @client = Savon.client(options) do |globals|
        globals.wsdl @configuration.wsdl
        globals.endpoint @configuration.wsdl.gsub('?WSDL', '')
        globals.adapter :net_http
      end
    end

    def key_list(keys)
      "'" + keys.join("','") + "'"
    end

    def ivd_key_list(products_with_ivd_key)
      "'" + products_with_ivd_key.map { |m| m[:ivd_key] }.join("','") + "'"
    end

    def get_array(service, params, klass, options={})
      operation = client.operation(service.to_sym)
      response = operation.call(message: params, soap_header: { 'tns:AuthorizationToken' => { 'tns:Token' => @authentication_token } })
      @last_request = operation.raw_request
      @last_response = operation.raw_response
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
      @last_request = operation&.raw_request
      @last_response = error.http
      fault_code = error.to_hash[:fault][:faultcode]
      Rails.logger.error "!! NetforumEnterprise get_array error: #{fault_code}"
      []
    end

    def get_object(service, params, klass, options={})
      operation = client.operation(service.to_sym)
      response = operation.call(message: params, soap_header: { 'tns:AuthorizationToken' => { 'tns:Token' => @authentication_token } })
      @last_request = operation.raw_request
      @last_response = operation.raw_response
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
      @last_request = operation&.raw_request
      @last_response = error.http
      fault_code = error.to_hash[:fault][:faultcode]
      Rails.logger.error "!! NetforumEnterprise get_object error: #{fault_code}"
      nil
    end

    def set_auth_token(response)
      @authentication_token = response.header[:authorization_token][:token]
    end
  end
end
