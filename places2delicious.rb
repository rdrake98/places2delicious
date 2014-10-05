#!/usr/bin/ruby

require 'rubygems'
require 'sqlite3'
require 'net/https'
require 'rexml/document'
require 'uri'
require_relative 'Bookmark'
require 'yaml'
require 'netrc'
require 'inifile'

=begin
* Name: places2delicious
* Description: export bookmarks from Firefox >3.x places.sqlite to delicious
* Author: Nicolas Meier
* Creation Date: 2009-02-06
* License: All Rights Reserved, Copyright © Nicolas Meier
* Version 1.2 2014-10-05
=end

class Net::HTTP
  alias_method :old_initialize, :initialize
  def initialize(*args)
    old_initialize(*args)
    @ssl_context = OpenSSL::SSL::SSLContext.new
    @ssl_context.verify_mode = OpenSSL::SSL::VERIFY_NONE
  end
end

module Places2delicious
    class Places2delicious
      CONFIG = YAML.load_file("places2delicious.yml")
      n = Netrc.read
    
      # Get current user
      currentUser = (%x(echo $USER)).delete("\n")
      # Path to Firefox data and profiles.ini
      pathToFirefox = "/Users/" + currentUser + "/Library/Application Support/Firefox/"
      pathToProfilesIni = pathToFirefox + "profiles.ini"
      
      # Load profiles.ini file
      file = IniFile.load(pathToProfilesIni)
      
      # Get the profile and its path
      iniProfile = file["Profile" + CONFIG["places"]["profile-number"].to_s]
      profilePath = iniProfile["Path"]
      isRelative = iniProfile["IsRelative"]
      if isRelative
        pathProfile = pathToFirefox + profilePath
      else
        pathProfile = profilePath
      end
      
      @@pathToPlaces = pathProfile + "/places.sqlite"
      @@notSharedTag = CONFIG["places"]["not-shared-tag"]
      @@apiUrl = CONFIG["delicious"]["api"]["url"]
      @@apiPort = CONFIG["delicious"]["api"]["port"]
      # Get delicious username and password from .netrc
      @@username, @@password = n["delicious.com"]

      def initialize
      end
      
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
              bookmarks[array] = Bookmark::Bookmark.new(title, url, [tag], description, visitCount, frecency) # Create the Bookmark
            else
              bookmark.tags.push(tag) # Add the tags to the bookmark
            end
          end
          
          # Close the database connection
          db.close
          
          bookmarks
      end
      
      def importToDelicious tagToImport
        i = 0
        
        # Open a TCP connection and an HTTPs session
        http = Net::HTTP.new(@@apiUrl, @@apiPort)
        http.use_ssl = true
        http.start do |http|  
        
          bookmarks = retrieveBookmarks
          nbOfBookmarks = bookmarks.values.size
        
          # Iterate over the retrieved bookmarks
          bookmarks.values.each do |bookmark|
            i += 1
        
            # Keep the bookmark private?
            doNotShare = !(bookmark.tags.index(@@notSharedTag).nil?)
        
            # Import everything or Specific tag to process?
            if tagToImport.nil? or !bookmark.tags.index(tagToImport).nil?
              puts i.to_s + " / #{nbOfBookmarks}: #{bookmark.title} -> #{bookmark.url} : #{bookmark.tags.join(', ')}"
        
              puts bookmark.postToDelicious(http, @@username, @@password, doNotShare)
            end
          end
        end
      end

      if __FILE__ == $0
        @@tagToImport = ARGV[0]
  
        instance = Places2delicious.new
        instance.importToDelicious @@tagToImport
      end
      
    end
end
