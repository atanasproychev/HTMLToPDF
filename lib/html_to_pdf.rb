# encoding: utf-8
require 'nokogiri'
require 'prawn'
require 'open-uri'

module HTMLToPDF
  class Document
    attr_reader :content

    def initialize(html)
      @content = HTMLToPDF::Tag.parse html
      p @content.class
      @pdf = Prawn::Document.new
    end

    def to_pdf
      #@content.pdf = @pdf
      font_path = "#{Prawn::BASEDIR}/data/fonts/"
      @pdf.font_families.update("TimesNewRoman" => {:bold => font_path + "timesbd.ttf",
                                                    :italic => font_path + "timesi.ttf",
                                                    :bold_italic => font_path + "timesbi.ttf",
                                                    :normal => font_path + "times.ttf"},
                                "CourierNew" => {:normal => font_path + "cour.ttf"})
      @pdf.font "TimesNewRoman"
      p @pdf.font_size
      p @content.class
      @content.to_pdf @pdf
      name = @content.title
      p "name is #{name}"
      #p @pdf
      #@pdf.render_file "#{name}.pdf"
      @pdf.render_file "Test.pdf"
    end
  end

  class Tag
    attr_accessor :content, :attributes

    def initialize(tag_tree)
      @attributes = {:class => nil, :id => nil, :hidden => nil}
      @tag_tree = tag_tree
      @content = []
      #@pdf = Prawn::Document.new
    end

    def self.parse(content)
      # name = /<(\w+)\b/.match(html) ? $1 : "unknown"
      # return if name == "unknown"
      # html = /<(#{name}).*?<\/#{name}>/.match(html)
      # #html = html.reject(/<(#{name})/)
      # Object.const_get(name.capitalize + "Tag").new html.to_s
      # p html

      # puts name
      #p content
      #p content.class
      #test = HtmlTag.new nil
      tag_tree = content.kind_of?(String) ? Nokogiri::XML::DocumentFragment.parse(content).children[0] : content 
      #p tag_tree.name
       # tag_tree = 
      name = case tag_tree.name
               when /h[1-6]/
                 'h'
               when /\A((b|i|u)|strong)\z/
                 'biu'
               when 'label' #possible problem with CSS!
                 'span'
               when 'script', 'style', 'link', 'meta', 'head', 'title'
                 'nothing'
               when 'select', 'textarea', 'button'
                 'input'
               else
                 tag_tree.name
             end
      #p name
      #p HTMLToPDF.const_get(name.capitalize + "Tag").new tag_tree
      begin
        HTMLToPDF.const_get(name.capitalize + "Tag").new tag_tree
      rescue NameError
        #p "#{name} neshto"
        TextTags.new tag_tree
      end
    end

    def get_attributes
      # tag = only_tag
      # /id=(".*?")/.match(tag)
      # @attributes[:id] = $1.gsub(/\"/, "")
      # /class=(".*?")/.match(tag)
      # @attributes[:class] = $1.gsub(/\"/, "")
      # @attributes[:hidden] = if /hidden/.match(tag)
                              # true
                            # else
                              # false
                            # end
      # tag
      #p @attributes
      @attributes.each_key do |key|
        @attributes[key] = @tag_tree[key]
      end
    end

    def get_content
      #only_content = /<a.*?>(.*?)<\/a>/.match(@html)[1]
      #p only_content.scan(/<(\w+)>(.*?)<\/\1>/)
      #original_content = Nokogiri::XML::DocumentFragment.parse(@html)
      #p @tag_tree.children.children.length
      #p @tag_tree
      @tag_tree.children.each do |child|
        @content << if child.name == "text"
                      child.text
                    else
                      HTMLToPDF::Tag.parse(child)
                    end
        #p child.name
        #p child.text
        #puts "\n"
      end
      # @content.each do |item|
        # #item.gsub('\n', '')
        # #p item.class
      # end
      # #p @content
      @content.reject! { |item| item == "\n" or item == "\n\n" }
    end

    def title
      self.class
    end

    def to_pdf prawn_object
      #p @content
      @content.each do |item|
        if item.class == String
          render item, prawn_object
        else
          p item
          item.to_pdf prawn_object
        end
      end
    end

    def to_s
      @content.each { |object| object.to_s }
    end
  end

  class HtmlTag < Tag
    def initialize(tag_tree)
      super(tag_tree)
      get_content
      #to_pdf
    end

    def title
      @tag_tree.css('title').text
    end
    # def to_pdf(pdf)
      # p @content

      # @content.each { |item| item.to_pdf(pdf) }
      # #@pdf.render_file "test.pdf"
      # # Prawn::Document.generate("test.pdf") do
        # # #@content.each { |item| item.to_pdf }
        # # p @content
      # # end
    # end
  end

  class BodyTag < Tag
    def initialize(tag_tree)
      super
      get_content
      #to_pdf
    end
  end

  class ATag < Tag
    def initialize(html)
      super(html)
      @attributes.merge!({:href => nil, :target => nil})
      get_attributes
      get_content
      #p @attributes
    end

    def render(string, prawn_object)
      #p 'self '
      #p string
      #prawn_object.fill_color "189E18"
      prawn_object.formatted_text([{:text => string, :color => "189E18", :link => @attributes[:href]}])
      # @content.each do |item|
        # if item.class == String
          # pdf.text item
        # else
          # item.to_pdf(pdf)
        # end
      # end
      #pdf.render_file "testA.pdf"
    end

    # def get_attributes
      # tag = super
      # /href=(".*?")/.match(tag)
      # @attributes[:href] = $1.gsub(/\"/, "")
      # /target=(".*?")/.match(tag)
      # @attributes[:target] = $1.gsub(/\"/, "")
    # end
  end

  class SectionTag < Tag
    def initialize(tag_tree)
      super
      get_content
      #to_pdf
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
      #p @attributes
    end

    def render(string, prawn_object)
      p string
      prawn_object.formatted_text([{:text => string}.merge(@attributes)])
    end

    def to_pdf(prawn_object)
      prawn_object.span(550) do
        super
      end
    end
  end

  class DivTag < TextTags
    def initialize(tag_tree)
      super(tag_tree)
    end

    #def render(string, prawn_object)
      #prawn_object.fill_color "000000"
      #prawn_object.text string
      # p @content
      # @content.each do |item|
        # if item.class == String
          # pdf.text item
        # else
          # item.to_pdf pdf
        # end
      # end
    #end
  end

  class PTag < TextTags
    def initialize(tag_tree)
      super(tag_tree)
    end
  end

  class SpanTag < TextTags
    def initialize(tag_tree)
      super(tag_tree)
    end
  end

  class HTag < TextTags
    def initialize(tag_tree)
      type = /h([1-6])/.match(tag_tree.name)[1].to_i
      size = 18 - (type - 1) * 2
      options = {:size => size, :style => :bold}
      super(tag_tree, options)
    end
  end

  class BiuTag < TextTags
    def initialize(tag_tree)
      option = case tag_tree.name
                 when "b", "strong"
                   :bold
                 when "i"
                   :italic
                 when "u"
                   :underline
               end
      p option
      super(tag_tree, {:style => option})
    end
  end

  class CodeTag < TextTags
    def initialize(tag_tree)
      super(tag_tree, {:font => "CourierNew"})
    end
  end

  class HrTag < Tag
    def initialize(tag_tree)
      super(tag_tree)
    end

    def to_pdf(prawn_object)
      prawn_object.stroke_horizontal_rule
      prawn_object.move_down 15
    end

    def to_s
      "-------------"
    end
  end

  class BrTag < Tag
    def initialize(tag_tree)
      super(tag_tree)
    end

    def to_pdf(prawn_object)
      prawn_object.move_down 10
    end

    def to_s
      "             "
    end
  end

  class ImgTag < Tag
    def initialize(tag_tree)
      super
      @attributes.merge!({:alt => nil, :src => nil, :height => nil, :width => nil})
      get_attributes
      p @attributes
    end

    def to_pdf(prawn_object)
      p @attributes
      #if @attributes[:src] #when it is a URL and when is a file
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
      @attributes[:alt].to_s
    end
  end

  class TableTag < Tag
    def initialize(tag_tree)
      super(tag_tree)
      @attributes.merge!({:border => nil})
      get_attributes
      get_content
    end

    def to_pdf(prawn_object)
      #p @content[0].class
      #p @content.class
      border ||= @attributes[:border]
      p border
      prawn_object.table @content.map { |item| item.render(prawn_object) },
                         :cell_style => {:border_width => border.nil? ? 0 : border.to_i}
    end
  end

  class TrTag < Tag
    def initialize(tag_tree)
      super(tag_tree)
      get_attributes
      get_content
    end

    def render(prawn_object)
      #rows = []
      #p "predi"
      @content.map { |item| item.render(prawn_object) }.flatten(1)
      #p "tr:"
      #p @content
      #rows
    end
  end

  class TdTag < Tag
    def initialize(tag_tree)
      super(tag_tree)
      get_attributes
      get_content
    end

    def render(prawn_object)
      #p @content
      @content.each do |item|
        p item.class
        unless item.class == String
          item.to_pdf(prawn_object)
        end
      end
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
      @content.map { |item| item.render(@attributes[:type], prawn_object) }
    end
  end

  class OlTag < Tag
    def initialize(tag_tree)
      super
      get_attributes
      get_content
    end

    def to_pdf(prawn_object)
      @content.each_with_index { |item, index| item.render(index + 1, prawn_object) }
    end
  end

  class LiTag < Tag
    def initialize(tag_tree)
      super
      get_attributes
      get_content
    end

    def render_ul(prawn_object)
      p @content[0].class
      #prawn_object.fill_circle [5, prawn_object.cursor], 2
      @content.each do |item|
        prawn_object.span(550) do
          prawn_object.fill_circle [5, prawn_object.cursor], 2
          if item.class == String
            prawn_object.text_box item, :at => [12, prawn_object.cursor + 4]
            lines = item.length / 52.0
            prawn_object.move_down (lines > lines.floor ? lines.ceil : lines) * 15
          else
            item.to_pdf prawn_object
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
          item.to_pdf prawn_object
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
      @attributes.merge!({:checked => nil, :disabled => nil, :placeholder => nil, :type => tag_tree.name, :required => nil, :value => nil,})
      get_attributes
      get_content
    end

    def render(prawn_object)
      # if @attributes[:type].is_a? Array
        # p 'y'
      # end
      p @attributes[:type].class, @attributes[:type]
      case @attributes[:type]
        when 'button', 'submit', 'reset', ['Button']
          prawn_object.fill_color 'B1B1B1'
          prawn_object.fill_rounded_rectangle [0, prawn_object.cursor], 50, 20, 5
          prawn_object.fill_color '000000'
          if @attributes[:type] == 'button'
            text = @tag_tree.child.nil? ? @attributes[:value] : @tag_tree.child[0].text
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
          prawn_object.stroke_rectangle [0, prawn_object.cursor], 5, 5
          prawn_object.text_box @attributes[:value], :at => [10, prawn_object.cursor]
        when 'radio'
          prawn_object.stroke_circle [0, prawn_object.cursor], 3
          prawn_object.text_box @attributes[:value], :at => [10, prawn_object.cursor]
        when 'textarea'
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
      end
    end

    def to_pdf(prawn_object)
      prawn_object.span(550) do
        render prawn_object
      end
      prawn_object.move_down 25
    end
  end
