#load 'lib/pd/survey_pipeline/retriever.rb'

module Pd
  module SurveyPipeline
    class RetrieverBase
      def self.retrive_data(*)
        # TODO: is there a better way to enforce this using mix-in?
        raise 'Child class must override this method'
      end
    end

    class WorkshopDailySurveyRetriever < RetrieverBase
      # Retrieve data from pd_workshop_daily_surveys and pd_survey_questions tables
      # @param filters [Hash] a list of filter conditions
      # @option filters [Array<Integer>] :workshop_ids array of workshop ids
      # @option filters [Array<Integer>] :form_ids array of form ids
      # @return [Hash{DataType => Array<DataValue>}] a hash contains array of WorkshopDailySurvey and array of SurveyQuestion
      def self.retrieve_data(filters: {}, debug: false)
        p "filters = #{filters}" if debug

        questions = []
        Pd::SurveyQuestion.find_each do |question|
          next unless !filters.key?(:form_ids) || filters[:form_ids]&.include?(question.form_id)
          questions << question
        end

        p "questions.count = #{questions.count}" if debug
        p "questions = #{questions}" if debug

        submissions = []
        Pd::WorkshopDailySurvey.find_each do |submission|
          next unless !filters.key?(:form_ids) || filters[:form_ids]&.include?(submission.form_id)
          next unless !filters.key?(:workshop_ids) ||
            filters[:workshop_ids]&.include?(submission.pd_workshop_id)
          submissions << submission
        end

        p "submissions.count = #{submissions.count}" if debug
        p "submissions = #{submissions}" if debug

        {survey_questions: questions, workshop_daily_surveys: submissions}
      end
    end
  end
end

__END__

def test_retriever(debug: false)
  res = Pd::SurveyPipeline::WorkshopDailySurveyRetriever.retrieve_data(filters: {form_ids: [1], workshop_ids: [6547]}, debug: debug)
  p "Retriever returns = #{res}" if debug

  res = Pd::SurveyPipeline::WorkshopDailySurveyRetriever.retrieve_data(debug: debug)
  p "Retriever returns = #{res}" if debug
end

test_retriever(debug: false)
