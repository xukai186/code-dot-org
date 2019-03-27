/** @file Test of searchAssetsTest.js. */

import assert from 'assert';
import {searchAssets} from '@cdo/apps/code-studio/assets/searchAssets';
import animationLibrary from '@cdo/apps/gamelab/animationLibrary.json';
import soundLibrary from '@cdo/apps/code-studio/soundLibrary.json';

describe('search assets from animation library', function() {
  it('searchAssets searches the animation library in a category', function() {
    const maxResults = 5;
    const pageCount = 0;
    const searchedData = searchAssets(
      'hip',
      'category_animals',
      animationLibrary,
      pageCount,
      maxResults
    );

    assert.equal(searchedData.pageCount, 1);
    assert.equal(searchedData.results.length, 4);
    assert.equal(searchedData.results[0].name, 'hippo');
    assert.equal(searchedData.results[1].name, 'hippo_gray');
    assert.equal(searchedData.results[2].name, 'hippo_square');
    assert.equal(searchedData.results[3].name, 'hippo_token');
  });

  it('searchAssets searches the animation library without a category', function() {
    const maxResults = 5;
    const pageCount = 0;
    const searchedData = searchAssets(
      'hip',
      '',
      animationLibrary,
      pageCount,
      maxResults
    );

    assert.equal(searchedData.pageCount, 1);
    assert.equal(searchedData.results.length, 4);
    assert.equal(searchedData.results[0].name, 'hippo');
    assert.equal(searchedData.results[1].name, 'hippo_gray');
    assert.equal(searchedData.results[2].name, 'hippo_square');
    assert.equal(searchedData.results[3].name, 'hippo_token');
  });

  it('searchAssets finds results where search term is not at the begining', function() {
    const maxResults = 5;
    const pageCount = 0;
    const searchedData = searchAssets(
      'square',
      '',
      animationLibrary,
      pageCount,
      maxResults
    );

    assert.equal(searchedData.results.length, 5);
    assert.equal(searchedData.results[0].name, 'elephant_square');
    assert.equal(searchedData.results[1].name, 'giraffe_square');
    assert.equal(searchedData.results[2].name, 'hippo_square');
    assert.equal(searchedData.results[3].name, 'monkey_square');
    assert.equal(searchedData.results[4].name, 'panda_square');
  });
});

describe('search assets from sound library', function() {
  it('searchAssets searches the sound library with a cateogry', function() {
    const maxResults = 5;
    const pageCount = 0;
    const searchedData = searchAssets(
      'click',
      'category_objects',
      soundLibrary,
      pageCount,
      maxResults
    );

    assert.equal(searchedData.pageCount, 1);
    assert.equal(searchedData.results.length, 2);
    assert.equal(searchedData.results[0].name, 'click');
    assert.equal(searchedData.results[1].name, 'metal_click');
  });

  it('searchAssets searches the sound library without a cateogry, using multiple pages', function() {
    const maxResults = 1;
    const pageCount = 0;
    const searchedData = searchAssets(
      'click',
      '',
      soundLibrary,
      pageCount,
      maxResults
    );

    assert.equal(searchedData.pageCount, 407);
    assert.equal(searchedData.results.length, 1);
    assert.equal(
      searchedData.results[0].name,
      'lighthearted_bonus_objective_1'
    );
  });

  it('searchAssets searches the sound library getting page 2 results', function() {
    const maxResults = 1;
    const pageCount = 1;
    const searchedData = searchAssets(
      'click',
      '',
      soundLibrary,
      pageCount,
      maxResults
    );

    assert.equal(searchedData.pageCount, 407);
    assert.equal(searchedData.results.length, 1);
    assert.equal(
      searchedData.results[0].name,
      'lighthearted_bonus_objective_2'
    );
  });

  function CheckForCorruptedFilenames(files) {
    let ar = [];
    for (let i = 0; i < files.results.length; i++) {
      // regex for checking if there are spaces anywhere in the filename
      // also checks if there are more than one underscores anywhere in the filename
      let regex = /(^\_+|\_+$|_{2,}|\s|[A-Z])/gm;
      if (files.results[i].name.match(regex)) {
        ar.push(files.results[i].name);
        // assert.equal(
        //   files.results[i].name,
        //   files.results[i].name
        //     .toLowerCase()
        //     .replace(/\s/g, '_')
        //     .replace(/_{2,}/g, '_')
        //     .replace(/^\_+/g, '')
        //     .replace(/\_+$/g, '')
        // );
        // shows what is making the filename test fail
        // most likely it's because of multiple underscores or spaces
        // or there's caps while it should all be lowercase
        // assert.equal(files.results[i].name.match(regex), null);
      }
    }
    if (ar.length !== 0) {
      for (let file in ar) {
        console.log(ar[file]);
      }
    }
    assert.equal(ar.length, 0);
  }

  function testValidityOfEachSoundCategory(
    categoryName,
    totalNumberOfFilesInCategory
  ) {
    it(`searchAssets searches the ${categoryName} in sound library to check if all filenames are valid`, function() {
      const maxResults = totalNumberOfFilesInCategory;
      const pageCount = 0;
      const searchedData = searchAssets(
        categoryName,
        '',
        soundLibrary,
        pageCount,
        maxResults
      );

      // making sure number of files loaded through search matches
      // the desired number of files to show up for the users
      // length test will fail if totalNumberOfFilesInCategory you gave
      // is greater than actual files displayed to user
      // so decrease the totalNumberOfFilesInCategory
      assert.equal(searchedData.results.length, totalNumberOfFilesInCategory);
      // pageCount should be 1 because that's how you can access all filenames
      // if pageCount is greater than 1 then the totalNumberOfFilesInCategory
      // is less than the actual number of files displayed to the user
      // so increase the totalNumberOfFilesInCategory
      assert.equal(
        searchedData.pageCount,
        Math.ceil(searchedData.results.length / maxResults)
      );
      // checks if any filenames are corrupted
      console.log(categoryName);
      CheckForCorruptedFilenames(searchedData);
    });
  }

  function TestAllSoundFilesInAllCategories() {
    // All category names listed here except category_all
    // category_all exists is seen by user, not in s3
    let categoryNameWithFileNumber = {
      category_accent: 39,
      // category_achievements: 47,
      // category_alerts: 27,
      category_animals: 34,
      category_app: 45,
      category_background: 32,
      // category_bell: 18,
      category_board_games: 12,
      // category_collect: 37,
      category_digital: 40,
      // category_explosion: 47,
      category_female_voiceover: 32,
      // category_hits: 46,
      // category_human: 87,
      category_instrumental: 38,
      category_jump: 35,
      // category_loops: 19,
      category_male_voiceover: 32,
      category_movement: 50,
      category_music: 42,
      category_nature: 21,
      // category_notifications: 36,
      category_objects: 25,
      // category_points: 18,
      category_poof: 23,
      // category_pop: 60,
      // category_projectile: 29,
      category_puzzle: 99,
      category_retro: 51,
      category_slide: 41,
      category_swing: 6,
      category_swish: 32,
      // category_tap: 49,
      // category_transition: 133,
      category_whoosh: 178
    };

    for (const categoryName in categoryNameWithFileNumber) {
      let NumOfFiles = categoryNameWithFileNumber[categoryName];
      testValidityOfEachSoundCategory(categoryName, NumOfFiles);
    }
  }

  TestAllSoundFilesInAllCategories();
});
