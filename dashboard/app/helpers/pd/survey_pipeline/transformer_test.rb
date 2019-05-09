#load 'app/helpers/pd/survey_pipeline/transformer_test.rb'

load 'app/helpers/pd/survey_pipeline/transformer.rb'
load 'app/helpers/pd/survey_pipeline/retriever.rb'

def test_transformer(log_level = Logger::ERROR)
  logger = Logger.new(STDOUT, level: log_level)

  filters = {form_ids: [82_115_699_619_165], workshop_ids: [6424]}
  retrieved_data = Pd::SurveyPipeline::WorkshopDailySurveyRetriever.retrieve_data filters: filters

  res = Pd::SurveyPipeline::WorkshopDailySurveyFlattenTransformer.transform_data(data: retrieved_data, logger: logger)

  logger.warn "TR Final result count = #{res.count}"
  #logger.debug "TR Final result = #{res}"
end

test_transformer(Logger::DEBUG) if $0 == 'rails_console'