end

# HtmlTag.parse '<p class="Something">Text <h3 id="test">Nov Text</h3> Something</p>'
# HtmlTag.parse '<p class="Something">Text <a href="test.com">Nov Text</a> Something</p>'
# HtmlTag.parse '<html><a href="test.com">Nov <a href="newtest.com">Q<div>k</div></a> Text</a><a>Something</a></html>'
# test = Document.new('<html><a href="test.com">Nov <a href="newtest.com">Q<div>k</div></a> Text</a><a>Something</a></html>')
# p test.class
# test.to_pdf
# HtmlTag.parse '<a href="test.com" id="new_a" class="test" target="_blank">Nov Q<div>kdfgdf <span>rgrgrgf</span></div> fghfh<div id="5">Hello</div> Text</a>'
# HtmlTag.parse '<a href="test.com" id="new_a" class="test" target="_blank">Nov Q<div>kdfgdf <label>rgrgrgf</label></div> fghfh<div id="5">Hello</div> Text</a>'
#Document.new('<a href="test.com" id="new_a" class="test" target="_blank">Nov Q<div>kdfgdf <label>rgrgrgf</label></div> fghfh<h6>Р—РґСЂР°РІРµР№</h6> <br />Text</a>').to_pdf
#Document.new('<a href="test.com" id="new_a" class="test" target="_blank">Nov Q<div>kdfgdf <label>rgrgrgf</label></div> fghfh<code>РҐРµР№</code> <br />Text</a>').to_pdf
#Document.new('<a href="test.com" id="new_a" class="test" target="_blank">Nov Q fghfh <img src="Google.jpg" alt="РўРѕРІР° Рµ Google" width="300" height="150" /> Text</a>').to_pdf
# HtmlTag.parse '<a href="test.com" id="new_a" class="test" target="_blank">Nov Q<div>kdfgdf <label>rgrgrgf</label></div> fghfh<div id="5">Hello</div> <br />Text</a>'
# p HtmlTag.parse '<a href="test.com" id="new_a" class="test" target="_blank">Nov Q
# <div>kdfgdf 
# <img src="http://www.google.com" alt="РўРѕРІР° Рµ Google" width="300" height="200"/></div> fghfh
# <div id="5">Hello</div> Text</a>'
# HtmlTag.parse '<a href="test.com" id="new_a" class="test" target="_blank">Nov Q<div>kdfgdf <i>rgrgrgf</i></div> fghfh<div id="5">Hello</div> Text</a>'
# HtmlTag.parse '<a href="test.com" id="new_a" class="test" target="_blank">Nov Q<div>kdfgdf <div>rgrgrgf</div></div> fghfh<div id="5">Hello</div> Text</a>'
#HtmlTag.parse '<a href="test.com" id="new_a" class="test" target="_blank">Nov Text</a>'
# Document.new('<table border="1" cellpadding="1" cellspacing="1">
# <tr style="font-weight: bold; color: white; text-align: center; background: grey">
# <td>РљР°С‚РµРґСЂР°</td>
# <td>Р”РёСЃС†РёРїР»РёРЅР°</td>
# <td>РҐРѕСЂР°СЂРёСѓРј</td>
# <td>РљСЂРµРґРёС‚Рё Р•РЎРўРљ</td>
# <td>Р“СЂСѓРїР° Р?Р”</td>
# <td>РџСЂРµРїРѕРґР°РІР°С‚РµР»</td>
# <td>Р?</td>
# <td>Р?РЎ</td>
# <td>РљРќ</td>
# <td>Рњ</td>
# <td>РњР?</td>
# <td>РџРњ</td>
# <td>РЎР?</td>
# <td>РЎС‚Р°С‚</td>

# </tr>
# <tr>

# <td>Р?Рў</td>
# <td>Р?РЅС„РѕСЂРјР°С†РёРѕРЅРЅРёС‚Рµ С‚РµС…РЅРѕР»РѕРіРёРё РІ РѕР±СѓС‡РµРЅРёРµС‚Рѕ РЅР° РґРµС†Р° СЃСЉСЃ СЃРїРµС†РёР°Р»РЅРё РѕР±СЂР°Р·РѕРІР°С‚РµР»РЅРё РїРѕС‚СЂРµР±РЅРѕСЃС‚Рё</td>
# <td>0+0+2</td>
# <td>2,5</td>
# <td>Р”</td>
# <td>Р°СЃ. Рў. Р—Р°С„РёСЂРѕРІР°-РњР°Р»С‡РµРІР°</td>
# <td>В </td>
# <td>В </td>
# <td>В </td>
# <td>В </td>
# <td>4</td>
# <td>В </td>
# <td>В </td>
# <td>В </td>

# </tr>
# <tr style="background: #D3D3D3;">

# <td>РћРњР?</td>
# <td>РљРѕРјР±РёРЅР°С‚РѕСЂРёРєР°, РІРµСЂРѕСЏС‚РЅРѕСЃС‚Рё Рё СЃС‚Р°С‚РёСЃС‚РёРєР° РІ СѓС‡РёР»РёС‰РЅРёСЏ РєСѓСЂСЃ РїРѕ РјР°С‚РµРјР°С‚РёРєР°</td>
# <td>2+2+0</td>
# <td>5</td>
# <td>Р”</td>
# <td>РїСЂРѕС„. Рљ. Р‘Р°РЅРєРѕРІ</td>
# <td>В </td>
# <td>В </td>
# <td>В </td>
# <td>В </td>
# <td>3</td>
# <td>В </td>
# <td>В </td>
# <td>В </td>

# </tr>
# <tr>

# <td>Р?Рў</td>
# <td>РЎРїРµС†РёС„РёС‡РЅРё РІСЉРїСЂРѕСЃРё РІ РѕР±СѓС‡РµРЅРёРµС‚Рѕ РїРѕ РёРЅС„РѕСЂРјР°С†РёРѕРЅРЅРё С‚РµС…РЅРѕР»РѕРіРёРё</td>
# <td>2+0+2</td>
# <td>5</td>
# <td>Р”</td>
# <td>РіР».Р°СЃ. Р•. РЎС‚РµС„Р°РЅРѕРІР°, РіР».Р°СЃ. Рќ. РќРёРєРѕР»РѕРІР°</td>
# <td>В </td>
# <td>В </td>
# <td>В </td>
# <td>В </td>
# <td>4</td>
# <td>В </td>
# <td>В </td>
# <td>В </td>

# </tr>
# </table>').to_pdf

# Document.new('<table>
# <tr>
# <td>РљР»РµС‚РєР° 1</td>
# <td>Cell 2</td>
# </tr>
# <tr>
# <td>2.1</td>
# <td>2.2</td>
# </tr>
# </table>').to_pdf

# Document.new('<ul><li class="action">Р?РЅС‚РµСЂС„РµР№СЃР° Рё РёРјРїР»РµРјРµРЅС‚Р°С†РёСЏ СЃР° РґРІРµ СЂР°Р·Р»РёС‡РЅРё РЅРµС‰Р°
# </li><li class="action">РҐСѓР±Р°РІРѕ Рµ РёРјРїР»РµРјРµРЅС‚Р°С†РёСЏС‚Р° РґР° РјРѕР¶Рµ РґР° СЃРµ РїСЂРѕРјРµРЅСЏ РЅРµР·Р°РІРёСЃРёРјРѕ РѕС‚ РёРЅС‚РµСЂС„РµР№СЃР°РҐСѓР±Р°РІРѕ Рµ РёРјРїР»РµРјРµРЅС‚Р°С†РёСЏС‚Р° РґР° РјРѕР¶Рµ РґР° СЃРµ РїСЂРѕРјРµРЅСЏ РЅРµР·Р°РІРёСЃРёРјРѕ РѕС‚ РёРЅС‚РµСЂС„РµР№СЃР°
# </li><li class="action">РҐСѓР±Р°РІРѕ Рµ <a href="http://test.com">РёРЅС‚РµСЂС„РµР№СЃР°</a> РґР° РЅРµ РїРѕРєР°Р·РІР° С‚РІСЉСЂРґРµ РјРЅРѕРіРѕ РѕС‚ РёРјРїР»РµРјРµРЅС‚Р°С†РёСЏС‚Р°
# </li><li class="action">РњРёСЃР»РµС‚Рµ Р·Р° С‚РѕРІР° РєР°С‚Рѕ РґРёР·Р°Р№РЅРІР°С‚Рµ РєР»Р°СЃРѕРІРµ</li></ul>').to_pdf


