#load 'app/helpers/pd/survey_pipeline/retriever_test.rb'

load 'app/helpers/pd/survey_pipeline/retriever.rb'

def test_retriever(logger = nil)
  # filters = {form_ids: [82115699619165], workshop_ids: [6424]}
  # filters = {form_ids: [1], workshop_ids: [6547]}
  filters = {workshop_ids: [6424]}
  # filters = {form_ids: [1]}
  # filters = nil

  res = Pd::SurveyPipeline::WorkshopDailySurveyRetriever.retrieve_data(filters: filters, logger: logger)
  logger&.warn "RE: Final result = #{res}"
end

# log_file = File.new("#{File.dirname(__FILE__)}/log_retriever.txt", 'w')
# log_file.sync = true
# logger = Logger.new(log_file, level: Logger::DEBUG)

logger = Logger.new(STDOUT, level: Logger::DEBUG)
STDOUT.sync = true

test_retriever(logger) if $0 == 'rails_console'
