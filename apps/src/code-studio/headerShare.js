/* globals dashboard, appOptions */

import React from 'react';
import ReactDOM from 'react-dom';
import popupWindow from './popup-window';
import ShareDialog from './components/ShareDialog';
import {Provider} from 'react-redux';
import {getStore} from '../redux';
import {showShareDialog} from './components/shareDialogRedux';
import {
  setLibraryFunctions,
  setLibraryName,
  setLibrarySource,
  setContainsError
} from './components/libraryShareDialogRedux';
import {AllPublishableProjectTypes} from '../util/sharedConstants';
import experiments from '@cdo/apps/util/experiments';

export function shareProject(shareUrl) {
  dashboard.project.saveIfSourcesChanged().then(() => {
    const appType = dashboard.project.getStandaloneApp();
    if (appType === 'applab' && experiments.isEnabled('student-libraries')) {
      getStore().dispatch(
        setLibraryFunctions(dashboard.project.getLibraryFromApp())
      );
      var containsError = dashboard.project.containsError();
      getStore().dispatch(setContainsError(containsError));

      // strip whitespace and non alphanumeric characters (underscores are preserved)
      var projectName = dashboard.project
        .getCurrentName()
        .replace(/\s+/g, '')
        .replace(/\W/g, '');
      if (projectName.length === 0 || !isNaN(projectName.charAt(0))) {
        // if all characters are now gone or the library starts with a number, prepend 'Lib'.
        projectName = 'Lib' + projectName;
      }

      // Make the first character uppercase
      var libraryName =
        projectName.charAt(0).toUpperCase() + projectName.slice(1);
      getStore().dispatch(setLibraryName(libraryName));
      dashboard.project.getUpdatedSourceAndHtml_(response =>
        getStore().dispatch(setLibrarySource(response.source))
      );
    }
    var i18n = window.dashboard.i18n;

    var dialogDom = document.getElementById('project-share-dialog');
    if (!dialogDom) {
      dialogDom = document.createElement('div');
      dialogDom.setAttribute('id', 'project-share-dialog');
      document.body.appendChild(dialogDom);
    }

    const selectedSong = dashboard.project.getSelectedSong();

    // The AgeDialog used by Dance Party stores an 'ad_anon_over13' cookie for signed out users,
    // so we want to use that when we decide whether the user can share their project via social media.
    const pageConstants = getStore().getState().pageConstants;
    let canShareSocial;
    if (appType === 'dance') {
      const is13Plus = sessionStorage.getItem('ad_anon_over13') === 'true';
      canShareSocial =
        pageConstants.is13Plus || (!pageConstants.isSignedIn && is13Plus);
    } else {
      canShareSocial = pageConstants.is13Plus || !pageConstants.isSignedIn;
    }

    // Allow publishing for any project type that students can publish.
    // Younger students can now get to the share dialog if their teacher allows
    // it, and should be able to publish in that case.
    const canPublish =
      !!appOptions.isSignedIn && AllPublishableProjectTypes.includes(appType);

    ReactDOM.render(
      <Provider store={getStore()}>
        <ShareDialog
          isProjectLevel={!!dashboard.project.isProjectLevel()}
          allowSignedOutShare={appType === 'dance'}
          i18n={i18n}
          shareUrl={shareUrl}
          selectedSong={selectedSong}
          thumbnailUrl={dashboard.project.getThumbnailUrl()}
          isAbusive={dashboard.project.exceedsAbuseThreshold()}
          canPrint={appType === 'artist'}
          canPublish={canPublish}
          isPublished={dashboard.project.isPublished()}
          channelId={dashboard.project.getCurrentId()}
          appType={appType}
          onClickPopup={popupWindow}
          canShareSocial={canShareSocial}
          userSharingDisabled={appOptions.userSharingDisabled}
        />
      </Provider>,
      dialogDom
    );

    getStore().dispatch(showShareDialog());
  });
}
