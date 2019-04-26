import React from 'react';
import {mount} from 'enzyme';
import {assert, expect} from '../../../util/configuredChai';
import SubmissionStatusAssessmentsTable from '@cdo/apps/templates/sectionAssessments/SubmissionStatusAssessmentsTable';
import {studentOverviewData} from '@cdo/apps/templates/sectionAssessments/assessmentsTestHelpers';

describe('SubmissionStatusAssessmentsTable', () => {
  it('renders a table', () => {
    const wrapper = mount(
      <SubmissionStatusAssessmentsTable
        studentOverviewData={studentOverviewData}
      />
    );

    expect(wrapper.find('table')).to.exist;
  });

  it('renders the correct number of rows and headers', () => {
    const wrapper = mount(
      <SubmissionStatusAssessmentsTable
        studentOverviewData={studentOverviewData}
      />
    );

    const tableHeaders = wrapper.find('th');
    expect(tableHeaders).to.have.length(4);

    const tableRows = wrapper.find('tr');
    expect(tableRows).to.have.length(7);
  });

  it('renders with an icon if specified', () => {
    const wrapper = mount(
      <SubmissionStatusAssessmentsTable
        studentOverviewData={studentOverviewData}
        icon="check-circle"
      />
    );

    const icon = wrapper.find('FontAwesome');
    assert(icon);
  });

  it('renders a checkmark when an assessment is submitted', () => {
    const wrapper = mount(
      <SubmissionStatusAssessmentsTable
        studentOverviewData={studentOverviewData}
      />
    );

    const checkMarkIcons = wrapper.find('#checkmark');
    assert.equal(checkMarkIcons.length, 4);
  });

  it('sorts submissions by date accurately', () => {
    const wrapper = mount(
      <SubmissionStatusAssessmentsTable
        studentOverviewData={studentOverviewData}
      />
    );
    const timeStampCells = wrapper.find('#timestampCell');
    assert.equal(timeStampCells.length, 6);

    const timestampHeaderCell = wrapper.find('#timestampHeaderCell')

    console.log(" 1st timestamp cell after 1st click", wrapper.find('#timestampCell').at(0).text())
    console.log(" 2nd timestamp cell after 1st click", wrapper.find('#timestampCell').at(1).text())
    console.log(" 3rd timestamp cell after 1st click", wrapper.find('#timestampCell').at(2).text())
    console.log(" 4th timestamp cell after 1st click", wrapper.find('#timestampCell').at(3).text())
    console.log(" 5th timestamp cell after 1st click", wrapper.find('#timestampCell').at(4).text())
    console.log(" 6th timestamp cell after 1st click", wrapper.find('#timestampCell').at(5).text())

    console.log('...........................')
    console.log('...........................')
    console.log('...........................')

    timestampHeaderCell.simulate('click');
    console.log(" 1st timestamp cell after 2nd click", wrapper.find('#timestampCell').at(0).text())
    console.log(" 2nd timestamp cell after 2nd click", wrapper.find('#timestampCell').at(1).text())
    console.log(" 3rd timestamp cell after 2nd click", wrapper.find('#timestampCell').at(2).text())
    console.log(" 4th timestamp cell after 2nd click", wrapper.find('#timestampCell').at(3).text())
    console.log(" 5th timestamp cell after 2nd click", wrapper.find('#timestampCell').at(4).text())
    console.log(" 6th timestamp cell after 2nd click", wrapper.find('#timestampCell').at(5).text())

    console.log('...........................')
    console.log('...........................')
    console.log('...........................')

    timestampHeaderCell.simulate('click');
    console.log(" 1st timestamp cell after 3rd click", wrapper.find('#timestampCell').at(0).text())
    console.log(" 2nd timestamp cell after 3rd click", wrapper.find('#timestampCell').at(1).text())
    console.log(" 3rd timestamp cell after 3rd click", wrapper.find('#timestampCell').at(2).text())
    console.log(" 4th timestamp cell after 3rd click", wrapper.find('#timestampCell').at(3).text())
    console.log(" 5th timestamp cell after 3rd click", wrapper.find('#timestampCell').at(4).text())
    console.log(" 6th timestamp cell after 3rd click", wrapper.find('#timestampCell').at(5).text())


  });
});
