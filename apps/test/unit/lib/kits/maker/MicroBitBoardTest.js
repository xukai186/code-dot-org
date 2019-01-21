import MicroBitBoard from '@cdo/apps/lib/kits/maker/MicroBitBoard';
import {itImplementsTheMakerBoardInterface} from './MakerBoardTest';

describe('MicroBitBoard', () => {
  itImplementsTheMakerBoardInterface(MicroBitBoard);
});
