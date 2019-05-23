#load 'app/helpers/pd/survey_pipeline/transformer_test.rb'

load 'app/helpers/pd/survey_pipeline/transformer.rb'
load 'app/helpers/pd/survey_pipeline/retriever.rb'

# TODO: add unit tests
# Test Join transformer
# Can join. Cannot join.
# Test Matrix transformer
# Selected type + Transformable type is transformed
# Selected type but not transformable type is not transformed
# Not selected type is not transformed
# Transformable types has function to transform them

def test_transformer(logger = nil)
  #filters = {workshop_ids: [6547]}
  filters = {form_ids: [82_115_699_619_165], workshop_ids: [6424]}
  retriever = ::Pd::SurveyPipeline::DailySurveyRetriever.new filters
  retrieved_data = retriever.retrieve_data

  transformer = Pd::SurveyPipeline::DailySurveyJoinTransformer.new(
    survey_questions: retrieved_data[:survey_questions],
    survey_submissions: retrieved_data[:workshop_daily_surveys]
  )
  joined_row = transformer.transform_data(data: retrieved_data, logger: logger)
  logger&.info "TR: joined_row.count = #{joined_row.count}"

  res = Pd::SurveyPipeline::ComplexQuestionTransformer.new(question_types: ['matrix']).transform_data(data: joined_row, logger: logger)

  logger&.warn "TR: Final result count = #{res.count}"
  logger&.debug "TR: Final result = #{res}"
end

log_file = File.new("#{File.dirname(__FILE__)}/log_transformer.txt", 'w')
log_file.sync = true
logger = Logger.new(log_file, level: Logger::DEBUG)

test_transformer(logger) if $0 == 'rails_console'
