onReminders ->
  class @TimeZone
    constructor: (data) ->
      @code = data?.code
      @name = data?.name

    @convert_to_reminder_zone: (time, zone) =>
      time_zone = @find_time_zone(zone)
      base_diff_minutes = @calculate_time_different_by_time(new Date())
      remote_diff_minutes = @calculate_time_different_by_zone(time_zone["zone"])
      diff_minutes = remote_diff_minutes - base_diff_minutes
      return new Date(time.setMinutes(time.getMinutes() + diff_minutes))

    @find_time_zone: (zone) =>
      list_time_zone = @getListTimeZone()
      for time_zone in list_time_zone
        if time_zone["key"] == zone
          return time_zone

    @calculate_time_different_by_zone: (time_zone) =>
      [hours,minutes] = time_zone.split(":")
      if parseInt(hours) >= 0
        return parseInt(hours) * 60 + parseInt(minutes)
      return parseInt(hours) * 60 - parseInt(minutes)

    @calculate_time_different_by_time: (time_zone) =>
      time_string = time_zone.toString()
      # "Wed Jun 04 2014 10:25:19 GMT+0700 (ICT)"
      zone = time_string.split(" ")[5].replace("GMT","")
      zone_hour = zone[0] + zone[1] + zone[2]
      zone_min  = zone[3] + zone[4]
      if parseInt(zone_hour) >= 0
        return parseInt(zone_hour) * 60 + parseInt(zone_min)
      return parseInt(zone_hour) * 60 - parseInt(zone_min)

    @getListTimeZone: =>
      list = [
        {
          "key" : "International Date Line West"
          "name": "(GMT-11:00) International Date Line West"
          "zone": "-11:00"
        }    
        {  
          "key" : "Midway Island"
          "name": "(GMT-11:00) Midway Island"
        }  
        {     
          "key" : "Hawaii"
          "name": "(GMT-10:00) Hawaii"
          "zone": "-10:00"
        }  
        {     
          "key" : "Alaska"
          "name": "(GMT-09:00) Alaska"
          "zone": "-09:00"
        }  
        {     
          "key" : "Pacific Time (US &amp; Canada)"
          "name": "(GMT-08:00) Pacific Time (US &amp; Canada)"
          "zone": "-08:00"
        }  
        {     
          "key" : "Tijuana"
          "name": "(GMT-08:00) Tijuana"
          "zone": "-08:00"
        }  
        {     
          "key" : "Arizona"
          "name": "(GMT-07:00) Arizona"
          "zone": "-07:00"
        }  
        {     
          "key" : "Chihuahua"
          "name": "(GMT-07:00) Chihuahua"
          "zone": "-07:00"
        }  
        {     
          "key" : "Mazatlan"
          "name": "(GMT-07:00) Mazatlan"
          "zone": "-07:00"
        }  
        {     
          "key" : "Mountain Time (US &amp; Canada)"
          "name": "(GMT-07:00) Mountain Time (US &amp; Canada)"
          "zone": "-07:00"
        }  
        {     
          "key" : "Central America"
          "name": "(GMT-06:00) Central America"
          "zone": "-06:00"
        }  
        {     
          "key" : "Central Time (US &amp; Canada)"
          "name": "(GMT-06:00) Central Time (US &amp; Canada)"
          "zone": "-06:00"
        }  
        {     
          "key" : "Guadalajara"
          "name": "(GMT-06:00) Guadalajara"
          "zone": "-06:00"
        }  
        {     
          "key" : "Mexico City"
          "name": "(GMT-06:00) Mexico City"
          "zone": "-06:00"
        }  
        {     
          "key" : "Monterrey"
          "name": "(GMT-06:00) Monterrey"
          "zone": "-06:00"
        }  
        {     
          "key" : "Saskatchewan"
          "name": "(GMT-06:00) Saskatchewan"
          "zone": "-06:00"
        }  
        {     
          "key" : "Bogota"
          "name": "(GMT-05:00) Bogota"
          "zone": "-05:00"
        }  
        {     
          "key" : "Eastern Time (US &amp; Canada)"
          "name": "(GMT-05:00) Eastern Time (US &amp; Canada)"
          "zone": "-05:00"
        }  
        {     
          "key" : "Indiana (East)"
          "name": "(GMT-05:00) Indiana (East)"
          "zone": "-05:00"
        }  
        {     
          "key" : "Lima"
          "name": "(GMT-05:00) Lima"
          "zone": "-05:00"
        }  
        {     
          "key" : "Quito"
          "name": "(GMT-05:00) Quito"
          "zone": "-05:00"
        }  
        {     
          "key" : "Caracas"
          "name": "(GMT-04:30) Caracas"
          "zone": "-04:30"
        }  
        {     
          "key" : "Atlantic Time (Canada)"
          "name": "(GMT-04:00) Atlantic Time (Canada)"
          "zone": "-04:00"
        }  
        {     
          "key" : "Georgetown"
          "name": "(GMT-04:00) Georgetown"
          "zone": "-04:00"
        }  
        {     
          "key" : "La Paz"
          "name": "(GMT-04:00) La Paz"
          "zone": "-04:00"
        }  
        {     
          "key" : "Santiago"
          "name": "(GMT-04:00) Santiago"
          "zone": "-04:00"
        }  
        {     
          "key" : "Newfoundland"
          "name": "(GMT-03:30) Newfoundland"
          "zone": "-03:30"
        }  
        {     
          "key" : "Brasilia"
          "name": "(GMT-03:00) Brasilia"
          "zone": "-03:00"
        }  
        {     
          "key" : "Buenos Aires"
          "name": "(GMT-03:00) Buenos Aires"
          "zone": "-03:00"
        }  
        {     
          "key" : "Greenland"
          "name": "(GMT-03:00) Greenland"
          "zone": "-03:00"
        }  
        {     
          "key" : "Mid-Atlantic"
          "name": "(GMT-02:00) Mid-Atlantic"
          "zone": "-02:00"
        }  
        {     
          "key" : "Azores"
          "name": "(GMT-01:00) Azores"
          "zone": "-01:00"
        }  
        {     
          "key" : "Cape Verde Is."
          "name": "(GMT-01:00) Cape Verde Is."
          "zone": "-01:00"
        }  
        {     
          "key" : "Casablanca"
          "name": "(GMT+00:00) Casablanca"
          "zone": "+00:00"
        }  
        {     
          "key" : "Dublin"
          "name": "(GMT+00:00) Dublin"
          "zone": "+00:00"
        }  
        {     
          "key" : "Edinburgh"
          "name": "(GMT+00:00) Edinburgh"
          "zone": "+00:00"
        }  
        {     
          "key" : "Lisbon"
          "name": "(GMT+00:00) Lisbon"
          "zone": "+00:00"
        }  
        {     
          "key" : "London"
          "name": "(GMT+00:00) London"
          "zone": "+00:00"
        }  
        {     
          "key" : "Monrovia"
          "name": "(GMT+00:00) Monrovia"
          "zone": "+00:00"
        }  
        {     
          "key" : "UTC"
          "name": "(GMT+00:00) UTC"
          "zone": "+00:00"
        }  
        {     
          "key" : "Amsterdam"
          "name": "(GMT+01:00) Amsterdam"
          "zone": "+01:00"
        }  
        {     
          "key" : "Belgrade"
          "name": "(GMT+01:00) Belgrade"
          "zone": "+01:00"
        }  
        {     
          "key" : "Berlin"
          "name": "(GMT+01:00) Berlin"
          "zone": "+01:00"
        }  
        {     
          "key" : "Bern"
          "name": "(GMT+01:00) Bern"
          "zone": "+01:00"
        }  
        {     
          "key" : "Bratislava"
          "name": "(GMT+01:00) Bratislava"
          "zone": "+01:00"
        }  
        {     
          "key" : "Brussels"
          "name": "(GMT+01:00) Brussels"
          "zone": "+01:00"
        }  
        {     
          "key" : "Budapest"
          "name": "(GMT+01:00) Budapest"
          "zone": "+01:00"
        }  
        {     
          "key" : "Copenhagen"
          "name": "(GMT+01:00) Copenhagen"
          "zone": "+01:00"
        }  
        {     
          "key" : "Ljubljana"
          "name": "(GMT+01:00) Ljubljana"
          "zone": "+01:00"
        }  
        {     
          "key" : "Madrid"
          "name": "(GMT+01:00) Madrid"
          "zone": "+01:00"
        }  
        {     
          "key" : "Paris"
          "name": "(GMT+01:00) Paris"
          "zone": "+01:00"
        }  
        {     
          "key" : "Prague"
          "name": "(GMT+01:00) Prague"
          "zone": "+01:00"
        }  
        {     
          "key" : "Rome"
          "name": "(GMT+01:00) Rome"
          "zone": "+01:00"
        }  
        {     
          "key" : "Sarajevo"
          "name": "(GMT+01:00) Sarajevo"
          "zone": "+01:00"
        }  
        {     
          "key" : "Skopje"
          "name": "(GMT+01:00) Skopje"
          "zone": "+01:00"
        }  
        {     
          "key" : "Stockholm"
          "name": "(GMT+01:00) Stockholm"
          "zone": "+01:00"
        }  
        {     
          "key" : "Vienna"
          "name": "(GMT+01:00) Vienna"
          "zone": "+01:00"
        }  
        {     
          "key" : "Warsaw"
          "name": "(GMT+01:00) Warsaw"
          "zone": "+01:00"
        }  
        {     
          "key" : "West Central Africa"
          "name": "(GMT+01:00) West Central Africa"
          "zone": "+01:00"
        }  
        {     
          "key" : "Zagreb"
          "name": "(GMT+01:00) Zagreb"
          "zone": "+01:00"
        }  
        {     
          "key" : "Athens"
          "name": "(GMT+02:00) Athens"
          "zone": "+01:00"
        }  
        {     
          "key" : "Bucharest"
          "name": "(GMT+02:00) Bucharest"
          "zone": "+02:00"
        }  
        {     
          "key" : "Cairo"
          "name": "(GMT+02:00) Cairo"
          "zone": "+02:00"
        }  
        {     
          "key" : "Harare"
          "name": "(GMT+02:00) Harare"
          "zone": "+02:00"
        }  
        {     
          "key" : "Helsinki"
          "name": "(GMT+02:00) Helsinki"
          "zone": "+02:00"
        }  
        {     
          "key" : "Istanbul"
          "name": "(GMT+02:00) Istanbul"
          "zone": "+02:00"
        }  
        {     
          "key" : "Jerusalem"
          "name": "(GMT+02:00) Jerusalem"
          "zone": "+02:00"
        }  
        {     
          "key" : "Kyiv"
          "name": "(GMT+02:00) Kyiv"
          "zone": "+02:00"
        }  
        {     
          "key" : "Pretoria"
          "name": "(GMT+02:00) Pretoria"
          "zone": "+02:00"
        }  
        {     
          "key" : "Riga"
          "name": "(GMT+02:00) Riga"
          "zone": "+02:00"
        }  
        {     
          "key" : "Sofia"
          "name": "(GMT+02:00) Sofia"
          "zone": "+02:00"
        }  
        {     
          "key" : "Tallinn"
          "name": "(GMT+02:00) Tallinn"
          "zone": "+02:00"
        }  
        {     
          "key" : "Vilnius"
          "name": "(GMT+02:00) Vilnius"
          "zone": "+02:00"
        }  
        {     
          "key" : "Baghdad"
          "name": "(GMT+03:00) Baghdad"
          "zone": "+03:00"
        }  
        {     
          "key" : "Kuwait"
          "name": "(GMT+03:00) Kuwait"
          "zone": "+03:00"
        }  
        {     
          "key" : "Minsk"
          "name": "(GMT+03:00) Minsk"
          "zone": "+03:00"
        }  
        {     
          "key" : "Nairobi"
          "name": "(GMT+03:00) Nairobi"
          "zone": "+03:00"
        }  
        {     
          "key" : "Riyadh"
          "name": "(GMT+03:00) Riyadh"
          "zone": "+03:00"
        }  
        {     
          "key" : "Tehran"
          "name": "(GMT+03:30) Tehran"
          "zone": "+03:00"
        }  
        {     
          "key" : "Abu Dhabi"
          "name": "(GMT+04:00) Abu Dhabi"
          "zone": "+04:00"
        }  
        {     
          "key" : "Baku"
          "name": "(GMT+04:00) Baku"
          "zone": "+04:00"
        }  
        {     
          "key" : "Moscow"
          "name": "(GMT+04:00) Moscow"
          "zone": "+04:00"
        }  
        {     
          "key" : "Muscat"
          "name": "(GMT+04:00) Muscat"
          "zone": "+04:00"
        }  
        {     
          "key" : "St. Petersburg"
          "name": "(GMT+04:00) St. Petersburg"
          "zone": "+04:00"
        }  
        {     
          "key" : "Tbilisi"
          "name": "(GMT+04:00) Tbilisi"
          "zone": "+04:00"
        }  
        {     
          "key" : "Volgograd"
          "name": "(GMT+04:00) Volgograd"
          "zone": "+04:00"
        }  
        {     
          "key" : "Yerevan"
          "name": "(GMT+04:00) Yerevan"
          "zone": "+04:00"
        }  
        {     
          "key" : "Kabul"
          "name": "(GMT+04:30) Kabul"
          "zone": "+04:30"
        }  
        {     
          "key" : "Islamabad"
          "name": "(GMT+05:00) Islamabad"
          "zone": "+05:00"
        }  
        {     
          "key" : "Karachi"
          "name": "(GMT+05:00) Karachi"
          "zone": "+05:00"
        }  
        {     
          "key" : "Tashkent"
          "name": "(GMT+05:00) Tashkent"
          "zone": "+05:00"
        }  
        {     
          "key" : "Chennai"
          "name": "(GMT+05:30) Chennai"
          "zone": "+05:30"
        }  
        {     
          "key" : "Kolkata"
          "name": "(GMT+05:30) Kolkata"
          "zone": "+05:30"
        }  
        {     
          "key" : "Mumbai"
          "name": "(GMT+05:30) Mumbai"
          "zone": "+05:30"
        }  
        {     
          "key" : "New Delhi"
          "name": "(GMT+05:30) New Delhi"
          "zone": "+05:30"
        }  
        {     
          "key" : "Sri Jayawardenepura"
          "name": "(GMT+05:30) Sri Jayawardenepura"
          "zone": "+05:30"
        }  
        {     
          "key" : "Kathmandu"
          "name": "(GMT+05:45) Kathmandu"
          "zone": "+05:45"
        }  
        {     
          "key" : "Almaty"
          "name": "(GMT+06:00) Almaty"
          "zone": "+06:00"
        }  
        {     
          "key" : "Astana"
          "name": "(GMT+06:00) Astana"
          "zone": "+06:00"
        }  
        {     
          "key" : "Dhaka"
          "name": "(GMT+06:00) Dhaka"
          "zone": "+06:00"
        }  
        {     
          "key" : "Ekaterinburg"
          "name": "(GMT+06:00) Ekaterinburg"
          "zone": "+06:00"
        }  
        {     
          "key" : "Rangoon"
          "name": "(GMT+06:30) Rangoon"
          "zone": "+06:30"
        }   
        {    
          "key" : "Bangkok"
          "name": "(GMT+07:00) Bangkok"
          "zone": "+07:00"
        }  
        {     
          "key" : "Hanoi"
          "name": "(GMT+07:00) Hanoi"
          "zone": "+07:00"
        }  
        {     
          "key" : "Jakarta"
          "name": "(GMT+07:00) Jakarta"
          "zone": "+07:00"
        }  
        {     
          "key" : "Novosibirsk"
          "name": "(GMT+07:00) Novosibirsk"
          "zone": "+07:00"
        }  
        {     
          "key" : "Beijing"
          "name": "(GMT+08:00) Beijing"
          "zone": "+08:00"
        }  
        {     
          "key" : "Chongqing"
          "name": "(GMT+08:00) Chongqing"
          "zone": "+08:00"
        }  
        {     
          "key" : "Hong Kong"
          "name": "(GMT+08:00) Hong Kong"
          "zone": "+08:00"
        }  
        {     
          "key" : "Krasnoyarsk"
          "name": "(GMT+08:00) Krasnoyarsk"
          "zone": "+08:00"
        }  
        {     
          "key" : "Kuala Lumpur"
          "name": "(GMT+08:00) Kuala Lumpur"
          "zone": "+08:00"
        }  
        {     
          "key" : "Perth"
          "name": "(GMT+08:00) Perth"
          "zone": "+08:00"
        }  
        {     
          "key" : "Singapore"
          "name": "(GMT+08:00) Singapore"
          "zone": "+08:00"
        }  
        {     
          "key" : "Taipei"
          "name": "(GMT+08:00) Taipei"
          "zone": "+08:00"
        }  
        {     
          "key" : "Ulaan Bataar"
          "name": "(GMT+08:00) Ulaan Bataar"
          "zone": "+08:00"
        }  
        {     
          "key" : "Urumqi"
          "name": "(GMT+08:00) Urumqi"
          "zone": "+08:00"
        }  
        {     
          "key" : "Irkutsk"
          "name": "(GMT+09:00) Irkutsk"
          "zone": "+09:00"
        }  
        {     
          "key" : "Osaka"
          "name": "(GMT+09:00) Osaka"
          "zone": "+09:00"
        }  
        {     
          "key" : "Sapporo"
          "name": "(GMT+09:00) Sapporo"
          "zone": "+09:00"
        }  
        {     
          "key" : "Seoul"
          "name": "(GMT+09:00) Seoul"
          "zone": "+09:00"
        }  
        {     
          "key" : "Tokyo"
          "name": "(GMT+09:00) Tokyo"
          "zone": "+09:00"
        }  
        {     
          "key" : "Adelaide"
          "name": "(GMT+09:30) Adelaide"
          "zone": "+09:00"
        }  
        {     
          "key" : "Darwin"
          "name": "(GMT+09:30) Darwin"
          "zone": "+09:00"
        }  
        {     
          "key" : "Brisbane"
          "name": "(GMT+10:00) Brisbane"
          "zone": "+10:00"
        }  
        {     
          "key" : "Canberra"
          "name": "(GMT+10:00) Canberra"
          "zone": "+10:00"
        }  
        {     
          "key" : "Guam"
          "name": "(GMT+10:00) Guam"
          "zone": "+10:00"
        }  
        {     
          "key" : "Hobart"
          "name": "(GMT+10:00) Hobart"
          "zone": "+10:00"
        }  
        {     
          "key" : "Melbourne"
          "name": "(GMT+10:00) Melbourne"
          "zone": "+10:00"
        }  
        {     
          "key" : "Port Moresby"
          "name": "(GMT+10:00) Port Moresby"
          "zone": "+10:00"
        }  
        {     
          "key" : "Sydney"
          "name": "(GMT+10:00) Sydney"
          "zone": "+10:00"
        }  
        {     
          "key" : "Yakutsk"
          "name": "(GMT+10:00) Yakutsk"
          "zone": "+10:00"
        }  
        {     
          "key" : "New Caledonia"
          "name": "(GMT+11:00) New Caledonia"
          "zone": "+11:00"
        }  
        {     
          "key" : "Vladivostok"
          "name": "(GMT+11:00) Vladivostok"
          "zone": "+11:00"
        }  
        {     
          "key" : "Auckland"
          "name": "(GMT+12:00) Auckland"
          "zone": "+12:00"
        }  
        {     
          "key" : "Fiji"
          "name": "(GMT+12:00) Fiji"
          "zone": "+12:00"
        }  
        {     
          "key" : "Kamchatka"
          "name": "(GMT+12:00) Kamchatka"
          "zone": "+12:00"
        }  
        {     
          "key" : "Magadan"
          "name": "(GMT+12:00) Magadan"
          "zone": "+12:00"
        }  
        {     
          "key" : "Marshall Is."
          "name": "(GMT+12:00) Marshall Is."
          "zone": "+12:00"
        }  
        {     
          "key" : "Solomon Is."
          "name": "(GMT+12:00) Solomon Is."
          "zone": "+12:00"
        }  
        {     
          "key" : "Wellington"
          "name": "(GMT+12:00) Wellington"
          "zone": "+12:00"
        }  
        {     
          "key" : "Nuku'alofa"
          "name": "(GMT+13:00) Nuku'alofa"
          "zone": "+13:00"
        }  
        {     
          "key" : "Samoa"
          "name": "(GMT+13:00) Samoa"
          "zone": "+13:00"
        }  
        {     
          "key" : "Tokelau Is."
          "name": "(GMT+13:00) Tokelau Is."
          "zone": "+13:00"
        }    
      ]