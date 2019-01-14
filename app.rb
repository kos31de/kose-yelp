require 'sinatra'
require 'sinatra/reloader'
require 'json'
require 'rest-client'
require 'pry'

FB_ENDPOINT = "https://graph.facebook.com/v2.6/me/messages?access_token=" + "EAAf9VlE5LSsBAMZBnEDd6kQlnHzhDGE3XHQXHe8ZApLWmeC2JiHxOHk29JwU4AnpXvJHxkRFI1ALx3cZAutrc8ybFfLAbXONRENzgFTIukyZCrSO7LxhtLb09yRGyAZCd6CSHvjMZAPfuEl1CyPD5ZAjMqehga8cxm2AkD8AEMPHbnOuGkstrfB"
GNAVI_KEYID = "50f3f62e0ff8c812044c1e69d7d5ea08"
GNAVI_CATEGORY_LARGE_SEARCH_API = "https://api.gnavi.co.jp/master/CategoryLargeSearchAPI/v3/"

helpers do
  # Get vategory from gurunavi API
  def get_categories
    response = JSON.parse(RestClient.get GNAVI_CATEGORY_LARGE_SEARCH_API + "?keyid=#{GNAVI_KEYID}")
    categories = response["category_l"]
    categories
  end

  def set_quick_reply_of_categories sender, categories
    {
      recipient: {
        id: sender
      },
      message: {
        text: 'Thanks :P Please tell me, what do you wanna eat?',
        quick_replies: categories
      }
    }.to_json
  end

  # quicl reply. category is up to 11.
  def filter_categories
      categories = []
      get_categories.each_with_index do |category, i|
        if i < 11
          hash = {
            content_type: 'text',
            title: category["category_l_name"],
            payload: category["category_l_code"],
          }
          p hash
          categories.push(hash)
        else
          p "dont add 11th into categories"
        end
      end
      categories
    end
end


get '/' do
  'hello'
end

# initial auth
get '/callback' do
  if params["hub.verify_token"] != 'foobarbaz'
    return 'Error, wrong validation token'
  end
    params["hub.challenge"]
end

# when receiving message
post '/callback' do
  hash = JSON.parse(request.body.read)
  message = hash["entry"][0]["messaging"][0]
  sender = message["sender"]["id"]

if message["message"]["text"] == "hungry!"
  categories = filter_categories
  request_body = set_quick_reply_of_categories(sender, categories)
  RestClient.post FB_ENDPOINT, request_body, content_type: :json, accept: :json
else
  #  add message in text 
text = "Search restaurants by your location and category. Say 'hungry!' "
  content = {
    recipient: {id: sender},
    message: {text: text}
  }
  request_body = content.to_json # convert to json
  #reply by POST
  RestClient.post endpoint, FB_ENDPOINT, request_body, content_type: :json, accept: :json
  end
  status 201
  body ''
end
