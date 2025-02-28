/** @file App Lab redux module */
import {ApplabInterfaceMode} from '../constants';
import data from '../../storage/redux/data';
import screens from './screens';
import {reducers as jsDebuggerReducers} from '../../lib/tools/jsdebugger/redux';
import {reducer as maker} from '../../lib/kits/maker/redux';

// Selectors

// Actions

/** @enum {string} */
const CHANGE_INTERFACE_MODE = 'applab/CHANGE_INTERFACE_MODE';
const ADD_REDIRECT_NOTICE = 'applab/ADD_REDIRECT_NOTICE';
const DISMISS_REDIRECT_NOTICE = 'applab/DISMISS_REDIRECT_NOTICE';

/**
 * Change the interface mode between Design Mode and Code Mode
 * @param {!ApplabInterfaceMode} interfaceMode
 * @returns {{type: string, interfaceMode: ApplabInterfaceMode}}
 */
function changeInterfaceMode(interfaceMode) {
  if (!interfaceMode) {
    throw new Error('Expected an interace mode!');
  }
  return {
    type: CHANGE_INTERFACE_MODE,
    interfaceMode: interfaceMode
  };
}

/**
 * Add a redirect notice to our stack
 * @param {bool} approved
 * @param {string} url
 * @returns {{type: string, approved: bool, url: string}}
 */
function addRedirectNotice(approved, url) {
  return {
    type: ADD_REDIRECT_NOTICE,
    approved: approved,
    url: url
  };
}

/**
 * Remove the first redirect notice from our stack
 * @returns {{type: string}}
 */
function dismissRedirectNotice() {
  return {
    type: DISMISS_REDIRECT_NOTICE
  };
}

export const actions = {
  changeInterfaceMode,
  addRedirectNotice,
  dismissRedirectNotice
};

// Reducers

function interfaceMode(state, action) {
  state = state || ApplabInterfaceMode.CODE;

  switch (action.type) {
    case CHANGE_INTERFACE_MODE:
      return action.interfaceMode;
    default:
      return state;
  }
}

function redirectDisplay(state, action) {
  state = state || [];

  switch (action.type) {
    case ADD_REDIRECT_NOTICE:
      // Add a redirect notice to our stack of notices
      return [
        {
          approved: action.approved,
          url: action.url
        }
      ].concat(state);
    case DISMISS_REDIRECT_NOTICE:
      // Dismiss the top-most redirect on the stack of notices
      if (state.length > 0) {
        return state.slice(1);
      } else {
        return state;
      }
    default:
      return state;
  }
}

export const reducers = {
  ...jsDebuggerReducers,
  maker,
  data,
  interfaceMode,
  redirectDisplay,
  screens
};
