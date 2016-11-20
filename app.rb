require 'sinatra'
require 'sinatra/json'
require "sinatra/cross_origin"
require './parse-warnings.rb'

set :bind, '0.0.0.0'

register Sinatra::CrossOrigin

configure do
  enable :cross_origin
end

get '/' do
  'Hello world!'
end

get '/latest-warning' do
  json parse_latest_warning
end

get '/warning-history' do
  json parse_warning_history
end

get '/active-warning' do
  json parse_active_warnings
end

options "*" do
  response.headers["Allow"] = "HEAD,GET,PUT,POST,DELETE,OPTIONS"
  response.headers["Access-Control-Allow-Headers"] = "X-Requested-With, X-HTTP-Method-Override, Content-Type, Cache-Control, Accept"
  200
end
