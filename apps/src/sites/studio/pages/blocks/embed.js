import $ from 'jquery';
import assetUrl from '@cdo/apps/code-studio/assetUrl';
import {valueTypeTabShapeMap} from '@cdo/apps/gamelab/GameLab';
import {parseElement} from '@cdo/apps/xml';
import {shrinkBlockSpaceContainer} from '@cdo/apps/templates/instructions/utils';
import {installCustomBlocks} from '@cdo/apps/block_utils';
import {install, customInputTypes} from '@cdo/apps/gamelab/blocks';

const script = document.querySelector('script[data-xml]');
const xmlStr = script.dataset.xml;

$(document).ready(() => {
  const container = document.getElementById('blockly-container');
  // investigate why default is always displayed from blocksDom.
  const blocksDom = parseElement(xmlStr);

  Blockly.assetUrl = assetUrl;
  Blockly.valueTypeTabShapeMap = valueTypeTabShapeMap(Blockly);
  Blockly.typeHints = true;
  Blockly.Css.inject(document);
  const blockSpace = Blockly.BlockSpace.createReadOnlyBlockSpace(
    container,
    blocksDom,
    {
      noScrolling: true,
      inline: false
    }
  );
  shrinkBlockSpaceContainer(blockSpace, true);

  install(Blockly);
  // isn't actually installing customInputTypes:
  // are blockDefinitions required? what should they be?
  installCustomBlocks({
    blockly: Blockly,
    blockDefinitions: [],
    customInputTypes
  });
});
