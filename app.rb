require 'sinatra'
require 'sinatra/reloader'
require 'json'

get '/' do
  'hello'
end

get '/callback' do
  if params["hub.verify_token"] != 'EAAf9VlE5LSsBAHYtSZC3BuXnfWwG32BzWZB3oeIiRSVxG9mmFLMa3vGfdlxklQ9ZA7dB1aOI56woQoJ2ZAmWTBXVWU6nj1tbMpI5s9QPT40iZAZBad9keicRN2TSRn44bxSJDAJlHL09PxcjqvRSKkg1XZCwgjB8H9Awvmejq03gySnpvYqw4EL'
    return 'Error, wrong validation token'
  end
    params["hub.challenge"]
end