# Document.new('<html lang="bg"><head><meta charset="utf-8" /><!--[if lt IE 9]><script src="js/html5shim.js"></script><![endif]--><link href="css/styles.css" rel="stylesheet" /><link href="css/pygments.css" rel="stylesheet" /><title>08. РџР°СЂР°Р»РµР»РЅРѕ РїСЂРёСЃРІРѕСЏРІР°РЅРµ, case, РёРЅС‚СЂРѕСЃРїРµРєС†РёСЏ, require Рё РѕС‰Рµ</title></head><body><header><h1>08. РџР°СЂР°Р»РµР»РЅРѕ РїСЂРёСЃРІРѕСЏРІР°РЅРµ, case, РёРЅС‚СЂРѕСЃРїРµРєС†РёСЏ, require Рё РѕС‰Рµ</h1><nav></nav></header><div id="deck"><section><hgroup><h1>08. РџР°СЂР°Р»РµР»РЅРѕ РїСЂРёСЃРІРѕСЏРІР°РЅРµ, case, РёРЅС‚СЂРѕСЃРїРµРєС†РёСЏ, require Рё РѕС‰Рµ</h1><h2>5 РЅРѕРµРјРІСЂРё 2012</h2></hgroup></section><section>
# <hgroup><h1>Р”РЅРµСЃ</h1></hgroup>
# <ul><li class="action"><code>case</code> РІ Ruby
# </li><li class="action">РўСЂРёРєРѕРІРµ СЃ РїСЂРёСЃРІРѕСЏРІР°РЅРµ
# </li><li class="action"><code>require</code>
# </li><li class="action">РЎС‚СЂСѓРєС‚СѓСЂР° РЅР° РїСЂРѕСЃС‚РёС‡РєРё gem-РѕРІРµ
# </li><li class="action">Р—Р°РјСЂР°Р·СЏРІР°РЅРµ РЅР° РѕР±РµРєС‚Рё
# </li><li class="action">РњР°Р»РєРѕ РёРЅС‚СЂРѕСЃРїРµРєС†РёСЏ
# </li><li class="action">Р Р°Р·РЅРё</li></ul></section>
# <section>
# <hgroup><h1>case</h1></hgroup>
# <p>Р’ Ruby РёРјР° "switch". РљР°Р·РІР° СЃРµ <code>case</code>.</p><div class="highlight"><pre><span class="k">def</span> <span class="nf">quote</span><span class="p">(</span><span class="nb">name</span><span class="p">)</span>
  # <span class="k">case</span> <span class="nb">name</span>
    # <span class="k">when</span> <span class="s1">&#39;Yoda&#39;</span>
      # <span class="nb">puts</span> <span class="s1">&#39;Do or do not. There is no try.&#39;</span>
    # <span class="k">when</span> <span class="s1">&#39;Darth Vader&#39;</span>
      # <span class="nb">puts</span> <span class="s1">&#39;The Force is strong with this one.&#39;</span>
    # <span class="k">when</span> <span class="s1">&#39;R2-D2&#39;</span>
      # <span class="nb">puts</span> <span class="s1">&#39;Beep. Beep. Beep.&#39;</span>
    # <span class="k">else</span>
      # <span class="nb">puts</span> <span class="s1">&#39;Dunno what to say&#39;</span>
  # <span class="k">end</span>
# <span class="k">end</span>
# </pre>
# </div>
# </section>
# <section>
# <hgroup><h1>case</h1><h2>РѕСЃРѕР±РµРЅРѕСЃС‚Рё</h2></hgroup>
# <ul><li class="action">РќСЏРјР° fall-through. РќРµ СЃРµ РїРёС€Рµ <code>break</code>.
# </li><li class="action">РђРєРѕ РЅРёС‚Рѕ РµРґРёРЅ <code>when</code> РЅРµ РјРёРЅРµ, РёР·РїСЉР»РЅСЏРІР° СЃРµ <code>else</code>.
# </li><li class="action">РђРєРѕ РЅРёС‚Рѕ РµРґРёРЅ <code>when</code> РЅРµ РјРёРЅРµ, Рё РЅСЏРјР° <code>else</code>, РЅРµ СЃС‚Р°РІР° РЅРёС‰Рѕ.
# </li><li class="action"><code>case</code> Рµ РёР·СЂР°Р·, РєРѕРµС‚Рѕ Р·РЅР°С‡Рё, С‡Рµ РІСЂСЉС‰Р° СЃС‚РѕР№РЅРѕСЃС‚.</li></ul></section>
# <section>
# <hgroup><h1>case</h1><h2>Р°Р»С‚РµСЂРЅР°С‚РёРІРµРЅ СЃРёРЅС‚Р°РєСЃРёСЃ</h2></hgroup>
# <div class="highlight"><pre><span class="k">case</span> <span class="n">operation</span>
  # <span class="k">when</span> <span class="ss">:&amp;</span> <span class="k">then</span> <span class="nb">puts</span> <span class="s1">&#39;And?&#39;</span>
  # <span class="k">when</span> <span class="ss">:|</span> <span class="k">then</span> <span class="nb">puts</span> <span class="s1">&#39;Or...&#39;</span>
  # <span class="k">when</span> <span class="p">:</span><span class="o">!</span> <span class="k">then</span> <span class="nb">puts</span> <span class="s1">&#39;Not!&#39;</span>
# <span class="k">end</span>
# </pre>
# </div>
# </section>
# <section>
# <hgroup><h1>case</h1><h2>РІСЂСЉС‰Р°РЅР° СЃС‚РѕР№РЅРѕСЃС‚</h2></hgroup>
# <p>РќР° РєР°РєРІРѕ С‰Рµ СЃРµ РѕС†РµРЅРё СЃР»РµРґРЅРёСЏС‚ РєРѕРґ?</p><div class="highlight"><pre><span class="k">case</span> <span class="s1">&#39;Wat?&#39;</span>
  # <span class="k">when</span> <span class="s1">&#39;watnot&#39;</span> <span class="k">then</span> <span class="nb">puts</span> <span class="s2">&quot;I&#39;m on a horse.&quot;</span>
# <span class="k">end</span>
# </pre>
# </div>
# <div class="action answer"><p>РђРєРѕ РЅСЏРјР° <code>else</code> Рё РЅРёРєРѕР№ <code>when</code> РЅРµ match-РЅРµ, СЃРµ РІСЂСЉС‰Р° <code>nil</code>.</p></div></section>
# <section>
# <hgroup><h1>case</h1><h2>СЃС‚РѕР№РЅРѕСЃС‚Рё</h2></hgroup>
# <p><code>case</code> РЅРµ СЃСЂР°РІРЅСЏРІР° СЃ <code>==</code>. РњРѕР¶Рµ РґР° РЅР°РїРёС€РµС‚Рµ СЃР»РµРґРЅРѕС‚Рѕ.</p><div class="highlight"><pre><span class="k">def</span> <span class="nf">qualify</span><span class="p">(</span><span class="n">age</span><span class="p">)</span>
  # <span class="k">case</span> <span class="n">age</span>
    # <span class="k">when</span> <span class="mi">0</span><span class="o">.</span><span class="n">.</span><span class="mi">12</span>
      # <span class="s1">&#39;still very young&#39;</span>
    # <span class="k">when</span> <span class="mi">13</span><span class="o">.</span><span class="n">.</span><span class="mi">19</span>
      # <span class="s1">&#39;a teenager! oh no!&#39;</span>
    # <span class="k">when</span> <span class="mi">33</span>
      # <span class="s1">&#39;the age of jesus&#39;</span>
    # <span class="k">when</span> <span class="mi">90</span><span class="o">.</span><span class="n">.</span><span class="mi">200</span>
      # <span class="s1">&#39;wow. that is old!&#39;</span>
    # <span class="k">else</span>
      # <span class="s1">&#39;not very interesting&#39;</span>
    # <span class="k">end</span>
# <span class="k">end</span>
# </pre>
# </div>
# </section>
# <section>
# <hgroup><h1>case</h1><h2>Object#===</h2></hgroup>
# <p><code>case</code> СЃСЂР°РІРЅСЏРІР° СЃ <code>===</code>. РќСЏРєРѕР»РєРѕ РєР»Р°СЃР° РіРѕ РёРјРїР»РµРјРµРЅС‚РёСЂР°С‚:</p><ul><li class="action"><code>Range</code>
# </li><li class="action"><code>Regexp</code>
# </li><li class="action"><code>Class</code>
# </li><li class="action">РЎРїРёСЃСЉРєСЉС‚ РЅРµ Рµ РёР·С‡РµСЂРїР°С‚РµР»РµРЅ...
# </li><li class="action">РџРѕ РїРѕРґСЂР°Р·Р±РёСЂР°РЅРµ СЃРµ РѕС†РµРЅСЏРІР° РєР°С‚Рѕ <code>==</code>.</li></ul></section>
# <section>
# <hgroup><h1>case</h1><h2>Class#===</h2></hgroup>
# <div class="highlight"><pre><span class="k">def</span> <span class="nf">qualify</span><span class="p">(</span><span class="n">thing</span><span class="p">)</span>
  # <span class="k">case</span> <span class="n">thing</span>
    # <span class="k">when</span> <span class="nb">Integer</span> <span class="k">then</span> <span class="s1">&#39;this is a number&#39;</span>
    # <span class="k">when</span> <span class="nb">String</span> <span class="k">then</span> <span class="s1">&#39;it is a string&#39;</span>
    # <span class="k">when</span> <span class="nb">Array</span> <span class="k">then</span> <span class="n">thing</span><span class="o">.</span><span class="n">map</span> <span class="p">{</span> <span class="o">|</span><span class="n">item</span><span class="o">|</span> <span class="n">qualify</span> <span class="n">item</span> <span class="p">}</span>
    # <span class="k">else</span> <span class="s1">&#39;huh?&#39;</span>
  # <span class="k">end</span>
