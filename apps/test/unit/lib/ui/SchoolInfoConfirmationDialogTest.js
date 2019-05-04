import React from 'react';
import {mount} from 'enzyme';
import sinon from 'sinon';
import {expect} from '../../../util/configuredChai';
// import ChangeUserTypeModal from '@cdo/apps/lib/ui/accounts/ChangeUserTypeModal';
import Button from '@cdo/apps/templates/Button';
import i18n from '@cdo/locale';

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

  it('calls handleClickYes when a user confirms current school', () => {
   const handleClickYes = sinon.spy();
    wrapper.setProps({handleClickYes});
    expect(handleClickYes).not.to.have.been.called;
    cancelButton(wrapper).simulate('click');
    expect(handleClickYes).to.have.been.calledOnce;
  });
});

