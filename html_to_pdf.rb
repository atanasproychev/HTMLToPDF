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
    p @content.class
    @content.to_pdf @pdf
    name = @content.title
    #p @pdf
    @pdf.render_file "#{name}.pdf"
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
             when 'script', 'style', 'link', 'meta', 'head', 'title'
               'nothing'
             else
               tag_tree.name
           end
    p name
    begin
      Object.const_get(name.capitalize + "Tag").new tag_tree
    rescue NameError
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
    prawn_object.fill_circle [5, prawn_object.cursor], 2
    @content.each do |item|
      if item.class == String
        prawn_object.text_box item, :at => [12, prawn_object.cursor + 4]
        lines = item.length / 52.0
        prawn_object.move_down (lines > lines.floor ? lines.ceil : lines) * 15
      else
        item.to_pdf prawn_object
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
#Document.new('<a href="test.com" id="new_a" class="test" target="_blank">Nov Q fghfh <img src="Google.jpg" alt="Това е Google" width="300" height="150" /> Text</a>').to_pdf
# HtmlTag.parse '<a href="test.com" id="new_a" class="test" target="_blank">Nov Q<div>kdfgdf <label>rgrgrgf</label></div> fghfh<div id="5">Hello</div> <br />Text</a>'
# p HtmlTag.parse '<a href="test.com" id="new_a" class="test" target="_blank">Nov Q
# <div>kdfgdf 
# <img src="http://www.google.com" alt="Това е Google" width="300" height="200"/></div> fghfh
# <div id="5">Hello</div> Text</a>'
# HtmlTag.parse '<a href="test.com" id="new_a" class="test" target="_blank">Nov Q<div>kdfgdf <i>rgrgrgf</i></div> fghfh<div id="5">Hello</div> Text</a>'
# HtmlTag.parse '<a href="test.com" id="new_a" class="test" target="_blank">Nov Q<div>kdfgdf <div>rgrgrgf</div></div> fghfh<div id="5">Hello</div> Text</a>'
#HtmlTag.parse '<a href="test.com" id="new_a" class="test" target="_blank">Nov Text</a>'
# Document.new('<table border="1" cellpadding="1" cellspacing="1">
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
# </table>').to_pdf

# Document.new('<table>
# <tr>
# <td>Клетка 1</td>
# <td>Cell 2</td>
# </tr>
# <tr>
# <td>2.1</td>
# <td>2.2</td>
# </tr>
# </table>').to_pdf

# Document.new('<ol><li class="action">Интерфейса и имплементация са две различни неща
# </li><li class="action">Хубаво е имплементацията да може да се променя независимо от интерфейсаХубаво е имплементацията да може да се променя независимо от интерфейса
# </li><li class="action">Хубаво е интерфейса да не показва твърде много от имплементацията
# </li><li class="action">Мислете за това като дизайнвате класове</li></ol>').to_pdf


