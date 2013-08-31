# encoding: utf-8
require 'nokogiri'
require 'prawn'
require 'open-uri'

module HTMLToPDF
  class Tag
    attr_accessor :content, :attributes

    def initialize(tag_tree)
      @attributes = {:class => nil, :id => nil, :hidden => nil}
      @tag_tree = tag_tree
      @content = []
    end

    def self.parse(content)
      tag_tree = content.kind_of?(String) ? Nokogiri::XML::DocumentFragment.parse(content).children[0] : content
      name = case tag_tree.name
               when /h[1-6]/
                 'h'
               when /\A((b|i|u)|strong)\z/
                 'biu'
               when 'label'
                 'span'
               when 'script', 'style', 'link', 'meta', 'head', 'title', 'option'
                 'nothing'
               when 'select', 'textarea', 'button'
                 'input'
               else
                 tag_tree.name
             end
      begin
        HTMLToPDF.const_get(name.capitalize + "Tag").new tag_tree
      rescue NameError
        TextTags.new tag_tree
      end
    end

    def get_attributes
      @attributes.each_key { |key| @attributes[key] ||= @tag_tree[key] }
    end

    def get_content
      @tag_tree.children.each do |child|
        @content << if child.name == 'text'
                      child.text
                    else
                      HTMLToPDF::Tag.parse(child)
                    end
      end
      @content.reject! { |item| item == "\n" or item == "\n\n" }
    end

    def title
      title = @tag_tree.css('title').text
      title.length == 0 ? self.class.to_s.match(/HTMLToPDF::(\w+)/)[1] : title
    end

    def to_pdf prawn_object
      @content.each do |item|
        if item.class == String
          render item, prawn_object
        else
          item.to_pdf prawn_object
        end
      end
    end

    def render(string, prawn_object)
      prawn_object.text string
    end

    def to_s
      @content.map { |item| item.to_s }.join " "
    end
  end

  class HtmlTag < Tag
    def initialize(tag_tree)
      super
      get_content
    end
  end

  class BodyTag < Tag
    def initialize(tag_tree)
      super
      get_content
    end
  end

  class ATag < Tag
    def initialize(tag_tree)
      super
      @attributes.merge!({:href => nil, :target => nil})
      get_attributes
      get_content
    end

    def render(string, prawn_object)
      prawn_object.formatted_text([{:text => string, :color => '189E18', :link => @attributes[:href]}])
    end

    def to_s
      str = ''
      @content.each do |item|
        str << (item.class == String ? "_#{item}_" : item.to_s)
      end
      str
    end
  end

  class SectionTag < Tag
    def initialize(tag_tree)
      super
      get_content
    end

    def to_pdf(prawn_object)
      prawn_object.start_new_page
      @content.map { |item| item.to_pdf(prawn_object) }
    end
  end

  class NothingTag < Tag
    def initialize(tag_tree)
      super
    end

    def to_pdf(prawn_object)
      prawn_object
    end
  end

  class TextTags < Tag
    def initialize(tag_tree, options = {})
      super(tag_tree)
      get_attributes
      @attributes.update options
      get_content
    end

    def render(string, prawn_object)
      prawn_object.formatted_text([{:text => string}.merge(@attributes)])
    end
  end

  class DivTag < TextTags
    def initialize(tag_tree)
      super
    end
  end

  class PTag < TextTags
    def initialize(tag_tree)
      super
    end
  end

  class SpanTag < TextTags
    def initialize(tag_tree)
      super
    end
  end

  class HTag < TextTags
    def initialize(tag_tree)
      type = /h([1-6])/.match(tag_tree.name)[1].to_i
      size = 18 - (type - 1) * 2
      options = {:size => size, :styles => [:bold]}
      super(tag_tree, options)
    end
  end

  class BiuTag < TextTags
    def initialize(tag_tree)
      option = case tag_tree.name
                 when 'b', 'strong'
                   :bold
                 when 'i'
                   :italic
                 when 'u'
                   :underline
               end
      super(tag_tree, {:styles => [option]})
    end
  end

  class CodeTag < TextTags
    def initialize(tag_tree)
      super(tag_tree, {:font => 'CourierNew'})
    end
  end

  class HrTag < Tag
    def initialize(tag_tree)
      super
    end

    def to_pdf(prawn_object)
      prawn_object.stroke_horizontal_rule
      prawn_object.move_down 15
    end

    def to_s
      '--------------------------------------'
    end
  end

  class BrTag < Tag
    def initialize(tag_tree)
      super
    end

    def to_pdf(prawn_object)
      prawn_object.move_down 10
    end

    def to_s
      "\n"
    end
  end

  class ImgTag < Tag
    def initialize(tag_tree)
      super
      @attributes.merge!({:alt => nil, :src => nil, :height => nil, :width => nil})
      get_attributes
    end

    def to_pdf(prawn_object)
      if (image = open @attributes[:src])
        prawn_object.image open(@attributes[:src]), @attributes
      else
        prawn_object.text @attributes[:alt]
      end
    end

    def get_attributes
      super
      @attributes[:height] = @attributes[:height].to_i if @attributes[:height]
      @attributes[:width] = @attributes[:width].to_i if @attributes[:width]
    end

    def to_s
      @attributes[:alt].nil? ? '' : @attributes[:alt].to_s
    end
  end

  class TableTag < Tag
    def initialize(tag_tree)
      super
      @attributes.merge!({:border => nil})
      get_attributes
      get_content
    end

    def to_pdf(prawn_object)
      border ||= @attributes[:border]
      prawn_object.table @content.map { |item| item.render(prawn_object) },
                         :cell_style => {:border_width => border.nil? ? 0 : border.to_i}
    end
  end

  class TrTag < Tag
    def initialize(tag_tree)
      super
      get_attributes
      get_content
    end

    def render(prawn_object)
      @content.map { |item| item.render(prawn_object) }.flatten(1)
    end
  end

  class TdTag < Tag
    def initialize(tag_tree)
      super
      get_attributes
      get_content
    end

    def render(prawn_object)
      @content.each { |item| item.to_pdf(prawn_object) unless item.class == String }
    end
  end

  class UlTag < Tag
    def initialize(tag_tree)
      super
      get_attributes
      @attributes.merge!({:type => 'ul'})
      get_content
    end

    def to_pdf(prawn_object)
      prawn_object.move_down 10
      @content.map { |item| item.render(@attributes[:type], prawn_object) }
    end

    def to_s
      @content.map { |item| item.to_s }.join "\n"
    end
  end

  class OlTag < Tag
    def initialize(tag_tree)
      super
      get_attributes
      get_content
    end

    def to_pdf(prawn_object)
      prawn_object.move_down 10
      @content.each_with_index { |item, index| item.render(index + 1, prawn_object) }
    end

    def to_s
      @content.map { |item| item.to_s }.join "\n"
    end
  end

  class LiTag < Tag
    def initialize(tag_tree)
      super
      get_attributes
      get_content
    end

    def render_ul(prawn_object)
      @content.each do |item|
        prawn_object.span(550) do
          prawn_object.fill_circle [5, prawn_object.cursor], 2
          if item.class == String
            prawn_object.text_box item, :at => [12, prawn_object.cursor + 4]
            lines = item.length / 52.0
            prawn_object.move_down (lines > lines.floor ? lines.ceil : lines) * 15
          else
            prawn_object.span(550, :position => 12) do
              prawn_object.move_up 5
              item.to_pdf prawn_object
              prawn_object.move_down 5
            end
          end
        end
      end
    end

    def render_ol(number, prawn_object)
      @content.each do |item|
        if item.class == String
          prawn_object.text_box "#{number}. #{item}", :at => [12, prawn_object.cursor + 4]
          lines = item.length / 52.0
          prawn_object.move_down (lines > lines.floor ? lines.ceil : lines) * 15
        else
          prawn_object.span(550, :position => 12) do
            prawn_object.move_up 5
            item.to_pdf prawn_object
            prawn_object.move_down 5
          end
        end
      end
    end

    def render(type, prawn_object)
      type == 'ul' ? render_ul(prawn_object) : render_ol(type, prawn_object)
    end
  end

  class InputTag < Tag
    def initialize(tag_tree)
      super
      @attributes.merge!({:name => tag_tree.name, :placeholder => nil, :type => nil, :value => nil,})
      get_attributes
      get_content
    end

    def render(prawn_object)
      @attributes[:type] ||= if @attributes[:name] == 'button' or
                              @attributes[:name] == 'textarea' or @attributes[:name] == 'select'
                             @attributes[:name]
                           end
      p @attributes[:type]
      case @attributes[:type]
        when 'button', 'submit', 'reset'
          prawn_object.fill_color 'B1B1B1'
          prawn_object.fill_rounded_rectangle [0, prawn_object.cursor], 50, 20, 5
          prawn_object.fill_color '000000'
          if @attributes[:type] == 'button'
            text = @tag_tree.child.nil? ? @attributes[:value] : @tag_tree.child.text
          else
            text = @attributes[:value]
          end
          prawn_object.text_box text, :at => [5, prawn_object.cursor - 5], :width => 48, :height => 18
        when 'email', 'password', 'text', 'search', 'url', 'date', 'time'
          prawn_object.stroke_rectangle [0, prawn_object.cursor], 110, 20
          text = if @attributes[:value]
                   @attributes[:value]
                 elsif @attributes[:placeholder]
                   prawn_object.fill_color 'B1B1B1'
                   @attributes[:placeholder]
                 else
                   ''
                 end
          prawn_object.text_box text, :at => [5, prawn_object.cursor - 5], :width => 108, :height => 18
        when 'number'
          prawn_object.stroke_rectangle [0, prawn_object.cursor], 110, 20
          prawn_object.text_box @attributes[:value].to_i ? @attributes[:value] : '',
                                :at => [5, prawn_object.cursor - 5], :width => 108, :height => 18
          prawn_object.fill_color 'B1B1B1'
          prawn_object.fill_and_stroke_rectangle [95, prawn_object.cursor], 15, 10
          prawn_object.fill_and_stroke_rectangle [95, prawn_object.cursor - 10], 15, 10
        when 'checkbox'
          prawn_object.stroke_rectangle [0, prawn_object.cursor - 3], 5, 5
          prawn_object.text_box @tag_tree.child.text, :at => [10, prawn_object.cursor]
        when 'radio'
          prawn_object.stroke_circle [2, prawn_object.cursor - 3], 3
          prawn_object.text_box @tag_tree.child.text, :at => [10, prawn_object.cursor]
        when 'textarea'
          prawn_object.stroke_rectangle [0, prawn_object.cursor], 510, 60
          text = if @attributes[:placeholder]
                   prawn_object.fill_color 'B1B1B1'
                   @attributes[:placeholder]
                 elsif @tag_tree.child
                   @tag_tree.child.text
                 else
                   ''
                 end
          prawn_object.text_box text, :at => [5, prawn_object.cursor - 5], :width => 508, :height => 58
          prawn_object.move_down 60
        when 'select'
          prawn_object.stroke_rectangle [0, prawn_object.cursor], 110, 20
          text = if @tag_tree.children[1].text
                   @tag_tree.children[1].text
                 else
                   ''
                 end
          prawn_object.text_box text, :at => [5, prawn_object.cursor - 5], :width => 108, :height => 18
          prawn_object.fill_color 'B1B1B1'
          prawn_object.fill_and_stroke_rectangle [95, prawn_object.cursor], 15, 20
          end
      prawn_object.fill_color '000000'
    end

    def to_pdf(prawn_object)
      prawn_object.span(550) do
        render prawn_object
      end
      prawn_object.move_down 25
    end
  end
end