##
# Rain Graph
# for any uk lat and lon, will create a graph showing predicted rainfall
#
# 
require 'sinatra'
require 'simple_mercator_location'
require 'chunky_png'
require 'open-uri'
require 'digest/md5'

ZOOM =  9
API_KEY = ENV["API_KEY"]

get '/' do
 erb :index
end


def get_tile_url(tile_coords, time_stamp, forecast)
  tile_url = "http://www.metoffice.gov.uk/public/data/LayerCache/UKPPNOW/ItemBbox/Precipitation_Rate/#{tile_coords[0]}/#{tile_coords[1]}/#{ZOOM}/png?RUN=#{time_stamp}&FORECAST=#{forecast}&styles=Bitmap+Blue-Pale+blue+gradient+0.01+to+greater+than+32mm%2Fhr&key=#{API_KEY}"
  return tile_url
end

def get_values_at_lat_lon(lat,lon)
  location = SimpleMercatorLocation.new({:lat => lat, :lon => lon})

  xy = location.zoom_at(ZOOM).to_px
  tile_coords = location.zoom_at(ZOOM).to_tile

  time_nowish = Time.now
  if time_nowish.min < 20
    time_nowish = time_nowish - 20*60
  end
  time_stamp = time_nowish.strftime("%FT%H:00:00Z")
 
  
  pixels = []
  (0..5).each do | hr |
    forecast =  "%2B"+hr.to_s # %2B = + thus "%2B0" = "+0"
    tile_url = get_tile_url(tile_coords, time_stamp, forecast) 
   
    filename = File.join("cache", Digest::MD5.hexdigest(tile_url))
    
    unless File.exists? filename
      require "open-uri"
      File.open(filename, 'wb') do |fo|
        fo.write open(tile_url).read 
      end
    end

    image = ChunkyPNG::Image.from_file(filename)
    
    puts tile_coords.inspect

    pixels << ChunkyPNG::Color.to_truecolor_bytes(image[tile_coords[0],tile_coords[1]]) #pixel value at that location
  end

  return pixels
end

get '/forecast/:place' do
  @place = params[:place]

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
  #Leeds =  53.7997° N, 1.5492

  pixel_values = get_values_at_lat_lon(53.799, -1.549)
  #puts pixel_values.inspect

  rainfall = []
  pixel_values.each_with_index do | px, i |
    if lookup.keys.include? px
      rainfall << lookup[px]
      puts "#{i}: #{lookup[px]}"
    else
      puts "unknown" + px
    end
  end
  
  @rainfall = rainfall
  
  erb :forecast
end
