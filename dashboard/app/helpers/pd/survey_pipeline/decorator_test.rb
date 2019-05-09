#load 'app/helpers/pd/survey_pipeline/decorator_test.rb'

# only load these file for testing from Rails console
load 'app/helpers/pd/survey_pipeline/decorator.rb'
load 'app/helpers/pd/survey_pipeline/map_reducer.rb'
load 'app/helpers/pd/survey_pipeline/transformer.rb'
load 'app/helpers/pd/survey_pipeline/retriever.rb'

def test_mapreducer(log_level = Logger::ERROR)
  logger = Logger.new(STDOUT, level: log_level)

  retrieved_data = Pd::SurveyPipeline::WorkshopDailySurveyRetriever.retrieve_data
  transformed_data = Pd::SurveyPipeline::WorkshopDailySurveyFlattenTransformer.transform_data data: retrieved_data

  # 1st groupping
  group_fields1 = [:workshop_id, :form_id, :qid, :type]
  is_type_number_cond = lambda {|hash| hash.dig(:type) == 'number'}
  map_config1 = [{condition: is_type_number_cond, field: :answer, reducers: [Pd::SurveyPipeline::AvgReducer, Pd::SurveyPipeline::HistogramReducer]}]
  mapreducer1 = Pd::SurveyPipeline::GenericMapReducer.new(group_fields1, map_config1)

  summaries = mapreducer1.mapreduce(data: transformed_data)

  # 2nd groupping
  group_fields2 = [:workshop_id, :form_id]
  no_cond = lambda {|_| true}
  map_config2 = [{condition: no_cond, field: :answer, reducers: [Pd::SurveyPipeline::CountReducer]}]
  mapreducer2 = Pd::SurveyPipeline::GenericMapReducer.new(group_fields2, map_config2)

  summaries += mapreducer2.mapreduce(data: transformed_data)

  decorator = ::Pd::SurveyPipeline::WorkshopDailySurveyReportDecorator.new(
    form_names: {1 => "Pre workshop", 9 => "Post workshop"}
  )

  res = decorator.decorate(
    summaries: summaries,
    raw_data: retrieved_data,
    logger: logger
  )

  logger.warn "DECO Final result = #{res}"
end

test_mapreducer(Logger::DEBUG) if $0 == 'rails_console'