# <span class="k">end</span>
# </pre>
# </div>
# </section>
# <section>
# <hgroup><h1>case</h1><h2>Range#===</h2></hgroup>
# <div class="highlight"><pre><span class="k">case</span> <span class="n">hours_of_sleep</span>
  # <span class="k">when</span> <span class="mi">8</span><span class="o">.</span><span class="n">.</span><span class="mi">10</span> <span class="k">then</span> <span class="s1">&#39;I feel fine.&#39;</span>
  # <span class="k">when</span> <span class="mi">6</span><span class="o">.</span><span class="n">.</span><span class="o">.</span><span class="mi">8</span> <span class="k">then</span> <span class="s1">&#39;I am a little sleepy.&#39;</span>
  # <span class="k">when</span> <span class="mi">1</span><span class="o">.</span><span class="n">.</span><span class="mi">3</span>  <span class="k">then</span> <span class="s1">&#39;OUT OF MY WAY! I HAVE PLACES TO BE AND PEOPLE TO SEE!&#39;</span>
# <span class="k">end</span>
# </pre>
# </div>
# </section>
# <section>
# <hgroup><h1>case</h1><h2>Regexp#===</h2></hgroup>
# <div class="highlight"><pre><span class="k">def</span> <span class="nf">parse_date</span><span class="p">(</span><span class="n">date_string</span><span class="p">)</span>
  # <span class="k">case</span> <span class="n">date_string</span>
    # <span class="k">when</span><span class="sr"> /(\d{4})-(\d\d)-(\d\d)/</span>
      # <span class="no">Date</span><span class="o">.</span><span class="n">new</span> <span class="vg">$1</span><span class="o">.</span><span class="n">to_i</span><span class="p">,</span> <span class="vg">$2</span><span class="o">.</span><span class="n">to_i</span><span class="p">,</span> <span class="vg">$3</span><span class="o">.</span><span class="n">to_i</span>
    # <span class="k">when</span><span class="sr"> /(\d\d)\/(\d\d)/</span><span class="p">(\</span><span class="n">d</span><span class="p">{</span><span class="mi">4</span><span class="p">})</span><span class="o">/</span>
      # <span class="no">Date</span><span class="o">.</span><span class="n">new</span> <span class="vg">$3</span><span class="o">.</span><span class="n">to_i</span><span class="p">,</span> <span class="vg">$1</span><span class="o">.</span><span class="n">to_i</span><span class="p">,</span> <span class="vg">$2</span><span class="o">.</span><span class="n">to_i</span>
  # <span class="k">end</span>
# <span class="k">end</span>
# </pre>
# </div>
# </section>
# <section>
# <hgroup><h1>case</h1><h2>СЃ РѕР±РёРєРЅРѕРІРµРЅРё СѓСЃР»РѕРІРёСЏ</h2></hgroup>
# <ul><li class="action">РњРѕР¶РµС‚Рµ РґР° СЃР»Р°РіР°С‚Рµ Рё С†РµР»Рё РёР·СЂР°Р·Рё РІСЉРІ <code>when</code>
# </li><li class="action">Р?Р·РїСѓСЃРєР° СЃРµ РїР°СЂР°РјРµС‚СЉСЂСЉС‚ СЃР»РµРґ <code>case</code>, РЅР°РїСЂРёРјРµСЂ:</li></ul><div class="action"><div class="highlight"><pre><span class="n">thing</span> <span class="o">=</span> <span class="mi">42</span>
# <span class="k">case</span>
  # <span class="k">when</span> <span class="n">thing</span> <span class="o">==</span> <span class="mi">1</span> <span class="k">then</span> <span class="mi">1</span>
  # <span class="k">else</span> <span class="s1">&#39;no_idea&#39;</span>
# <span class="k">end</span>
# </pre>
# </div>
# </div><ul><li class="action">РќРµ РіРѕ РїСЂР°РІРµС‚Рµ.
# </li><li class="action">РђРєРѕ РІРё СЃРµ РЅР°Р»Р°РіР°, РїРѕР»Р·РІР°Р№С‚Рµ РѕР±РёРєРЅРѕРІРµРЅРё <code>if</code>-РѕРІРµ</li></ul></section>
# <section>
# <hgroup><h1>Р’СЉРїСЂРѕСЃРё РїРѕ case</h1></hgroup>
# <p>РЎРµРіР° Рµ РјРѕРјРµРЅС‚СЉС‚.</p></section>
# <section>
# <hgroup><h1>РџСЂРёСЃРІРѕСЏРІР°РЅРµ РІ Ruby</h1></hgroup>
# <ul><li class="action">РџСЂРёСЃРІРѕСЏРІР°РЅРµС‚Рѕ РІ Ruby:
# </li><li class="action"><code>foo = \'baba\'</code>
# </li><li class="action">РњРѕР¶Рµ РјР°Р»РєРѕ РїРѕРІРµС‡Рµ РѕС‚ С‚РѕРІР°... :)
# </li><li class="action">РџР°СЂР°Р»РµР»РЅРѕ РїСЂРёСЃРІРѕСЏРІР°РЅРµ
# </li><li class="action">Р’Р»РѕР¶РµРЅРѕ РїСЂРёСЃРІРѕСЏРІР°РЅРµ
# </li><li class="action">РљРѕРјР±РёРЅР°С†РёРё РјРµР¶РґСѓ РґРІРµС‚Рµ</li></ul></section>
# <section>
# <hgroup><h1>РџР°СЂР°Р»РµР»РЅРѕ РїСЂРёСЃРІРѕСЏРІР°РЅРµ</h1><h2>РїСЂРѕСЃС‚ РїСЂРёРјРµСЂ</h2></hgroup>
# <div class="highlight"><pre><span class="n">a</span><span class="p">,</span> <span class="n">b</span> <span class="o">=</span> <span class="mi">1</span><span class="p">,</span> <span class="mi">2</span>
# <span class="n">a</span>              <span class="c1"># 1</span>
# <span class="n">b</span>              <span class="c1"># 2</span>

# <span class="n">a</span><span class="p">,</span> <span class="n">b</span> <span class="o">=</span> <span class="n">b</span><span class="p">,</span> <span class="n">a</span>
# <span class="n">a</span>              <span class="c1"># 2</span>
# <span class="n">b</span>              <span class="c1"># 1</span>
# </pre>
# </div>
# <p>Р?РјР° РЅСЏРєРѕР»РєРѕ СЂР°Р·Р»РёС‡РЅРё СЃР»СѓС‡Р°СЏ, РєРѕРёС‚Рѕ С‰Рµ СЂР°Р·РіР»РµРґР°РјРµ.</p></section>
# <section>
# <hgroup><h1>РџР°СЂР°Р»РµР»РЅРѕ РїСЂРёСЃРІРѕСЏРІР°РЅРµ</h1><h2>РїСЂРёСЃРІРѕСЏРІР°РЅРµ РЅР° РµРґРЅР° РїСЂРѕРјРµРЅР»РёРІР°</h2></hgroup>
# <div class="highlight"><pre><span class="n">a</span> <span class="o">=</span> <span class="mi">1</span><span class="p">,</span> <span class="mi">2</span><span class="p">,</span> <span class="mi">3</span>
# <span class="n">a</span> <span class="c1"># [1, 2, 3]</span>
# </pre>
# </div>
# <p>РџСЂР°РєС‚РёС‡РµСЃРєРё СЃСЉС‰РѕС‚Рѕ РєР°С‚Рѕ <code>a = [1, 2, 3]</code></p></section>
# <section>
# <hgroup><h1>РџР°СЂР°Р»РµР»РЅРѕ РїСЂРёСЃРІРѕСЏРІР°РЅРµ</h1><h2>СЂР°Р·РїР°РєРµС‚РёСЂР°РЅРµ РЅР° РґСЏСЃРЅР°С‚Р° СЃС‚СЂР°РЅР°</h2></hgroup>
# <div class="highlight"><pre><span class="n">a</span><span class="p">,</span> <span class="n">b</span> <span class="o">=</span> <span class="o">[</span><span class="mi">1</span><span class="p">,</span> <span class="mi">2</span><span class="p">,</span> <span class="mi">3</span><span class="o">]</span>
# <span class="n">a</span> <span class="c1"># 1</span>
# <span class="n">b</span> <span class="c1"># 2</span>

# <span class="n">a</span><span class="p">,</span> <span class="n">b</span> <span class="o">=</span> <span class="mi">1</span><span class="p">,</span> <span class="mi">2</span><span class="p">,</span> <span class="mi">3</span>
# <span class="n">a</span> <span class="c1"># 1</span>
# <span class="n">b</span> <span class="c1"># 2</span>
# </pre>
# </div>
# <ul><li class="action">Р?Р·Р»РёС€РЅРёС‚Рµ Р°СЂРіСѓРјРµРЅС‚Рё РІРґСЏСЃРЅРѕ СЃРµ РёРіРЅРѕСЂРёСЂР°С‚
# </li><li class="action">РЎРєРѕР±РёС‚Рµ СЃР° "РѕРїС†РёРѕРЅР°Р»РЅРё" РІ С‚РѕР·Рё СЃР»СѓС‡Р°Р№
# </li><li class="action">РђРєРѕ РІР»СЏРІРѕ РёРјР°С‚Рµ РїРѕРІРµС‡Рµ РїСЂРѕРјРµРЅР»РёРІРё РѕС‚РєРѕР»РєРѕС‚Рѕ РІРґСЏСЃРЅРѕ, С‚Рµ С‰Рµ РїРѕР»СѓС‡Р°С‚ СЃС‚РѕР№РЅРѕСЃС‚ <code>nil</code></li></ul></section>
# <section>
# <hgroup><h1>РџР°СЂР°Р»РµР»РЅРѕ РїСЂРёСЃРІРѕСЏРІР°РЅРµ</h1><h2>СЃСЉСЃ splat Р°СЂРіСѓРјРµРЅС‚Рё</h2></hgroup>
# <div class="highlight"><pre><span class="n">head</span><span class="p">,</span> <span class="o">*</span><span class="n">tail</span> <span class="o">=</span> <span class="o">[</span><span class="mi">1</span><span class="p">,</span> <span class="mi">2</span><span class="p">,</span> <span class="mi">3</span><span class="o">]</span>
# <span class="n">head</span>   <span class="c1"># 1</span>
# <span class="n">tail</span>   <span class="c1"># [2, 3]</span>

