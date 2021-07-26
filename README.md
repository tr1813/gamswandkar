# Gamswandkar Cave Survey Project

## What is this?

This repository hosts cave data and drawings of the caves of the Gamswandkar area \[47.790°N 13.681°E 47.795°N 13.686°E\], a karst plateau which is part of the Höllengebirge massif, Upper Austria.
The data presented herein was collected starting July 2021, as part of the Hell's Mountains VIII expedition, run by the Landesverein für Höhlenkunde in Wien und Niederösterreich.

## How to contribute

### Structure of the repository
The cave survey data is stored as plain text files under [Therion] format.

+ Each cave survey data, with map definitions and meta-data about explorers and surveyors can be found at `Cave/Cave.th`.
+ Sketches made in-cave are saved as respective plan/extended elevation scraps in the relevant folders e.g., `Cave/Cave-1p.xvi`.
+ Refined drawings are made using [Inkscape] and the [inkscape-speleo extension](https://github.com/speleo3/inkscape-speleo), which allows the graphics software to open Therion `.th2` files. e.g., `Cave/Cave-1p.th2`.
+ Specific new layout definition files e.g., `detailed-p.thl` are located under the `layouts/` directory.

Most cave survey data was generated using the Android-apps [Topodroid] or [SexyTopo].

### Prerequisites
To work on the files, you will need to install:
+ [Therion], the main package, which reads plain text data and drawing files to compile among other things the pretty maps [full map].
+ [Survex], used by Therion to produce .3d files
+ [Inkscape] and its extensions.

Optionally, you may also install:
+[VSCode]
+ its [Therion extension] developed by GitHub contributor [rhyst]. 

These offer very nifty code completion and syntax highlighting capabilities.

### Summary workflow

In order to add to the cave drawings, in particular, the overview map of the cave area, you will need to complete the following steps:

1. Create a new `data/Cave` folder.
2. Import a data file (`.th` file) under `data/Cave/Cave.th`.
3. Import sketches made in cave under e.g.:  `data/Cave/Cave-1p.xvi` for the first scrap in plan projection.
4. Work on a refined drawing in a file called `data/Cave/Cave-1p.th2`.
5. Add the drawn map to the overview data file `data/gamswandkar.th`

[Therion]: https://therion.speleo.sk
[Inkscape]: https://inkscape.org
[SexyTopo]: https://play.google.com/store/apps/details?id=org.hwyl.sexytopo&hl=de_AT&gl=US
[Topodroid]: https://play.google.com/store/apps/details?id=com.topodroid.DistoX&hl=de_AT&gl=US
[VSCode]: https://code.visualstudio.com/Download
[Therion extension]: https://marketplace.visualstudio.com/items?itemName=rhystyers.therion
[Survex]: https://survex.com/download.html
[rhyst]: https://github.com/rhyst
[full map]: https://github.com/tr1813/gamswandkar/blob/9240b1784eed24136aa4d47a432c32c3066d5c6d/outputs/gamswandkar-p.pdf

