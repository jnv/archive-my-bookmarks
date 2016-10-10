#!/usr/bin/env ruby

require 'instapaper'
require_relative 'secrets'

credentials = {
  consumer_key: CONSUMER_KEY,
  consumer_secret: CONSUMER_SECRET,
}

client = Instapaper::Client.new(credentials)
token = client.access_token(USERNAME, PASSWORD)
client.oauth_token = token.oauth_token
client.oauth_token_secret = token.oauth_token_secret

client.verify_credentials

## Move all articles to folder

FOLDER_FROM = 'unread'
FOLDER_TO = '12345'

p client.folders

begin
  i = 0
  client.bookmarks(limit: 500, folder_id: FOLDER_FROM).each do |bookmark|
    i += 1
    id = bookmark.bookmark_id
    client.move_bookmark(id, FOLDER_TO)
    puts "#{i} #{bookmark.title}"
  end
  puts "#{i} bookmarks processed"
rescue Instapaper::Error => e
  p e
  raise
end
