# encoding: utf-8
require '../lib/sinatra_app'
require 'minitest/unit'
require 'rack/test'

module HTMLToPDF
  class SinatraAppTest < MiniTest::Unit::TestCase
    include Rack::Test::Methods
    
    def app
      Sinatra::Application
    end
    
    def test_index_page
      get '/'
      assert last_response.ok?
    end
    
    def test_returning_a_pdf_file
      post '/', :to_convert => '<div>Some Text</div>'
      assert_equal 'application/pdf', last_response.headers['content-type']
    end
    
    def test_converting_url
      post '/', :to_convert => 'http://example.com'
      assert last_response.headers['content-disposition'].include? 'Example Domain'
    end
    
    def test_converting_html_with_title
      post '/', :to_convert => '<html><head><title>Document to convert</title></head><body><div>Some Text</div></body></html>'
      assert last_response.headers['content-disposition'].include? 'Document to convert'
    end
    
    def test_converting_html_without_title
      post '/', :to_convert => '<div>Some Text</div>'
      assert last_response.headers['content-disposition'].include? 'TextTags'
    end
    
    def test_converting_nothing
      post '/', :to_convert => ''
      assert last_response.headers['content-disposition'].include? 'TextTags'
    end
  end
end