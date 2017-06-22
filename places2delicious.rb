#!/usr/bin/ruby

require 'sqlite3'
require 'yaml'
require 'inifile'
require_relative 'Bookmark'

class Places2delicious
  pathToFirefox = "/Users/rd/Library/Application Support/Firefox/"
  file = IniFile.load(pathToFirefox + "profiles.ini")
  CONFIG = YAML.load_file("places2delicious.yml")
  iniProfile = file["Profile" + CONFIG["places"]["profile-number"].to_s]
  pathProfile = iniProfile["Path"]
  pathProfile = pathToFirefox + pathProfile if iniProfile["IsRelative"]
  @@pathToPlaces = pathProfile + "/places.sqlite"

  def retrieveBookmarks
      bookmarks = {}
      # Open the places SQLite database
      db = SQLite3::Database.open(@@pathToPlaces)

      # Query - Retrieve bookmarks associated to a place and to tags
      query = "SELECT bookmark.title, place.url, place.title, tag.title, anno.content,
      place.visit_count, place.frecency

      FROM moz_bookmarks bookmark, moz_places place

      LEFT OUTER JOIN moz_bookmarks bt on bt.fk = bookmark.fk
      LEFT OUTER JOIN moz_bookmarks tag on bt.parent = tag.id
      LEFT OUTER JOIN moz_bookmarks tag_parent on tag.parent = tag_parent.id
      LEFT OUTER JOIN moz_items_annos anno on bookmark.id = anno.item_id AND anno.anno_attribute_id = 2
      AND tag_parent.title = 'Tags'

      WHERE place.id = bookmark.fk
      AND bookmark.title is not null
      AND bookmark.type = 1"

      # Execute the query
      db.execute(query) do |row|
        title = row[0]              # Bookmark title
        url = row[1]                # Place url
        tag = row[3]                # Bookmark tags
        description = row[4]        # Description
        visitCount = row[5].to_f    # Visit count
        frecency = row[6].to_f      # Frecency

        array = [title, url]
        bookmark = bookmarks[array]
        if bookmark.nil?
          bookmarks[array] = Bookmark.new(title, url, [tag], description, visitCount, frecency)
        else
          bookmark.tags.push(tag) # Add the tags to the bookmark
        end
      end

      # Close the database connection
      db.close

      bookmarks
  end
end
instance = Places2delicious.new
bookmarks = instance.retrieveBookmarks
puts bookmarks.size
