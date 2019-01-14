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

post '/callback' do
  hash = JSON.parse(request.body.read)
  message = hash["entry"][0]["messaging"][0] #entryの0個目のmessagingの0個目
  sender = message["sender"]["id"] #上記で取得したmessage変数の中のsenderのid
  text = message["message"]["text"]#上記で取得したmessage変数の中のmessageのtest
  endpoint = "https://graph.facebook.com/v2.6/me/messages?access_token=" + "EAAf9VlE5LSsBAHYtSZC3BuXnfWwG32BzWZB3oeIiRSVxG9mmFLMa3vGfdlxklQ9ZA7dB1aOI56woQoJ2ZAmWTBXVWU6nj1tbMpI5s9QPT40iZAZBad9keicRN2TSRn44bxSJDAJlHL09PxcjqvRSKkg1XZCwgjB8H9Awvmejq03gySnpvYqw4EL"
  content = {
    recipient: {id: sender},
    message: {text: text}
  }
  request_body = content.to_json

  #オウム返しの返信をPOSTする（返す）
  RestClient.post endpoint, request_body, content_type: :json, accept: :json
  status 201
  body ''
end
