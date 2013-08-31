# encoding: utf-8
require 'sinatra'
require './document'

get '/' do
  erb :index
end

post '/' do
  html = params[:to_convert]
  document = HTMLToPDF::Document.new(html)
  document.to_pdf
  send_file document.filename, :filename => document.name, :type => 'application/pdf'
end
