# Gamswandkar Cave Survey Project

## What is this?

This repository hosts cave data and drawings of the caves of the Gamswandkar area \[47.790°N 13.681°E 47.795°N 13.686°E\], a karst plateau which is part of the Höllengebirge massif, Upper Austria.
The data presented herein was collected starting July 2021, as part of the Hell's Mountains VIII expedition, run by the Landesverein für Höhlenkunde in Wien und Niederösterreich.


## How to contribute

The cave survey data is stored as plain text files under [Therion] format.

+ Each cave survey data, with map definitions and meta-data about explorers and surveyors can be found at `Cave/Cave.th`.
+ Sketches made in-cave are saved as respective plan/extended elevation scraps in the relevant folders e.g., `Cave/Cave-1p.xvi`.
+ Refined drawings are made using [Inkscape] and the [inkscape-speleo extension](https://github.com/speleo3/inkscape-speleo), which allows the graphics software to open Therion `.th2` files. e.g., `Cave/Cave-1p.th2`.
+ Specific new layout definition files e.g., `detailed-p.thl` are located under the `layouts/` directory.


Most cave survey data was generated using the Android-apps [Topodroid] or [SexyTopo].


[Therion]: https://therion.speleo.sk
[Inkscape]: https://inkscape.org
[SexyTopo]: https://play.google.com/store/apps/details?id=org.hwyl.sexytopo&hl=de_AT&gl=US
[Topodroid]: https://play.google.com/store/apps/details?id=com.topodroid.DistoX&hl=de_AT&gl=US