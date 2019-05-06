#require_relative '../../../config/environment'
#test from console:
#load 'lib/pd/jot_form/retriever.rb'

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

def test_retriever(debug: false)
  res = Pd::SurveyPipeline::WorkshopDailySurveyRetriever.retrieve_data(filters: {form_ids: [1], workshop_ids: [6547]}, debug: debug)
  p "Retriever returns = #{res}" if debug

  res = Pd::SurveyPipeline::WorkshopDailySurveyRetriever.retrieve_data(debug: debug)
  p "Retriever returns = #{res}" if debug
end

test_retriever(debug: false)

__END__

class AnswerCollection
  attr_reader :question_name, :question_type

  def initialize(qname, qtype)
    @question_name = qname
    @question_type = qtype
  end
end

# logger = Logger.new(STDOUT)
# logger.level = 0
# logger.info "Starting..."
# logger.info "done"

#https://github.com/code-dot-org/code-dot-org/pull/28139/files
#survey.summarize.each do |key, value|
  # row = {
  #   form_id: survey.form_id,
  #   question_id: key.to_s,
  #   preamble: (value.key?(:parent) ? sanitize_string_for_db(survey[value[:parent]].text) : nil),
  #   question_text: sanitize_string_for_db(value[:text]),
  #   answer_type: value[:answer_type],
  #   answer_options: sanitize_string_for_db(value[:options].to_s),
  #   min_value: value[:min_value].to_i,
  #   max_value: value[:max_value].to_i
  # }
#  survey_questions << row
#end


require File.expand_path('../../../../config/application', __FILE__)
require File.expand_path('../../../../app/models/pd/survey_question.rb', __FILE__)
require_all('../../../app/models/pd/')
require File.expand_path('../../../app/models/pd/',__dir__)
require_relative('../../../app/models/application_record.rb')
require_relative('../../../app/models/pd/survey_question.rb')
require 'active_record/connection_adapters/abstract_mysql_adapter'

require 'require_all'
require 'active_record'
require 'active_record/connection_adapters/abstract_mysql_adapter'
autoload_all File.expand_path('../../../app/', File.dirname(__FILE__))
autoload_all File.expand_path('../', File.dirname(__FILE__))
autoload_all File.expand_path('../../lib/cdo/shared_constants/pd', File.dirname(__FILE__))
