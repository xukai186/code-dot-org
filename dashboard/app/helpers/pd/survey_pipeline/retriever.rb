module Pd::SurveyPipeline
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
    def self.retrieve_data(filters: {}, logger: nil)
      logger&.info "RE: filters = #{filters}"

      submissions = []
      selected_form_ids = []
      Pd::WorkshopDailySurvey.find_each do |submission|
        next unless !filters.key?(:form_ids) ||
          filters[:form_ids]&.include?(submission.form_id)
        next unless !filters.key?(:workshop_ids) ||
          filters[:workshop_ids]&.include?(submission.pd_workshop_id)

        selected_form_ids << submission.form_id
        submissions << submission
      end

      logger&.info "RE: submissions.count = #{submissions.count}"
      logger&.debug "RE: submissions = #{submissions}"

      questions = []
      Pd::SurveyQuestion.find_each do |question|
        next unless selected_form_ids.blank? || selected_form_ids.include?(question.form_id)
        questions << question
      end

      logger&.info "RE: questions.count = #{questions.count}"
      logger&.debug "RE: questions = #{questions}"

      {survey_questions: questions, workshop_daily_surveys: submissions}
    end
  end
end
