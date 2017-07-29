#!/usr/bin/env ruby

require 'rss/2.0'
require 'open-uri'

def get_forecast(loc, type)
  url = "http://open.live.bbc.co.uk/weather/feeds/en/#{loc}/#{type}.rss"

  open(url) do |s|
    content = s.read
    return RSS::Parser.parse(content, false)
  end
end

def parse(str, re)
  str.match(re) or ""
end

def parse_latest(rss)
  info = {}
  title = parse(rss.channel.title, /Observations for (.*),/)
  descr1 = parse(rss.items[0].description,
                 /Temperature: (-?\d+).*Wind Direction: (\w+).*Wind Speed: (\d+)/)
  descr2 = parse(rss.items[0].description,
                 /Humidity: (\d+).*Pressure: (\d+).*Visibility: (.*)/)
  { :where => title[1],
    :temp  => descr1[1],
    :wind  => descr1[3],
    :wdir  => descr1[2],
    :humid => descr2[1],
    :press => descr2[2],
    :vis   => descr2[3] }
end

def parse_3day(rss)
  rss.items.collect do |i|
    { :day   => parse(i.title, /(\w+):/)[1],
      :short => parse(i.title, /: ([\w\s]+),/)[1],
      :max   => parse(i.title, /, Maximum Temperature: (-?\d+).* /)[1],
      :min   => parse(i.title, / Minimum Temperature: (-?\d+)/)[1]}
  end
end

def fmt_temp(val)
  if $units == 'f' then
    "#{(9 * val.to_i) / 5 + 32}°F"
  else
    "#{val}°C"
  end
end

top = 800

loc = $ARGV[0].to_i or raise "please specify location"
$units = $ARGV[1] || 'c'

raise "bad units #{$units}" unless $units == 'c' or $units == 'f'

days = parse_3day(get_forecast(loc, '3dayforecast'))
now = parse_latest(get_forecast(loc, 'observations'))

puts "${voffset 1}${goto 36}${font Weather:size=43}${color2}y${font}"
puts "${voffset -45}${font RadioSpace:size=32}${color3}${alignc}#{fmt_temp now[:temp]}${font}"
puts "${voffset -35}${goto 199}${font Ubuntu:bold:size=7}${color2}H:${offset 2}#{fmt_temp(days[1][:max])}${voffset 15}${goto 200}L:${offset 2}#{fmt_temp(days[1][:min])}${font}"
puts "${voffset -42}${font KRARound:size=38}${color2}${goto 184}I${font}"
puts "${voffset 10}${font Ubuntu:size=18}${color4}${alignc}#{now[:vis]}${font}"
puts "${voffset 2}${font Ubuntu:size=8}${color2}${color1}#{now[:wind]} mph #{now[:wdir]}${goto 120}#{now[:humid]}%${alignr}#{now[:press]}${font}"
puts

days.each do |d|
  printf("${font Ubuntu:size=9}${color2}%-10s${goto 80}%s${alignr}%s/%s${font}\n",
         d[:day], d[:short], fmt_temp(d[:min]), fmt_temp(d[:max]))
end
