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
end
