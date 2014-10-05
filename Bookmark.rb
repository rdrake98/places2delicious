require 'net/https'
require 'rexml/document'
require 'uri'
require 'yaml'

=begin
* Name: Bookmark module and class
* Description: a bookmark is a title, a url and tags
* Author: Nicolas Meier
* Creation Date: 2009-02-06
* License: All Rights Reserved, Copyright © Nicolas Meier
* Version 1.1 2009-02-06
* Version 1.2 2012-03-03: separating tags by a comma
=end
module Bookmark

  CONFIG = YAML.load_file("places2delicious.yml")

  class Bookmark
    VISIT_COUNT_SYMBOL = :"♞"
    FRECENCY_SYMBOL =  :"♚"

    @@maxVisitCount = 0
    @@maxFrecency = 0
    attr_accessor :title, :url, :tags, :description, :visitCount, :frecency

    def initialize(title, url, tags, description, visitCount, frecency)
      @title = title
      @url = url
      @tags = tags
      @description = description
      @visitCount = visitCount
      @frecency = frecency

      if @visitCount > @@maxVisitCount
        @@maxVisitCount = @visitCount
      end

      if @frecency > @@maxFrecency
        @@maxFrecency = @frecency
      end
    end

    def postToDelicious(http, username, password, doNotShare)
      if CONFIG["delicious"]["import-stats"]
        visitCountTag = VISIT_COUNT_SYMBOL.to_s * (10 * @visitCount / @@maxVisitCount).ceil
        frecencyTag = FRECENCY_SYMBOL.to_s * (10 * @frecency / @@maxFrecency).ceil
        @tags.push(visitCountTag)
        @tags.push(frecencyTag)
      end

      # Add the import tag
      importTag = CONFIG["delicious"]["import-tag"]
      if !importTag.nil? 
        @tags.push(importTag)
      end

      # Prepare the arguments
      encodedUrl = URI.escape(@url)
      encodedUrl = URI.escape(encodedUrl, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
      postUrl = "?url=" + encodedUrl

      encodedDesc = URI.escape(@title)
      postDesc = "&description=" + encodedDesc

      postExt = ""
      if !@description.nil?
        encodeExtended = URI.escape(@description)
        postExt = "&extended=" + encodeExtended
      end

      postTags = "&tags=" + URI.escape(@tags.join(','))

      post = postUrl + postDesc + postTags + postExt

      # Keep the bookmark private ?
      if doNotShare
        post += "&shared=no"
      end

      # Create the HTTPs request
      req = Net::HTTP::Get.new("/v1/posts/add" + post, {"User-Agent" => "juretta.com RubyLicious 0.2"})
      req.basic_auth(username, password)

      # Send the request
      response = http.request(req)
      resp = response.body

      #  XML Document
      doc = REXML::Document.new(resp)
      doc.root.attributes['code'].upcase == "DONE"
    end
  end
end