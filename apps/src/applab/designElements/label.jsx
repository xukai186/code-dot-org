import $ from 'jquery';
import PropTypes from 'prop-types';
import React from 'react';
import PropertyRow from './PropertyRow';
import BooleanPropertyRow from './BooleanPropertyRow';
import ColorPickerPropertyRow from './ColorPickerPropertyRow';
import FontFamilyPropertyRow from './FontFamilyPropertyRow';
import ZOrderRow from './ZOrderRow';
import EventHeaderRow from './EventHeaderRow';
import EventRow from './EventRow';
import EnumPropertyRow from './EnumPropertyRow';
import BorderProperties from './BorderProperties';
import * as applabConstants from '../constants';
import * as elementUtils from './elementUtils';
import * as gridUtils from '../gridUtils';
import designMode from '../designMode';
import themeColor from '../themeColor';
import elementLibrary from './library';
import experiments from '../../util/experiments';

class LabelProperties extends React.Component {
  static propTypes = {
    element: PropTypes.instanceOf(HTMLElement).isRequired,
    handleChange: PropTypes.func.isRequired,
    onDepthChange: PropTypes.func.isRequired
  };

  render() {
    const element = this.props.element;

    return (
      <div id="propertyRowContainer">
        <PropertyRow
          desc={'id'}
          initialValue={elementUtils.getId(element)}
          handleChange={this.props.handleChange.bind(this, 'id')}
          isIdRow
        />
        <PropertyRow
          desc={'text'}
          initialValue={$(element).text()}
          handleChange={this.props.handleChange.bind(this, 'text')}
        />
        <PropertyRow
          desc={'width (px)'}
          isNumber
          lockState={
            $(element).data('lock-width') || PropertyRow.LockState.UNLOCKED
          }
          handleLockChange={this.props.handleChange.bind(this, 'lock-width')}
          initialValue={parseInt(element.style.width, 10)}
          handleChange={this.props.handleChange.bind(this, 'style-width')}
        />
        <PropertyRow
          desc={'height (px)'}
          isNumber
          lockState={
            $(element).data('lock-height') || PropertyRow.LockState.UNLOCKED
          }
          handleLockChange={this.props.handleChange.bind(this, 'lock-height')}
          initialValue={parseInt(element.style.height, 10)}
          handleChange={this.props.handleChange.bind(this, 'style-height')}
        />
        <PropertyRow
          desc={'x position (px)'}
          isNumber
          initialValue={parseInt(element.style.left, 10)}
          handleChange={this.props.handleChange.bind(this, 'left')}
        />
        <PropertyRow
          desc={'y position (px)'}
          isNumber
          initialValue={parseInt(element.style.top, 10)}
          handleChange={this.props.handleChange.bind(this, 'top')}
        />
        <ColorPickerPropertyRow
          desc={'text color'}
          initialValue={elementUtils.rgb2hex(element.style.color)}
          handleChange={this.props.handleChange.bind(this, 'textColor')}
        />
        <ColorPickerPropertyRow
          desc={'background color'}
          initialValue={elementUtils.rgb2hex(element.style.backgroundColor)}
          handleChange={this.props.handleChange.bind(this, 'backgroundColor')}
        />
        <FontFamilyPropertyRow
          initialValue={designMode.fontFamilyOptionFromStyle(
            element.style.fontFamily
          )}
          handleChange={this.props.handleChange.bind(this, 'fontFamily')}
        />
        <PropertyRow
          desc={'font size (px)'}
          isNumber
          initialValue={parseInt(element.style.fontSize, 10)}
          handleChange={this.props.handleChange.bind(this, 'fontSize')}
        />
        <EnumPropertyRow
          desc={'text alignment'}
          initialValue={element.style.textAlign || 'left'}
          options={['left', 'right', 'center', 'justify']}
          handleChange={this.props.handleChange.bind(this, 'textAlign')}
        />
        <BorderProperties
          element={element}
          handleBorderWidthChange={this.props.handleChange.bind(
            this,
            'borderWidth'
          )}
          handleBorderColorChange={this.props.handleChange.bind(
            this,
            'borderColor'
          )}
          handleBorderRadiusChange={this.props.handleChange.bind(
            this,
            'borderRadius'
          )}
        />
        <BooleanPropertyRow
          desc={'hidden'}
          initialValue={$(element).hasClass('design-mode-hidden')}
          handleChange={this.props.handleChange.bind(this, 'hidden')}
        />
        <ZOrderRow
          element={this.props.element}
          onDepthChange={this.props.onDepthChange}
        />
      </div>
    );

    // TODO:
    // bold/italics/underline (p2)
    // textAlignment (p2)
    // enabled (p2)
  }
}

class LabelEvents extends React.Component {
  static propTypes = {
    element: PropTypes.instanceOf(HTMLElement).isRequired,
    handleChange: PropTypes.func.isRequired,
    onInsertEvent: PropTypes.func.isRequired
  };

