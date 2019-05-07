#load 'lib/api/v1/pd/map_reducer.rb'

require_relative 'transformer.rb'

module Pd
  module SurveyPipeline
    class MapReducerBase
      def self.mapreduce(*)
        raise 'Child class must override this method'
      end
    end

    class GenericMapReducer < MapReducerBase
      attr_reader :group_fields, :map_config

      def initialize(group_fields, map_config)
        @group_fields = group_fields
        @map_config = map_config
      end

      # Summarize input data using groupping and map-reduce configurations
      # @param data Array<Hash{}>
      # @param group_config Array<string/symbol>
      # @param map_config Array<Hash{}>
      # @return Array<Hash>
      def mapreduce(data:, debug: false)
        p "group_fields = #{group_fields}" if debug
        p "map_config = #{map_config}" if debug

        # split data into groups
        groups = {}
        data.each do |row|
          #gkey = row.values_at(*group_fields)  # array
          gkey = Hash[group_fields.map {|field| [field, row[field]]}]

          groups[gkey] ||= []
          groups[gkey] << row
        end

        p "groups.count = #{groups.count}" if debug
        #p "groups = #{groups}" if debug

        # Apply reducers on each group
        summaries = []
        groups.each do |gkey, gvalue|
          map_config.each do |condition:, field:, reducers:|
            p "gkey = #{gkey}" if debug
            p "gvalue.count = #{gvalue.count}" if debug

            next unless condition.call(gkey)

            p "reducers.count = #{reducers.count}" if debug

            reducers.each do |reducer|
              reducer_result = reducer.reduce(gvalue.map {|record| record[field]})

              p "reducer.name = #{reducer.name}, result = #{reducer_result}" if debug

              summaries << gkey.merge({reducer: reducer.name, reducer_result: reducer_result})
            end
          end
        end

        return summaries
      end
    end

    class ReducerBase
      def self.name(*)
        raise 'Child class must override this method'
      end

      def self.reduce(*)
        raise 'Child class must override this method'
      end
    end

    class AvgReducer < ReducerBase
      def self.name
        'average'
      end

      # @param values Array<number/string>
      # @return [float] average of the input values
      def self.reduce(values)
        # TODO: enforce value type or just ignore it?
        #p "values = #{values}"
        return unless values
        values.inject(0.0) {|sum, elem| sum + elem.to_f} / values.size
      end
    end

    class CountReducer < ReducerBase
      def self.name
        'count'
      end

      def self.reduce(values)
        return values&.count || 0
      end
    end

    class HistogramReducer < ReducerBase
      def self.name
        'histogram'
      end

      def self.reduce(values)
        # TODO: enforce input is array
        values&.group_by {|v| v}&.transform_values(&:size)
      end
    end
  end
end

def test_mapreducer(debug: false)
  print_key_count = lambda {|hash| hash.each_key {|key| p key, hash[key].count}}

  retrieved_data = Pd::SurveyPipeline::WorkshopDailySurveyRetriever.retrieve_data
  print_key_count.call(retrieved_data)

  transformed_data = Pd::SurveyPipeline::WorkshopDailySurveyFlattenTransformer.transform_data data: retrieved_data
  #p transformed_data.count

  # 1st groupping
  group_fields1 = [:workshop_id, :form_id, :qid, :type]
  is_type_number_cond = lambda {|hash| hash.dig(:type) == 'number'}
  map_config1 = [{condition: is_type_number_cond, field: :answer, reducers: [Pd::SurveyPipeline::AvgReducer, Pd::SurveyPipeline::HistogramReducer]}]
  mapreducer1 = Pd::SurveyPipeline::GenericMapReducer.new(group_fields1, map_config1)

  res = mapreducer1.mapreduce(data: transformed_data, debug: debug)

  # 2nd groupping
  group_fields2 = [:workshop_id, :form_id]
  no_cond = lambda {|_| true}
  map_config2 = [{condition: no_cond, field: :answer, reducers: [Pd::SurveyPipeline::CountReducer]}]
  mapreducer2 = Pd::SurveyPipeline::GenericMapReducer.new(group_fields2, map_config2)

  res += mapreducer2.mapreduce(data: transformed_data, debug: debug)

  p "Final result count = #{res.count}"
  p "Final result = #{res}"
end

test_mapreducer(debug: true) if $0 == 'rails_console'
