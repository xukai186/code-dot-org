module Pd::SurveyPipeline
  class RetrieverBase
    def retrive_data(*)
      raise 'Must override in derived class'
    end
  end

  class WorkshopDailySurveyRetriever < RetrieverBase
    attr_reader :filters

    # @param filters [Hash] a list of filter conditions
    # @option filters [Array<Integer>] :workshop_ids array of workshop ids
    # @option filters [Array<Integer>] :form_ids array of form ids
    def initialize(filters: {})
      @filters = filters
    end

    # Retrieve data from pd_workshop_daily_surveys and pd_survey_questions tables
    # @return [Hash{WorkshopDailySurveys, SurveyQuestions}] a hash contains array of WorkshopDailySurvey and array of SurveyQuestion
    def retrieve_data(logger: nil)
      logger&.info "RE: filters = #{filters}"

      submissions = []
      selected_form_ids = []  # TODO: use set

      # TODO: take advantage of table indexes to find faster
      Pd::WorkshopDailySurvey.find_each do |submission|
        next unless !filters.key?(:form_ids) ||
          filters[:form_ids].include?(submission.form_id)

        next unless !filters.key?(:workshop_ids) ||
          filters[:workshop_ids].include?(submission.pd_workshop_id)

        selected_form_ids << submission.form_id
        submissions << submission
      end

      logger&.info "RE: submissions.count = #{submissions.count}"
      logger&.debug "RE: submissions = #{submissions}"

      # TODO: use index to search using form_ids
      questions = []
      Pd::SurveyQuestion.find_each do |question|
        next unless selected_form_ids.blank? || selected_form_ids.include?(question.form_id)

        questions << question
      end

      logger&.info "RE: questions.count = #{questions.count}"
      logger&.debug "RE: questions = #{questions}"

      {workshop_daily_surveys: submissions, survey_questions: questions}
    end
  end
end
