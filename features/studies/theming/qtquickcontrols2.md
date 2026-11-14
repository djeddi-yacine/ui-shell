# qtquickcontrols2: standalone Qt Quick Controls 2 repo (moved into qtdeclarative; checkout holds only a README)

Source: refs/qtquickcontrols2 (shallow clone; commit 809339d, 2021-08-16; branch dev, origin/HEAD -> origin/dev). License: none found in this checkout (no LICENSE or COPYING file; the file list is the single file `README.md`). Scope: whole repo (1 tracked file).
Id prefix: QC.

## 1. Purpose and shape
- QC1.1 The repo's only tracked file is `README.md` (`git ls-files` returns one entry). It states that the Qt Quick Controls 2 module "has been moved into qtdeclarative.git". `README.md:3`
- QC1.2 Top-level layout: `README.md` only. No source, CMake, QML or style files are present in the checkout.
- QC1.3 Build system and dependencies: none in this checkout. The module's build lives in `qtdeclarative` (see `features/studies/theming/qtdeclarative.md`, QD1.3).
- QC1.4 Version: the checkout's only commit is dated 2021-08-16 (`git log -1 --format=%cs`). No Qt version string is present in the checkout.

## 2. Theme input (how configuration reaches it)
- QC2.1 None in this checkout. The README gives no config keys, environment variables or settings APIs.

## 3. Color and style model
- QC3.1 None in this checkout. The palette and style code is in `qtdeclarative/src/quickcontrols/` (see the qtdeclarative study).

## 4. Output and rendering path
- QC4.1 None in this checkout.

## 5. Extension and integration points
- QC5.1 None in this checkout. The README gives a history-recovery procedure only: `git checkout -b my-dev dev~1` restores the code "prior to its removal" from the `dev` branch. `README.md:17-22`
- QC5.2 The README links the motivation in QTBUG-79454 (`README.md:9`) and a Qt contributor-summit page (`README.md:13`, wiki link under "There was then a contributor summit session:" at line 11).

## 6. Data and tooling
- QC6.1 None in this checkout.

## 7. Facts of note
- QC7.1 The README states the conclusion of the contributor-summit session: "The conclusion from this was that the best solution would be to move qtquickcontrols2 into qtdeclarative." Verbatim at `README.md:15`. Verified text only.
- QC7.2 Because only one commit is present (grafted clone), the earlier `dev` history that the README points to is NOT in this checkout. UNVERIFIED: whether `dev~1` exists in the upstream repo; the local clone has no parent commits (`git rev-list --count HEAD` returns 1).

## 8. Not covered
- The code history before the move was not available in this shallow clone, so no style code was studied here. For the style implementation, use the qtdeclarative study (`features/studies/theming/qtdeclarative.md`), which covers the same module as merged into Qt 6.13.0-alpha1.
- The QTBUG and contributor-summit links were not opened (no network access used).
