# encoding: utf-8
require '../lib/document'
require 'minitest/unit'

module HTMLToPDF
  EXAMPLE_COM = <<END
<html>
<head>
    <title>Example Domain</title>

    <meta charset="utf-8" />
    <meta http-equiv="Content-type" content="text/html; charset=utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <style type="text/css">
    body {
        background-color: #f0f0f2;
        margin: 0;
        padding: 0;
        font-family: "Open Sans", "Helvetica Neue", Helvetica, Arial, sans-serif;
        
    }
    div {
        width: 600px;
        margin: 5em auto;
        padding: 50px;
        background-color: #fff;
        border-radius: 1em;
    }
    a:link, a:visited {
        color: #38488f;
        text-decoration: none;
    }
    @media (max-width: 700px) {
        body {
            background-color: #fff;
        }
        div {
            width: auto;
            margin: 0 auto;
            border-radius: 0;
            padding: 1em;
        }
    }
    </style>    
</head>

<body>
<div>
    <h1>Example Domain</h1>
    <p>This domain is established to be used for illustrative examples in documents. You may use this
    domain in examples without prior coordination or asking for permission.</p>
    <p><a href="http://www.iana.org/domains/example">More information...</a></p>
</div>
</body>
</html>
END

  class DocumentTest < MiniTest::Unit::TestCase
    def test_creating_empty_document
      document = Document.new
      assert_instance_of Document, Document.new
    end

    def test_text_format_with_url
      document = Document.new
      expected = EXAMPLE_COM.gsub(/\n/, '')
      assert_equal expected, document.text_format('http://example.com')
    end

    def test_text_format_with_html
      html = '<!doctype html>
              <html>
                <h1>H1</h1>
                <h2>H2</h2>
                <h3>H3</h3>
                <h4>H4</h4>
                <h5>H5</h5>
                <h6>H6</h6>
              </html>'
      document = Document.new
      expected = html.gsub(/\A<!.*?>/, '').gsub(/\n/, '')
      assert_equal expected, document.text_format(html)
    end

    def test_creating_document_with_url
      document = Document.new 'http://example.com'
      expected = EXAMPLE_COM.gsub(/\A<!.*?>/, '').gsub(/\n/, '')
      assert_equal "<document>#{expected}</document>", document.html
    end

    def test_creating_document_with_html
      document = Document.new EXAMPLE_COM
      expected = EXAMPLE_COM.gsub(/\A<!.*?>/, '').gsub(/\n/, '')
      assert_equal "<document>#{expected}</document>", document.html
    end

    def text_getting_html_from_site
      document = Document.new
      expected = EXAMPLE_COM
      assert_equal expected, document.get_html_from('http://example.com')
    end
  end
end