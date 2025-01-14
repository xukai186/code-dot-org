require 'test_helper'

class BubbleChoiceTest < ActiveSupport::TestCase
  setup_all do
    create :game, name: 'BubbleChoice'
    Rails.application.config.stubs(:levelbuilder_mode).returns false
  end

  test 'create_from_level_builder creates level from DSL input' do
    sublevel = create :level, name: 'level for bubble choice'

    input_dsl = <<DSL
name 'bubble choice 1'
title 'Choose a Bubble'
description 'Choose the level you want to complete.'

sublevels
level 'level for bubble choice'
DSL

    level = BubbleChoice.create_from_level_builder({}, {name: 'bubble choice 1', dsl_text: input_dsl})
    assert_equal 'bubble choice 1', level.name
    assert_equal 'Choose a Bubble', level.title
    assert_equal 'Choose the level you want to complete.', level.description
    assert_equal [sublevel], level.sublevels
  end

  test 'create_from_level_builder fails if a sublevel does not exist' do
    input_dsl = <<DSL
name 'bubble choice'

sublevels
level 'some nonexistent level'
DSL

    error = assert_raises do
      BubbleChoice.create_from_level_builder({}, {name: 'bubble choice', dsl_text: input_dsl})
    end
    assert_equal "Unable to locate level 'some nonexistent level'.", error.message
  end

  test 'create_from_level_builder fails if a sublevel is used twice' do
    create :level, name: 'level for bubble choice'

    input_dsl = <<DSL
name 'bubble choice'

sublevels
level 'level for bubble choice'
level 'level for bubble choice'
DSL

    error = assert_raises do
      BubbleChoice.create_from_level_builder({}, {name: 'bubble choice', dsl_text: input_dsl})
    end
    assert_equal "Don't use the same level twice in a BubbleChoice (level for bubble choice).", error.message
  end

  test 'sublevels are returned in the order defined by the DSL' do
    sublevel1 = create :level, name: 'bubble choice level 1'
    sublevel2 = create :level, name: 'bubble choice level 2'
    sublevel3 = create :level, name: 'bubble choice level 3'

    input_dsl = <<DSL
name 'bubble choice'

sublevels
level 'bubble choice level 1'
level 'bubble choice level 2'
level 'bubble choice level 3'
DSL

    level = BubbleChoice.create_from_level_builder({}, {name: 'bubble choice', dsl_text: input_dsl})
    assert_equal [sublevel1, sublevel2, sublevel3], level.sublevels
  end

  test 'summarize' do
    sublevel1 = create :level, name: 'choice_1', display_name: 'Choice 1!', thumbnail_url: 'some-fake.url/kittens.png'
    sublevel2 = create :level, name: 'choice_2'
    bubble_choice = BubbleChoice.create(name: 'bubble_choices', title: 'Bubble Choices', description: 'Choose one or more!')
    bubble_choice.properties['sublevels'] = [sublevel1.name, sublevel2.name]
    bubble_choice.save!

    summary = bubble_choice.summarize
    expected_summary = {
      title: bubble_choice.title,
      description: bubble_choice.description,
      sublevels: [
        {id: sublevel1.id, title: sublevel1.display_name, thumbnail_url: sublevel1.thumbnail_url},
        {id: sublevel2.id, title: sublevel2.name, thumbnail_url: nil}
      ]
    }

    assert_equal expected_summary, summary
  end
end