# <span class="n">first</span><span class="p">,</span> <span class="o">*</span><span class="n">middle</span><span class="p">,</span> <span class="n">last</span> <span class="o">=</span> <span class="mi">1</span><span class="p">,</span> <span class="mi">2</span><span class="p">,</span> <span class="mi">3</span><span class="p">,</span> <span class="mi">4</span>
# <span class="n">first</span>  <span class="c1"># 1</span>
# <span class="n">middle</span> <span class="c1"># [2, 3]</span>
# <span class="n">last</span>   <span class="c1"># 4</span>
# </pre>
# </div>
# <ul><li class="action"><code>middle</code> Рё <code>head</code> РѕР±РёСЂР°С‚ РІСЃРёС‡РєРѕ РѕСЃС‚Р°РЅР°Р»Рѕ
# </li><li class="action">РћС‡РµРІРёРґРЅРѕ, РјРѕР¶Рµ РґР° РёРјР°С‚Рµ СЃР°РјРѕ РµРґРЅР° splat-РїСЂРѕРјРµРЅР»РёРІР° РЅР° РїСЂРёСЃРІРѕСЏРІР°РЅРµ</li></ul></section>
# <section>
# <hgroup><h1>РџР°СЂР°Р»РµР»РЅРѕ РїСЂРёСЃРІРѕСЏРІР°РЅРµ</h1><h2>splat Р°СЂРіСѓРјРµРЅС‚Рё РѕС‚РґСЏСЃРЅРѕ</h2></hgroup>
# <div class="highlight"><pre><span class="n">first</span><span class="p">,</span> <span class="o">*</span><span class="n">middle</span><span class="p">,</span> <span class="n">last</span> <span class="o">=</span> <span class="mi">1</span><span class="p">,</span> <span class="o">[</span><span class="mi">2</span><span class="p">,</span> <span class="mi">3</span><span class="p">,</span> <span class="mi">4</span><span class="o">]</span>
# <span class="n">first</span>  <span class="c1"># 1</span>
# <span class="n">middle</span> <span class="c1"># []</span>
# <span class="n">last</span>   <span class="c1"># [2, 3, 4]</span>

# <span class="n">first</span><span class="p">,</span> <span class="o">*</span><span class="n">middle</span><span class="p">,</span> <span class="n">last</span> <span class="o">=</span> <span class="mi">1</span><span class="p">,</span> <span class="o">*[</span><span class="mi">2</span><span class="p">,</span> <span class="mi">3</span><span class="p">,</span> <span class="mi">4</span><span class="o">]</span>
# <span class="n">first</span>  <span class="c1"># 1</span>
# <span class="n">middle</span> <span class="c1"># [2, 3]</span>
# <span class="n">last</span>   <span class="c1"># 4</span>
# </pre>
# </div>
# </section>
# <section>
# <hgroup><h1>Р’Р»РѕР¶РµРЅРѕ РїСЂРёСЃРІРѕСЏРІР°РЅРµ</h1></hgroup>
# <div class="highlight"><pre><span class="n">head</span><span class="p">,</span> <span class="p">(</span><span class="n">title</span><span class="p">,</span> <span class="n">body</span><span class="p">)</span> <span class="o">=</span> <span class="o">[</span><span class="mi">1</span><span class="p">,</span> <span class="o">[</span><span class="mi">2</span><span class="p">,</span> <span class="mi">3</span><span class="o">]]</span>
# <span class="n">head</span>   <span class="c1"># 1</span>
# <span class="n">title</span>  <span class="c1"># 2</span>
# <span class="n">body</span>   <span class="c1"># 3</span>
# </pre>
# </div>
# <ul><li class="action">РЎРєРѕР±РёС‚Рµ РІРё РїРѕР·РІРѕР»СЏРІР°С‚ РґР° РІР»РµР·РµС‚Рµ РµРґРЅРѕ РЅРёРІРѕ "РЅР°РІСЉС‚СЂРµ" Рё РґР° СЂР°Р·Р±РёРµС‚Рµ РїРѕРґР°РґРµРЅ СЃРїРёСЃСЉРє РЅР° РїСЂРѕРјРµРЅР»РёРІРё
# </li><li class="action">РќРµ СЃС‚Рµ РѕРіСЂР°РЅРёС‡РµРЅРё СЃР°РјРѕ РґРѕ РґРІРµ РЅРёРІР° (С‚РѕРІР° СЂР°Р±РѕС‚Рё: <code>head, (title, (body,)) = [1, [2, [3]]]</code>)
# </li><li class="action">РњРѕР¶РµС‚Рµ РґР° РіРё РєРѕРјР±РёРЅРёСЂР°С‚Рµ СЃ РїР°СЂР°Р»РµР»РЅРѕС‚Рѕ РїСЂРёСЃРІРѕСЏРІР°РЅРµ, Р·Р° РґР° РїСЂР°РІРёС‚Рµ СЃР»РѕР¶РЅРё РјР°РіР°СЂРёРё</li></ul></section>
# <section>
# <hgroup><h1>Р’Р»РѕР¶РµРЅРѕ РїСЂРёСЃРІРѕСЏРІР°РЅРµ Рё splat-РѕРІРµ</h1></hgroup>
# <div class="highlight"><pre><span class="n">head</span><span class="p">,</span> <span class="p">(</span><span class="n">title</span><span class="p">,</span> <span class="o">*</span><span class="n">sentences</span><span class="p">)</span> <span class="o">=</span> <span class="mi">1</span><span class="p">,</span> <span class="o">[</span><span class="mi">2</span><span class="p">,</span> <span class="mi">3</span><span class="p">,</span> <span class="mi">4</span><span class="p">,</span> <span class="mi">5</span><span class="p">,</span> <span class="mi">6</span><span class="o">]</span>
# <span class="n">head</span>      <span class="c1"># 1</span>
# <span class="n">title</span>     <span class="c1"># 2</span>
# <span class="n">sentences</span> <span class="c1"># [3, 4, 5, 6]</span>
# </pre>
# </div>
# <ul><li class="action">РњРѕР¶Рµ РґР° РёРјР°С‚Рµ РїРѕ РµРґРЅР° Р·РІРµР·РґРёС‡РєР° РЅР° "РЅРёРІРѕ" (С‚.Рµ. СЃРєРѕР±Рё)</li></ul></section>
# <section>
# <hgroup><h1>Р РµРґ РЅР° РѕС†РµРЅРєР°</h1></hgroup>
# <p>Р‘РµР»РµР¶РєР° Р·Р° СЂРµРґР° РЅР° РѕС†РµРЅРєР° РїСЂРё РїСЂРёСЃРІРѕСЏРІР°РЅРµ вЂ” РїСЉСЂРІРѕ РѕС‚РґСЏСЃРЅРѕ, СЃР»РµРґ С‚РѕРІР° РѕС‚Р»СЏРІРѕ:</p><div class="highlight"><pre><span class="n">x</span> <span class="o">=</span> <span class="mi">0</span>
# <span class="n">a</span><span class="p">,</span> <span class="n">b</span><span class="p">,</span> <span class="n">c</span> <span class="o">=</span> <span class="n">x</span><span class="p">,</span> <span class="p">(</span><span class="n">x</span> <span class="o">+=</span> <span class="mi">1</span><span class="p">),</span> <span class="p">(</span><span class="n">x</span> <span class="o">+=</span> <span class="mi">1</span><span class="p">)</span>
# <span class="n">x</span> <span class="c1"># 2</span>
# <span class="n">a</span> <span class="c1"># 0</span>
# <span class="n">b</span> <span class="c1"># 1</span>
# <span class="n">c</span> <span class="c1"># 2</span>
# </pre>
# </div>
# </section>
# <section>
# <hgroup><h1>РџСЂРѕРјРµРЅР»РёРІР°С‚Р° _</h1></hgroup>
# <ul><li class="action">РќРѕСЃРё СЃРµРјР°РЅС‚РёРєР° РЅР° placeholder ("С‚РѕР·Рё Р°СЂРіСѓРјРµРЅС‚ РЅРµ РјРё С‚СЂСЏР±РІР°")
# </li><li class="action">РћСЃРІРµРЅ С‚Р°Р·Рё СЃРµРјР°РЅС‚РёРєР°, РІ Ruby Рµ Рё РјР°Р»РєРѕ РїРѕ-СЃРїРµС†РёР°Р»РЅР°</li></ul></section>
# <section>
# <hgroup><h1>РџСЂРѕРјРµРЅР»РёРІР°С‚Р° _</h1></hgroup>
# <p>РњРѕР¶Рµ РґР° РїРѕР»Р·РІР°С‚Рµ РµРґРЅРѕ РёРјРµ СЃР°РјРѕ РµРґРёРЅ РїСЉС‚, РєРѕРіР°С‚Рѕ С‚Рѕ СЃРµ СЃСЂРµС‰Р° РІ СЃРїРёСЃСЉРє СЃ РїР°СЂР°РјРµС‚СЂРё РЅР° РјРµС‚РѕРґ, Р±Р»РѕРє Рё РїСЂРѕС‡РµРµ.</p><div class="highlight"><pre><span class="no">Proc</span><span class="o">.</span><span class="n">new</span> <span class="p">{</span> <span class="o">|</span><span class="n">a</span><span class="p">,</span> <span class="n">b</span><span class="p">,</span> <span class="n">a</span><span class="o">|</span> <span class="p">}</span> <span class="c1"># SyntaxError: duplicated argument name</span>
# <span class="no">Proc</span><span class="o">.</span><span class="n">new</span> <span class="p">{</span> <span class="o">|</span><span class="n">_</span><span class="p">,</span> <span class="n">b</span><span class="p">,</span> <span class="n">_</span><span class="o">|</span> <span class="p">}</span> <span class="c1"># =&gt; #&lt;Proc:0x007f818af68de0@(irb):23&gt;</span>
# </pre>
# </div>
# <p>Р“РѕСЂРЅРѕС‚Рѕ РІР°Р¶Рё РЅРµ СЃР°РјРѕ Р·Р° Р±Р»РѕРєРѕРІРµ, РЅРѕ Рё Р·Р° РјРµС‚РѕРґРё.</p></section>
# <section>
# <hgroup><h1>РџСЂРёСЃРІРѕСЏРІР°РЅРµ РІ Ruby</h1><h2>РљСЉРґРµ РІР°Р¶Р°С‚ С‚РµР·Рё РїСЂР°РІРёР»Р°?</h2></hgroup>
# <ul><li class="action">РћС‡РµРІРёРґРЅРѕ, РїСЂРё РЅРѕСЂРјР°Р»РЅРѕ РїСЂРёСЃРІРѕСЏРІР°РЅРµ
# </li><li class="action">РўРѕРІР° РІРєР»СЋС‡РІР° Рё РІСЂСЉС‰Р°РЅР° СЃС‚РѕР№РЅРѕСЃС‚ РѕС‚ РјРµС‚РѕРґ, РЅР°РїСЂРёРјРµСЂ <code>success, message = execute(job)</code>
# </li><li class="action">РџСЂРё СЂР°Р·РіСЉРІР°РЅРµ РЅР° Р°СЂРіСѓРјРµРЅС‚Рё РЅР° Р±Р»РѕРєРѕРІРµ, РЅР°РїСЂРёРјРµСЂ:</li></ul><div class="action"><div class="highlight"><pre><span class="o">[[</span><span class="mi">1</span><span class="p">,</span> <span class="o">[</span><span class="mi">2</span><span class="p">,</span> <span class="mi">3</span><span class="o">]]</span><span class="p">,</span> <span class="o">[</span><span class="mi">4</span><span class="p">,</span> <span class="o">[</span><span class="mi">5</span><span class="p">,</span> <span class="mi">6</span><span class="o">]]</span><span class="p">,</span> <span class="o">[</span><span class="mi">7</span><span class="p">,</span> <span class="o">[</span><span class="mi">8</span><span class="p">,</span> <span class="mi">9</span><span class="o">]]].</span><span class="n">each</span> <span class="k">do</span> <span class="o">|</span><span class="n">a</span><span class="p">,</span> <span class="p">(</span><span class="n">b</span><span class="p">,</span> <span class="n">c</span><span class="p">)</span><span class="o">|</span>
  # <span class="nb">puts</span> <span class="s2">&quot;</span><span class="si">#{</span><span class="n">a</span><span class="si">}</span><span class="s2">, </span><span class="si">#{</span><span class="n">b</span><span class="si">}</span><span class="s2">, </span><span class="si">#{</span><span class="n">c</span><span class="si">}</span><span class="s2">&quot;</span>
