#test from console:
#load 'lib/pd/jot_form/transformer.rb'

require_relative 'retriever.rb'

module Pd
  module SurveyPipeline
    class TransformerBase
      def self.transform_data(*)
        raise 'Child class must override this method'
      end
    end

    class WorkshopDailySurveyTransformer < TransformerBase
      def self.transform_data(data: {}, debug: false)
        return unless data.dig(:workshop_daily_surveys)
        return unless data.dig(:survey_questions)

        res = {}
        data[:survey_questions].each do |sq|
          q_arr = JSON.parse(sq.questions)
          q_arr.each do |q|
            # TODO: how to fit question type in here?. Need type to know what aggregation to run
            q_key = {name: q["id"].to_s, type: q["type"]}
            res[q_key] ||= []
          end
        end

        p "res ater extracting questions = #{res}" if debug

        data[:workshop_daily_surveys].each do |sub|
          ans_h = JSON.parse(sub.answers)
          ans_h.each do |qid, ans|
            qid_str = qid.to_s

            found = false
            res.each_key do |key|
              next if key[:name] != qid_str

              res[key] << {form_id: sub.form_id, workshop_id: sub.pd_workshop_id, ans: ans}
              found = true
              break
            end

            raise "Question id #{qid} does not exist in SurveyQuestion data" unless found
          end
        end

        p "res ater extracting answers = #{res}" if debug
        return res
      end
    end
  end
end

def test_transformer(debug: false)
  retrieved_data = Pd::SurveyPipeline::WorkshopDailySurveyRetriever.retrieve_data(filters: {form_ids: [1], workshop_ids: [6547]})
  Pd::SurveyPipeline::WorkshopDailySurveyTransformer.transform_data data: retrieved_data, debug: debug
end

test_transformer(debug: true)

__END__

#p sq.id
#p sq.questions
q = JSON.parse(sq.questions)
p "JSON parsed questions = #{q}"
q.map do |question_hash|
  p "question hash = #{question_hash}"
  #sanitized_question_hash = question_hash.symbolize_keys
  #question_type = sanitized_question_hash[:type]
  #Translation.get_question_class_for(question_type).new(sanitized_question_hash)
end
# TODO: filter by workshop_id and form_id
# name = survey.questions.id (not survey.questions.name yet)
# type = survey.questions.type
# survey.questions.find_each do |question|
#   question_content << AnswerCollection.new(questions.id, questions.type)
# end