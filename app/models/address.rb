class Address < ActiveRecord::Base
  acts_as_mappable

  validates_presence_of :country, :street_address_1, :city, :state


  # GeoKit spec:
  # # Location attributes. Full address is a concatenation of all values. For example:
  # # 100 Spear St, San Francisco, CA, 94101, US
  # # Street number and street name are extracted from the street address attribute if they don't exist
  # attr_accessor :street_number, :street_name, :street_address, :city, :state, :zip, :country_code, :country
  # attr_accessor :full_address, :all, :district, :province, :sub_premise, :neighborhood
  # # Attributes set upon return from geocoding. Success will be true for successful
  # # geocode lookups. The provider will be set to the name of the providing geocoder.
  # # Finally, precision is an indicator of the accuracy of the geocoding.
  # attr_accessor :success, :provider, :precision, :suggested_bounds
  # # accuracy is set for Yahoo and Google geocoders, it is a numeric value of the
  # # precision. see http://code.google.com/apis/maps/documentation/geocoding/#GeocodingAccuracy
  # attr_accessor :accuracy
  # # FCC Attributes
  # attr_accessor :district_fips, :state_fips, :block_fips

  # TODO: Google's components - each can have both short_name and long_name
  # street_address # indicates a precise street address.
  # route # indicates a named route (such as "US 101").
  # intersection # indicates a major intersection, usually of two major roads.
  # political # indicates a political entity. Usually, this type indicates a polygon of some civil administration.
  # country # indicates the national political entity, and is typically the highest order type returned by the Geocoder.
  # administrative_area_level_1 # indicates a first-order civil entity below the country level. Within the United States, these administrative levels are states. Not all nations exhibit these administrative levels.
  # administrative_area_level_2 # indicates a second-order civil entity below the country level. Within the United States, these administrative levels are counties. Not all nations exhibit these administrative levels.
  # administrative_area_level_3 # indicates a third-order civil entity below the country level. This type indicates a minor civil division. Not all nations exhibit these administrative levels.
  # colloquial_area # indicates a commonly-used alternative name for the entity.
  # locality # indicates an incorporated city or town political entity.
  # sublocality # indicates a first-order civil entity below a locality. For some locations may receive one of the additional types: sublocality_level_1 through to sublocality_level_5. Each sublocality level is a civil entity. Larger numbers indicate a smaller geographic area.
  # neighborhood # indicates a named neighborhood
  # premise # indicates a named location, usually a building or collection of buildings with a common name
  # subpremise # indicates a first-order entity below a named location, usually a singular building within a collection of buildings with a common name
  # postal_code # indicates a postal code as used to address postal mail within the country.
  # natural_feature # indicates a prominent natural feature.
  # floor # indicates the floor of a building address.
  # establishment # typically indicates a place that has not yet been categorized.
  # parking # indicates a parking lot or parking structure.
  # post_box # indicates a specific postal box.
  # postal_town # indicates a grouping of geographic areas, such as locality and sublocality, used for mailing addresses in some countries.
  # room # indicates the room of a building address.
  # street_number # indicates the precise street number.
end