# <span class="k">end</span>
# <span class="c1"># 1, 2, 3</span>
# <span class="c1"># 4, 5, 6</span>
# <span class="c1"># 7, 8, 9</span>
# </pre>
# </div>
# </div><ul><li class="action">Р”РѕРЅСЏРєСЉРґРµ Рё РїСЂРё СЂР°Р·РіСЉРІР°РЅРµ РЅР° Р°СЂРіСѓРјРµРЅС‚Рё РЅР° РјРµС‚РѕРґРё (Р±СЂРѕР№РєР°С‚Р° С‚СЂСЏР±РІР° РґР° РѕС‚РіРѕРІР°СЂСЏ)
# </li><li class="action">Р—Р°РїРѕРјРЅРµС‚Рµ РіРё</li></ul></section>
# <section>
# <hgroup><h1>РџСЂРёСЃРІРѕСЏРІР°РЅРµ РІ Ruby</h1></hgroup>
# <p>Р?РјР°С‚Рµ Р»Рё РІСЉРїСЂРѕСЃРё РїРѕ С‚Р°Р·Рё С‚РµРјР°?</p></section>
# <section>
# <hgroup><h1>Р?РјРїРѕСЂС‚РёСЂР°РЅРµ РЅР° С„Р°Р№Р»РѕРІРµ</h1></hgroup>
# <p>Р’ Ruby, РєРѕРґ РѕС‚ РґСЂСѓРіРё С„Р°Р№Р»РѕРІРµ СЃРµ РёРјРїРѕСЂС‚РёСЂР° СЃ <code>require</code>.</p><div class="action"><p>РќР°РїСЂРёРјРµСЂ:</p><div class="highlight"><pre><span class="nb">require</span> <span class="s1">&#39;bigdecimal&#39;</span>
# <span class="nb">require</span> <span class="s1">&#39;bigdecimal/util&#39;</span>
# </pre>
# </div>
# </div></section>
# <section>
# <hgroup><h1>РљР°РєРІРѕ С‚СЉСЂСЃРё require?</h1></hgroup>
# <ul><li class="action"><code>require \'foo\'</code> С‚СЉСЂСЃРё С„Р°Р№Р» <code>foo.rb</code> РІ "РїСЉС‚СЏ Р·Р° Р·Р°СЂРµР¶РґР°РЅРµ".
# </li><li class="action">РћС‰Рµ РёР·РІРµСЃС‚РµРЅ РєР°С‚Рѕ load path.
# </li><li class="action">РўРѕР№ СЃСЉРґСЉСЂР¶Р° РЅСЏРєРѕР»РєРѕ "СЃРёСЃС‚РµРјРЅРё" РїСЉС‚РёС‰Р°, РїР»СЋСЃ РїСЉС‚РёС‰Р° РѕС‚ gem-РѕРІРµ, РєРѕРёС‚Рѕ СЃС‚Рµ СЃРё РёРЅСЃС‚Р°Р»РёСЂР°Р»Рё.
# </li><li class="action">РћС‡РµРІРёРґРЅРѕ, <code>require \'foo/bar\'</code> С‚СЉСЂСЃРё РґРёСЂРµРєС‚РѕСЂРёСЏ <code>foo</code> СЃ С„Р°Р№Р» <code>bar.rb</code>.
# </li><li class="action">Р Р°Р·С€РёСЂРµРЅРёРµС‚Рѕ <code>.rb</code> РѕС‚Р·Р°Рґ РЅРµ Рµ Р·Р°РґСЉР»Р¶РёС‚РµР»РЅРѕ РґР° РїСЂРёСЃСЉСЃС‚РІР°.
# </li><li class="action"><code>require \'./foo\'</code> С‚СЉСЂСЃРё <code>foo.rb</code> РІ С‚РµРєСѓС‰Р°С‚Р° РґРёСЂРµРєС‚РѕСЂРёСЏ.
# </li><li class="action">Р Р°Р·Р±РёСЂР° СЃРµ, Р°Р±СЃРѕР»СЋС‚РЅРё РїСЉС‚РёС‰Р° СЃСЉС‰Рѕ СЂР°Р±РѕС‚СЏС‚: <code>require \'/home/skanev/foo.rb\'</code>.</li></ul></section>
# <section>
# <hgroup><h1>Р—Р°СЂРµР¶РґР°РЅРµ РЅР° С„Р°Р№Р»РѕРІРµ РѕС‚ С‚РµРєСѓС‰Р°С‚Р° РґРёСЂРµРєС‚РѕСЂРёСЏ</h1></hgroup>
# <ul><li class="action">РћР±РёРєРЅРѕРІРµРЅРѕ РІСЉРІ РІР°С€РёСЏ load path С‚РµРєСѓС‰Р°С‚Р° РґРёСЂРµРєС‚РѕСЂРёСЏ РЅРµ РїСЂРёСЃСЉСЃС‚РІР°
# </li><li class="action">РќСЏРєРѕРё С…РѕСЂР° СЃРµ РѕСЃРјРµР»СЏРІР°С‚ РґР° СЃРё СЏ РґРѕР±Р°РІСЏС‚, РїСЂРѕРјРµРЅСЏР№РєРё load path
# </li><li class="action">РђРґСЉС‚ СЃРµ РѕС‚РІР°СЂСЏ Рё РіРё РїРѕРіР»СЉС‰Р°
# </li><li class="action">РџРѕР»Р·РІР°Р№С‚Рµ СЂРµР»Р°С‚РёРІРµРЅ РїСЉС‚, С‚.Рµ. <code>require \'./foo\'</code></li></ul></section>
# <section>
# <hgroup><h1>Р—Р°СЂРµР¶РґР°РЅРµ РЅР° С„Р°Р№Р»РѕРІРµ РѕС‚ С‚РµРєСѓС‰Р°С‚Р° РґРёСЂРµРєС‚РѕСЂРёСЏ</h1><h2>require_relative</h2></hgroup>
# <ul><li class="action">РђР»С‚РµСЂРЅР°С‚РёРІР° РЅР° РіРѕСЂРЅРѕС‚Рѕ Рµ <code>require_relative</code>
# </li><li class="action"><code>require_relative \'foo\'</code> Р·Р°СЂРµР¶РґР° \'foo\' СЃРїСЂСЏРјРѕ <strong>РґРёСЂРµРєС‚РѕСЂРёСЏС‚Р° РЅР° РёР·РїСЉР»РЅСЏРІР°С‰РёСЏ СЃРµ С„Р°Р№Р»</strong>
# </li><li class="action"><code>require \'./foo\'</code> Р·Р°СЂРµР¶РґР° СЃРїСЂСЏРјРѕ <strong>С‚РµРєСѓС‰Р°С‚Р° РґРёСЂРµРєС‚РѕСЂРёСЏ РЅР° РёР·РїСЉР»РЅСЏРІР°С‰РёСЏ РїСЂРѕС†РµСЃ</strong></li></ul></section>
# <section>
# <hgroup><h1>Load path</h1><h2>РєСЉРґРµС‚Рѕ Ruby С‚СЉСЂСЃРё С„Р°Р№Р»РѕРІРµ Р·Р° require</h2></hgroup>
# <ul><li>Р”РѕСЃС‚СЉРїРµРЅ Рµ РєР°С‚Рѕ <code>$LOAD_PATH</code>.</li><li>РћС‰Рµ <code>$:</code></li><li>РњРѕР¶Рµ РґР° РіРѕ РїСЂРѕРјРµРЅСЏС‚Рµ. РЎС‚Р°РЅРґР°СЂС‚РЅРѕ СЃ <code>$:.unshift(path)</code></li><li>РќРµ Рµ РјРЅРѕРіРѕ РґРѕР±СЂР° РїСЂР°РєС‚РёРєР° РґР° РіРѕ РїСЂР°РІРёС‚Рµ.</li></ul></section>
# <section>
# <hgroup><h1>РљР°Рє СЂР°Р±РѕС‚Рё require?</h1></hgroup>
# <ul><li class="action">Р?Р·РїСЉР»РЅСЏРІР° С„Р°Р№Р»Р°.
# </li><li class="action">РљРѕРЅСЃС‚Р°РЅС‚РёС‚Рµ, РєР»Р°СЃРѕРІРµ, РіР»РѕР±Р°Р»РЅРё РїСЂРѕРјРµРЅР»РёРІРё Рё РїСЂРѕС‡РµРµ СЃР° РґРѕСЃС‚СЉРїРЅРё РѕС‚РІСЉРЅ.
# </li><li class="action">РќСЏРјР° Р°Р±СЃС‚СЂР°РєС†РёСЏ. Р’СЃРµ РµРґРЅРѕ СЃС‚Рµ inline-РЅР°Р»Рё С„Р°Р№Р»Р° РЅР° РјСЏСЃС‚РѕС‚Рѕ РЅР° <code>require</code>-Р°. РџРѕС‡С‚Рё.
# </li><li class="action">Р¤Р°Р№Р»СЉС‚ Рµ РёР·РїСЉР»РЅРµРЅ СЃ РґСЂСѓРі binding. Р”РµРјРµРє, Р»РѕРєР°Р»РЅРёС‚Рµ РјСѓ РїСЂРѕРјРµРЅР»РёРІРё СЃР° РёР·РѕР»РёСЂР°РЅРё. РќРѕ СЃР°РјРѕ С‚Рµ.
# </li><li class="action">РќРµ С‡Рµ РёРјР° Р·РЅР°С‡РµРЅРёРµ, РЅРѕ <code>main</code> РѕР±РµРєС‚Р° Рµ СЃСЉС‰РёСЏ.
# </li><li class="action">Р¤Р°Р№Р»СЉС‚ СЃРµ РёР·РїСЉР»РЅСЏРІР° СЃР°РјРѕ РІРµРґРЅСЉР¶. РџРѕРІС‚РѕСЂРЅРё <code>require</code>-Рё РЅРµ РїСЂР°РІСЏС‚ РЅРёС‰Рѕ.
# </li><li class="action">РџРѕСЃР»РµРґРЅРѕС‚Рѕ РјРѕР¶Рµ РґР° СЃРµ РёР·Р»СЉР¶Рµ РїРѕ РЅСЏРєРѕР»РєРѕ РЅР°С‡РёРЅР°.
# </li><li class="action"><code>require</code> РјРѕР¶Рµ РґР° Р·Р°СЂРµР¶РґР° <code>.so</code> Рё <code>.dll</code> С„Р°Р№Р»РѕРІРµ.</li></ul></section>
# <section>
# <hgroup><h1>РўРёРїРёС‡РЅР°С‚Р° СЃС‚СЂСѓРєС‚СѓСЂР° РЅР° РµРґРёРЅ gem</h1><h2>skeptic РѕРїСЂРѕСЃС‚РµРЅ</h2></hgroup>
# <pre>.
# в”њв”Ђв”Ђ README.rdoc
# в”њв”Ђв”Ђ Rakefile
# в”њв”Ђв”Ђ bin
# в”‚   в””в”Ђв”Ђ skeptic
# в”њв”Ђв”Ђ features
# в”њв”Ђв”Ђ lib
# в”‚   в”њв”Ђв”Ђ skeptic
# в”‚   в”‚   в”њв”Ђв”Ђ rules.rb
# в”‚   в”‚   в””в”Ђв”Ђ scope.rb
# в”‚   в””в”Ђв”Ђ skeptic.rb
# в”њв”Ђв”Ђ skeptic.gemspec
# в””в”Ђв”Ђ spec </pre></section>
# <section>
# <hgroup><h1>РћСЃРѕР±РµРЅРѕСЃС‚РёС‚Рµ</h1></hgroup>
# <ul><li class="action"><code>lib/</code> РѕР±РёРєРЅРѕРІРµРЅРѕ СЃСЉРґСЉСЂР¶Р° <code>foo.rb</code> Рё <code>lib/foo/</code>.
# </li><li class="action"><code>foo.rb</code> РѕР±РёРєРЅРѕРІРµРЅРѕ Рµ РµРґРёРЅСЃС‚РІРµРЅРѕС‚Рѕ РЅРµС‰Рѕ РІ <code>lib/</code>.
# </li><li class="action">Р’СЃРёС‡РєРѕ РѕСЃС‚Р°РЅР°Р»Рѕ Рµ РІ <code>lib/foo</code>.
# </li><li class="action"><code>lib/</code> СЃРµ РґРѕР±Р°РІСЏ РІ load path.
# </li><li class="action">РўР°РєР° РІРµС‡Рµ РјРѕР¶Рµ РґР° РїСЂР°РІРёС‚Рµ <code>require \'foo\'</code> РёР»Рё <code>require \'foo/something\'</code>.
# </li><li class="action">РџРѕ С‚РѕР·Рё РЅР°С‡РёРЅ РЅРµ Р·Р°РјСЉСЂСЃСЏРІР°С‚Рµ <code>require</code> РѕР±Р»Р°СЃС‚С‚Р°.
# </li><li class="action">RubyGems РїСЂР°РІРё С‚РѕРІР° "Р°РІС‚РѕРјР°РіРёС‡РЅРѕ".</li></ul></section>
# <section>
# <hgroup><h1>РћСЃС‚Р°РЅР°Р»РёС‚Рµ РЅРµС‰Р°</h1></hgroup>
# <ul><li>Р Р°Р·РіР»РµРґР°Р№С‚Рµ <a href="http://github.com/skanev/skeptic">skanev/skeptic</a> Р·Р° РїРѕРІРµС‡Рµ РїРѕРґСЂРѕР±РЅРѕСЃС‚Рё.</li><li>РџРѕСЃР»Рµ СЂР°Р·РіР»РµРґР°Р№С‚Рµ РЅСЏРєРѕР№ РґСЂСѓРі gem.</li><li>РџРѕСЃР»Рµ СЃРё РїРѕРёРіСЂР°Р№С‚Рµ РјР°Р»РєРѕ СЃ <code>require</code> Рё <code>$LOAD_PATH</code> Рё РІРёР¶С‚Рµ РєР°РєРІРѕ СЃРµ СЃР»СѓС‡РІР°.</li></ul></section>
# <section>
# <hgroup><h1>Kernel#load</h1></hgroup>
# <ul><li class="action"><code>load</code> Рµ РјРЅРѕРіРѕ СЃС…РѕРґРµРЅ СЃ <code>require</code>, РЅРѕ РёРјР° РЅСЏРєРѕР»РєРѕ СЂР°Р·Р»РёРєРё.
# </li><li class="action">Р?СЃРєР° СЂР°Р·С€РёСЂРµРЅРёРµ РЅР° С„Р°Р№Р» - <code>load \'foo.rb\'</code>.
# </li><li class="action">РџРѕРІС‚РѕСЂРЅРё <code>load</code>-РѕРІРµ РёР·РїСЉР»РЅСЏРІР°С‚ С„Р°Р№Р»Р°.
# </li><li class="action"><code>load</code> РЅРµ РјРѕР¶Рµ РґР° Р·Р°СЂРµР¶РґР° <code>.so</code>/<code>.dll</code> Р±РёР±Р»РёРѕС‚РµРєРё.
# </li><li class="action"><code>load</code> РёРјР° РѕРїС†РёРѕРЅР°Р»РµРЅ РїР°СЂР°РјРµС‚СЉСЂ, СЃ РєРѕР№С‚Рѕ РјРѕР¶Рµ РґР° РѕР±РІРёРµ С„Р°Р№Р»Р° РІ Р°РЅРѕРЅРёРјРµРЅ РјРѕРґСѓР».
# </li><li class="action">РџРѕСЃР»РµРґРЅРѕС‚Рѕ РґР°РІР° РёР·РІРµСЃС‚РЅР° РёР·РѕР»Р°С†РёСЏ.</li></ul></section>
# <section>
# <hgroup><h1>Р—Р°РјСЂР°Р·СЏРІР°РЅРµ РЅР° РѕР±РµРєС‚Рё РІ Ruby</h1></hgroup>
# <ul><li class="action">Р РµР°Р»РЅРѕ РїСЂРµРІСЂСЉС‰Р° mutable-РѕР±РµРєС‚Рё РІ immutable
# </li><li class="action">Р—Р°РјСЂР°Р·СЏРІР°РЅРµС‚Рѕ СЃС‚Р°РІР° СЃ <code>Object#freeze</code>
# </li><li class="action">РњРѕР¶РµС‚Рµ РґР° РїСЂРѕРІРµСЂРёС‚Рµ РґР°Р»Рё РѕР±РµРєС‚ Рµ Р·Р°РјСЂР°Р·РµРЅ СЃ <code>Object#frozen?</code>
# </li><li class="action">Р’РµРґРЅСЉР¶ Р·Р°РјСЂР°Р·РµРЅ, РґР°РґРµРЅ РѕР±РµРєС‚ РЅРµ РјРѕР¶Рµ РґР° Р±СЉРґРµ СЂР°Р·РјСЂР°Р·РµРЅ
# </li><li class="action">РќРµ РјРѕР¶РµС‚Рµ РґР° РїСЂРѕРјРµРЅСЏС‚Рµ РІРµС‡Рµ Р·Р°РјСЂР°Р·РµРЅРё РѕР±РµРєС‚Рё
# </li><li class="action">Р§РµСЃС‚Рѕ СЃРµ РїРѕР»Р·РІР°, РєРѕРіР°С‚Рѕ РїСЂРёСЃРІРѕР»СЏРІР°С‚Рµ mutable-С‚РёРїРѕРІРµ РЅР° РєРѕРЅСЃС‚Р°РЅС‚Рё
# </li><li class="action">Р’СЉР·РјРѕР¶РЅРѕ Рµ РґР° РґРѕРІРµРґРµ РґРѕ СѓСЃРєРѕСЂСЏРІР°РЅРµ РЅР° РІР°С€РёСЏ РєРѕРґ</li></ul></section>
# <section>
# <hgroup><h1>Р—Р°РјСЂР°Р·СЏРІР°РЅРµ РЅР° РѕР±РµРєС‚Рё</h1></hgroup>
# <div class="highlight"><pre><span class="k">module</span> <span class="nn">Entities</span>
  # <span class="no">ENTITIES</span> <span class="o">=</span> <span class="p">{</span>
    # <span class="s1">&#39;&amp;&#39;</span> <span class="o">=&gt;</span> <span class="s1">&#39;&amp;amp;&#39;</span><span class="p">,</span>
    # <span class="s1">&#39;&quot;&#39;</span> <span class="o">=&gt;</span> <span class="s1">&#39;&amp;quot;&#39;</span><span class="p">,</span>
    # <span class="s1">&#39;&lt;&#39;</span> <span class="o">=&gt;</span> <span class="s1">&#39;&amp;lt;&#39;</span><span class="p">,</span>
    # <span class="s1">&#39;&gt;&#39;</span> <span class="o">=&gt;</span> <span class="s1">&#39;&amp;gt;&#39;</span><span class="p">,</span>
  # <span class="p">}</span><span class="o">.</span><span class="n">freeze</span>

  # <span class="no">ENTITY_PATTERN</span> <span class="o">=</span> <span class="sr">/</span><span class="si">#{</span><span class="no">ENTITIES</span><span class="o">.</span><span class="n">keys</span><span class="o">.</span><span class="n">join</span><span class="p">(</span><span class="s1">&#39;|&#39;</span><span class="p">)</span><span class="si">}</span><span class="sr">/</span><span class="o">.</span><span class="n">freeze</span>

  # <span class="k">def</span> <span class="nf">escape</span><span class="p">(</span><span class="n">text</span><span class="p">)</span>
    # <span class="n">text</span><span class="o">.</span><span class="n">gsub</span> <span class="no">ENTITY_PATTERN</span><span class="p">,</span> <span class="no">ENTITIES</span>
  # <span class="k">end</span>
