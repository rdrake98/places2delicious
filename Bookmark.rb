class Bookmark
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

    @@maxVisitCount = @visitCount if @visitCount > @@maxVisitCount
    @@maxFrecency = @frecency if @frecency > @@maxFrecency
  end
end
