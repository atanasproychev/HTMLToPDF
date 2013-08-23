# encoding: utf-8
require 'nokogiri'

class HtmlTag
  def initialize(tag_tree)
    @attributes = {:class => nil, :id => nil, :hidden => nil}
    @tag_tree = tag_tree
    @content = []
  end

  def HtmlTag.parse(content)
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
    @content.select! do |item|
      item != "\n"
    end
    #p @content
  end
  
  def to_s
    @content.each { |object| object.to_s }
  end
end

class ATag < HtmlTag
  def initialize(html)
    super(html)
    @attributes.merge!({:href => nil, :target => nil})
    get_attributes
    get_content
    #p @attributes
  end
  
  # def get_attributes
    # tag = super
    # /href=(".*?")/.match(tag)
    # @attributes[:href] = $1.gsub(/\"/, "")
    # /target=(".*?")/.match(tag)
    # @attributes[:target] = $1.gsub(/\"/, "")
  # end
end

class TextTags < HtmlTag
  def initialize(tag_tree, options = {})
    super(tag_tree)
    get_attributes
    @attributes.update options
    get_content
    #p @attributes
  end
end

class DivTag < TextTags
  def initialize(tag_tree)
    super(tag_tree)
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
    options = {:size => /h([1-6])/.match(tag_tree.name)[1], :bold => true}
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
    super(tag_tree, {option => true})
  end
end

class CodeTag < TextTags
  def initialize(tag_tree)
    super(tag_tree, {:font => "Courier New"})
  end
end

class HrTag < HtmlTag
  def initialize(tag_tree)
    super(tag_tree)
  end
  
  def to_s
    "-------------"
  end
end

class BrTag < HtmlTag
  def initialize(tag_tree)
    super(tag_tree)
  end
  
  def to_s
    "             "
  end
end

class ImgTag < HtmlTag
  def initialize(tag_tree)
    super(tag_tree)
    @attributes.merge!({:alt => nil, :src => nil, :height => nil, :width => nil})
    get_attributes
    p @attributes
  end
  
  def to_s
    @attributes[:alt]
  end
end

class TableTag < HtmlTag
  def initialize(tag_tree)
    super(tag_tree)
    @attributes.merge!({:border => nil})
    get_attributes
    get_content
  end
end

class TrTag < HtmlTag
  def initialize(tag_tree)
    super(tag_tree)
    get_attributes
    get_content
  end
end

class TdTag < HtmlTag
  def initialize(tag_tree)
    super(tag_tree)
    get_attributes
    get_content
  end
end

# HtmlTag.parse '<p class="Something">Text <h3 id="test">Nov Text</h3> Something</p>'
# HtmlTag.parse '<p class="Something">Text <a href="test.com">Nov Text</a> Something</p>'
# HtmlTag.parse '<a href="test.com">Nov <a href="newtest.com">Q<div>k</div></a> Text</a><a>Something</a>'
# HtmlTag.parse '<a href="test.com" id="new_a" class="test" target="_blank">Nov Q<div>kdfgdf <span>rgrgrgf</span></div> fghfh<div id="5">Hello</div> Text</a>'
# HtmlTag.parse '<a href="test.com" id="new_a" class="test" target="_blank">Nov Q<div>kdfgdf <label>rgrgrgf</label></div> fghfh<div id="5">Hello</div> Text</a>'
# HtmlTag.parse '<a href="test.com" id="new_a" class="test" target="_blank">Nov Q<div>kdfgdf <label>rgrgrgf</label></div> fghfh<div id="5">Hello</div> <hr />Text</a>'
# HtmlTag.parse '<a href="test.com" id="new_a" class="test" target="_blank">Nov Q<div>kdfgdf <label>rgrgrgf</label></div> fghfh<div id="5">Hello</div> <br />Text</a>'
p HtmlTag.parse '<a href="test.com" id="new_a" class="test" target="_blank">Nov Q<div>kdfgdf <img src="http://www.google.com" alt="Това е Google" width="300" height="200"/></div> fghfh<div id="5">Hello</div> Text</a>'
# HtmlTag.parse '<a href="test.com" id="new_a" class="test" target="_blank">Nov Q<div>kdfgdf <i>rgrgrgf</i></div> fghfh<div id="5">Hello</div> Text</a>'
# HtmlTag.parse '<a href="test.com" id="new_a" class="test" target="_blank">Nov Q<div>kdfgdf <div>rgrgrgf</div></div> fghfh<div id="5">Hello</div> Text</a>'
#HtmlTag.parse '<a href="test.com" id="new_a" class="test" target="_blank">Nov Text</a>'
p HtmlTag.parse '<table border="1" cellpadding="1" cellspacing="1">
<tr style="font-weight: bold; color: white; text-align: center; background: grey">
<td>Катедра</td>
<td>Дисциплина</td>
<td>Хорариум</td>
<td>Кредити ЕСТК</td>
<td>Група ИД</td>
<td>Преподавател</td>
<td>И</td>
<td>ИС</td>
<td>КН</td>
<td>М</td>
<td>МИ</td>
<td>ПМ</td>
<td>СИ</td>
<td>Стат</td>

</tr>
<tr>

<td>ИТ</td>
<td>Информационните технологии в обучението на деца със специални образователни потребности</td>
<td>0+0+2</td>
<td>2,5</td>
<td>Д</td>
<td>ас. Т. Зафирова-Малчева</td>
<td> </td>
<td> </td>
<td> </td>
<td> </td>
<td>4</td>
<td> </td>
<td> </td>
<td> </td>

</tr>
<tr style="background: #D3D3D3;">

<td>ОМИ</td>
<td>Комбинаторика, вероятности и статистика в училищния курс по математика</td>
<td>2+2+0</td>
<td>5</td>
<td>Д</td>
<td>проф. К. Банков</td>
<td> </td>
<td> </td>
<td> </td>
<td> </td>
<td>3</td>
<td> </td>
<td> </td>
<td> </td>

</tr>
<tr>

<td>ИТ</td>
<td>Специфични въпроси в обучението по информационни технологии</td>
<td>2+0+2</td>
<td>5</td>
<td>Д</td>
<td>гл.ас. Е. Стефанова, гл.ас. Н. Николова</td>
<td> </td>
<td> </td>
<td> </td>
<td> </td>
<td>4</td>
<td> </td>
<td> </td>
<td> </td>

</tr>
</table>'

p HtmlTag.parse '<table border="1">
<tr>
<td>Клетка 1</td>
<td>Cell 2</td>
</tr>
<tr>
<td>2.1</td>
<td>2.2</td>
</tr>
</table>'