# <span class="k">end</span>
# </pre>
# </div>
# </section>
# <section><hgroup><h1>Р’СЉРїСЂРѕСЃРё</h1></hgroup><ul><li><a href="http://fmi.ruby.bg/topics">http://fmi.ruby.bg/</a></li><li><a href="http://twitter.com/rbfmi/">@rbfmi</a></li></ul></section></div><script src="js/jquery-1.5.2.min.js"></script><script src="js/jquery.jswipe-0.1.2.js"></script><script src="js/htmlSlides.js"></script><script type="text/javascript">$(function() {
  # htmlSlides.init({ hideToolbar: true });
# });</script></body></html>').to_pdf

# Document.new('<html><section>
# <hgroup><h1>case</h1><h2>Object#===</h2></hgroup>
# <p><code>case</code> СЃСЂР°РІРЅСЏРІР° СЃ <code>===</code>. РќСЏРєРѕР»РєРѕ РєР»Р°СЃР° РіРѕ РёРјРїР»РµРјРµРЅС‚РёСЂР°С‚:</p><ul><li class="action"><code>Range</code>
# </li><li class="action"><code>Regexp</code>
# </li><li class="action"><code>Class</code>
# </li><li class="action">РЎРїРёСЃСЉРєСЉС‚ РЅРµ Рµ РёР·С‡РµСЂРїР°С‚РµР»РµРЅ...
# </li><li class="action">РџРѕ РїРѕРґСЂР°Р·Р±РёСЂР°РЅРµ СЃРµ РѕС†РµРЅСЏРІР° РєР°С‚Рѕ <code>==</code>.</li></ul></section>
# <section>
# <hgroup><h1>case</h1><h2>Class#===</h2></hgroup>
# <div class="highlight"><pre><span class="k">def</span> <span class="nf">qualify</span><span class="p">(</span><span class="n">thing</span><span class="p">)</span>
  # <span class="k">case</span> <span class="n">thing</span>
    # <span class="k">when</span> <span class="nb">Integer</span> <span class="k">then</span> <span class="s1">&#39;this is a number&#39;</span>
    # <span class="k">when</span> <span class="nb">String</span> <span class="k">then</span> <span class="s1">&#39;it is a string&#39;</span>
    # <span class="k">when</span> <span class="nb">Array</span> <span class="k">then</span> <span class="n">thing</span><span class="o">.</span><span class="n">map</span> <span class="p">{</span> <span class="o">|</span><span class="n">item</span><span class="o">|</span> <span class="n">qualify</span> <span class="n">item</span> <span class="p">}</span>
    # <span class="k">else</span> <span class="s1">&#39;huh?&#39;</span>
  # <span class="k">end</span>
