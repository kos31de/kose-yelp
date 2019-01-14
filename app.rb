require 'sinatra'
require 'sinatra/reloader'
require 'json'

get '/' do
  'hello'
end

get '/callback' do
  if params["hub.verify_token"] != 'foobarbaz'
    return 'Error, wrong validation tokenz'
  end
    params["hub.challenge"]
end
