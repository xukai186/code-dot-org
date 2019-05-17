#load 'app/helpers/pd/survey_pipeline/retriever_test.rb'

load 'app/helpers/pd/survey_pipeline/retriever.rb'

# TODO: Add unit tests
# Create dumb data in Pd::WorkshopDailySurvey
# Test retrieving data with different filters: empty, 1 workshop, 1 form, 1 workshop + 1 form, multi workshops, multi forms, multi workshops + forms

def test_retriever(logger = nil)
  # filters = {form_ids: [82115699619165], workshop_ids: [6424]}
  # filters = {form_ids: [1], workshop_ids: [6547]}
  filters = {workshop_ids: [6424]}
  # filters = {form_ids: [1]}
  # filters = nil

  res = Pd::SurveyPipeline::WorkshopDailySurveyRetriever.new(filters: filters).retrieve_data logger: logger
  logger&.warn "RE: Final result = #{res}"
end

log_file = File.new("#{File.dirname(__FILE__)}/log_retriever.txt", 'w')
log_file.sync = true
logger = Logger.new(log_file, level: Logger::DEBUG)

test_retriever(logger) if $0 == 'rails_console'