  getClickEventCode() {
    const id = elementUtils.getId(this.props.element);
    const code =
      'onEvent("' +
      id +
      '", "click", function(event) {\n' +
      '  console.log("' +
      id +
      ' clicked!");\n' +
      '});\n';
    return code;
  }

  insertClick = () => {
    this.props.onInsertEvent(this.getClickEventCode());
  };

  render() {
    const element = this.props.element;
    const clickName = 'Click';
    const clickDesc =
      'Triggered when the label is clicked with a mouse or tapped on a screen.';

    return (
      <div id="eventRowContainer">
        <PropertyRow
          desc={'id'}
          initialValue={elementUtils.getId(element)}
          handleChange={this.props.handleChange.bind(this, 'id')}
          isIdRow
        />
        <EventHeaderRow />
        <EventRow
          name={clickName}
          desc={clickDesc}
          handleInsert={this.insertClick}
        />
      </div>
    );
  }
}

/**
 * This represents the amount of error allowed before we consider a label's size to "fit exactly".
 * This allows for rounding errors for adjusting center aligned labels, as well as allowing users
 * to have a chance of returning to an exact fit.
 */
const STILL_FITS = 5;

const CLASSIC_LABEL_PADDING = '2px';
const NEW_THEME_LABEL_PADDING = '2px 15px';

