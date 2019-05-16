#load 'app/helpers/pd/survey_pipeline/transformer_test.rb'

load 'app/helpers/pd/survey_pipeline/transformer.rb'
load 'app/helpers/pd/survey_pipeline/retriever.rb'

def test_transformer(logger = nil)
  filters = {form_ids: [82_115_699_619_165], workshop_ids: [6424]}
  retrieved_data = Pd::SurveyPipeline::WorkshopDailySurveyRetriever.retrieve_data filters: filters

  joined_row = Pd::SurveyPipeline::WorkshopDailySurveyJoinTransformer.new.transform_data(data: retrieved_data, logger: logger)
  logger&.info "TR: joined_row.count = #{joined_row.count}"

  res = Pd::SurveyPipeline::ComplexQuestionTransformer.new(question_types: ['matrix']).transform_data(data: joined_row, logger: logger)

  logger&.warn "TR: Final result count = #{res.count}"
  logger&.debug "TR: Final result = #{res}"
end

log_file = File.new("#{File.dirname(__FILE__)}/log_transformer.txt", 'w')
log_file.sync = true
logger = Logger.new(log_file, level: Logger::DEBUG)

test_transformer(logger) if $0 == 'rails_console'
