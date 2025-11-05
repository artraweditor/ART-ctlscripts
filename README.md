# README

This repository contains a list of [custom CTL scritps](https://artraweditor.github.io/Luts) plugins for the [ART](https://artraweditor.github.io) raw processor.

## Installation in ART

Each script can be loaded as a LUT in ART. In order to make it available automatically, it can simply be copied to the `ctlscripts` directory in the ART config folder (e.g. on Linux that would be `$HOME/.config/ART/ctlscripts`).
Note that many of the scripts depend also on the `_artlib.ctl` auxiliary library, so make sure to copy also that when installing.

## License

[GNU GPLv3](https://www.gnu.org/licenses/gpl-3.0.html)

## Available scripts

- `colormix.ctl`: mixes a user-selected RGB color with the image, using
  various blending modes

- `density.ctl`: increase saturation while also lowering luminance, emulating
  ["film density" filters available for some video editors](https://filmmakingelements.com/davinci-resolve-color-density-dctl/)

- `gamutcompress.ctl`: gamut compression using [the ACES method](https://github.com/jedypod/gamut-compress)

- `hueeq.ctl`: adjust the hue, saturation or luminance of each pixel
  according to its hue

- `lumeq.ctl`: adjust the hue, saturation or luminance of each pixel
  according to its luminance

- `odt.ctl`: ART's take on tone mapping from scene to display

- `posterize.ctl`: simulates a posterization effect given by reducing the bit
  depth of the image

- `sateq.ctl`: adjust the hue, saturation or luminance of each pixel
  according to its saturation

- `submix.ctl`: mixes a user-selected RGB color with the image
  [in a subtractive manner](http://scottburns.us/subtractive-color-mixture/)
  (i.e. as if the two colors were mixed like paint colors)

- `tetrahsl.ctl`:
  [color warping by means of tetrahedral division of the RGB color cube](https://drive.google.com/file/d/1h5BE2qGgxyKpEMC3hM1brolZkv28vagz/view?usp=sharing),
  using a HSL interface

- `tetrargb.ctl`: tetrahedral color warping using the original RGB interface

- `tinteq.ctl`: add a color cast to each pixel according to its luminance

- `wbchmix.ctl`: white balance and RGB primaries correction
