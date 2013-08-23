require 'nokogiri'

class HtmlTag
  def initialize(html)
    @attributes = {:class => nil, :id => nil, :hidden => nil}
    @html = html
    @content = []
  end

  def HtmlTag.parse(html)
    name = /<(\w+)\b/.match(html) ? $1 : "unknown"
    return if name == "unknown"
    html = /<(#{name}).*?<\/#{name}>/.match(html)
    #html = html.reject(/<(#{name})/)
    Object.const_get(name.capitalize + "Tag").new html.to_s
    #p html

    #puts name
  end

  def get_attributes
    tag = only_tag
    /id=(".*?")/.match(tag)
    @attributes[:id] = $1.gsub(/\"/, "")
    /class=(".*?")/.match(tag)
    @attributes[:class] = $1.gsub(/\"/, "")
    @attributes[:hidden] = if /hidden/.match(tag)
                            true
                          else
                            false
                          end
    tag
  end

  def only_tag
    /<.*?>/.match(@html).to_s
  end
  
  def get_content
    #only_content = /<a.*?>(.*?)<\/a>/.match(@html)[1]
    #p only_content.scan(/<(\w+)>(.*?)<\/\1>/)
    original_content = Nokogiri::XML::DocumentFragment.parse(@html)
    p original_content.children.children.length
    original_content.children.children.each do |child|
      @content << if child.name == "text"
                    child.text
                  else
                    #HtmlTag.parse(child.
                  end
      p child.name
      p child.text
      puts "\n"
    end
  end
end

class ATag < HtmlTag
  def initialize(html)
    super(html)
    @attributes.merge!({:href => nil, :target => nil})
    get_attributes
    get_content
    p @attributes
  end
  
  def get_attributes
    tag = super
    /href=(".*?")/.match(tag)
    @attributes[:href] = $1.gsub(/\"/, "")
    /target=(".*?")/.match(tag)
    @attributes[:target] = $1.gsub(/\"/, "")
  end
end

class DivTag < HtmlTag
  def initialize(html)
    super(html)
    get_attributes()
    p @attributes
  end
end

#HtmlTag.parse '<a href="test.com">Nov <a href="newtest.com">Q<div>k</div></a> Text</a><a>Something</a>'
HtmlTag.parse '<a href="test.com" id="new_a" class="test" target="_blank">Nov Q<div>kdfgdf <b>rgrgrgf</b></div> fghfh<div id="5">Hello</div> Text</a>'
#HtmlTag.parse '<a href="test.com" id="new_a" class="test" target="_blank">Nov Text</a>'