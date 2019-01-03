#!/usr/bin/env ruby
# frozen_string_literal: true

require 'instapaper'
require 'fileutils'
require 'stringex_lite'
require_relative 'secrets'
require_relative 'ndjson'
require_relative 'colorize'

ARCHIVE_ROOT = File.join __dir__, '..', 'bookmarks', 'instapaper'
BOOKMARKS_LIMIT = 500
APPEND = true

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

def load_existing_ids(filename)
  ids = []

  return ids unless File.exist? filename

  File.readlines(filename).each do |line|
    parsed = JSON.parse(line)
    ids.push(parsed['bookmark_id'])
  end
  puts "Already have #{ids.count} IDs"
  ids
end

def download_bookmarks(client, folder_id, output, text_dir, have = [])
  response = client.bookmarks(have: have.join(','), limit: BOOKMARKS_LIMIT, folder_id: folder_id)
  if response.bookmarks.empty?
    puts 'Response empty'
    return
  end
  response.bookmarks.each do |bookmark|
    bookmark_id = bookmark.bookmark_id
    puts " #{bookmark_id} #{bookmark.title}"
    h = bookmark.to_hash
    h[:highlights] = get_highlights(client, bookmark_id)
    download_text client, h, text_dir
    output.write h
    have.push bookmark_id
  end
  puts "Have #{have.count} bookmarks"
  download_bookmarks client, folder_id, output, text_dir, have
end

def download_from_folder(client, folder_id, folder_name)
  filename = File.join ARCHIVE_ROOT, "#{folder_name}.jsonl"
  puts "Fetching folder #{folder_name} (#{folder_id}) to #{filename}".yellow
  text_dir = folder_dir folder_name
  mode = 'w'
  mode = 'a' if APPEND
  has_ids = load_existing_ids(filename)
  output = NdjsonFile.new(filename, mode)
  download_bookmarks client, folder_id, output, text_dir, has_ids
end

def download_text(client, bookmark, dir)
  bookmark_id = bookmark[:bookmark_id]
  errored = false
  slug = bookmark[:title].to_url(limit: 30, replace_whitespace_with: '_')
  begin
    text = client.get_text bookmark_id
  rescue StandardError => e
    print ' Error fetching text:'.red
    puts e
    puts " #{bookmark[:url]}"
    errored = true
  end
  filename = File.join dir, "#{errored ? 'err-' : ''}#{bookmark_id}-#{slug}.html"
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