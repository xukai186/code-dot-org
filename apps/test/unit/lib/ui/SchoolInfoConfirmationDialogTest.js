import React from 'react';
import {shallow} from 'enzyme';
import sinon from 'sinon';
import {expect} from '../../../util/configuredChai';
import i18n from '@cdo/locale';
import BaseDialog from '@cdo/apps/templates/BaseDialog';
import Button from '@cdo/apps/templates/Button';
import SchoolInfoInputs from '@cdo/apps/templates/SchoolInfoInputs';
import SchoolInfoInterstitial from '@cdo/apps/lib/ui/SchoolInfoInterstitial';
import SchoolInfoConfirmationDialog from '@cdo/apps/lib/ui/SchoolInfoConfirmationDialog';
import firehoseClient from '@cdo/apps/lib/util/firehose';

describe('SchoolInfoConfirmationDialog', () => {
  const MINIMUM_PROPS = {
    scriptData: {
      formUrl: '',
      authTokenName: 'auth_token',
      authTokenValue: 'fake_auth_token',
      existingSchoolInfo: {}
    },
    onClose: function() {}
  };
  //
  // beforeEach(() => sinon.stub(firehoseClient, 'putRecord'));
  // afterEach(() => firehoseClient.putRecord.restore());

  // it('renders the schoolinfointerstitial form', () => {
  //   const wrapper = shallow(
  //     <SchoolInfoConfirmationDialog
  //       {...MINIMUM_PROPS}
  //       scriptData={{
  //         ...MINIMUM_PROPS.scriptData,
  //         existingSchoolInfo: {
  //           country: 'US'
  //         }
  //       }}
  //     />
  //   );
  //
  //   expect(wrapper.find(SchoolInfoInterstitial)).to.have.lengthOf(1);
  // });

  it('simulates click events', () => {
    debugger;
    const onButtonClick = sinon.spy();
    const wrapper = shallow(
          <SchoolInfoConfirmationDialog
            {...MINIMUM_PROPS}
            scriptData={{
              ...MINIMUM_PROPS.scriptData,
              existingSchoolInfo: {
                country: 'US'
              }
            }}
          />
    );
    wrapper.find('Button').simulate('click');
    expect(onButtonClick).to.have.property('callCount', 2);
  });
});

// describe('Local State', () => {
//   it('should display school info interstitial', () => {
//     const state = { showSchoolInterstitial: false };
//     const newState = handleClickUpdate(state);

//     expect(newState.counter).to.equal(true);
//   });

//   // it('should decrement the counter in state', () => {
//   //   const state = { counter: 0 };
//   //   const newState = doDecrement(state);

//   //   expect(newState.counter).to.equal(-1);
//   // });
// });

// describe('SchoolInfoConfirmationDialog', () => {
//   let wrapper;
//   const MINIMUM_PROPS = {
//     scriptData: {
//       formUrl: '',
//       authTokenName: 'auth_token',
//       authTokenValue: 'fake_auth_token',
//       existingSchoolInfo: {}
//     },
//     handleClickYes: () => {}
//   };

//   const yesButton = wrapper =>
//   wrapper.find(Button).filterWhere(n => n.prop('text') === i18n.yes());

//   beforeEach(() => {
//     wrapper = mount(<SchoolInfoConfirmationDialog {...MINIMUM_PROPS} />);
//   });

//   afterEach(() => {
//     wrapper.unmount();
//   });

//   it.only('calls handleClickYes when a user clicks on the yes button', () => {


// console.log('yes biuttton', yesButton);


//     const handleClickYes = sinon.spy();

//     wrapper.setProps({handleClickYes});
//     expect(handleClickYes).not.to.have.been.called;
//     yesButton(wrapper).simulate('click');
//     //expect(handleClickYes).toHa;
//     expect(handleClickYes).to.have.been.calledOnce;
//   });

//   // it('calls handleClickUpdate when a user clicks on No, update button', () => {

//   // });

//   // it('renders the school info interstitial form when No, update button is clicked', () => {

//   // });

//   // it('calls handleClickSave when a user clicks on save button', () => {

//   // });

//   // it('checks that the form is completely filled out and it is not rendered', () => {

//   // });

//   // // maybe better to use it submits with.....
//   // it('checks that if the form is missing the required fields and save, that it is rendered again', () => {

//   // });

//   // it('closes the dialog on successful submission', () => {

//   // });

//   // it('is not complete if country is US and school type is public/private/charter but other information is missing', () => {
//   // });
// });
