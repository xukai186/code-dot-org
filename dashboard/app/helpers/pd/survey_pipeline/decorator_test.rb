#load 'app/helpers/pd/survey_pipeline/decorator_test.rb'

# only load these file for testing from Rails console
load 'app/helpers/pd/survey_pipeline/decorator.rb'
load 'app/helpers/pd/survey_pipeline/map_reducer.rb'
load 'app/helpers/pd/survey_pipeline/transformer.rb'
load 'app/helpers/pd/survey_pipeline/retriever.rb'

def test_decorator(logger)
  filters = {form_ids: [82_115_699_619_165], workshop_ids: [6424]}
  retrieved_data = Pd::SurveyPipeline::WorkshopDailySurveyRetriever.retrieve_data filters: filters, logger: logger

  joined_data = Pd::SurveyPipeline::WorkshopDailySurveyJoinTransformer.new.transform_data data: retrieved_data, logger: logger
  transformed_data = Pd::SurveyPipeline::ComplexQuestionTransformer.new(question_types: ['matrix']).transform_data data: joined_data, logger: logger

  # 1st groupping
  group_config1 = [:workshop_id, :form_id, :name, :type, :hidden, :answer_type]
  is_single_select_answer = lambda {|hash| hash.dig(:answer_type) == 'singleSelect'}
  is_free_format_question = lambda {|hash| ['textbox', 'textarea'].include?(hash.dig(:type)) && !!!hash.dig(:hidden)}

  map_config1 = [
    {
      condition: is_single_select_answer,
      field: :answer,
      reducers: [Pd::SurveyPipeline::HistogramReducer.new]
    },
    {
      condition: is_free_format_question,
      field: :answer,
      reducers: [Pd::SurveyPipeline::NoOpReducer]
    }
  ]
  map_reducer1 = Pd::SurveyPipeline::GenericMapReducer.new(group_config: group_config1, map_config: map_config1)

  summaries = map_reducer1.mapreduce(data: transformed_data, logger: logger)

  decorator = ::Pd::SurveyPipeline::WorkshopDailySurveyReportDecorator.new(
    form_names: {1 => "Pre workshop", 9 => "Post workshop", 82_115_699_619_165 => "Pre Workshop"}
  )

  res = decorator.decorate(
    summaries: summaries,
    transform_data: transformed_data,
    retrieved_data: retrieved_data,
    logger: logger
  )

  logger&.warn "DECO Final result = #{res}"
end

log_file = File.new("#{File.dirname(__FILE__)}/log_decorator.txt", 'w')
log_file.sync = true
logger = Logger.new(log_file, level: Logger::DEBUG)

test_decorator(logger) if $0 == 'rails_console'
