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


def get_tile_url(tile_coords, time_stamp, forecast)

  tile_url = "http://www.metoffice.gov.uk/public/data/LayerCache/UKPPNOW/ItemBbox/Precipitation_Rate/#{tile_coords[0]}/#{tile_coords[1]}/#{ZOOM}/png?RUN=#{time_stamp}&FORECAST=#{forecast}&styles=Bitmap+Blue-Pale+blue+gradient+0.01+to+greater+than+32mm%2Fhr&api_key=#{API_KEY}"
  return tile_url
end

def get_value_at_lat_lon(lat,lon)
  location = SimpleMercatorLocation.new({:lat => lat, :lon => lon})

  xy = location.zoom_at(ZOOM).to_px
  tile_coords = location.zoom_at(ZOOM).to_tile

  time_nowish = Time.now
  if time_nowish.min < 20
    time_nowish = time_nowish - 20*60
  end
  time_stamp = time_nowish.strftime("%FT%H:00:00Z")
 
  
  pixels = []
  (0..4).each do | hr |
    
    forecast =  "%2B"+hr.to_s # %2B = + thus "%2B0" = "+0"

    tile_url = get_tile_url(tile_coords, time_stamp, forecast) 
    puts tile_url 
  
    image = ChunkyPNG::Image.from_io(open(tile_url))
    puts tile_coords.inspect

    pixels << ChunkyPNG::Color.to_truecolor_bytes(image[tile_coords[0],tile_coords[1]]) #pixel value at that location
  end

  puts pixels.inspect
  
  return pixels
end

lookup = {
  [0,0,0] => 0,
  [0,0,254] => 0.5,
  [50,101,254] => 1,
  [127,127,0] => 2,
  [254,203,0]=> 4,
  [254,152,0]=>8,
  [254,0,0] => 16,
  [254,0,254]=>32,
  [999,999,999]=>48
}

pixel_values = get_value_at_lat_lon(49.08, -8.62)
puts pixel_values.inspect

rainfall = []
pixel_values.each_with_index do | px, i |
  if lookup.keys.include? px
    rainfall << lookup[px]
    puts "#{i}: #{lookup[px]}"
  else
    puts "unknown" + px
  end
end

puts rainfall.inspect

