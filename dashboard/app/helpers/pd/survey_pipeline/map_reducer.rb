module Pd::SurveyPipeline
  class MapReducerBase
    def mapreduce(*)
      raise 'Child class must override this method'
    end
  end

  class GenericMapReducer < MapReducerBase
    attr_reader :group_config, :map_config

    def initialize(group_config:, map_config:)
      @group_config = group_config
      @map_config = map_config
    end

    # Summarize input data using groupping and map-reduce configurations
    # @param data Array<Hash{}>
    # @param group_config Array<string/symbol>
    # @param map_config Array<Hash{}>
    # @return Array<Hash>
    def mapreduce(data:, logger: nil)
      logger&.info "MP: set group_config = #{group_config}"
      logger&.info "MP: set map_config = #{map_config}"

      # split data into groups
      groups = {}
      data.each do |row|
        gkey = Hash[group_config.map {|field| [field, row[field]]}]

        groups[gkey] ||= []
        groups[gkey] << row
      end

      logger&.info "MP: groups.count = #{groups.count}"
      logger&.debug "MP: groups = #{groups}"

      # Apply reducers on each group
      summaries = []
      groups.each do |gkey, gvalue|
        logger&.debug "MP: gkey = #{gkey}"
        logger&.debug "MP: gvalue.count = #{gvalue.count}"

        map_config.each do |condition:, field:, reducers:|
          logger&.debug "Match condition = #{condition.call(gkey)}"
          next unless condition.call(gkey)

          logger&.debug "MP: reducers.count = #{reducers.count}"

          reducers.each do |reducer|
            reducer_result = reducer.reduce(gvalue.map {|record| record[field]})
            logger&.debug "MP: reducer.name = #{reducer.name}, result = #{reducer_result}"
            next unless reducer_result.present?
            summaries << gkey.merge({reducer: reducer.name, reducer_result: reducer_result})
          end
        end
      end

      return summaries
    end
  end

  class ReducerBase
    def name(*)
      raise 'Child class must override this method'
    end

    def reduce(*)
      raise 'Child class must override this method'
    end
  end

  class AvgReducer < ReducerBase
    def name
      'average'
    end

    # @param values Array<number/string>
    # @return [float] average of the input values
    def reduce(values)
      # TODO: enforce value type or just ignore it?
      return unless values
      values.inject(0.0) {|sum, elem| sum + elem.to_f} / values.size
    end
  end

  class CountReducer < ReducerBase
    attr_reader :distinct
    def initialize(distinct: false)
      @distinct = distinct
    end

    def name
      distinct ? 'count_distinct' : 'count'
    end

    def reduce(values)
      (distinct ? values&.uniq&.count : values&.count) || 0
    end
  end

  class HistogramReducer < ReducerBase
    def name
      'histogram'
    end

    def reduce(values)
      # TODO: enforce input is array
      values&.group_by {|v| v}&.transform_values(&:size)
    end
  end

  class MatrixHistogramReducer < ReducerBase
    def name
      'matrix_histogram'
    end

    # @param values Array<Hash{sub_q => ans}>
    # @return Hash{sub_q => Hash{ans => count}}
    def reduce(values)
      # TODO: enforce value type as array? `values.is_a? Array`
      # TODO: how to return warning/errors. strict? let the caller decide what to do it
      return unless values.present?

      {}.tap do |res|
        values.each do |answers|
          answers.each do |ques, ans|
            next unless ans.present?
            res[ques] ||= {}
            res[ques][ans] ||= 0
            res[ques][ans] += 1
          end
        end
      end
    end
  end
end
