# encoding: utf-8
require 'nokogiri'
require 'prawn'
require 'open-uri'
require 'tempfile'
require_relative './html_to_pdf'

module HTMLToPDF
  class Document
    attr_reader :content, :html, :name

    def initialize(html = nil)
      return unless html
      @html = text_format html
      @html.insert(0, '<document>').insert(-1, '</document>')
      #p @html
      @content = Tag.parse @html
      #p @content.class
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
      #p @pdf.font_size
      #p @content.class
      @content.to_pdf @pdf
      @name = @content.title
      #p "name is #{name}"
      #p @pdf
      @pdf.render_file "#{name}.pdf"
      #@pdf.render_file "Test.pdf"
    end
    
    def filename
      Dir.pwd + "/#@name.pdf"
    end
    
    def text_format(content)
      html = if content.strip.start_with?('http://')
               get_html_from content.strip
             else
               content
             end
      html.gsub(/\A<!.*?>/, '').gsub(/\n/, '')
    end
    
    def get_html_from(site)
      open(site).read
    end
  end
end