# <span class="k">end</span>
# </pre>
# </div>
# </section>
# <section>
# <hgroup><h1>case</h1><h2>Range#===</h2></hgroup>
# <div class="highlight"><pre><span class="k">case</span> <span class="n">hours_of_sleep</span>
  # <span class="k">when</span> <span class="mi">8</span><span class="o">.</span><span class="n">.</span><span class="mi">10</span> <span class="k">then</span> <span class="s1">&#39;I feel fine.&#39;</span>
  # <span class="k">when</span> <span class="mi">6</span><span class="o">.</span><span class="n">.</span><span class="o">.</span><span class="mi">8</span> <span class="k">then</span> <span class="s1">&#39;I am a little sleepy.&#39;</span>
  # <span class="k">when</span> <span class="mi">1</span><span class="o">.</span><span class="n">.</span><span class="mi">3</span>  <span class="k">then</span> <span class="s1">&#39;OUT OF MY WAY! I HAVE PLACES TO BE AND PEOPLE TO SEE!&#39;</span>
# <span class="k">end</span>
# </pre>
# </div>
# </section></html>').to_pdf

# Document.new('<html><input type="button" value="Mouse"/><input type="number" value="Mouse and other and other and other"/><input type="text" placeholder="Only mouse"/>
# <input type="checkbox" value="First"/><input type="checkbox" value="Second"/><input type="radio" value="Third"/></html>').to_pdf


# HTMLToPDF::Document.new('<html>
# <head>
# <meta charset="utf-8" />
# <title>Демонстрация</title>
# </head>

# <body>
# <h1>Демонстрация</h1>
# <section>
# <h2>Няколко линка:</h2>
# <a href="http://google.bg">Google</a>
# <a href="http://example.com">Един линк <a href="http://otherexample.com">Втори</a> Отново първия</a>
# </section>
# <section>
# <h2>Текст и код:</h2>
# <p>Малко текст и сега код:</p><br />
# <code>def new_function<br />
  # puts "I am new function"<br />
# end
# </code>
# </section>
# <section>
# <h2>Таблица без рамка:</h2>
# <table>
# <tr>
# <td>1.1</td>
# <td>1.2</td>
# </tr>
# <tr>
# <td>2.1</td>
# <td>2.2</td>
# </tr>
# </table>
# <div>И сега с:</div>
# <table border="2">
# <tr>
# <td>1.1</td>
# <td>1.2</td>
# </tr>
# <tr>
# <td>2.1</td>
# <td>2.2</td>
# </tr>
# </table>
# </section>
# <section>
# <h2>Номериран и неномериран списък:</h2>
# <ul><li class="action">Забравете за IDE-тата. Това не е Java.</li>
# <li class="action">Ползвайте любимия си текстов редактор</li>
# <li class="action">Научете Vim или Emacs. Ще ми благодарите после</li>
# </ul>
# <div>Това е от:</div>
# <ol><li class="action">Първата лекция на Руби</li>
# <li class="action">Друга лекция</li>
# <li class="action">Друг предмет</li>
# </ol>
# </section>
# <section>
# <h2>Картинка:</h2>
# <img src="http://vmfarms.com/static/img/logos/ruby-logo.png" alt="Ruby" width="300" height="300" />
# </section>
# <section>
# <h2>Една форма:</h2>
# <form action="demo_form.asp">
# <input type="text" name="FirstName" placeholder="Mickey"><br />
# <input type="button" value="Mouse"><br />
# <input type="checkbox" value="First">First<br />
# <input type="checkbox" value="Second">Second<br />
# <input type="checkbox" value="Third">Third<br />
# <input type="radio" value="First">First<br />
# <input type="radio" value="Second">Second<br />
# <input type="radio" value="Third">Third<br />
# <select>
  # <option value="volvo">Volvo</option>
  # <option value="saab">Saab</option>
  # <option value="mercedes">Mercedes</option>
  # <option value="audi">Audi</option>
# </select><br />
# <textarea rows="4" cols="50" required="required">
# At w3schools.com you will learn how to make a website. We offer free tutorials in all web development technologies. 
# </textarea><br />
# <button type="button">Click Me!</button><br />
# <input type="submit" value="Submit"><br />
# <input type="reset" value="Mouse"><br />
# </form>
# </section>
# <section>
# <h1>Край.</h1>
# </section>
# </body>
# </html>').to_pdf