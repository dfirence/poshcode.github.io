
## And a slick weather widget using Yahoo's forecast and images
New-UIWidget -AsJob { 
    Grid {
        Rectangle -RadiusX 10 -RadiusY 10 -StrokeThickness 0 -Width 170 -Height 80 -HorizontalAlignment Left -VerticalAlignment Top -Margin "60,40,0,0" -Fill { 
            LinearGradientBrush -Start "0.5,0" -End "0.5,1" -Gradient {
                GradientStop -Color "#FF007bff" -Offset 0
                GradientStop -Color "#FF40d6ff" -Offset 1
            }
        }
        Image -Name Image -Stretch Uniform -Width 250.0 -Height 180.0 -Source "http://l.yimg.com/a/i/us/nws/weather/gr/31d.png"
        TextBlock -Name Temp -Text "99°" -FontSize 80 -Foreground White -Margin "130,0,0,0" -Effect { DropShadowEffect -Color Black -Shadow 0 -Blur 8 }
        TextBlock -Name Forecast -Text "Forecast" -FontSize 12 -Foreground White -Margin "120,95,0,0"
    }
} -Refresh "00:10" {
    # To find your WOEID, browse or search for your city from the Weather home page. 
    # The WOEID is the LAST PART OF the URL for the forecast page for that city. 
    $woEID = 14586
    $channel = ([xml](New-Object Net.WebClient).DownloadString("http://weather.yahooapis.com/forecastrss?p=$woEID")).rss.channel
    $h = ([int](Get-Date -f hh))
    
    if($h -gt ([DateTime]$channel.astronomy.sunrise).Hour -and $h -lt ([DateTime]$channel.astronomy.sunset).Hour) {
        $dayOrNight = 'd'
    } else {
        $dayOrNight = 'n'
    }
    $source = "http`://l.yimg.com/a/i/us/nws/weather/gr/{0}{1}.png" -f $channel.item.condition.code, $dayOrNight
    
    $Image.Source  = $source
    $Temp.Text     = $channel.item.condition.temp + [char]176
    $Forecast.Text = "High: {0}{2} Low: {1}{2}" -f $channel.item.forecast[0].high, $channel.item.forecast[0].low, [char]176
}
