#load 'app/helpers/pd/survey_pipeline/decorator_test.rb'

# only load these file for testing from Rails console
load 'app/helpers/pd/survey_pipeline/decorator.rb'
load 'app/helpers/pd/survey_pipeline/map_reducer.rb'
load 'app/helpers/pd/survey_pipeline/transformer.rb'
load 'app/helpers/pd/survey_pipeline/retriever.rb'

def test_decorator(logger)
  filters = {form_ids: [82_115_699_619_165], workshop_ids: [6424]}
  retrieved_data = Pd::SurveyPipeline::WorkshopDailySurveyRetriever.retrieve_data filters: filters, logger: logger
  transformed_data = Pd::SurveyPipeline::WorkshopDailySurveyFlattenTransformer.transform_data data: retrieved_data, logger: logger

  # 1st groupping
  group_config1 = [:workshop_id, :form_id, :qid, :type]
  is_number_type = lambda {|hash| hash.dig(:type) == 'number'}
  is_matrix_type = lambda {|hash| hash.dig(:type) == 'matrix'}
  map_config1 = [
    {
      condition: is_number_type,
      field: :answer,
      reducers: [Pd::SurveyPipeline::AvgReducer.new, Pd::SurveyPipeline::HistogramReducer.new]
    },
    {
      condition: is_matrix_type,
      field: :answer,
      reducers: [Pd::SurveyPipeline::MatrixHistogramReducer.new]
    }
  ]
  map_reducer1 = Pd::SurveyPipeline::GenericMapReducer.new(group_config: group_config1, map_config: map_config1)

  summaries = map_reducer1.mapreduce(data: transformed_data, logger: logger)

  # 2nd groupping
  group_config2 = [:workshop_id, :form_id]
  no_cond = lambda {|_| true}
  map_config2 = [{
    condition: no_cond,
    field: :submission_id,
    reducers: [Pd::SurveyPipeline::CountReducer.new(distinct: true)]
  }]
  map_reducer2 = Pd::SurveyPipeline::GenericMapReducer.new(group_config: group_config2, map_config: map_config2)

  summaries += map_reducer2.mapreduce(data: transformed_data, logger: logger)

  decorator = ::Pd::SurveyPipeline::WorkshopDailySurveyReportDecorator.new(
    form_names: {1 => "Pre workshop", 9 => "Post workshop"}
  )

  res = decorator.decorate(
    summaries: summaries,
    raw_data: retrieved_data,
    logger: logger
  )

  logger&.warn "DECO Final result = #{res}"
end

log_file = File.new("#{File.dirname(__FILE__)}/log_decorator.txt", 'w')
log_file.sync = true
logger = Logger.new(log_file, level: Logger::DEBUG)

test_decorator(logger) if $0 == 'rails_console'