Document.new('<html lang="bg"><head><meta charset="utf-8" /><!--[if lt IE 9]><script src="js/html5shim.js"></script><![endif]--><link href="css/styles.css" rel="stylesheet" /><link href="css/pygments.css" rel="stylesheet" /><title>08. Паралелно присвояване, case, интроспекция, require и още</title></head><body><header><h1>08. Паралелно присвояване, case, интроспекция, require и още</h1><nav></nav></header><div id="deck"><section><hgroup><h1>08. Паралелно присвояване, case, интроспекция, require и още</h1><h2>5 ноември 2012</h2></hgroup></section><section>
<hgroup><h1>Днес</h1></hgroup>
<ul><li class="action"><code>case</code> в Ruby
</li><li class="action">Трикове с присвояване
</li><li class="action"><code>require</code>
</li><li class="action">Структура на простички gem-ове
</li><li class="action">Замразяване на обекти
</li><li class="action">Малко интроспекция
</li><li class="action">Разни</li></ul></section>
<section>
<hgroup><h1>case</h1></hgroup>
<p>В Ruby има "switch". Казва се <code>case</code>.</p><div class="highlight"><pre><span class="k">def</span> <span class="nf">quote</span><span class="p">(</span><span class="nb">name</span><span class="p">)</span>
  <span class="k">case</span> <span class="nb">name</span>
    <span class="k">when</span> <span class="s1">&#39;Yoda&#39;</span>
      <span class="nb">puts</span> <span class="s1">&#39;Do or do not. There is no try.&#39;</span>
    <span class="k">when</span> <span class="s1">&#39;Darth Vader&#39;</span>
      <span class="nb">puts</span> <span class="s1">&#39;The Force is strong with this one.&#39;</span>
    <span class="k">when</span> <span class="s1">&#39;R2-D2&#39;</span>
      <span class="nb">puts</span> <span class="s1">&#39;Beep. Beep. Beep.&#39;</span>
    <span class="k">else</span>
      <span class="nb">puts</span> <span class="s1">&#39;Dunno what to say&#39;</span>
  <span class="k">end</span>
<span class="k">end</span>
</pre>
</div>
</section>
<section>
<hgroup><h1>case</h1><h2>особености</h2></hgroup>
<ul><li class="action">Няма fall-through. Не се пише <code>break</code>.
</li><li class="action">Ако нито един <code>when</code> не мине, изпълнява се <code>else</code>.
</li><li class="action">Ако нито един <code>when</code> не мине, и няма <code>else</code>, не става нищо.
</li><li class="action"><code>case</code> е израз, което значи, че връща стойност.</li></ul></section>
<section>
<hgroup><h1>case</h1><h2>алтернативен синтаксис</h2></hgroup>
<div class="highlight"><pre><span class="k">case</span> <span class="n">operation</span>
  <span class="k">when</span> <span class="ss">:&amp;</span> <span class="k">then</span> <span class="nb">puts</span> <span class="s1">&#39;And?&#39;</span>
  <span class="k">when</span> <span class="ss">:|</span> <span class="k">then</span> <span class="nb">puts</span> <span class="s1">&#39;Or...&#39;</span>
  <span class="k">when</span> <span class="p">:</span><span class="o">!</span> <span class="k">then</span> <span class="nb">puts</span> <span class="s1">&#39;Not!&#39;</span>
<span class="k">end</span>
</pre>
</div>
</section>
<section>
<hgroup><h1>case</h1><h2>връщана стойност</h2></hgroup>
<p>На какво ще се оцени следният код?</p><div class="highlight"><pre><span class="k">case</span> <span class="s1">&#39;Wat?&#39;</span>
  <span class="k">when</span> <span class="s1">&#39;watnot&#39;</span> <span class="k">then</span> <span class="nb">puts</span> <span class="s2">&quot;I&#39;m on a horse.&quot;</span>
<span class="k">end</span>
</pre>
</div>
<div class="action answer"><p>Ако няма <code>else</code> и никой <code>when</code> не match-не, се връща <code>nil</code>.</p></div></section>
<section>
<hgroup><h1>case</h1><h2>стойности</h2></hgroup>
<p><code>case</code> не сравнява с <code>==</code>. Може да напишете следното.</p><div class="highlight"><pre><span class="k">def</span> <span class="nf">qualify</span><span class="p">(</span><span class="n">age</span><span class="p">)</span>
  <span class="k">case</span> <span class="n">age</span>
    <span class="k">when</span> <span class="mi">0</span><span class="o">.</span><span class="n">.</span><span class="mi">12</span>
      <span class="s1">&#39;still very young&#39;</span>
    <span class="k">when</span> <span class="mi">13</span><span class="o">.</span><span class="n">.</span><span class="mi">19</span>
      <span class="s1">&#39;a teenager! oh no!&#39;</span>
    <span class="k">when</span> <span class="mi">33</span>
      <span class="s1">&#39;the age of jesus&#39;</span>
    <span class="k">when</span> <span class="mi">90</span><span class="o">.</span><span class="n">.</span><span class="mi">200</span>
      <span class="s1">&#39;wow. that is old!&#39;</span>
    <span class="k">else</span>
      <span class="s1">&#39;not very interesting&#39;</span>
    <span class="k">end</span>
<span class="k">end</span>
</pre>
</div>
</section>
<section>
<hgroup><h1>case</h1><h2>Object#===</h2></hgroup>
<p><code>case</code> сравнява с <code>===</code>. Няколко класа го имплементират:</p><ul><li class="action"><code>Range</code>
</li><li class="action"><code>Regexp</code>
</li><li class="action"><code>Class</code>
</li><li class="action">Списъкът не е изчерпателен...
</li><li class="action">По подразбиране се оценява като <code>==</code>.</li></ul></section>
<section>
<hgroup><h1>case</h1><h2>Class#===</h2></hgroup>
<div class="highlight"><pre><span class="k">def</span> <span class="nf">qualify</span><span class="p">(</span><span class="n">thing</span><span class="p">)</span>
  <span class="k">case</span> <span class="n">thing</span>
    <span class="k">when</span> <span class="nb">Integer</span> <span class="k">then</span> <span class="s1">&#39;this is a number&#39;</span>
    <span class="k">when</span> <span class="nb">String</span> <span class="k">then</span> <span class="s1">&#39;it is a string&#39;</span>
    <span class="k">when</span> <span class="nb">Array</span> <span class="k">then</span> <span class="n">thing</span><span class="o">.</span><span class="n">map</span> <span class="p">{</span> <span class="o">|</span><span class="n">item</span><span class="o">|</span> <span class="n">qualify</span> <span class="n">item</span> <span class="p">}</span>
    <span class="k">else</span> <span class="s1">&#39;huh?&#39;</span>
  <span class="k">end</span>
<span class="k">end</span>
</pre>
</div>
</section>
<section>
<hgroup><h1>case</h1><h2>Range#===</h2></hgroup>
<div class="highlight"><pre><span class="k">case</span> <span class="n">hours_of_sleep</span>
  <span class="k">when</span> <span class="mi">8</span><span class="o">.</span><span class="n">.</span><span class="mi">10</span> <span class="k">then</span> <span class="s1">&#39;I feel fine.&#39;</span>
  <span class="k">when</span> <span class="mi">6</span><span class="o">.</span><span class="n">.</span><span class="o">.</span><span class="mi">8</span> <span class="k">then</span> <span class="s1">&#39;I am a little sleepy.&#39;</span>
  <span class="k">when</span> <span class="mi">1</span><span class="o">.</span><span class="n">.</span><span class="mi">3</span>  <span class="k">then</span> <span class="s1">&#39;OUT OF MY WAY! I HAVE PLACES TO BE AND PEOPLE TO SEE!&#39;</span>
<span class="k">end</span>
</pre>
</div>
</section>
<section>
<hgroup><h1>case</h1><h2>Regexp#===</h2></hgroup>
<div class="highlight"><pre><span class="k">def</span> <span class="nf">parse_date</span><span class="p">(</span><span class="n">date_string</span><span class="p">)</span>
  <span class="k">case</span> <span class="n">date_string</span>
    <span class="k">when</span><span class="sr"> /(\d{4})-(\d\d)-(\d\d)/</span>
      <span class="no">Date</span><span class="o">.</span><span class="n">new</span> <span class="vg">$1</span><span class="o">.</span><span class="n">to_i</span><span class="p">,</span> <span class="vg">$2</span><span class="o">.</span><span class="n">to_i</span><span class="p">,</span> <span class="vg">$3</span><span class="o">.</span><span class="n">to_i</span>
    <span class="k">when</span><span class="sr"> /(\d\d)\/(\d\d)/</span><span class="p">(\</span><span class="n">d</span><span class="p">{</span><span class="mi">4</span><span class="p">})</span><span class="o">/</span>
      <span class="no">Date</span><span class="o">.</span><span class="n">new</span> <span class="vg">$3</span><span class="o">.</span><span class="n">to_i</span><span class="p">,</span> <span class="vg">$1</span><span class="o">.</span><span class="n">to_i</span><span class="p">,</span> <span class="vg">$2</span><span class="o">.</span><span class="n">to_i</span>
  <span class="k">end</span>
<span class="k">end</span>
</pre>
</div>
</section>
<section>
<hgroup><h1>case</h1><h2>с обикновени условия</h2></hgroup>
<ul><li class="action">Можете да слагате и цели изрази във <code>when</code>
</li><li class="action">Изпуска се параметърът след <code>case</code>, например:</li></ul><div class="action"><div class="highlight"><pre><span class="n">thing</span> <span class="o">=</span> <span class="mi">42</span>
<span class="k">case</span>
  <span class="k">when</span> <span class="n">thing</span> <span class="o">==</span> <span class="mi">1</span> <span class="k">then</span> <span class="mi">1</span>
  <span class="k">else</span> <span class="s1">&#39;no_idea&#39;</span>
<span class="k">end</span>
</pre>
</div>
</div><ul><li class="action">Не го правете.
</li><li class="action">Ако ви се налага, ползвайте обикновени <code>if</code>-ове</li></ul></section>
<section>
<hgroup><h1>Въпроси по case</h1></hgroup>
<p>Сега е моментът.</p></section>
<section>
<hgroup><h1>Присвояване в Ruby</h1></hgroup>
<ul><li class="action">Присвояването в Ruby:
</li><li class="action"><code>foo = \'baba\'</code>
</li><li class="action">Може малко повече от това... :)
</li><li class="action">Паралелно присвояване
</li><li class="action">Вложено присвояване
</li><li class="action">Комбинации между двете</li></ul></section>
<section>
<hgroup><h1>Паралелно присвояване</h1><h2>прост пример</h2></hgroup>
<div class="highlight"><pre><span class="n">a</span><span class="p">,</span> <span class="n">b</span> <span class="o">=</span> <span class="mi">1</span><span class="p">,</span> <span class="mi">2</span>
<span class="n">a</span>              <span class="c1"># 1</span>
<span class="n">b</span>              <span class="c1"># 2</span>

