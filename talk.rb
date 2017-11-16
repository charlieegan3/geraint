require "aws-sdk"
require "twitter"
require "cgi"

def clean_text(tweet)
  text = tweet.full_text

  text = text.gsub(/https?\S+$/, "")

  tweet.urls.map(&:url).each do |url|
    text = text.gsub(url.to_s, ["(a link)", "(a website)", "(some site)", "(some webpage)"].sample)
  end

  tweet.media.map(&:url).each do |url|
    text = text.gsub(url.to_s, ["(a photograph)", "(a photo)", "(some photo)", "(some pic)", "(an image)"].sample)
  end

  CGI.unescapeHTML(text).
    gsub(/^@\S+/, "").
    gsub("@", " ").
    gsub(/\s+/, " ").
    gsub("\"", "'").
    strip
end

def talk_tweet(client, tweet)
  system("rm ./tmp/*")

  text = clean_text(tweet)
  system("convert -bordercolor white -border 20 -size 400x400 caption:\"#{text}\" ./tmp/image.jpg")

  @polly = Aws::Polly::Client.new(region: "us-east-1")

  @polly.synthesize_speech(
    response_target: "./tmp/output.mp3",
    text: text,
    output_format: "mp3",
    voice_id: "Geraint"
  )

  system("ffmpeg -i ./tmp/output.mp3 -strict -2 -c:a aac ./tmp/output.m4a")
  system("ffmpeg -i ./tmp/output.m4a -loop 1 -i ./tmp/image.jpg -pix_fmt yuv420p -c:a copy -c:v libx264 -shortest ./tmp/output.mp4")

  video = File.open("./tmp/output.mp4")

  client.update_with_media("via #{tweet.user.screen_name}", video)

  system("rm ./tmp/*")
end

client = Twitter::REST::Client.new do |config|
  config.consumer_key        = ENV.fetch("TWITTER_CONSUMER_KEY")
  config.consumer_secret     = ENV.fetch("TWITTER_CONSUMER_SECRET")
  config.access_token        = ENV.fetch("TWITTER_ACCESS_TOKEN")
  config.access_token_secret = ENV.fetch("TWITTER_ACCESS_TOKEN_SECRET")
end

# client.user_timeline.each {|t|client.destroy_status(t); puts t }

client.favorites.each do |tweet|
  begin
    talk_tweet(client, tweet)
  rescue Exception => e
    puts "FAILED TO TALK TWEET: #{e} - #{tweet.url} - #{tweet.text}"
  end
end

client.unfavorite(client.favorites)
