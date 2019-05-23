#load 'app/helpers/pd/survey_pipeline/map_reducer_test.rb'

# only load these file for testing from Rails console
load 'app/helpers/pd/survey_pipeline/map_reducer.rb'
load 'app/helpers/pd/survey_pipeline/transformer.rb'
load 'app/helpers/pd/survey_pipeline/retriever.rb'

def test_mapreducer(logger = nil)
  #filters = {form_ids: [82_115_699_619_165], workshop_ids: [6424]}
  filters = {workshop_ids: [6547]}
  retrieved_data = Pd::SurveyPipeline::DailySurveyRetriever.new(filters: filters).retrieve_data

  joined_data = Pd::SurveyPipeline::DailySurveyJoinTransformer.new.transform_data data: retrieved_data
  transformed_data = Pd::SurveyPipeline::ComplexQuestionTransformer.new(question_types: ['matrix']).transform_data data: joined_data

  # 1st groupping
  group_config1 = [:workshop_id, :form_id, :name, :type, :hidden, :answer_type]

  # TODO: make it clear lambda condition can only execute on fields in group_config. Either processing all rows in a group or none.

  is_single_select_answer = lambda {|hash| hash.dig(:answer_type) == 'singleSelect'}
  is_free_format_question = lambda {|hash| ['textbox', 'textarea'].include?(hash.dig(:type)) && !!!hash.dig(:hidden)}
  is_number_question = lambda {|hash| hash.dig(:type) == 'number'}

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
    },
    {
      condition: is_number_question,
      field: :answer,
      reducers: [Pd::SurveyPipeline::AvgReducer.new]
    },
  ]
  map_reducer1 = Pd::SurveyPipeline::GenericMapReducer.new(group_config: group_config1, map_config: map_config1)

  res = map_reducer1.mapreduce data: transformed_data, logger: logger

  logger&.warn "MP: Final result count = #{res.count}"
  logger&.info "MP: Final result = #{res}"
end

log_file = File.new("#{File.dirname(__FILE__)}/log_mapreducer.txt", 'w')
log_file.sync = true
logger = Logger.new(log_file, level: Logger::DEBUG)

test_mapreducer(logger) if $0 == 'rails_console'

__END__
#print_key_count = lambda {|hash| hash.each_key {|key| p key, hash[key].count}}
#print_key_count.call(retrieved_data) if log_level >= Logger::WARN


# 2nd groupping
group_config2 = [:workshop_id, :form_id]
no_cond = lambda {|_| true}
map_config2 = [{
  condition: no_cond,
  field: :submission_id,
  reducers: [Pd::SurveyPipeline::CountReducer.new(distinct: true)]
}]
map_reducer2 = Pd::SurveyPipeline::GenericMapReducer.new(group_config: group_config2, map_config: map_config2)
res += map_reducer2.mapreduce(data: transformed_data, logger: logger)

is_number_type = lambda {|hash| hash.dig(:type) == 'number'}
map_config1 = [
  {
    condition: is_number_type,
    field: :answer,
    reducers: [Pd::SurveyPipeline::AvgReducer.new, Pd::SurveyPipeline::HistogramReducer.new]
  },
]