<span class="n">a</span><span class="p">,</span> <span class="n">b</span> <span class="o">=</span> <span class="n">b</span><span class="p">,</span> <span class="n">a</span>
<span class="n">a</span>              <span class="c1"># 2</span>
<span class="n">b</span>              <span class="c1"># 1</span>
</pre>
</div>
<p>Има няколко различни случая, които ще разгледаме.</p></section>
<section>
<hgroup><h1>Паралелно присвояване</h1><h2>присвояване на една променлива</h2></hgroup>
<div class="highlight"><pre><span class="n">a</span> <span class="o">=</span> <span class="mi">1</span><span class="p">,</span> <span class="mi">2</span><span class="p">,</span> <span class="mi">3</span>
<span class="n">a</span> <span class="c1"># [1, 2, 3]</span>
</pre>
</div>
<p>Практически същото като <code>a = [1, 2, 3]</code></p></section>
<section>
<hgroup><h1>Паралелно присвояване</h1><h2>разпакетиране на дясната страна</h2></hgroup>
<div class="highlight"><pre><span class="n">a</span><span class="p">,</span> <span class="n">b</span> <span class="o">=</span> <span class="o">[</span><span class="mi">1</span><span class="p">,</span> <span class="mi">2</span><span class="p">,</span> <span class="mi">3</span><span class="o">]</span>
<span class="n">a</span> <span class="c1"># 1</span>
<span class="n">b</span> <span class="c1"># 2</span>

