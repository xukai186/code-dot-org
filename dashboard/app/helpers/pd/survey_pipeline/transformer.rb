require_relative '../../../../lib/pd/jot_form/constants.rb'

module Pd::SurveyPipeline
  class TransformerBase
    def transform_data(*)
      raise 'Must override in derived class'
    end
  end

  class WorkshopDailySurveyJoinTransformer < TransformerBase
    include Pd::JotForm::Constants

    ANSWER_MAPPING = {
      TYPE_NUMBER => ANSWER_TEXT,
      TYPE_TEXTBOX => ANSWER_TEXT,
      TYPE_TEXTAREA => ANSWER_TEXT,
      TYPE_RADIO => ANSWER_SINGLE_SELECT,
      TYPE_DROPDOWN => ANSWER_SINGLE_SELECT,
      TYPE_CHECKBOX => ANSWER_MULTI_SELECT,
      TYPE_MATRIX => ANSWER_MULTI_SELECT,
      TYPE_SCALE => ANSWER_SCALE,
    }.freeze

    # Split and join WorkshopDailySurvey and SurveyQuestion data.
    # @param data [Hash] the input data contains WorkshopDailySurvey and SurveyQuestion
    # @return [Array<Hash{FieldKey => FieldValue}>] array of results after join
    # TODO: @see design doc
    # TODO: make it clear what is required in input. what output looks like
    def transform_data(data:, logger: nil)
      # TODO: make these input params
      return unless data.dig(:workshop_daily_surveys)
      return unless data.dig(:survey_questions)

      # Create question mapping: (form_id, qid) => q_content
      questions = {}
      data[:survey_questions].each do |sq|
        q_arr = JSON.parse(sq.questions)
        logger&.info "TR: survey form_id #{sq.form_id} has #{q_arr.count} questions"

        q_arr.each do |q|
          q_key = {form_id: sq.form_id, qid: q["id"].to_s}
          questions[q_key] = q.symbolize_keys
        end
      end

      logger&.info "TR: questions.count = #{questions.count}"
      logger&.debug "TR: questions = #{questions}"

      # Split answers into rows and add question content for each row
      res = []
      data[:workshop_daily_surveys].each do |submission|
        next unless submission.answers

        ans_h = JSON.parse(submission.answers)
        logger&.info "TR: submission id #{submission.id} has #{ans_h.count} answers"

        ans_h.each do |qid, ans|
          q_key = {form_id: submission.form_id, qid: qid.to_s}
          raise "Question id #{qid} in form #{form_id} does not exist in SurveyQuestion data" unless questions.key?(q_key)

          # TODO: add answer_type to question_content
          # TODO: how to decide what fields to take from sumission record? How to config it?
          question_content = questions[q_key].except(:form_id, :id)
          answer_type = ANSWER_MAPPING[question_content[:type]] || 'unknown'
          submission_content = {
            workshop_id: submission.pd_workshop_id, form_id: submission.form_id,
            submission_id: submission.id, answer: ans, answer_type: answer_type, qid: qid
          }
          res << submission_content.merge(question_content)
        end
      end

      logger&.info "TR: answer count = #{res.count}"
      logger&.debug "TR: first 10 answers = #{res[0..9]}"

      res
    end
  end

  class ComplexQuestionTransformer < TransformerBase
    include Pd::JotForm::Constants

    attr_reader :question_types

    TRANSFORMABLE_QUESTION_TYPES = [TYPE_MATRIX].freeze
    STRING_DIGEST_LENGTH = 16

    def initialize(question_types: [])
      @question_types = question_types
    end

    def transform_matrix_question(row)
      # precondition: row[:answer] exists and is Hash{sub_question => ans}
      # postcondition: even sub question with empty answer will be produced. Transformer does not attempt
      # to filter data

      return unless row

      produced_rows = []
      # Create a new row for each answer
      row[:answer].each do |sub_q, ans|
        temp_row = row.except(:name, :type, :text, :answer, :answer_type, :sub_questions)

        sub_q_digest = Digest::SHA256.base64digest(sub_q)[0, STRING_DIGEST_LENGTH - 1]
        temp_row[:name] = "#{row[:name]}_#{sub_q_digest}"
        temp_row[:type] = 'matrix_derived'
        temp_row[:text] = "#{row[:text]} #{sub_q}"
        temp_row[:answer] = ans

        # Just to make the UI happy
        temp_row[:max_value] = row[:options].length
        temp_row[:parent] = row[:name]

        # TODO: (Future) New answer_type is default to ANSWER_SINGLE_SELECT for now.
        # Once we have row[:inputType] for matrix question we can map it to correct answer type,
        # e.g. "Radio Button" -> ANSWER_SINGLE_SELECT, "Check Box" -> ANSWER_MULTI_SELECT
        temp_row[:answer_type] = ANSWER_SINGLE_SELECT

        produced_rows << temp_row
      end

      # TODO: remove
      raise "not expected" unless row[:sub_questions].count == produced_rows.count

      produced_rows
    end

    # Break complex questions into multiple smaller questions
    # @param Array<Hash{}>
    # @return Array<Hash{}>
    def transform_data(data:, logger: nil)
      return unless data

      logger&.info "TR: input question_types = #{question_types}"
      logger&.info "TR: transformable question types = #{TRANSFORMABLE_QUESTION_TYPES}"

      res = []
      data.each do |row|
        if question_types.include?(row[:type]) && TRANSFORMABLE_QUESTION_TYPES.include?(row[:type])
          logger&.debug "transforming #{row[:type]}"

          # TODO: add if/else or use hash of function to map question types to transform functions
          res += transform_matrix_question(row)
        else
          logger&.debug "TR: cannot transform #{row[:type]}"
          res << row
        end
      end

      res
    end
  end
end
