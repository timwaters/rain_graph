##
# Rain Graph
# for any uk lat and lon, will create a graph showing predicted rainfall
#
# 

# lat lon to pixel for zoom level
# get value for pixel level
# get tiles for now, 1hr, 2hr, 3hr
# get value for pixel
# create graph
# output graph

require 'rubygems'
require 'simple_mercator_location'
require 'chunky_png'
require 'open-uri'

ZOOM =  9
API_KEY = ENV["API_KEY"]

def get_value_at_lat_lon(lat,lon)
  location = SimpleMercatorLocation.new({:lat => lat, :lon => lon})

  xy = location.zoom_at(ZOOM).to_px
  tile_coords = location.zoom_at(ZOOM).to_tile

  puts xy.inspect
  puts tile_coords.inspect

  time_now = Time.now.strftime("%FT%H:00:00Z")
  time_stamp = time_now
  
  forecast =  "%2B0" # %2B = + thus "%2B0" = "+0"
  
  tile_url = "http://www.metoffice.gov.uk/public/data/LayerCache/UKPPNOW/ItemBbox/Precipitation_Rate/#{tile_coords[0]}/#{tile_coords[1]}/#{ZOOM}/png?RUN=#{time_stamp}&FORECAST=#{forecast}&styles=Bitmap+Blue-Pale+blue+gradient+0.01+to+greater+than+32mm%2Fhr&api_key=#{API_KEY}"
  
  image = ChunkyPNG::Image.from_io(open(tile_url))
  puts image[tile_coords[0],tile_coords[1]]  #pixel value at that location
end

pixel_value = get_value_at_lat_lon(53, -3)
puts pixel_value



