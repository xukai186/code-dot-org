#load 'lib/pd/survey_pipeline/decorator.rb'

# require_relative 'map_reducer.rb'

module Pd
  module SurveyPipeline
    class DecoratorBase
      def self.decorate(*)
        raise 'Child class must override this method'
      end
    end

    class WorkshopDailySurveyReportDecorator < DecoratorBase
      attr_reader :form_names

      def initialize(form_names:)
        @form_names = form_names
      end

      def decorate(summaries:, raw_data:, debug: false)
        return unless summaries
        return unless raw_data.dig(:survey_questions)

        #p "summaries.count = #{summaries.count}" if debug
        #p "form_names.count = #{form_names.count}" if debug
        #p "questions.count = #{raw_data[:survey_questions].count}" if debug

        res = {
          course_name: nil,
          questions: {},
          this_workshop: {},
          all_my_workshops: {},
          facilitators: {},
          facilitator_averages: {},
          facilitator_response_counts: {}
        }

        #p "form_names = #{form_names}"

        # build questions list
        question_names = {}
        raw_data[:survey_questions].each do |sq|
          fname = get_form_name(sq.form_id, form_names)
          res[:questions][fname] ||= {general: {}}

          q_arr = JSON.parse(sq.questions)
          q_arr.each do |q|
            question_names[{form_id: sq.form_id, qid: q["id"].to_s}] = q["name"]
            res[:questions][fname][:general][q["name"]] = {text: q["text"], answer_type: q["type"]}
          end
        end

        #p question_names

        # build summary results for this workshop and all workshops
        summaries.each do |row|
          # Not yet support calculating res[:all_my_workshops]
          next unless row.dig(:workshop_id)
          # Not yet support combining results from different forms
          next unless row.dig(:form_id)

          # Populate data for res[:this_workshop]
          res[:course_name] ||= get_course_name(row[:workshop_id])

          fname = get_form_name(row[:form_id], form_names)
          res[:this_workshop][fname] ||= {general: {}}

          if row.dig(:qid)
            next unless row.dig(:reducer)&.downcase == 'histogram'
            p "row with question = #{row}" if debug

            qname = question_names[{form_id: row[:form_id], qid: row[:qid]}]
            res[:this_workshop][fname][:general][qname] = row[:reducer_result]
          elsif row.dig(:reducer)&.downcase == 'count'
            p "row w/o question = #{row}" if debug

            res[:this_workshop][fname][:response_count] = row[:reducer_result]
          end
        end

        return res
      end

      private

      def get_form_name(form_id, form_names)
        form_names.dig(form_id) || form_id.to_s
      end

      def get_course_name(workshop_id)
        # TODO: implement real lookup
        'CS Fundamentals'
      end
    end
  end
end

__END__

def test_mapreducer(debug: false)
  retrieved_data = Pd::SurveyPipeline::WorkshopDailySurveyRetriever.retrieve_data
  transformed_data = Pd::SurveyPipeline::WorkshopDailySurveyFlattenTransformer.transform_data data: retrieved_data

  # 1st groupping
  group_fields1 = [:workshop_id, :form_id, :qid, :type]
  is_type_number_cond = lambda {|hash| hash.dig(:type) == 'number'}
  map_config1 = [{condition: is_type_number_cond, field: :answer, reducers: [Pd::SurveyPipeline::AvgReducer, Pd::SurveyPipeline::HistogramReducer]}]
  mapreducer1 = Pd::SurveyPipeline::GenericMapReducer.new(group_fields1, map_config1)

  summaries = mapreducer1.mapreduce(data: transformed_data, debug: debug)

  # 2nd groupping
  group_fields2 = [:workshop_id, :form_id]
  no_cond = lambda {|_| true}
  map_config2 = [{condition: no_cond, field: :answer, reducers: [Pd::SurveyPipeline::CountReducer]}]
  mapreducer2 = Pd::SurveyPipeline::GenericMapReducer.new(group_fields2, map_config2)

  summaries += mapreducer2.mapreduce(data: transformed_data, debug: debug)

  decorator = ::Pd::SurveyPipeline::WorkshopDailySurveyReportDecorator.new(
    form_names: {1 => "Pre workshop", 9 => "Post workshop"}
  )

  res = decorator.decorate(
    summaries: summaries,
    raw_data: retrieved_data,
    debug: debug
  )

  p Time.now
  p "Final result = #{res}"
end

test_mapreducer(debug: true) if $0 == 'rails_console'
