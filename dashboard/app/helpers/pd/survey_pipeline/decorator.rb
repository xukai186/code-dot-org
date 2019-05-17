module Pd::SurveyPipeline
  class DecoratorBase
    def self.decorate(*)
      raise 'Must override in derived class'
    end
  end

  class WorkshopDailySurveyReportDecorator < DecoratorBase
    attr_reader :form_names

    def initialize(form_names:)
      # TODO: read from constant list
      # TODO: provide a way to override option
      @form_names = form_names
    end

    def decorate(summaries:, transformed_data:, retrieved_data: nil, logger: nil)
      return unless summaries && transformed_data

      logger&.debug "DECO: summaries.count = #{summaries.count}"
      logger&.debug "DECO: transformed_data.count = #{transformed_data.count}"
      logger&.debug "DECO: form_names.count = #{form_names.count}"
      logger&.debug "DECO: form_names = #{form_names}"

      res = {
        course_name: nil,
        questions: {},
        this_workshop: {},
        all_my_workshops: {},
        facilitators: {},
        facilitator_averages: {},
        facilitator_response_counts: {}
      }

      # Build question list from transformed_data
      transformed_data.each do |record|
        next if !!record[:hidden]

        form_name = get_form_name(record[:form_id], form_names)
        res[:questions][form_name] ||= {general: {}}

        q_name = record[:name]
        next if res[:questions][form_name][:general].include? q_name

        res[:questions][form_name][:general][q_name] =
          record.except(:workshop_id, :form_id, :submission_id, :name, :qid, :type, :order, :answer)
      end

      logger&.debug "DECO: res[:questions] = #{res[:questions]}"

      # Populate results for res[:this_workshop]
      summaries.each do |summary|
        # Not yet support calculating res[:all_my_workshops]
        next unless summary.dig(:workshop_id)

        # Not yet support combining results from different forms
        next unless summary.dig(:form_id)

        res[:course_name] ||= get_course_name(summary[:workshop_id])

        form_name = get_form_name(summary[:form_id], form_names)
        res[:this_workshop][form_name] ||= {general: {}}

        # TODO: get total response count

        res[:this_workshop][form_name][:general][summary[:name]] = summary[:reducer_result]
      end

      # summaries.each do |row|
      #   # Not yet support calculating res[:all_my_workshops]
      #   next unless row.dig(:workshop_id)
      #   # Not yet support combining results from different forms
      #   next unless row.dig(:form_id)

      #   # Populate data for res[:this_workshop]
      #   res[:course_name] ||= get_course_name(row[:workshop_id])

      #   form_name = get_form_name(row[:form_id], form_names)
      #   res[:this_workshop][form_name] ||= {general: {}}

      #   if row.dig(:qid)
      #     #next unless row.dig(:reducer)&.downcase == 'histogram'
      #     logger&.debug "DECO: row w/ question = #{row}"
      #     qname = question_names[{form_id: row[:form_id], qid: row[:qid]}]
      #     res[:this_workshop][form_name][:general][qname] = row[:reducer_result]
      #   elsif row.dig(:reducer)&.downcase == 'count' || row.dig(:reducer)&.downcase == 'count_distinct'
      #     # TODO: we have the retrieved_data, get response_count directly from it instead (cheaper!)
      #     logger&.debug "DECO: row w/o question = #{row}"
      #     res[:this_workshop][form_name][:response_count] = row[:reducer_result]
      #   end
      # end

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