<span class="n">a</span><span class="p">,</span> <span class="n">b</span> <span class="o">=</span> <span class="mi">1</span><span class="p">,</span> <span class="mi">2</span><span class="p">,</span> <span class="mi">3</span>
<span class="n">a</span> <span class="c1"># 1</span>
<span class="n">b</span> <span class="c1"># 2</span>
</pre>
</div>
<ul><li class="action">Излишните аргументи вдясно се игнорират
</li><li class="action">Скобите са "опционални" в този случай
</li><li class="action">Ако вляво имате повече променливи отколкото вдясно, те ще получат стойност <code>nil</code></li></ul></section>
<section>
<hgroup><h1>Паралелно присвояване</h1><h2>със splat аргументи</h2></hgroup>
<div class="highlight"><pre><span class="n">head</span><span class="p">,</span> <span class="o">*</span><span class="n">tail</span> <span class="o">=</span> <span class="o">[</span><span class="mi">1</span><span class="p">,</span> <span class="mi">2</span><span class="p">,</span> <span class="mi">3</span><span class="o">]</span>
<span class="n">head</span>   <span class="c1"># 1</span>
<span class="n">tail</span>   <span class="c1"># [2, 3]</span>

<span class="n">first</span><span class="p">,</span> <span class="o">*</span><span class="n">middle</span><span class="p">,</span> <span class="n">last</span> <span class="o">=</span> <span class="mi">1</span><span class="p">,</span> <span class="mi">2</span><span class="p">,</span> <span class="mi">3</span><span class="p">,</span> <span class="mi">4</span>
<span class="n">first</span>  <span class="c1"># 1</span>
<span class="n">middle</span> <span class="c1"># [2, 3]</span>
<span class="n">last</span>   <span class="c1"># 4</span>
</pre>
</div>
<ul><li class="action"><code>middle</code> и <code>head</code> обират всичко останало
</li><li class="action">Очевидно, може да имате само една splat-променлива на присвояване</li></ul></section>
<section>
<hgroup><h1>Паралелно присвояване</h1><h2>splat аргументи отдясно</h2></hgroup>
<div class="highlight"><pre><span class="n">first</span><span class="p">,</span> <span class="o">*</span><span class="n">middle</span><span class="p">,</span> <span class="n">last</span> <span class="o">=</span> <span class="mi">1</span><span class="p">,</span> <span class="o">[</span><span class="mi">2</span><span class="p">,</span> <span class="mi">3</span><span class="p">,</span> <span class="mi">4</span><span class="o">]</span>
<span class="n">first</span>  <span class="c1"># 1</span>
<span class="n">middle</span> <span class="c1"># []</span>
<span class="n">last</span>   <span class="c1"># [2, 3, 4]</span>

