require 'sinatra'
require 'sinatra/reloader'
require 'json'
require 'rest-client'
require 'pry'

FB_ENDPOINT = "https://graph.facebook.com/v2.6/me/messages?access_token=" + "EAAf9VlE5LSsBAMZBnEDd6kQlnHzhDGE3XHQXHe8ZApLWmeC2JiHxOHk29JwU4AnpXvJHxkRFI1ALx3cZAutrc8ybFfLAbXONRENzgFTIukyZCrSO7LxhtLb09yRGyAZCd6CSHvjMZAPfuEl1CyPD5ZAjMqehga8cxm2AkD8AEMPHbnOuGkstrfB"
GNAVI_KEYID = "50f3f62e0ff8c812044c1e69d7d5ea08"
GNAVI_CATEGORY_LARGE_SEARCH_API = "https://api.gnavi.co.jp/master/CategoryLargeSearchAPI/v3/"
GNAVI_SEARCHAPI = "https://api.gnavi.co.jp/RestSearchAPI/v3/"

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

  def set_quick_reply_of_location sender
    {
      recipient: {
        id: sender
      },
      message: {
        text: "Tell me your location information :P",
        quick_replies: [
          { content_type: "location" }
        ]
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

    # get location
    def get_location message
      lat = message["message"]["attachments"][0]["payload"]["coordinates"]["lat"]
      long = message["message"]["attachments"][0]["payload"]["coordinates"]["long"]
      [lat, long]
    end

    def get_restaurants lat, long, requested_category_code
      # location and category select
      params = "?keyid=#{GNAVI_KEYID}&latitude=#{lat}&longitude=#{long}&category_l=#{requested_category_code}&range=3"
      restaurants = JSON.parse(RestClient.get GNAVI_SEARCHAPI + params)
      restaurants
    end
  
    # A
    def set_restaurants_info restaurants
      elements = []
      restaurants["rest"].each do |rest|
          # sankoenzanshi
        image = rest["image_url"]["shop_image1"].empty? ? "http://techpit-bot.herokuapp.com/images/no-image.png" : rest["image_url"]["shop_image1"]
        elements.push(
          {
            title: rest["name"],
            item_url: rest["url_mobile"],
            image_url: image,
            subtitle: "[カテゴリー: #{rest["code"]["category_name_l"][0]}] #{rest["pr"]["pr_short"]}",
            buttons: [
              {
                type: "web_url",
                url: rest["url_mobile"],
                title: "詳細を見る"
              }
            ]
          }
        )
      end
      elements
    end
  
    # restaurant informatioon
    def set_reply_of_restaurant sender, elements
      {
        recipient: {
          id: sender
        },
        message: {
          attachment: {
            type: 'template',
            payload: {
              template_type: "generic",
              elements: elements
            }
          }
        }
      }.to_json
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
  # keep message and senderID
  hash = JSON.parse(request.body.read)
  message = hash["entry"][0]["messaging"][0]
  sender = message["sender"]["id"]

if message["message"]["text"] == "hungry!"
  categories = filter_categories
  request_body = set_quick_reply_of_categories(sender, categories)
  RestClient.post FB_ENDPOINT, request_body, content_type: :json, accept: :json  
# if category was selected, request the location
elsif !message["message"]["quick_reply"].nil?
    $requested_category_code = message["message"]["quick_reply"]["payload"]
    request_body = set_quick_reply_of_location(sender)
    RestClient.post FB_ENDPOINT, request_body, content_type: :json, accept: :json
elsif !message["message"]["attachments"].nil? && message["message"]["attachments"][0]["type"] == 'location' && !$requested_category_code.nil?
  lat, long = get_location(message)
  restaurants = get_restaurants(lat, long, $requested_category_code)
  elements = set_restaurants_info(restaurants)
  request_body = set_reply_of_restaurant(sender, elements)
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
  RestClient.post FB_ENDPOINT, request_body, content_type: :json, accept: :json
  end
  status 201
  body ''
end
