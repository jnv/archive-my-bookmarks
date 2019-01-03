# Archive Instapaper

The script `download.rb` downloads all your saved articles from Instapaper, including highlights and full text (if available).

By default data is stored to `../bookmarks/instapaper`. Articles' metadata is stored into `{folder-name}.jsonl` file (i.e. [newline-delimited JSON](http://jsonlines.org/)). Each article is stored into individual HTML file in respective folder with metadata repeated in [front matter](https://jekyllrb.com/docs/front-matter/).

## Usage

- Copy `secrets.example.rb` to `secrets.rb` and fill-in your OAuth application key, secret, access token and secret.
- Modify `download.rb`:
  - change `ARCHIVE_ROOT` if you wish to store your bookmarks elsewhere,
  - set `APPEND` to `false` if you wish to overwrite all data on every run, otherwise the script will skip already stored articles and continue,
  - set `MOVE_TO_FOLDER` to ID of the folder to move articles to after storing them; Instapaper API does not support pagination and gives you only 500 most recent articles in any folder, so to fetch everything, you need to move or delete the articles from the folder.
- Install dependencies with `bundle`
- Run `ruby download.rb`