<span class="n">first</span><span class="p">,</span> <span class="o">*</span><span class="n">middle</span><span class="p">,</span> <span class="n">last</span> <span class="o">=</span> <span class="mi">1</span><span class="p">,</span> <span class="o">*[</span><span class="mi">2</span><span class="p">,</span> <span class="mi">3</span><span class="p">,</span> <span class="mi">4</span><span class="o">]</span>
<span class="n">first</span>  <span class="c1"># 1</span>
<span class="n">middle</span> <span class="c1"># [2, 3]</span>
<span class="n">last</span>   <span class="c1"># 4</span>
</pre>
</div>
</section>
<section>
<hgroup><h1>Вложено присвояване</h1></hgroup>
<div class="highlight"><pre><span class="n">head</span><span class="p">,</span> <span class="p">(</span><span class="n">title</span><span class="p">,</span> <span class="n">body</span><span class="p">)</span> <span class="o">=</span> <span class="o">[</span><span class="mi">1</span><span class="p">,</span> <span class="o">[</span><span class="mi">2</span><span class="p">,</span> <span class="mi">3</span><span class="o">]]</span>
<span class="n">head</span>   <span class="c1"># 1</span>
<span class="n">title</span>  <span class="c1"># 2</span>
<span class="n">body</span>   <span class="c1"># 3</span>
</pre>
</div>
<ul><li class="action">Скобите ви позволяват да влезете едно ниво "навътре" и да разбиете подаден списък на променливи
</li><li class="action">Не сте ограничени само до две нива (това работи: <code>head, (title, (body,)) = [1, [2, [3]]]</code>)
</li><li class="action">Можете да ги комбинирате с паралелното присвояване, за да правите сложни магарии</li></ul></section>
<section>
<hgroup><h1>Вложено присвояване и splat-ове</h1></hgroup>
<div class="highlight"><pre><span class="n">head</span><span class="p">,</span> <span class="p">(</span><span class="n">title</span><span class="p">,</span> <span class="o">*</span><span class="n">sentences</span><span class="p">)</span> <span class="o">=</span> <span class="mi">1</span><span class="p">,</span> <span class="o">[</span><span class="mi">2</span><span class="p">,</span> <span class="mi">3</span><span class="p">,</span> <span class="mi">4</span><span class="p">,</span> <span class="mi">5</span><span class="p">,</span> <span class="mi">6</span><span class="o">]</span>
<span class="n">head</span>      <span class="c1"># 1</span>
<span class="n">title</span>     <span class="c1"># 2</span>
<span class="n">sentences</span> <span class="c1"># [3, 4, 5, 6]</span>
</pre>
</div>
<ul><li class="action">Може да имате по една звездичка на "ниво" (т.е. скоби)</li></ul></section>
<section>
<hgroup><h1>Ред на оценка</h1></hgroup>
<p>Бележка за реда на оценка при присвояване — първо отдясно, след това отляво:</p><div class="highlight"><pre><span class="n">x</span> <span class="o">=</span> <span class="mi">0</span>
<span class="n">a</span><span class="p">,</span> <span class="n">b</span><span class="p">,</span> <span class="n">c</span> <span class="o">=</span> <span class="n">x</span><span class="p">,</span> <span class="p">(</span><span class="n">x</span> <span class="o">+=</span> <span class="mi">1</span><span class="p">),</span> <span class="p">(</span><span class="n">x</span> <span class="o">+=</span> <span class="mi">1</span><span class="p">)</span>
<span class="n">x</span> <span class="c1"># 2</span>
<span class="n">a</span> <span class="c1"># 0</span>
<span class="n">b</span> <span class="c1"># 1</span>
<span class="n">c</span> <span class="c1"># 2</span>
</pre>
</div>
</section>
<section>
<hgroup><h1>Променливата _</h1></hgroup>
<ul><li class="action">Носи семантика на placeholder ("този аргумент не ми трябва")
</li><li class="action">Освен тази семантика, в Ruby е и малко по-специална</li></ul></section>
<section>
<hgroup><h1>Променливата _</h1></hgroup>
<p>Може да ползвате едно име само един път, когато то се среща в списък с параметри на метод, блок и прочее.</p><div class="highlight"><pre><span class="no">Proc</span><span class="o">.</span><span class="n">new</span> <span class="p">{</span> <span class="o">|</span><span class="n">a</span><span class="p">,</span> <span class="n">b</span><span class="p">,</span> <span class="n">a</span><span class="o">|</span> <span class="p">}</span> <span class="c1"># SyntaxError: duplicated argument name</span>
<span class="no">Proc</span><span class="o">.</span><span class="n">new</span> <span class="p">{</span> <span class="o">|</span><span class="n">_</span><span class="p">,</span> <span class="n">b</span><span class="p">,</span> <span class="n">_</span><span class="o">|</span> <span class="p">}</span> <span class="c1"># =&gt; #&lt;Proc:0x007f818af68de0@(irb):23&gt;</span>
</pre>
</div>
<p>Горното важи не само за блокове, но и за методи.</p></section>
<section>
<hgroup><h1>Присвояване в Ruby</h1><h2>Къде важат тези правила?</h2></hgroup>
<ul><li class="action">Очевидно, при нормално присвояване
</li><li class="action">Това включва и връщана стойност от метод, например <code>success, message = execute(job)</code>
</li><li class="action">При разгъване на аргументи на блокове, например:</li></ul><div class="action"><div class="highlight"><pre><span class="o">[[</span><span class="mi">1</span><span class="p">,</span> <span class="o">[</span><span class="mi">2</span><span class="p">,</span> <span class="mi">3</span><span class="o">]]</span><span class="p">,</span> <span class="o">[</span><span class="mi">4</span><span class="p">,</span> <span class="o">[</span><span class="mi">5</span><span class="p">,</span> <span class="mi">6</span><span class="o">]]</span><span class="p">,</span> <span class="o">[</span><span class="mi">7</span><span class="p">,</span> <span class="o">[</span><span class="mi">8</span><span class="p">,</span> <span class="mi">9</span><span class="o">]]].</span><span class="n">each</span> <span class="k">do</span> <span class="o">|</span><span class="n">a</span><span class="p">,</span> <span class="p">(</span><span class="n">b</span><span class="p">,</span> <span class="n">c</span><span class="p">)</span><span class="o">|</span>
  <span class="nb">puts</span> <span class="s2">&quot;</span><span class="si">#{</span><span class="n">a</span><span class="si">}</span><span class="s2">, </span><span class="si">#{</span><span class="n">b</span><span class="si">}</span><span class="s2">, </span><span class="si">#{</span><span class="n">c</span><span class="si">}</span><span class="s2">&quot;</span>
