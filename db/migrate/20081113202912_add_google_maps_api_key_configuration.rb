class AddGoogleMapsApiKeyConfiguration < ActiveRecord::Migration
  def self.up
    StringConfiguration.create!(:name => "google_maps_api_key", :domain_patterns => "liveinstrathcona.com", :str_value => "ABQIAAAAJqx9rI7QMow-DvzxzeY-fBSaaZQIUq9lhWMQ2UzzTiWx8YrmExQ38h3TgFUzJNlixV5hkeUK6WpffA")
    StringConfiguration.create!(:name => "google_maps_api_key", :domain_patterns => "liveinstrathcona.xlsuite.com", :str_value => "ABQIAAAAJqx9rI7QMow-DvzxzeY-fBQ5oy__ppmKpoaoEHxFW29qNOFLjhQEeVay554XKIVXQ30iXGIesiP_bQ")
    StringConfiguration.create!(:name => "google_maps_api_key", :domain_patterns => "rickstonehouse.com", :str_value => "ABQIAAAAJqx9rI7QMow-DvzxzeY-fBQ-1BtuL_NLrNxy9EjRTUjemGte6hTaKE5-I2JPAycb93rJbBJLgsMnsQ")
    StringConfiguration.create!(:name => "google_maps_api_key", :domain_patterns => "rickstonehouse.xlsuite.com", :str_value => "ABQIAAAAJqx9rI7QMow-DvzxzeY-fBSo84MB3C2SUohxgp_mw-amuEmdHhTdo9HIpmkPAZzWf3gTqTg-c1IRvg")
    StringConfiguration.create!(:name => "google_maps_api_key", :domain_patterns => "liveonthedrive.com", :str_value => "ABQIAAAAJqx9rI7QMow-DvzxzeY-fBSECeRgJcNybaHRlRbOL61cwATPoxRGHz_dqxeG1UkOforSVZbWAmftjA")
    StringConfiguration.create!(:name => "google_maps_api_key", :domain_patterns => "livinginmountpleasant.com", :str_value => "ABQIAAAAJqx9rI7QMow-DvzxzeY-fBTnRgf7juD8_lcpnvhXv3-JdPQUSxTdJknuvWrUi_2xQBjJY1ad1aDx4g")
    StringConfiguration.create!(:name => "google_maps_api_key", :domain_patterns => "liveinmountpleasant.xlsuite.com", :str_value => "ABQIAAAAJqx9rI7QMow-DvzxzeY-fBT0S6sNAjXY17gC7oENuFA3J1jNBRSY7L-hiGkQZf_D9td8flBOoCNsLQ")
    StringConfiguration.create!(:name => "google_maps_api_key", :domain_patterns => "liveonmountpleasant.com", :str_value => "ABQIAAAAJqx9rI7QMow-DvzxzeY-fBT3jcw80HnZVJAykDglRyeUGRoUFRTftR3PTPf0GvGkyCPasR121A07ig")
    StringConfiguration.create!(:name => "google_maps_api_key", :domain_patterns => "livingonmountpleasant.com", :str_value => "ABQIAAAAJqx9rI7QMow-DvzxzeY-fBRzhtNQUS0YZWUvqFdkGILgX2o3FRSJu857AAveVdzsJyj2fs2r_40UJA")
    StringConfiguration.create!(:name => "google_maps_api_key", :domain_patterns => "www.liveincommercialdrive.xlsuite.com", :str_value => "ABQIAAAAJqx9rI7QMow-DvzxzeY-fBTYJ2ARL-HIdaL5PlttVqBR8y7F9hT0IdCzVXki6LBj7VLNkAmcov5bsQ")
    StringConfiguration.create!(:name => "google_maps_api_key", :domain_patterns => "liveincommercialdrive.com", :str_value => "ABQIAAAAJqx9rI7QMow-DvzxzeY-fBRhmOJhsLYVEt8W_WFt8WTIs2v_sxSq1IPSHXdRHHD411d-Day3ghjfHQ")
    StringConfiguration.create!(:name => "google_maps_api_key", :domain_patterns => "liveoncommercialdrive.com", :str_value => "ABQIAAAAJqx9rI7QMow-DvzxzeY-fBSqxmgw8raeVrIFQbpQhh9TD4WHbxRdOh3t0U8L436J_sNdSPFVo8opWA")
    StringConfiguration.create!(:name => "google_maps_api_key", :domain_patterns => "tonipohl.com", :str_value => "ABQIAAAAJqx9rI7QMow-DvzxzeY-fBRhKirHQ9PX5gpdh3K6g8M3RiXDNhSwy-vwOotSfFaiX_P7ZNRH2P_MAQ")
    StringConfiguration.create!(:name => "google_maps_api_key", :domain_patterns => "rickstonehouse.net", :str_value => "ABQIAAAAKdthM4Y9Tw52n-Ml_qkGNxQm8R8__vxttBrzA7NunmxFLYHwcxTAT_k321iGcdanwRGAZZiXiQSAZg")
    StringConfiguration.create!(:name => "google_maps_api_key", :domain_patterns => "rickstonehouse.org", :str_value => "ABQIAAAAKdthM4Y9Tw52n-Ml_qkGNxQ8E21yWFjzYfteFcQ6278EofFI0RQi_qiUGSM3VlATJ1bHYO48scScuw")
    StringConfiguration.create!(:name => "google_maps_api_key", :domain_patterns => "rickstonehouse.ca", :str_value => "ABQIAAAAKdthM4Y9Tw52n-Ml_qkGNxS_ZY_RM2E1FA5W48rqF-TOb3Vl6hT_68MuQTvxj50TqkZ3sMtJYJwBqw")
    StringConfiguration.create!(:name => "google_maps_api_key", :domain_patterns => "rickstonehouse.name", :str_value => "ABQIAAAAKdthM4Y9Tw52n-Ml_qkGNxQfJj36uP3pGMjyRpyABdzUFqlatRT1X3LjLP43RINLldlv8VzQuZxBlQ")
    StringConfiguration.create!(:name => "google_maps_api_key", :domain_patterns => "rickstonehouse.info", :str_value => "ABQIAAAAKdthM4Y9Tw52n-Ml_qkGNxQ5N2LGRDGdViMyyPSprVV54w6EAhSVNv2ULcqgUkO0SkDuY7m9RqSbuA")
    StringConfiguration.create!(:name => "google_maps_api_key", :domain_patterns => "launt.com", :str_value => "ABQIAAAAor5ZN0DeH3kblRKe3x6FuhQenMLwtTr9iNoeWBcKNyMeDQ6AZxR6EkJGGP3AcAe_A_LMy57iUlxZsA")
  end

  def self.down
  end

  class Configuration < ActiveRecord::Base; end
  class StringConfiguration < Configuration; end
end
