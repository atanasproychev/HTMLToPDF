# encoding: utf-8
require '../lib/html_to_pdf'
require 'minitest/unit'

module HTMLToPDF
  class TagsTest < MiniTest::Unit::TestCase
    def test_creating_empty_tag_and_get_content
      tag = Tag.new(nil)
      assert_equal [], tag.content
    end
    
    def test_creating_empty_tag_and_get_attributes
      tag = Tag.new(nil)
      expected = {:class => nil, :id => nil, :hidden => nil}
      assert_equal expected, tag.attributes
    end
    
    def test_parsing_html
      html = '<a href="http://abv.bg/" id="one" class="second">New Text</a>'
      tag = Tag.parse html
      assert_instance_of ATag, tag
    end
    
    def test_parsing_tags_which_have_not_their_own_class_h1
      html = '<h1>New Text</h1>'
      tag = Tag.parse html
      assert_instance_of HTag, tag
    end
    
    def test_parsing_tags_which_have_not_their_own_class_h3
      html = '<h3>New Text</h3>'
      tag = Tag.parse html
      assert_instance_of HTag, tag
    end
    
    def test_parsing_tags_which_have_not_their_own_class_b
      html = '<b>New Text</b>'
      tag = Tag.parse html
      assert_instance_of BiuTag, tag
    end
    
    def test_parsing_tags_which_have_not_their_own_class_strong
      html = '<strong>New Text</strong>'
      tag = Tag.parse html
      assert_instance_of BiuTag, tag
    end
    
    def test_parsing_tags_which_have_not_their_own_class_label
      html = '<span>New Text</span>'
      tag = Tag.parse html
      assert_instance_of SpanTag, tag
    end
    
    def test_parsing_tags_which_have_not_their_own_class_script
      html = '<script src="js/jquery-1.5.2.min.js"></script><script src="js/jquery.jswipe-0.1.2.js"></script>'
      tag = Tag.parse html
      assert_instance_of NothingTag, tag
    end
    
    def test_parsing_tags_which_have_not_their_own_class_link
      html = '<link href="css/styles.css" rel="stylesheet" />'
      tag = Tag.parse html
      assert_instance_of NothingTag, tag
    end
    
    def test_parsing_tags_which_have_not_their_own_class_select
      html = '<select>New Text</select>'
      tag = Tag.parse html
      assert_instance_of InputTag, tag
    end
    
    def test_parsing_tags_which_have_not_their_own_class_textarea
      html = '<textarea>New Text</textarea>'
      tag = Tag.parse html
      assert_instance_of InputTag, tag
    end
    
    def test_parsing_tags_which_have_not_their_own_class
      html = '<pre>New Text</pre>'
      tag = Tag.parse html
      assert_instance_of TextTags, tag
    end
    
    def test_getting_attributes_from_tag
      tag = Tag.new nil
      expected = {:id => nil, :class => nil, :hidden => nil}
      assert_equal expected, tag.attributes
    end
    
    def test_getting_content_from_tag
      tag = Tag.new nil
      expected = []
      assert_equal expected, tag.content
    end
    
    def test_getting_content_from_nested_tags###################################################################
      html = '<a href="http://abv.bg/" id="one" class="second">New Text <div id="new">Other Text</div> again first</a>'
      tag = Tag.parse html
      expected = ["New Text ", ["Other Text"], " again first"]
      p tag.content
      assert_equal tag.content, tag.content
    end
    
    def test_getting_title_of_no_html_tag
      html = '<a href="http://abv.bg/" id="one" class="second">New Text <div id="new">Other Text</div> again first</a>'
      tag = Tag.parse html
      assert_equal 'ATag', tag.title
    end
    
    def test_to_s_method_of_Tag
      html = '<a href="http://abv.bg/" id="one" class="second">New Text</a>'
      tag = Tag.parse html
      assert_equal '_New Text_', tag.to_s
    end
    
    def test_creating_a_html_tag
      html = '<html><head><title>This is HTML tag</title></head></html>'
      html_tag = Tag.parse html
      assert_instance_of HtmlTag, html_tag
    end
    
    def test_getting_title_of_a_html_tag
      html = '<html><head><title>This is HTML tag</title></head></html>'
      html_tag = Tag.parse html
      assert_equal 'This is HTML tag', html_tag.title
    end
    
    def test_creating_a_body_tag
      html = '<body><div>This is Body tag</div></body>'
      body_tag = Tag.parse html
      assert_instance_of BodyTag, body_tag
    end
    
    def test_getting_attributes_from_A_tag
      html = '<a href="http://abv.bg/" id="one" class="second">New Text</a>'
      tag = Tag.parse html
      expected = {:id => 'one', :class => 'second', :href => 'http://abv.bg/', :target => nil, :hidden => nil}
      assert_equal expected, tag.attributes
    end
    
    def test_getting_content_from_A_tag
      html = '<a href="http://abv.bg/" id="one" class="second">New Text</a>'
      tag = Tag.parse html
      expected = ['New Text']
      assert_equal expected, tag.content
    end
    
    def test_to_s_method_of_ATag
      html = '<a href="http://abv.bg/" id="one" class="second">New Text</a>'
      tag = Tag.parse html
      p tag.class
      assert_equal '_New Text_', tag.to_s
    end
    
    def test_creating_a_section_tag
      html = '<section><div>This is Section tag</div></section>'
      section_tag = Tag.parse html
      assert_instance_of SectionTag, section_tag
    end
    
    def test_creating_a_nothing_tag
      html = '<style type="text/css">
               #vulns-alert #vulns{
                background-color: #c33 ! important;
                width: 100%;
                text-align: center;
               }
   
               #vulns-alert #vulns a {
                color: #F99 ! important;
               }
              </style>'
      nothing_tag = Tag.parse html
      assert_instance_of NothingTag, nothing_tag
    end
    
    def test_creating_a_text_tag
      html = '<pre id="ultimate">Text</pre>'
      text_tag = Tag.parse html
      assert_instance_of TextTags, text_tag
    end
    
    def test_creating_a_div_tag
      html = '<div id="ultimate">Text</div>'
      div_tag = Tag.parse html
      assert_instance_of DivTag, div_tag
    end
    
    def test_creating_a_p_tag
      html = '<p>Text</p>'
      p_tag = Tag.parse html
      assert_instance_of PTag, p_tag
    end
    
    def test_creating_a_span_tag
      html = '<span>Text</span>'
      span_tag = Tag.parse html
      assert_instance_of SpanTag, span_tag
    end
    
    def test_creating_a_h1_tag
      html = '<h1>Text</h1>'
      h_tag = Tag.parse html
      assert_instance_of HTag, h_tag
    end
    
    def test_getting_attributes_from_h1_tag
      html = '<h1 id="hello">Text</h1>'
      h_tag = Tag.parse html
      expected = {:size => 18, :style => :bold, :id => 'hello', :class => nil, :hidden => nil}
      assert_equal expected, h_tag.attributes
    end
    
    def test_creating_a_h4_tag
      html = '<h4>Text</h4>'
      h_tag = Tag.parse html
      assert_instance_of HTag, h_tag
    end
    
    def test_getting_attributes_from_h4_tag
      html = '<h4 class="helloNew">Text</h4>'
      h_tag = Tag.parse html
      expected = {:size => 12, :style => :bold, :id => nil, :class => 'helloNew', :hidden => nil}
      assert_equal expected, h_tag.attributes
    end
    
    def test_creating_a_h8_tag
      html = '<h8>Text</h8>'
      h_tag = Tag.parse html
      assert_instance_of TextTags, h_tag
    end
    
    def test_creating_a_bold_tag
      html = '<b>Text</b>'
      bold_tag = Tag.parse html
      assert_instance_of BiuTag, bold_tag
    end
    
    def test_getting_attributes_from_bold_tag
      html = '<b>Text</b>'
      bold_tag = Tag.parse html
      expected = {:style => :bold, :id => nil, :class => nil, :hidden => nil}
      assert_equal expected, bold_tag.attributes
    end
    
    def test_creating_a_strong_tag
      html = '<strong>Text</strong>'
      strong_tag = Tag.parse html
      assert_instance_of BiuTag, strong_tag
    end
    
    def test_getting_attributes_from_strong_tag
      html = '<strong>Text</strong>'
      strong_tag = Tag.parse html
      expected = {:style => :bold, :id => nil, :class => nil, :hidden => nil}
      assert_equal expected, strong_tag.attributes
    end
    
    def test_creating_an_italic_tag
      html = '<i>Text</i>'
      italic_tag = Tag.parse html
      assert_instance_of BiuTag, italic_tag
    end
    
    def test_getting_attributes_from_italic_tag
      html = '<i>Text</i>'
      italic_tag = Tag.parse html
      expected = {:style => :italic, :id => nil, :class => nil, :hidden => nil}
      assert_equal expected, italic_tag.attributes
    end
    
    def test_creating_a_code_tag
      html = '<code>Text</code>'
      code_tag = Tag.parse html
      assert_instance_of CodeTag, code_tag
    end
    
    def test_getting_attributes_from_code_tag
      html = '<code>Text</code>'
      code_tag = Tag.parse html
      expected = {:font => "CourierNew", :id => nil, :class => nil, :hidden => nil}
      assert_equal expected, code_tag.attributes
    end
    
    def test_creating_a_hr_tag
      html = '<hr/>'
      hr_tag = Tag.parse html
      assert_instance_of HrTag, hr_tag
    end
    
    def test_method_to_s_of_a_hr_tag
      html = '<hr/>'
      hr_tag = Tag.parse html
      assert_equal "-" * 38, hr_tag.to_s
    end
    
    def test_creating_a_br_tag
      html = '<br/>'
      br_tag = Tag.parse html
      assert_instance_of BrTag, br_tag
    end
    
    def test_method_to_s_of_a_br_tag
      html = '<br/>'
      br_tag = Tag.parse html
      assert_equal "\n", br_tag.to_s
    end
    
    def test_creating_an_img_tag
      html = '<img src="http://google.com/something.jpg" width="200" height="150" />'
      img_tag = Tag.parse html
      assert_instance_of ImgTag, img_tag
    end
    
    def test_getting_attributes_from_img_tag
      html = '<img src="http://google.com/something.jpg" width="200" height="150" />'
      img_tag = Tag.parse html
      expected = {:alt => nil, :src => 'http://google.com/something.jpg', :width => 200, :height => 150, :id => nil, :class => nil, :hidden => nil}
      assert_equal expected, img_tag.attributes
    end
    
    def test_method_to_s_of_an_img_tag_without_alt
      html = '<img src="http://google.com/something.jpg" width="200" height="150" />'
      img_tag = Tag.parse html
      assert_equal "", img_tag.to_s
    end
    
    def test_method_to_s_of_an_img_tag_with_alt
      html = '<img src="http://google.com/something.jpg" width="200" height="150" alt="Image from Google" />'
      img_tag = Tag.parse html
      assert_equal "Image from Google", img_tag.to_s
    end
    
    def test_creating_a_table_tag
      html = '<table><tr><td>Cell1</td></tr></table>'
      table_tag = Tag.parse html
      assert_instance_of TableTag, table_tag
    end
    
    def test_getting_attributes_from_table_tag_without_border
      html = '<table><tr><td>Cell1</td></tr></table>'
      table_tag = Tag.parse html
      expected = {:border => nil, :id => nil, :class => nil, :hidden => nil}
      assert_equal expected, table_tag.attributes
    end
    
    def test_getting_attributes_from_table_tag_with_border
      html = '<table border="3"><tr><td>Cell1</td></tr></table>'
      table_tag = Tag.parse html
      expected = {:border => '3', :id => nil, :class => nil, :hidden => nil}
      assert_equal expected, table_tag.attributes
    end
    
    def test_creating_a_tr_tag
      html = '<tr><td>Cell1</td><td>Cell2</td></tr>'
      tr_tag = Tag.parse html
      assert_instance_of TrTag, tr_tag
    end
    
    def test_creating_a_td_tag
      html = '<td>Cell1</td>'
      td_tag = Tag.parse html
      assert_instance_of TdTag, td_tag
    end
    
    def test_creating_an_ul_tag
      html = '<ul><li>First</li><li>Second</li></ul>'
      ul_tag = Tag.parse html
      assert_instance_of UlTag, ul_tag
    end
    
    def test_getting_attributes_from_ul_tag
      html = '<ul><li>First</li><li>Second</li></ul>'
      ul_tag = Tag.parse html
      expected = {:type => 'ul', :id => nil, :class => nil, :hidden => nil}
      assert_equal expected, ul_tag.attributes
    end
    
    def test_method_to_s_of_an_ul_tag
      html = '<ol><li>First</li><li>Second</li></ol>'
      ul_tag = Tag.parse html
      assert_equal "First\nSecond", ul_tag.to_s
    end
    
    def test_creating_an_ol_tag
      html = '<ol><li>First</li><li>Second</li></ol>'
      ol_tag = Tag.parse html
      assert_instance_of OlTag, ol_tag
    end
    
    def test_getting_attributes_from_ol_tag
      html = '<ol><li>First</li><li>Second</li></ol>'
      ol_tag = Tag.parse html
      expected = {:id => nil, :class => nil, :hidden => nil}
      assert_equal expected, ol_tag.attributes
    end
    
    def test_method_to_s_of_an_ol_tag
      html = '<ol><li>First</li><li>Second</li></ol>'
      ol_tag = Tag.parse html
      assert_equal "First\nSecond", ol_tag.to_s
    end
    
    def test_creating_a_li_tag
      html = '<li>First</li>'
      li_tag = Tag.parse html
      assert_instance_of LiTag, li_tag
    end
    
    def test_getting_content_from_li_tag
      html = '<li>First</li>'
      li_tag = Tag.parse html
      expected = ['First']
      assert_equal expected, li_tag.content
    end
  end
end