<span class="k">end</span>
<span class="c1"># 1, 2, 3</span>
<span class="c1"># 4, 5, 6</span>
<span class="c1"># 7, 8, 9</span>
</pre>
</div>
</div><ul><li class="action">Донякъде и при разгъване на аргументи на методи (бройката трябва да отговаря)
</li><li class="action">Запомнете ги</li></ul></section>
<section>
<hgroup><h1>Присвояване в Ruby</h1></hgroup>
<p>Имате ли въпроси по тази тема?</p></section>
<section>
<hgroup><h1>Импортиране на файлове</h1></hgroup>
<p>В Ruby, код от други файлове се импортира с <code>require</code>.</p><div class="action"><p>Например:</p><div class="highlight"><pre><span class="nb">require</span> <span class="s1">&#39;bigdecimal&#39;</span>
<span class="nb">require</span> <span class="s1">&#39;bigdecimal/util&#39;</span>
</pre>
</div>
</div></section>
<section>
<hgroup><h1>Какво търси require?</h1></hgroup>
<ul><li class="action"><code>require \'foo\'</code> търси файл <code>foo.rb</code> в "пътя за зареждане".
</li><li class="action">Още известен като load path.
</li><li class="action">Той съдържа няколко "системни" пътища, плюс пътища от gem-ове, които сте си инсталирали.
</li><li class="action">Очевидно, <code>require \'foo/bar\'</code> търси директория <code>foo</code> с файл <code>bar.rb</code>.
</li><li class="action">Разширението <code>.rb</code> отзад не е задължително да присъства.
</li><li class="action"><code>require \'./foo\'</code> търси <code>foo.rb</code> в текущата директория.
</li><li class="action">Разбира се, абсолютни пътища също работят: <code>require \'/home/skanev/foo.rb\'</code>.</li></ul></section>
<section>
<hgroup><h1>Зареждане на файлове от текущата директория</h1></hgroup>
<ul><li class="action">Обикновено във вашия load path текущата директория не присъства
</li><li class="action">Някои хора се осмеляват да си я добавят, променяйки load path
</li><li class="action">Адът се отваря и ги поглъща
</li><li class="action">Ползвайте релативен път, т.е. <code>require \'./foo\'</code></li></ul></section>
<section>
<hgroup><h1>Зареждане на файлове от текущата директория</h1><h2>require_relative</h2></hgroup>
<ul><li class="action">Алтернатива на горното е <code>require_relative</code>
</li><li class="action"><code>require_relative \'foo\'</code> зарежда \'foo\' спрямо <strong>директорията на изпълняващия се файл</strong>
</li><li class="action"><code>require \'./foo\'</code> зарежда спрямо <strong>текущата директория на изпълняващия процес</strong></li></ul></section>
<section>
<hgroup><h1>Load path</h1><h2>където Ruby търси файлове за require</h2></hgroup>
<ul><li>Достъпен е като <code>$LOAD_PATH</code>.</li><li>Още <code>$:</code></li><li>Може да го променяте. Стандартно с <code>$:.unshift(path)</code></li><li>Не е много добра практика да го правите.</li></ul></section>
<section>
<hgroup><h1>Как работи require?</h1></hgroup>
<ul><li class="action">Изпълнява файла.
</li><li class="action">Константите, класове, глобални променливи и прочее са достъпни отвън.
</li><li class="action">Няма абстракция. Все едно сте inline-нали файла на мястото на <code>require</code>-а. Почти.
</li><li class="action">Файлът е изпълнен с друг binding. Демек, локалните му променливи са изолирани. Но само те.
</li><li class="action">Не че има значение, но <code>main</code> обекта е същия.
</li><li class="action">Файлът се изпълнява само веднъж. Повторни <code>require</code>-и не правят нищо.
</li><li class="action">Последното може да се излъже по няколко начина.
</li><li class="action"><code>require</code> може да зарежда <code>.so</code> и <code>.dll</code> файлове.</li></ul></section>
<section>
<hgroup><h1>Типичната структура на един gem</h1><h2>skeptic опростен</h2></hgroup>
<pre>.
├── README.rdoc
├── Rakefile
├── bin
│   └── skeptic
├── features
├── lib
│   ├── skeptic
│   │   ├── rules.rb
│   │   └── scope.rb
│   └── skeptic.rb
├── skeptic.gemspec
└── spec </pre></section>
<section>
<hgroup><h1>Особеностите</h1></hgroup>
<ul><li class="action"><code>lib/</code> обикновено съдържа <code>foo.rb</code> и <code>lib/foo/</code>.
</li><li class="action"><code>foo.rb</code> обикновено е единственото нещо в <code>lib/</code>.
</li><li class="action">Всичко останало е в <code>lib/foo</code>.
</li><li class="action"><code>lib/</code> се добавя в load path.
</li><li class="action">Така вече може да правите <code>require \'foo\'</code> или <code>require \'foo/something\'</code>.
</li><li class="action">По този начин не замърсявате <code>require</code> областта.
</li><li class="action">RubyGems прави това "автомагично".</li></ul></section>
<section>
<hgroup><h1>Останалите неща</h1></hgroup>
<ul><li>Разгледайте <a href="http://github.com/skanev/skeptic">skanev/skeptic</a> за повече подробности.</li><li>После разгледайте някой друг gem.</li><li>После си поиграйте малко с <code>require</code> и <code>$LOAD_PATH</code> и вижте какво се случва.</li></ul></section>
<section>
<hgroup><h1>Kernel#load</h1></hgroup>
<ul><li class="action"><code>load</code> е много сходен с <code>require</code>, но има няколко разлики.
</li><li class="action">Иска разширение на файл - <code>load \'foo.rb\'</code>.
</li><li class="action">Повторни <code>load</code>-ове изпълняват файла.
</li><li class="action"><code>load</code> не може да зарежда <code>.so</code>/<code>.dll</code> библиотеки.
</li><li class="action"><code>load</code> има опционален параметър, с който може да обвие файла в анонимен модул.
</li><li class="action">Последното дава известна изолация.</li></ul></section>
<section>
<hgroup><h1>Замразяване на обекти в Ruby</h1></hgroup>
<ul><li class="action">Реално превръща mutable-обекти в immutable
</li><li class="action">Замразяването става с <code>Object#freeze</code>
</li><li class="action">Можете да проверите дали обект е замразен с <code>Object#frozen?</code>
</li><li class="action">Веднъж замразен, даден обект не може да бъде размразен
</li><li class="action">Не можете да променяте вече замразени обекти
</li><li class="action">Често се ползва, когато присволявате mutable-типове на константи
</li><li class="action">Възможно е да доведе до ускоряване на вашия код</li></ul></section>
<section>
<hgroup><h1>Замразяване на обекти</h1></hgroup>
<div class="highlight"><pre><span class="k">module</span> <span class="nn">Entities</span>
  <span class="no">ENTITIES</span> <span class="o">=</span> <span class="p">{</span>
    <span class="s1">&#39;&amp;&#39;</span> <span class="o">=&gt;</span> <span class="s1">&#39;&amp;amp;&#39;</span><span class="p">,</span>
    <span class="s1">&#39;&quot;&#39;</span> <span class="o">=&gt;</span> <span class="s1">&#39;&amp;quot;&#39;</span><span class="p">,</span>
    <span class="s1">&#39;&lt;&#39;</span> <span class="o">=&gt;</span> <span class="s1">&#39;&amp;lt;&#39;</span><span class="p">,</span>
    <span class="s1">&#39;&gt;&#39;</span> <span class="o">=&gt;</span> <span class="s1">&#39;&amp;gt;&#39;</span><span class="p">,</span>
  <span class="p">}</span><span class="o">.</span><span class="n">freeze</span>

  <span class="no">ENTITY_PATTERN</span> <span class="o">=</span> <span class="sr">/</span><span class="si">#{</span><span class="no">ENTITIES</span><span class="o">.</span><span class="n">keys</span><span class="o">.</span><span class="n">join</span><span class="p">(</span><span class="s1">&#39;|&#39;</span><span class="p">)</span><span class="si">}</span><span class="sr">/</span><span class="o">.</span><span class="n">freeze</span>

  <span class="k">def</span> <span class="nf">escape</span><span class="p">(</span><span class="n">text</span><span class="p">)</span>
    <span class="n">text</span><span class="o">.</span><span class="n">gsub</span> <span class="no">ENTITY_PATTERN</span><span class="p">,</span> <span class="no">ENTITIES</span>
  <span class="k">end</span>
<span class="k">end</span>
</pre>
</div>
</section>
<section><hgroup><h1>Въпроси</h1></hgroup><ul><li><a href="http://fmi.ruby.bg/topics">http://fmi.ruby.bg/</a></li><li><a href="http://twitter.com/rbfmi/">@rbfmi</a></li></ul></section></div><script src="js/jquery-1.5.2.min.js"></script><script src="js/jquery.jswipe-0.1.2.js"></script><script src="js/htmlSlides.js"></script><script type="text/javascript">$(function() {
  htmlSlides.init({ hideToolbar: true });
});</script></body></html>').to_pdf

# Document.new('<html><section>
# <hgroup><h1>case</h1><h2>Object#===</h2></hgroup>
# <p><code>case</code> сравнява с <code>===</code>. Няколко класа го имплементират:</p><ul><li class="action"><code>Range</code>
# </li><li class="action"><code>Regexp</code>
# </li><li class="action"><code>Class</code>
# </li><li class="action">Списъкът не е изчерпателен...
# </li><li class="action">По подразбиране се оценява като <code>==</code>.</li></ul></section>
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