##
# Rain Graph
# for any uk lat and lon, will create a graph showing predicted rainfall
#
# 
require 'sinatra'
require 'chunky_png'
require 'open-uri'
require 'digest/md5'
require 'json'


ZOOM =  7
API_KEY = ENV["API_KEY"]

def get_text_forecast(code)
  return nil unless code
    
  cachetime = Time.now.strftime("%D/%H").to_s
  url = "http://datapoint.metoffice.gov.uk/public/data/txt/wxfcs/regionalforecast/json/#{code}?key=#{API_KEY}&cachetime=#{cachetime}"
  filename = File.join("cache", Digest::MD5.hexdigest(url)+".json")
  unless File.exists? filename
    File.open(filename, 'wb') do |fo|
      fo.write open(url).read 
    end
  end
  
  forecast = JSON.parse(File.read(filename));

  headline = forecast["RegionalFcst"]["FcstPeriods"]["Period"][0]["Paragraph"][0]["$"]
  nextperiod = forecast["RegionalFcst"]["FcstPeriods"]["Period"][0]["Paragraph"][1]["$"]
  text_forecast = {:headline => headline, :nextperiod => nextperiod}
  
  return text_forecast
end

def get_tile_url(tile_coords, time_stamp, forecast)
  tile_url = "http://www.metoffice.gov.uk/public/data/LayerCache/UKPPNOW/ItemBbox/Precipitation_Rate/#{tile_coords[0]}/#{tile_coords[1]}/#{ZOOM}/png?RUN=#{time_stamp}&FORECAST=#{forecast}&styles=Bitmap+Blue-Pale+blue+gradient+0.01+to+greater+than+32mm%2Fhr&key=#{API_KEY}"
  return tile_url
end

def get_pixel_xy(lat, lon, zoom)
  mapSize = (2 ** zoom) * 256

  latitude = lat
  longitude = lon

  point_x = (longitude + 180.0) / 360.0 * (1 << zoom)
  point_y = (1.0 - Math.log(Math.tan(latitude * Math::PI / 180.0) + 1.0 / Math.cos(latitude * Math::PI / 180.0)) / Math::PI) / 2.0 * (1 << zoom)
  tilex = point_x.to_i
  tiley = point_y.to_i
  pixelX = (tilex * 256) + ((point_x - tilex) * 256)
  pixelY = (tiley * 256) + ((point_y - tiley) * 256)
 
  return {:tile => [tilex, tiley], :pixel =>[ (pixelX.modulo(1)*256).to_i, (pixelY.modulo(1)*256).to_i] }
end


def get_values_at_lat_lon(lat,lon)
  tile_pixel_hash = get_pixel_xy(lat,lon, ZOOM)
  #puts tile_pixel_hash.inspect
  tile_coords = tile_pixel_hash[:tile]

  time_nowish = Time.now
  if time_nowish.min < 20
    time_nowish = time_nowish - 20*60
  end
  time_stamp = time_nowish.strftime("%FT%H:00:00Z")
 
  pixels = []
  (0..5).each do | hr |
    forecast =  "%2B"+hr.to_s # %2B = + thus "%2B0" = "+0"
    tile_url = get_tile_url(tile_coords, time_stamp, forecast) 
    filename = File.join("cache", Digest::MD5.hexdigest(tile_url)+".png")
    
    unless File.exists? filename
      require "open-uri"
      File.open(filename, 'wb') do |fo|
        fo.write open(tile_url).read 
      end
    end
    
    image = ChunkyPNG::Image.from_file(filename)
    pixels << ChunkyPNG::Color.to_truecolor_bytes(image[tile_pixel_hash[:pixel][0],tile_pixel_hash[:pixel][1]]) #pixel value at that location
  end

  return pixels
end

get '/forecast/:place' do
  @place = params[:place]

  lookup = {
    [0,0,0] => 0, 
    [0,0,254] =>  1,
    [50,101,254] => 2,
    [127,127,0] => 3.5,
    [254,203,0]=> 5,
    [254,152,0]=>6,
    [254,0,0] => 7,
    [254,0,254]=> 8.5,
    [229,254,254]=>10
  }

 if @place == "custom" && params[:lat] && params[:lon]
   ll = {:lat => params[:lat].to_f, :lon => params[:lon].to_f, :code => nil}
 elsif @place == "leeds"
   ll = {:lat => 53.7997, :lon=>-1.5492, :code => 509}
 elsif @place == "manchester"
   ll = {:lat => 53.4667, :lon => -2.2333, :code => 507}
 else
   @place = "london"
   ll = {:lat => 52.507, :lon => -0.1275, :code => 514} 
 end
  pixel_values = get_values_at_lat_lon(ll[:lat], ll[:lon])
   
  @text_forecast = get_text_forecast(ll[:code])  

  rainfall = []
  pixel_values.each_with_index do | px, i |
    if lookup.keys.include? px
      rainfall << lookup[px]
      #puts "#{i}: #{lookup[px]}"
    else
      puts "unknown" + px
    end
  end
  puts rainfall.inspect
  @ll = ll
  @rainfall = rainfall
  
  erb :forecast
end

get '/' do
 erb :index
end
