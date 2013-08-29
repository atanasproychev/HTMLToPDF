# encoding: utf-8
require 'sinatra'
require './html_to_pdf'

get '/' do
  erb :index
end

post '/' do
  html = params[:to_convert]
  HTMLToPDF::Document.new(html).to_pdf
end
