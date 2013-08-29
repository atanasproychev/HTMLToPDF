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
      html = '<a href="http://abv.bg/" id="one" class="second">New Text</a>'
      tag = Tag.parse html
      expected = {:id => 'one', :class => 'second', :href => 'http://abv.bg/', :target => nil, :hidden => nil}
      assert_equal expected, tag.attributes
    end
  end
end