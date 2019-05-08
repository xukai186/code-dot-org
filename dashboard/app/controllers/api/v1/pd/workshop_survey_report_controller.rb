require_relative '../../../../../lib/pd/survey_pipeline/retriever.rb'
require_relative '../../../../../lib/pd/survey_pipeline/transformer.rb'
require_relative '../../../../../lib/pd/survey_pipeline/map_reducer.rb'
require_relative '../../../../../lib/pd/survey_pipeline/decorator.rb'

module Api::V1::Pd
  class WorkshopSurveyReportController < ReportControllerBase
    include WorkshopScoreSummarizer
    include ::Pd::WorkshopSurveyReportCsvConverter
    include Pd::WorkshopSurveyResultsHelper
    #include ::Pd::SurveyPipeline

    load_and_authorize_resource :workshop, class: 'Pd::Workshop'

    # GET /api/v1/pd/workshops/:id/workshop_survey_report
    def workshop_survey_report
      all_my_workshops = params[:organizer_view] ? Pd::Workshop.organized_by(current_user) : Pd::Workshop.facilitated_by(current_user)
      all_my_completed_workshops = all_my_workshops.where(course: @workshop.course).in_state(Pd::Workshop::STATE_ENDED).exclude_summer

      survey_repo
      survey_report = generate_summary_report(
        workshop: @workshop,
        workshops: all_my_completed_workshops,
        course: @workshop.course,
        facilitator_name: facilitator_name_filter
      )

      respond_to do |format|
        format.json do
          render json: survey_report
        end
        format.csv do
          # Kind of lame but we need to do this - Ruby orders hashes based on insertion order. We want to rename the first
          # key, but that's not really supported in a way to preserve insertion order. So we have to make a new hash
          ordered_survey_report = survey_report.transform_keys.with_index {|k, i| i == 0 ? @workshop.friendly_name : k}
          send_as_csv_attachment(convert_to_csv(ordered_survey_report), 'workshop_survey_report.csv', titleize: false)
        end
      end
    end

    # GET /api/v1/pd/workshops/:id/teachercon_survey_report
    def teachercon_survey_report
      unless @workshop.teachercon?
        raise 'Only call this route for teachercons'
      end

      facilitator_name = facilitator_name_filter
      survey_report = Hash.new

      survey_report[:this_teachercon] = summarize_workshop_surveys(
        workshops: [@workshop],
        facilitator_name_filter: current_user.facilitator? && current_user.name
      )
      survey_report[:all_my_teachercons] = summarize_workshop_surveys(
        workshops: Pd::Workshop.where(
          subject: [Pd::Workshop::SUBJECT_CSP_TEACHER_CON, Pd::Workshop::SUBJECT_CSD_TEACHER_CON]
        ).managed_by(current_user).in_state(Pd::Workshop::STATE_ENDED),
        include_free_response: false,
        facilitator_breakdown: false,
        facilitator_name_filter: facilitator_name
      )

      aggregate_for_all_workshops = JSON.parse(
        AWS::S3.download_from_bucket('pd-workshop-surveys', "aggregate-workshop-scores-production")
      )
      survey_report[:all_workshops_for_course] = aggregate_for_all_workshops[
        @workshop.course == Pd::Workshop::COURSE_CSP ? 'CSP TeacherCon' : 'CSD TeacherCon'
      ]

      survey_report[:facilitator_breakdown] = facilitator_name.nil?
      survey_report[:facilitator_names] = @workshop.facilitators.pluck(:name) if facilitator_name.nil?

      respond_to do |format|
        format.json do
          render json: survey_report
        end
      end
    end

    # GET /api/v1/pd/workshops/:id/local_workshop_survey_report
    def local_workshop_survey_report
      unless @workshop.local_summer?
        raise 'Only call this route for local workshop survey reports'
      end

      facilitator_name = facilitator_name_filter
      survey_report = Hash.new

      survey_report[:this_workshop] = summarize_workshop_surveys(workshops: [@workshop], facilitator_name_filter: facilitator_name)

      survey_report[:all_my_local_workshops] = summarize_workshop_surveys(
        workshops: Pd::Workshop.where(
          subject: @workshop.subject,
          course: @workshop.course
        ).managed_by(current_user).in_state(Pd::Workshop::STATE_ENDED),
        facilitator_breakdown: false,
        facilitator_name_filter: facilitator_name,
        include_free_response: false
      )

      aggregate_for_all_workshops = JSON.parse(AWS::S3.download_from_bucket('pd-workshop-surveys', "aggregate-workshop-scores-production"))
      survey_report[:all_workshops_for_course] = aggregate_for_all_workshops['CSP Local Summer Workshops']

      survey_report[:facilitator_breakdown] = facilitator_name.nil?
      survey_report[:facilitator_names] = @workshop.facilitators.pluck(:name) if facilitator_name.nil?

      respond_to do |format|
        format.json do
          render json: survey_report
        end
      end
    end

    # GET /api/v1/pd/workshops/:id/local_workshop_daily_survey_report
    def local_workshop_daily_survey_report
      unless @workshop.local_summer? || @workshop.teachercon? ||
        ([COURSE_CSP, COURSE_CSD].include?(@workshop.course) && @workshop.workshop_starting_date > Date.new(2018, 8, 1))
        return render status: :bad_request, json: {
          error: 'Only call this route for new academic year workshops, 5 day summer workshops, local or TeacherCon'
        }
      end

      survey_report = generate_workshop_daily_session_summary(@workshop)

      respond_to do |format|
        format.json do
          render json: survey_report
        end
      end
    end

    def fake_json_response
      JSON.parse('{
        "course_name": "CS Fundamentals",
        "questions": {
          "Pre Workshop": {
            "general": {
              "iBelieve_1": {
                "text": "I believe a successful computer science teacher… creates a classroom culture in which students regularly get feedback on their work from their peers.",
                "answer_type": "singleSelect",
                "parent": "iBelieve",
                "max_value": 7,
                "options": [
                  "Strongly Disagree",
                  "Disagree",
                  "Slightly Disagree",
                  "Neutral",
                  "Slightly Agree",
                  "Agree",
                  "Strongly Agree"
                ],
                "option_map": {
                  "Strongly Disagree": 1,
                  "Disagree": 2,
                  "Slightly Disagree": 3,
                  "Neutral": 4,
                  "Slightly Agree": 5,
                  "Agree": 6,
                  "Strongly Agree": 7
                }
              }
            }
          },
          "Post Workshop": {
            "general": {
              "iFeel18": {
                "text": "I feel more prepared to teach CS Principles than I did at the beginning of the day.",
                "answer_type": "scale",
                "min_value": 1,
                "max_value": 7,
                "options": [
                  "1 - Strongly Disagree",
                  "2",
                  "3",
                  "4",
                  "5",
                  "6",
                  "7 - Strongly Agree"
                ]
              }
            }
          }
        },
        "this_workshop": {
          "Pre Workshop": {
            "response_count": 11,
            "general": {
              "iBelieve_1": {
                "Agree": 7,
                "Neutral": 1,
                "Strongly Agree": 2,
                "Slightly Agree": 1
              }
            }
          },
          "Post Workshop": {
            "response_count": 12,
            "general": {
              "iFeel18": {
                "5": 2,
                "7": 6,
                "4": 2,
                "3": 1,
                "6": 1
              }
            },
            "facilitator": {
            }
          }
        },
        "all_my_workshops": {},
        "facilitators": {},
        "facilitator_averages": {},
        "facilitator_response_counts": {}
      }'
      )
    end

    def fake_json_response_csf
      JSON.parse('{
        "course_name": "CS Fundamentals",
        "questions": {
          "Pre Workshop": {
            "general": {
              "iBelieve_1": {
                "text": "I believe a successful computer science teacher… creates a classroom culture in which students regularly get feedback on their work from their peers.",
                "answer_type": "singleSelect"
              }
            }
          },
          "Post Workshop": {
            "general": {
              "iFeel18": {
                "text": "I feel more prepared to teach CS Principles than I did at the beginning of the day.",
                "answer_type": "scale",
                "min_value": 1,
                "max_value": 7,
                "options": [
                  "1 - Strongly Disagree",
                  "2",
                  "3",
                  "4",
                  "5",
                  "6",
                  "7 - Strongly Agree"
                ]
              }
            }
          }
        },
        "this_workshop": {
          "Pre Workshop": {
            "response_count": 11,
            "general": {
              "iBelieve_1": {
                "Agree": 7,
                "Neutral": 1,
                "Strongly Agree": 2,
                "Slightly Agree": 1
              }
            }
          },
          "Post Workshop": {
            "response_count": 12,
            "general": {
              "iFeel18": {
                "5": 2,
                "7": 6,
                "4": 2,
                "3": 1,
                "6": 1
              }
            },
            "facilitator": {
            }
          }
        },
        "all_my_workshops": {},
        "facilitators": {},
        "facilitator_averages": {},
        "facilitator_response_counts": {}
      }'
      )
    end

    def create_generic_survey_report(retriever:, transformer:, map_reducers:, decorator:)
      # Retrieve data from current db
      #p "Retrieving data"

      retrieved_data = retriever.retrieve_data(filters: {workshop_ids: [@workshop.id]})

      #p "retrieved_data = #{retrieved_data}"
      # transform data so they are aggregatable
      #p "Transforming data"

      transformed_data = transformer.transform_data(data: retrieved_data)

      #p "transformed_data = #{transformed_data}"
      # map-reduce configuration: number type -> histogram
      #p "Summarizing data"

      summaries = []
      map_reducers.each do |mr|
        summaries += mr.mapreduce(data: transformed_data)
      end

      #p "summaries = #{summaries}"
      # decorator compile input from current db and summary results into format for the current LSW presentor
      #p "Decorating data"

      decorated_result = decorator.decorate(summaries: summaries, raw_data: retrieved_data)

      #p "decorated_result = #{decorated_result}"

      render json: decorated_result.merge({created_time: Time.now})
      #render json: fake_json_response.merge({created_time: Time.now})
    end

    def csf_201_survey_report
      # MapReducer 1 configs
      p "Creating mapreducer 1 config"
      group_fields1 = [:workshop_id, :form_id, :qid, :type]
      is_type_number_cond = lambda {|hash| hash.dig(:type) == 'number'}

      map_config1 = [{condition: is_type_number_cond, field: :answer, reducers: [::Pd::SurveyPipeline::AvgReducer, ::Pd::SurveyPipeline::HistogramReducer]}]
      map_reducer1 = ::Pd::SurveyPipeline::GenericMapReducer.new(group_fields1, map_config1)

      # MapReducer 2 configs
      p "Creating mapreducer 2 config"
      group_fields2 = [:workshop_id, :form_id]
      no_cond = lambda {|_| true}
      map_config2 = [{condition: no_cond, field: :answer, reducers: [::Pd::SurveyPipeline::CountReducer]}]
      map_reducer2 = ::Pd::SurveyPipeline::GenericMapReducer.new(group_fields2, map_config2)

      p "Creating decorator config"
      # Decorator config
      decorator = ::Pd::SurveyPipeline::WorkshopDailySurveyReportDecorator.new(
        form_names: {1 => "Pre workshop", 9 => "Post workshop"}
      )

      create_generic_survey_report(
        retriever: ::Pd::SurveyPipeline::WorkshopDailySurveyRetriever,
        transformer: ::Pd::SurveyPipeline::WorkshopDailySurveyFlattenTransformer,
        map_reducers: [map_reducer1, map_reducer2],
        decorator: decorator
      )
    end

    # GET /api/v1/pd/workshops/:id/generic_survey_report
    def generic_survey_report
      p "workshop = #{@workshop}"

      return local_workshop_daily_survey_report if @workshop.local_summer? || @workshop.teachercon? ||
        ([COURSE_CSP, COURSE_CSD].include?(@workshop.course) &&
        @workshop.workshop_starting_date > Date.new(2018, 8, 1))

      return csf_201_survey_report if @workshop.csf? && @workshop.subject = SUBJECT_CSF_201

      # TODO: return default summarization + presentation pipeline

      render status: :bad_request, json: {
        error: "Do not know how to process survey results for this workshop #{@workshop.course} #{@workshop.subject}"
      }
    end

    private

    # We want to filter facilitator-specific responses if the user is a facilitator and
    # NOT a workshop admin, workshop organizer, or program manager - the filter is the user's name.
    def facilitator_name_filter
      return nil if current_user.workshop_admin? || current_user.workshop_organizer? || current_user.program_manager?
      return current_user.name if current_user.facilitator?

      raise "Unexpected permission for #{current_user.id}. Expected at least one of facilitator, workshop_admin, workshop_organizer, program_manager"
    end
  end
end

__END__

=begin
  summary = {
    this_workshop: {},
    course_name: @workshop.course,
    all_my_workshops: {},
    facilitators: {},
    facilitator_averages: {},
    facilitator_response_counts: {}
  }

  respond_to do |format|
    format.json do
      render json: summary
    end
  end
=end
