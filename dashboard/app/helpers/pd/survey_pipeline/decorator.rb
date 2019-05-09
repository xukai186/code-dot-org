module Pd::SurveyPipeline
  class DecoratorBase
    def self.decorate(*)
      raise 'Child class must override this method'
    end
  end

  class WorkshopDailySurveyReportDecorator < DecoratorBase
    attr_reader :form_names

    def initialize(form_names:)
      # TODO: read from constant list
      # TODO: provide a way to override option
      @form_names = form_names
    end

    def decorate(summaries:, raw_data:, logger: nil)
      return unless summaries
      return unless raw_data.dig(:survey_questions)

      logger&.debug "DECO summaries.count = #{summaries.count}"
      logger&.debug "DECO questions.count = #{raw_data[:survey_questions].count}"
      logger&.debug "DECO form_names.count = #{form_names.count}"
      logger&.debug "DECO form_names = #{form_names}"

      res = {
        course_name: nil,
        questions: {},
        this_workshop: {},
        all_my_workshops: {},
        facilitators: {},
        facilitator_averages: {},
        facilitator_response_counts: {}
      }

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

      logger&.debug "DECO question_names = #{question_names}"

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
          logger&.debug "DECO row with question = #{row}"
          qname = question_names[{form_id: row[:form_id], qid: row[:qid]}]
          res[:this_workshop][fname][:general][qname] = row[:reducer_result]
        elsif row.dig(:reducer)&.downcase == 'count' || row.dig(:reducer)&.downcase == 'count_distinct'
          # TODO: we have the raw_data, get response_count directly from it instead (cheaper!)
          logger&.debug "DECO row w/o question = #{row}"
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
