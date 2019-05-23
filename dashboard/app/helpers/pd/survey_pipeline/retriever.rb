module Pd::SurveyPipeline
  class RetrieverBase
    def retrive_data(*)
      raise 'Must override in derived class'
    end
  end

  class DailySurveyRetriever < RetrieverBase
    attr_reader :workshop_ids, :form_ids

    # @param workshop_ids [Array<Integer>] array of selected workshop ids
    # @param form_ids [Array<Integer>] array of selected form ids
    def initialize(workshop_ids: nil, form_ids: nil)
      @workshop_ids = workshop_ids
      @form_ids = form_ids
    end

    # Retrieve data from question_class and answer_class
    # @return [Hash{questions, answers}] a hash contains array of questions and answers
    def retrieve_data(logger: nil)
      logger&.info "RE: workshop_ids filter = #{workshop_ids}"
      logger&.info "RE: form_ids filter = #{form_ids}"

      # TODO: naming, answer or submission?
      # build where clause from filter values
      answer_filter = {}
      answer_filter[:pd_workshop_id] = workshop_ids if workshop_ids.present?
      answer_filter[:form_id] = form_ids if form_ids.present?

      # find in answer tables
      answers = Pd::WorkshopDailySurvey.where(answer_filter)
      facilitator_answers = Pd::WorkshopFacilitatorDailySurvey.where(answer_filter)

      logger&.info "RE: answers.count = #{answers.count}"
      logger&.debug "RE: answers = #{answers&.inspect}"
      logger&.info "RE: facilitator_answers.count = #{facilitator_answers.count}"
      logger&.debug "RE: facilitator_answers = #{facilitator_answers&.inspect}"

      # find in question table (ignore question that don't have answer)
      question_filter = {}
      form_ids_with_answers = answers.pluck(:form_id).uniq | facilitator_answers.pluck(:form_id).uniq
      question_filter[:form_id] = form_ids_with_answers if form_ids_with_answers.present?

      questions = Pd::SurveyQuestion.where(question_filter)

      logger&.info "RE: questions.count = #{questions.count}"
      logger&.debug "RE: questions = #{questions&.inspect}"

      {workshop_daily_surveys: answers, facilitator_daily_surveys: facilitator_answers, survey_questions: questions}
    end
  end
end
