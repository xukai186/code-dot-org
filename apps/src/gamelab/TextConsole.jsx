/** @file Grid over visualization */
import PropTypes from 'prop-types';
import React from 'react';

export const styles = {
  line: {
    stroke: '#000',
    strokeWidth: 0.8
  },
  semiBoldLine: {
    stroke: '#000',
    strokeWidth: 1.4
  },
  boldLine: {
    stroke: '#000',
    strokeWidth: 4
  },
  show: {
    display: ''
  },
  hide: {
    display: 'none'
  },
  consoleOpen: {
    display: '',
    background: 'rgba(128,128,128,0.3)',
    maxHeight: '108px',
    position: 'absolute',
    top: 0,
    left: 0,
    zIndex: 2,
    width: '100%',
    overflow: 'auto'
  },
  consoleClosed: {
    display: '',
    background: 'rgba(128,128,128,0.3)',
    position: 'absolute',
    top: 0,
    left: 0,
    zIndex: 2,
    width: '100%',
    overflow: 'hidden',
    whiteSpace: 'nowrap',
    maxHeight: '18px'
  },
  expandButton: {
    position: 'absolute',
    right: '0',
    zIndex: 3,
    minWidth: '16px',
    margin: '0px',
    border: '0px',
    padding: '0px',
    fontSize: 'inherit',
    lineHeight: 'inherit',
    borderRadius: '0px',
    fontFamily: 'monospace'
  },
  collapseButton: {
    position: 'absolute',
    right: '0',
    zIndex: 3,
    minWidth: '30px',
    margin: '0px',
    border: '0px',
    padding: '0px',
    fontSize: 'inherit',
    lineHeight: 'inherit',
    borderRadius: '0px'
  },
  paragraphStyle: {
    margin: '0px'
  }
};

/**
 * Grid layered over the play space.
 * Should be rendered inside a VisualizationOverlay.
 * @constructor
 */
export default class TextConsole extends React.Component {
  static propTypes = {
    // width, height, mouseX and mouseY are given in app-space, not screen-space
    width: PropTypes.number,
    height: PropTypes.number,
    show: PropTypes.bool.isRequired
  };

  state = {
    closed: true
  };

  getConsoleStyle() {
    return this.state.closed? styles.consoleClosed : styles.consoleOpen;
  }

  toggleStyle() {
    this.setState((state) => {
      return {closed: !state.closed};
    });
  }

  getButtonText() {
    return this.state.closed? '+' : '-';
  }

  render() {
    return (
      <div>
        <span id="text-console" className="text-console" style={this.getConsoleStyle()} >
          <p style={styles.paragraphStyle}>
            <b>Lorem</b> ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
          </p>
          <p style={styles.paragraphStyle}>
            <b>Lorem</b> ipsum
          </p>
          <p style={styles.paragraphStyle}>
            <b>Lorem</b> ipsum dolor
          </p>
          <p style={styles.paragraphStyle}>
            <b>Lorem</b> ipsum dolor sit amet, consectetur
          </p>
        </span>
        <button type="button" id="expand-collapse" style={styles.expandButton} onClick={() => this.toggleStyle()}>{this.getButtonText()}</button>
      </div>
    );
  }
}
