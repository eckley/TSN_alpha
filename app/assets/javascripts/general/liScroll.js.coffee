#!
# * liScroll 1.0
# * Examples and documentation at:
# * http://www.gcmingati.net/wordpress/wp-content/lab/jquery/newsticker/jq-liscroll/scrollanimate.html
# * 2007-2010 Gian Carlo Mingati
# * Version: 1.0.2.1 (22-APRIL-2011)
# * Dual licensed under the MIT and GPL licenses:
# * http://www.opensource.org/licenses/mit-license.php
# * http://www.gnu.org/licenses/gpl.html
# * Requires:
# * jQuery v1.2.x or later
# *
#
jQuery.fn.liScroll = (settings, callback_fn) ->
  settings = jQuery.extend(
    travelocity: 0.075
  , settings)
  test = callback_fn
  @each ->
    # thanks to Michael Haszprunar and Fabien Volpi
    #a.k.a. 'mask' width
    # thanks to Scott Waye
    scrollnews = (spazio, tempo) ->
      $strip.animate
        left: "-=" + spazio
      , tempo, "linear", ->
        if typeof(callback_fn) == "function"
          callback_fn( ->
            stripWidth = 1
            $strip.find("li").each (i) ->
              stripWidth += jQuery(this, i).outerWidth(true)
            $strip.width stripWidth
            totalTravel = stripWidth + containerWidth
            defTiming = totalTravel / settings.travelocity
            $strip.css "left", containerWidth
            scrollnews totalTravel, defTiming
          )
        else
          $strip.css "left", containerWidth
          scrollnews totalTravel, defTiming

    $strip = jQuery(this)
    $strip.addClass "newsticker"
    stripWidth = 1
    $strip.find("li").each (i) ->
      stripWidth += jQuery(this, i).outerWidth(true)
    if !$strip.parent().hasClass("mask")
      $mask = $strip.wrap("<div class='mask'></div>")
      $tickercontainer = $strip.parent().wrap("<div class='tickercontainer'></div>")
    containerWidth = $strip.parent().parent().width()
    $strip.width stripWidth
    totalTravel = stripWidth + containerWidth
    defTiming = totalTravel / settings.travelocity
    scrollnews totalTravel, defTiming
    $strip.hover (->
      jQuery(this).stop()
    ), ->
      offset = jQuery(this).offset()
      residualSpace = offset.left + stripWidth
      residualTime = residualSpace / settings.travelocity
      scrollnews residualSpace, residualTime