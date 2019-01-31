import sinon from 'sinon';
import MicroBitBoard from '@cdo/apps/lib/kits/maker/MicroBitBoard';
import {itImplementsTheMakerBoardInterface} from './MakerBoardTest';

describe('MicroBitBoard', () => {
  beforeEach(() => {
    sinon.stub(MicroBitBoard.prototype, 'setSerialPort');
  });

  afterEach(() => {
    MicroBitBoard.prototype.setSerialPort.restore();
  });

  itImplementsTheMakerBoardInterface(MicroBitBoard);
});
