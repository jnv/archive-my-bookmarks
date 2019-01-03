#!/usr/bin/env ruby
# frozen_string_literal: true

require 'instapaper'
require 'fileutils'
require_relative 'secrets'
require_relative 'ndjson'

ARCHIVE_ROOT = 'archive'

credentials = {
  consumer_key: CONSUMER_KEY,
  consumer_secret: CONSUMER_SECRET,
  oauth_token: OAUTH_TOKEN,
  oauth_token_secret: OAUTH_SECRET,
}

client = Instapaper::Client.new(credentials)
#token = client.access_token(USERNAME, PASSWORD)
#client.oauth_token = token.oauth_token
#client.oauth_token_secret = token.oauth_token_secret
client.verify_credentials

def folder_dir(folder_name)
  path = File.join ARCHIVE_ROOT, folder_name
  FileUtils.mkdir_p path
  path
end

def download_bookmarks(client, folder_id, output, text_dir, have = [])
  response = client.bookmarks(have: have.join(','), folder_id: folder_id)
  if response.bookmarks.empty?
    puts 'Response empty'
    return
  end
  response.bookmarks.each do |bookmark|
    bookmark_id = bookmark.bookmark_id
    puts " #{bookmark_id} #{bookmark.title}"
    h = bookmark.to_hash
    h[:highlights] = get_highlights(client, bookmark_id)
    output.write h
    download_text client, h, text_dir
    have.push bookmark_id
  end
  puts "Have #{have.count} bookmarks"
  download_bookmarks client, folder_id, output, text_dir, have
end

def download_from_folder(client, folder_id, folder_name)
  filename = File.join ARCHIVE_ROOT, "#{folder_name}.jsonl"
  ids = []
  puts "Fetching folder #{folder_name} (#{folder_id}) to #{filename}"
  text_dir = folder_dir folder_name
  output = NdjsonFile.new(filename)
  download_bookmarks client, folder_id, output, text_dir
end

def download_text(client, bookmark, dir)
  bookmark_id = bookmark[:bookmark_id]
  text = client.get_text bookmark_id
  filename = File.join dir, "#{bookmark_id}.html"
  File.open(filename, 'w') do |file|
    file.write "---\n"
    file.write bookmark.to_json
    file.write "\n---\n"
    file.write text
  end
end

def get_highlights(client, bookmark_id)
  client.highlights(bookmark_id).map(&:to_hash)
end


FileUtils.mkdir_p ARCHIVE_ROOT
#['unread', 'archive'].each do |folder|
#  download_from_folder client, folder, folder
#end
folders = client.folders
File.write File.join(ARCHIVE_ROOT, 'folders.json'), folders.map(&:to_hash).to_json
folders.each do |folder|
  download_from_folder client, folder.folder_id, folder.slug
end