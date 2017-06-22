#!/usr/bin/ruby

require 'sqlite3'
require 'inifile'
require_relative 'Bookmark'

class Places2delicious
  pathToFirefox = "/Users/rd/Library/Application Support/Firefox/"
  ini = IniFile.load(pathToFirefox + "profiles.ini")
  pathProfile = pathToFirefox + ini["Profile#{ARGV[0]}"]["Path"]
  @@pathToPlaces = pathProfile + "/places.sqlite"

  def retrieveBookmarks
    bookmarks = []
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

    db.execute(query) do |row|
      title = row[0]
      url = row[1]
      tag = row[3]
      description = row[4]
      visitCount = row[5].to_f
      frecency = row[6].to_f
      bookmarks << Bookmark.new(title, url, [tag], description, visitCount, frecency)
    end
    db.close
    bookmarks
  end
end
bookmarks = Places2delicious.new.retrieveBookmarks
puts bookmarks.size
