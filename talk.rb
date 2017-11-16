require "aws-sdk"
require "twitter"

text = "drilllllling sounds!"

@polly = Aws::Polly::Client.new(region: "us-east-1")

@polly.synthesize_speech(
  response_target: "./tmp/output.mp3",
  text: text,
  output_format: "mp3",
  voice_id: "Geraint"
)

system("ffmpeg -i ./tmp/output.mp3 -c:a aac ./tmp/output.m4a")
system("ffmpeg -i ./tmp/output.m4a -loop 1 -i drill.jpg -c:a copy -c:v libx264 -shortest ./tmp/output.mp4")

video = File.open("./tmp/output.mp4")

client = Twitter::REST::Client.new do |config|
  config.consumer_key        = ENV.fetch("TWITTER_CONSUMER_KEY")
  config.consumer_secret     = ENV.fetch("TWITTER_CONSUMER_SECRET")
  config.access_token        = ENV.fetch("TWITTER_ACCESS_TOKEN")
  config.access_token_secret = ENV.fetch("TWITTER_ACCESS_TOKEN_SECRET")
end

client.update_with_media(text, video)

system("rm ./tmp/*")
