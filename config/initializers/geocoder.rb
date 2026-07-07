Geocoder.configure(
  # Use Mapbox for geocoding (matches the map on event pages and is far more
  # reliable than the default Nominatim service). Falls back gracefully if the
  # key is missing in an environment.
  lookup: ENV["MAPBOX_API_KEY"].present? ? :mapbox : :nominatim,
  api_key: ENV["MAPBOX_API_KEY"],
  units: :km,
  timeout: 5
)
