require 'cdo/db'
require 'cdo/shared_cache'
require 'dynamic_config/dcdo'
require 'cdo/cache_method'

# Helper functions for Pegasus forms.
module Forms
  Sequel.extension :core_refinements
  using Sequel::CoreRefinements
  FORMS = ::PEGASUS_DB[:forms]

  # Converts a simple x.y JSON-attribute path to a MySQL 5.7 JSON expression using the inline-path operator.
  # Ref: https://dev.mysql.com/doc/refman/5.7/en/json-search-functions.html#operator_json-inline-path
  def self.json(path)
    column, attribute = path.split('.')
    "#{column}->>'$.#{attribute}'".lit
  end

  COUNTRY_CODE = json('processed_data.location_country_code_s')
  STATE_CODE = json('processed_data.location_state_code_s')

  class << self
    def events_by_country(kind, except_country='US')
      FORMS.
        where({kind: kind} & ~{COUNTRY_CODE => except_country}).
        group_and_count(COUNTRY_CODE.as(:country_code)).
        all
    end

    def events_by_state(kind, country='US')
      FORMS.
        where(
          kind: kind,
          COUNTRY_CODE => country
        ).
        group_and_count(
          STATE_CODE.as(:state_code)
        ).
        all
    end

    def events_by_name(kind, country, state=nil)
      where = {
        kind: kind,
        COUNTRY_CODE => country
      }
      where[STATE_CODE] = state if state

      FORMS.
        select(
          json('data.organization_name_s').as(:name),
          json('processed_data.location_city_s').as(:city)
        ).
        where(where).
        order_by(:city, :name).
        distinct.
        all
    end
  end
end
