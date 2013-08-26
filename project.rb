# encoding: utf-8
require 'nokogiri'
require 'prawn'
require 'open-uri'

class Document
  def initialize(html)
    @content = Tag.parse html
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
    @content.to_pdf @pdf
    p @pdf
    @pdf.render_file "test.pdf"
  end
end

class Tag
  attr_accessor :pdf
  
  def initialize(tag_tree)
    @attributes = {:class => nil, :id => nil, :hidden => nil}
    @tag_tree = tag_tree
    @content = []
    #@pdf = Prawn::Document.new
  end

  def Tag.parse(content)
    # name = /<(\w+)\b/.match(html) ? $1 : "unknown"
    # return if name == "unknown"
    # html = /<(#{name}).*?<\/#{name}>/.match(html)
    # #html = html.reject(/<(#{name})/)
    # Object.const_get(name.capitalize + "Tag").new html.to_s
    # p html

    # puts name
    #p content
    #p content.class
    tag_tree = content.kind_of?(String) ? Nokogiri::XML::DocumentFragment.parse(content).children[0] : content 
    p tag_tree.name
     # tag_tree = 
    name = case tag_tree.name
             when /h[1-6]/
               "h"
             when /\A((b|i|u)|strong)\z/
               "biu"
             when /label/ #possible problem with CSS!
               "span"
             else
               tag_tree.name
           end
    p name
    Object.const_get(name.capitalize + "Tag").new tag_tree
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

  def only_tag
    /<.*?>/.match(@html).to_s
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
                    HtmlTag.parse(child)
                  end
      #p child.name
      #p child.text
      #puts "\n"
    end
    @content.each do |item|
      #item.gsub('\n', '')
      #p item.class
    end
    #p @content
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

class ATag < Tag
  def initialize(html)
    super(html)
    @attributes.merge!({:href => nil, :target => nil})
    get_attributes
    get_content
    #p @attributes
  end
  
  def render(string, prawn_object)
    p 'self '
    p string
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

class TextTags < Tag
  def initialize(tag_tree, options = {})
    super(tag_tree)
    get_attributes
    @attributes.update options
    get_content
    #p @attributes
  end
  
  def render(string, prawn_object)
    prawn_object.formatted_text([{:text => string}.merge(@attributes)])
  end
end

class DivTag < TextTags
  def initialize(tag_tree)
    super(tag_tree)
  end
  
  def render(string, prawn_object)
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
  end
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
      prawn_object.image @attributes[:src], @attributes
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
end

class TrTag < Tag
  def initialize(tag_tree)
    super(tag_tree)
    get_attributes
    get_content
  end
end

class TdTag < Tag
  def initialize(tag_tree)
    super(tag_tree)
    get_attributes
    get_content
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
#Document.new('<a href="test.com" id="new_a" class="test" target="_blank">Nov Q<div>kdfgdf <label>rgrgrgf</label></div> fghfh<h6>Здравей</h6> <br />Text</a>').to_pdf
#Document.new('<a href="test.com" id="new_a" class="test" target="_blank">Nov Q<div>kdfgdf <label>rgrgrgf</label></div> fghfh<code>Хей</code> <br />Text</a>').to_pdf
Document.new('<a href="test.com" id="new_a" class="test" target="_blank">Nov Q fghfh <img src="Google.jpg" alt="Това е Google" width="300" height="150" /> Text</a>').to_pdf
# HtmlTag.parse '<a href="test.com" id="new_a" class="test" target="_blank">Nov Q<div>kdfgdf <label>rgrgrgf</label></div> fghfh<div id="5">Hello</div> <br />Text</a>'
# p HtmlTag.parse '<a href="test.com" id="new_a" class="test" target="_blank">Nov Q
# <div>kdfgdf 
# <img src="http://www.google.com" alt="Това е Google" width="300" height="200"/></div> fghfh
# <div id="5">Hello</div> Text</a>'
# HtmlTag.parse '<a href="test.com" id="new_a" class="test" target="_blank">Nov Q<div>kdfgdf <i>rgrgrgf</i></div> fghfh<div id="5">Hello</div> Text</a>'
# HtmlTag.parse '<a href="test.com" id="new_a" class="test" target="_blank">Nov Q<div>kdfgdf <div>rgrgrgf</div></div> fghfh<div id="5">Hello</div> Text</a>'
#HtmlTag.parse '<a href="test.com" id="new_a" class="test" target="_blank">Nov Text</a>'
# p HtmlTag.parse '<table border="1" cellpadding="1" cellspacing="1">
# <tr style="font-weight: bold; color: white; text-align: center; background: grey">
# <td>Катедра</td>
# <td>Дисциплина</td>
# <td>Хорариум</td>
# <td>Кредити ЕСТК</td>
# <td>Група ИД</td>
# <td>Преподавател</td>
# <td>И</td>
# <td>ИС</td>
# <td>КН</td>
# <td>М</td>
# <td>МИ</td>
# <td>ПМ</td>
# <td>СИ</td>
# <td>Стат</td>

# </tr>
# <tr>

# <td>ИТ</td>
# <td>Информационните технологии в обучението на деца със специални образователни потребности</td>
# <td>0+0+2</td>
# <td>2,5</td>
# <td>Д</td>
# <td>ас. Т. Зафирова-Малчева</td>
# <td> </td>
# <td> </td>
# <td> </td>
# <td> </td>
# <td>4</td>
# <td> </td>
# <td> </td>
# <td> </td>

# </tr>
# <tr style="background: #D3D3D3;">

# <td>ОМИ</td>
# <td>Комбинаторика, вероятности и статистика в училищния курс по математика</td>
# <td>2+2+0</td>
# <td>5</td>
# <td>Д</td>
# <td>проф. К. Банков</td>
# <td> </td>
# <td> </td>
# <td> </td>
# <td> </td>
# <td>3</td>
# <td> </td>
# <td> </td>
# <td> </td>

# </tr>
# <tr>

# <td>ИТ</td>
# <td>Специфични въпроси в обучението по информационни технологии</td>
# <td>2+0+2</td>
# <td>5</td>
# <td>Д</td>
# <td>гл.ас. Е. Стефанова, гл.ас. Н. Николова</td>
# <td> </td>
# <td> </td>
# <td> </td>
# <td> </td>
# <td>4</td>
# <td> </td>
# <td> </td>
# <td> </td>

# </tr>
# </table>'

# p HtmlTag.parse '<table border="1">
# <tr>
# <td>Клетка 1</td>
# <td>Cell 2</td>
# </tr>
# <tr>
# <td>2.1</td>
# <td>2.2</td>
# </tr>
# </table>'