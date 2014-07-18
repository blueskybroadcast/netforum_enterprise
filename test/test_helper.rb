require 'netforum_enterprise'
require 'minitest/autorun'
require 'minitest/pride'
require 'webmock/minitest'
require 'byebug'

def stub_wsdl
  stub_request(:get, "https://www.irwaonline.org/xweb/secure/netForumXML.asmx?WSDL").
    to_return(:status => 200, :body => File.read('test/fixtures/wsdl.xml'), :headers => {})
end

def stub_login
  stub_request(:post, "https://www.irwaonline.org/xweb/secure/netForumXML.asmx").
    with(:headers => {'Soapaction'=>'"http://www.avectra.com/2005/Authenticate"'}).
    to_return(:status => 200, :body => File.read('test/fixtures/authenticate_success.xml'), :headers => {})
end

def stub_login_failure
  stub_request(:post, "https://www.irwaonline.org/xweb/secure/netForumXML.asmx").
    with(:headers => {'Soapaction'=>'"http://www.avectra.com/2005/Authenticate"'}).
    to_return(:status => 200, :body => File.read('test/fixtures/authenticate_failure.xml'), :headers => {})
end

def stub_web_user_login
  stub_request(:post, "https://www.irwaonline.org/xweb/secure/netForumXML.asmx").
    with(:headers => {'Soapaction'=>'"http://www.avectra.com/2005/WEBWebUserLogin"'}).
    to_return(:status => 200, :body => File.read('test/fixtures/web_user_login_success.xml'), :headers => {})
end

def stub_web_user_login_failure
  stub_request(:post, "https://www.irwaonline.org/xweb/secure/netForumXML.asmx").
    with(:headers => {'Soapaction'=>'"http://www.avectra.com/2005/WEBWebUserLogin"'}).
    to_return(:status => 200, :body => File.read('test/fixtures/web_user_login_failure.xml'), :headers => {})
end

def stub_web_validate
  stub_request(:post, "https://www.irwaonline.org/xweb/secure/netForumXML.asmx").
    with(:headers => {'Soapaction'=>'"http://www.avectra.com/2005/WebValidate"'}).
    to_return(:status => 200, :body => File.read('test/fixtures/web_validate_success.xml'), :headers => {})
end

def stub_web_validate_failure
  stub_request(:post, "https://www.irwaonline.org/xweb/secure/netForumXML.asmx").
    with(:headers => {'Soapaction'=>'"http://www.avectra.com/2005/WebValidate"'}).
    to_return(:status => 200, :body => File.read('test/fixtures/web_validate_failure.xml'), :headers => {})
end

def stub_get_individual_information
  stub_request(:post, "https://www.irwaonline.org/xweb/secure/netForumXML.asmx").
    with(:headers => {'Soapaction'=>'"http://www.avectra.com/2005/GetIndividualInformation"'}).
    to_return(:status => 200, :body => File.read('test/fixtures/get_individual_information_success.xml'), :headers => {})
end

def stub_get_individual_information_failure
  stub_request(:post, "https://www.irwaonline.org/xweb/secure/netForumXML.asmx").
    with(:headers => {'Soapaction'=>'"http://www.avectra.com/2005/GetIndividualInformation"'}).
    to_return(:status => 200, :body => File.read('test/fixtures/get_individual_information_failure.xml'), :headers => {})
end
