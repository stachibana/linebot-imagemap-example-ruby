require 'sinatra'
require 'line/bot'
require 'mini_magick'

def client
  @client ||= Line::Bot::Client.new { |config|
    config.channel_secret = ENV['CHANNEL_SECRET']
    config.channel_token = ENV['CHANNEL_ACCESS_TOKEN']
  }
end

post '/' do
  body = request.body.read

  signature = request.env['HTTP_X_LINE_SIGNATURE']
  unless client.validate_signature(body, signature)
    error 400 do 'Bad Request' end
  end

  events = client.parse_events_from(body)
  events.each { |event|
    if event['type'] == 'message' then
      if event['message']['type'] == 'text' then
        actions = Array.new()
        actions.push({
          type: 'message',
          text: 'Button Pushed!',
          area: {
            x: 0,
            y: 0,
            # Button is 100px on 700px image. So 149px on base size(1040px)
            width: 149,
            height: 149,
          },
        })
        message = {
          type: 'imagemap',
          baseUrl: 'https://' + request.host + '/imagemap/' + SecureRandom.uuid, # prevent cache
          altText: '代替テキスト',
          baseSize: {
            width: 1040,
            height: 1040,
          },
          actions: actions
        }
        response = client.reply_message(event['replyToken'], message)
        puts response
        puts response.body
      end
    end
  }
  "OK"
end

get '/imagemap/:uniqid/:size' do |uniqid, size|

  image = MiniMagick::Image.open("./imagemap.png")
  image.resize size + "x" + size
  content_type :png
  send_file(image.path, :disposition => "inline")

end
