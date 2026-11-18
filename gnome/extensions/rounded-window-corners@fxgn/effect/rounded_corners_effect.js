/** @file Binds the actual corner rounding shader to the windows. */
var _a;
import Clutter from 'gi://Clutter';
import Cogl from 'gi://Cogl';
import GObject from 'gi://GObject';
import { readShader } from '../utils/file.js';
import { getPref } from '../utils/settings.js';
const [declarations, code] = readShader(import.meta.url, 'shader/rounded_corners.frag');
export const RoundedCornersEffect = GObject.registerClass({}, class Effect extends Clutter.ShaderEffect {
    vfunc_get_static_snippet() {
        const snippet = Cogl.Snippet.new(Cogl.SnippetHook.FRAGMENT, declarations, '');
        snippet.set_post(code);
        return snippet;
    }
    /**
     * Update uniforms of the shader.
     * For more information, see the comments in the shader file.
     *
     * @param scaleFactor - Desktop scaling factor
     * @param config - Rounded corners configuration
     * @param windowBounds - Bounds of the window without padding
     * @param borderColor - Border color to use for this window
     */
    updateUniforms(scaleFactor, config, windowBounds, borderColor) {
        const separateBorderWidths = getPref('separate-border-widths');
        const borderWidth = getPref('border-width') * scaleFactor;
        let innerBorderWidth;
        let outerBorderWidth;
        if (separateBorderWidths) {
            innerBorderWidth = borderWidth;
            outerBorderWidth =
                getPref('secondary-border-width') * scaleFactor;
        }
        else {
            innerBorderWidth = borderWidth > 0 ? borderWidth : 0;
            outerBorderWidth = borderWidth < 0 ? -borderWidth : 0;
        }
        const outerRadius = config.borderRadius * scaleFactor;
        const { padding, smoothing } = config;
        const bounds = [
            windowBounds.x1 + padding.left * scaleFactor,
            windowBounds.y1 + padding.top * scaleFactor,
            windowBounds.x2 - padding.right * scaleFactor,
            windowBounds.y2 - padding.bottom * scaleFactor,
        ];
        const innerBorderedAreaBounds = [
            bounds[0] + innerBorderWidth,
            bounds[1] + innerBorderWidth,
            bounds[2] - innerBorderWidth,
            bounds[3] - innerBorderWidth,
        ];
        let innerBorderedAreaRadius = outerRadius - innerBorderWidth;
        if (innerBorderedAreaRadius < 0.001) {
            innerBorderedAreaRadius = 0.0;
        }
        const outerBorderedAreaBounds = [
            bounds[0] - outerBorderWidth,
            bounds[1] - outerBorderWidth,
            bounds[2] + outerBorderWidth,
            bounds[3] + outerBorderWidth,
        ];
        let outerBorderedAreaRadius = outerRadius + outerBorderWidth;
        if (outerBorderedAreaRadius < 0.001) {
            outerBorderedAreaRadius = 0.0;
        }
        const pixelStep = [
            1 / this.actor.get_width(),
            1 / this.actor.get_height(),
        ];
        // This is needed for squircle corners
        let exponent = smoothing * 10 + 2;
        let radius = outerRadius * 0.5 * exponent;
        const maxRadius = Math.min(bounds[3] - bounds[0], bounds[4] - bounds[1]);
        if (radius > maxRadius) {
            exponent *= maxRadius / radius;
            radius = maxRadius;
        }
        innerBorderedAreaRadius *= radius / outerRadius;
        outerBorderedAreaRadius *= radius / outerRadius;
        this.#setUniforms(bounds, radius, innerBorderWidth, outerBorderWidth, borderColor, innerBorderedAreaBounds, innerBorderedAreaRadius, outerBorderedAreaBounds, outerBorderedAreaRadius, pixelStep, exponent);
    }
    #setUniforms(bounds, radius, innerBorderWidth, outerBorderWidth, borderColor, innerBorderedAreaBounds, innerBorderedAreaRadius, outerBorderedAreaBounds, outerBorderedAreaRadius, pixelStep, exponent) {
        this.set_uniform_float('bounds', 4, bounds);
        this.set_uniform_float('clipRadius', 1, [radius]);
        this.set_uniform_float('innerBorderWidth', 1, [
            innerBorderWidth,
        ]);
        this.set_uniform_float('outerBorderWidth', 1, [
            outerBorderWidth,
        ]);
        this.set_uniform_float('borderColor', 4, borderColor);
        this.set_uniform_float('innerBorderedAreaBounds', 4, innerBorderedAreaBounds);
        this.set_uniform_float('innerBorderedAreaClipRadius', 1, [
            innerBorderedAreaRadius,
        ]);
        this.set_uniform_float('outerBorderedAreaBounds', 4, outerBorderedAreaBounds);
        this.set_uniform_float('outerBorderedAreaClipRadius', 1, [
            outerBorderedAreaRadius,
        ]);
        this.set_uniform_float('pixelStep', 2, pixelStep);
        this.set_uniform_float('exponent', 1, [exponent]);
        this.queue_repaint();
    }
});