export default {
  PropertyTab: LabelProperties,
  EventTab: LabelEvents,
  themeValues: {
    backgroundColor: {
      type: 'color',
      ...themeColor.labelBackground
    },
    borderRadius: {
      default: 0,
      orange: 0,
      citrus: 2,
      ketchupAndMustard: 10,
      lemonade: 0,
      forest: 2,
      watermelon: 0,
      area51: 10,
      polar: 2,
      glowInTheDark: 0,
      bubblegum: 10,
      millennial: 4,
      robot: 0,
      classic: 0
    },
    borderWidth: {
      default: 0,
      orange: 0,
      citrus: 0,
      ketchupAndMustard: 0,
      lemonade: 0,
      forest: 0,
      watermelon: 0,
      area51: 0,
      polar: 0,
      glowInTheDark: 0,
      bubblegum: 0,
      millennial: 0,
      robot: 0,
      classic: 0
    },
    borderColor: {
      type: 'color',
      ...themeColor.textInputBorder
    },
    textColor: {
      type: 'color',
      ...themeColor.labelText
    },
    fontFamily: {
      default: 'Arial Black',
      orange: 'Arial',
      citrus: 'Georgia',
      ketchupAndMustard: 'Georgia',
      lemonade: 'Arial Black',
      forest: 'Verdana',
      watermelon: 'Georgia',
      area51: 'Trebuchet',
      polar: 'Verdana',
      glowInTheDark: 'Tahoma',
      bubblegum: 'Georgia',
      millennial: 'Arial',
      robot: 'Tahoma',
      classic: 'Arial'
    },
    fontSize: {
      default: 13,
      orange: 13,
      citrus: 13,
      ketchupAndMustard: 13,
      lemonade: 13,
      forest: 13,
      watermelon: 13,
      area51: 13,
      polar: 13,
      glowInTheDark: 13,
      bubblegum: 13,
      millennial: 13,
      robot: 13,
      classic: 14
    },
    padding: {
      default: NEW_THEME_LABEL_PADDING,
      orange: NEW_THEME_LABEL_PADDING,
      citrus: NEW_THEME_LABEL_PADDING,
      ketchupAndMustard: NEW_THEME_LABEL_PADDING,
      lemonade: NEW_THEME_LABEL_PADDING,
      forest: NEW_THEME_LABEL_PADDING,
      watermelon: NEW_THEME_LABEL_PADDING,
      area51: NEW_THEME_LABEL_PADDING,
      polar: NEW_THEME_LABEL_PADDING,
      glowInTheDark: NEW_THEME_LABEL_PADDING,
      bubblegum: NEW_THEME_LABEL_PADDING,
      millennial: NEW_THEME_LABEL_PADDING,
      robot: NEW_THEME_LABEL_PADDING,
      classic: CLASSIC_LABEL_PADDING
    }
  },

  create: function() {
    const element = document.createElement('label');
    element.style.margin = '0px';
    element.style.lineHeight = '1';
    element.style.overflow = 'hidden';
    element.style.wordWrap = 'break-word';
    element.textContent = 'text';
    element.style.maxWidth = applabConstants.APP_WIDTH + 'px';
    if (experiments.isEnabled('applabThemes')) {
      element.style.borderStyle = 'solid';
      elementLibrary.applyCurrentTheme(element, designMode.activeScreen());
    } else {
      element.style.padding = CLASSIC_LABEL_PADDING;
      element.style.backgroundColor = themeColor.labelBackground.classic;
      element.style.fontFamily = applabConstants.fontFamilyStyles[0];
      element.style.fontSize = applabConstants.defaultFontSizeStyle;
      element.style.color = themeColor.labelText.classic;
      elementUtils.setDefaultBorderStyles(element, {forceDefaults: true});
    }

    this.resizeToFitText(element);
    return element;
  },

  onDeserialize: function(element) {
    // Set background color style for older projects that didn't set them on create:
    if (!element.style.backgroundColor) {
      element.style.backgroundColor = themeColor.labelBackground.classic;
    }
    // Set border styles for older projects that didn't set them on create:
    elementUtils.setDefaultBorderStyles(element);
    // Set the font family for older projects that didn't set them on create:
    elementUtils.setDefaultFontFamilyStyle(element);
  },

  getCurrentSize: function(element) {
    return {
      width: parseInt(element.style.width, 10),
      height: parseInt(element.style.height, 10)
    };
  },

  /**
   * @returns {{width: number, height: number}} Size that this element should be if it were fitted exactly. If there is
   * no text, then the best size is 15 x 15 so that the user has something to drag around.
   */
  getBestSize: function(element) {
    // Start by assuming best fit is current size
    const size = this.getCurrentSize(element);

    const widthLocked =
      $(element).data('lock-width') === PropertyRow.LockState.LOCKED;
    const heightLocked =
      $(element).data('lock-height') === PropertyRow.LockState.LOCKED;

    // Change the size to fit the text.
    if (element.textContent) {
      // Max width depends on alignment.
      let maxWidth;
      if (element.style.textAlign === 'center') {
        maxWidth = applabConstants.APP_WIDTH;
      } else {
        // Note that left may not be defined yet, if this is just now being created.
        const left = parseInt(element.style.left || '0', 10);
        if (element.style.textAlign === 'right') {
          maxWidth = left + size.width;
        } else {
          maxWidth = applabConstants.APP_WIDTH - left;
        }
      }
      const clone = $(element)
        .clone()
        .css({
          position: 'absolute',
          visibility: 'hidden',
          width: 'auto',
          height: 'auto',
          maxWidth: maxWidth + 'px'
        })
        .appendTo($(document.body));

      const {
        horizontalPadding,
        verticalPadding
      } = elementUtils.calculatePadding(element.style.padding);

      if (!widthLocked) {
        // Truncate the width before it runs off the edge of the screen
        size.width = Math.min(clone.width() + 1 + horizontalPadding, maxWidth);
      }
      if (!heightLocked) {
        size.height = clone.height() + 1 + verticalPadding;
      }

      clone.remove();
    } else if (!widthLocked && !heightLocked) {
      // If either width or height are locked, then retain previous size.
      size.width = size.height = 15;
    }
    return size;
  },

  resizeToFitText: function(element) {
    const size = this.getBestSize(element);

    // For center or right alignment, we should adjust the left side to effectively retain that alignment.
    if (
      element.style.textAlign === 'center' ||
      element.style.textAlign === 'right'
    ) {
      let left = parseInt(element.style.left, 10);
      const width = parseInt(element.style.width, 10);
      // Positive delta means that it is getting wider
      const delta = size.width - width;
      if (element.style.textAlign === 'right') {
        left -= delta;
      } else {
        // must be centered
        left -= delta / 2;
      }
      // Don't move text past the left side.
      element.style.left = Math.max(0, left) + 'px';
      if (gridUtils.isDraggableContainer(element.parentNode)) {
        element.parentNode.style.left = element.style.left;
      }
    }
    element.style.width = size.width + 'px';
    element.style.height = size.height + 'px';
  },

  _lastFitsExactly: {},

  /**
   * Returns whether this element perfectly fits its bounding size, if that is needed in onPropertyChange.
   */
  beforePropertyChange: function(element, name, batchChangeId) {
    switch (name) {
      case 'padding':
      case 'text':
      case 'fontFamily':
      case 'fontSize': {
        const {
          batchId = -1,
          previouslyFitExactly: batchPreviouslyFitExactly
        } = this._lastFitsExactly;
        if (batchId === batchChangeId) {
          // We've already computed previouslyFitExactly for this batch of property updates:
          return batchPreviouslyFitExactly;
        }
        const currentSize = this.getCurrentSize(element);
        const bestSize = this.getBestSize(element);
        const previouslyFitExactly =
          Math.abs(currentSize.width - bestSize.width) < STILL_FITS &&
          Math.abs(currentSize.height - bestSize.height) < STILL_FITS;
        this._lastFitsExactly = batchChangeId
          ? {
              batchId: batchChangeId,
              previouslyFitExactly
            }
          : {};
        return previouslyFitExactly;
      }
      default:
        return null;
    }
  },

  /**
   * @returns {boolean} True if it modified the backing element
   */
  onPropertyChange: function(element, name, value, previouslyFitExactly) {
    switch (name) {
      case 'text':
      case 'fontFamily':
      case 'fontSize':
      case 'padding':
        if (previouslyFitExactly) {
          this.resizeToFitText(element);
        }
        break;
      case 'lock-width':
        $(element).data('lock-width', value);
        break;
      case 'lock-height':
        $(element).data('lock-height', value);
        break;
      default:
        return false;
    }
    return true;
  }
};
