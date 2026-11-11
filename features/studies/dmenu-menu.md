# dmenu-style menus: suckless dmenu, fuzzel, bemenu, rofi, fsel

Study of dmenu-style menu/picker programs under `refs/`: the suckless reference (`refs/dmenu`), fuzzel's `--dmenu` mode, bemenu, rofi's `-dmenu` mode, and fsel's dmenu mode. Facts only, with file citations. Paths are relative to the repository root, and citations use the form `path:start-end` (for example `refs/dmenu/dmenu.c:549-576`). Line numbers refer to the files as checked out. No decisions are recorded here. No program was run and no network command was used.

Id prefixes: `DM` = suckless dmenu, `FZ` = fuzzel, `BM` = bemenu, `RO` = rofi, `FS` = fsel.

Where the code shows no implementation the entry says "not found". `Partial` in the comparison table means some aspect of the feature is present but not the whole.

---

## 1. suckless dmenu (DM), `refs/dmenu/`

### 1.1 Input protocol

- **DM1.1** Items are read from stdin in `readstdin()` with `getline`, one newline-separated item per line. A trailing `\n` is replaced by `\0` only when the line is non-empty and ends in `\n`; the line is then duplicated into `items[i].text`. `refs/dmenu/dmenu.c:549-576`.
- **DM1.2** The item array grows in chunks of 256 (`itemsiz += 256`); a `realloc` failure calls `die("cannot realloc %zu bytes:")` and an overflow of `SIZE_MAX / sizeof(*items)` calls `die("too many items")`. After the loop a sentinel `items[i].text = NULL` is stored, and `lines` is clamped to the number of items read with `lines = MIN(lines, i)`. `refs/dmenu/dmenu.c:556-575`.
- **DM1.3** Empty lines are not skipped: a line of length 0 (or just `\n`) still becomes an item whose `text` is `strdup("")`. `refs/dmenu/dmenu.c:557-568`.
- **DM1.4** Every item is stored in the `items` singly-linked-array hybrid; `struct item` holds only `text`, `left`, `right`, `out` (no per-item extra data). `refs/dmenu/dmenu.c:31-35`.
- **DM1.5** No delimiter option and no NUL-separated mode. The accepted options are only `-b`, `-f`, `-i`, `-v`, `-l`, `-m`, `-p`, `-fn`, `-nb`/`-nf`, `-sb`/`-sf`, `-ob`/`-of`, `-w`. `refs/dmenu/dmenu.c:736-774`; `refs/dmenu/dmenu.1:5-28`; `refs/dmenu/dmenu.1:42-91`. Searching `refs/dmenu/dmenu.c` and `refs/dmenu/dmenu.1` for `nul`, `sep` and `delimiter` returns nothing.
- **DM1.6** Per-item icons, markup or metadata: not found. Searching `refs/dmenu/dmenu.c`, `refs/dmenu/dmenu.1` and `refs/dmenu/config.def.h` for `icon`, `markup`, `meta` and `preview` returns nothing.
- **DM1.7** Default is a single-line horizontal list (`lines = 0`); a non-zero `-l` gives a vertical list. `refs/dmenu/config.def.h:16-17`; `refs/dmenu/dmenu.c:171-191`.

### 1.2 Output and exit codes

- **DM2.1** Return prints the selected item's text to stdout with `puts` (which appends a newline). `refs/dmenu/dmenu.c:491-493`.
- **DM2.2** Shift-Return prints the typed input `text` instead of the selection, because the chosen expression is `(sel && !(ev->state & ShiftMask)) ? sel->text : text`. `refs/dmenu/dmenu.c:491-493`.
- **DM2.3** Ctrl-Return prints the selection (still `sel->text` unless Shift is also held) and keeps running, marking the item's `out` flag so it is drawn with the `SchemeOut` colours. `refs/dmenu/dmenu.c:494-499`.
- **DM2.4** Accept exits with status 0 (after `cleanup()`). `refs/dmenu/dmenu.c:494-497`; `refs/dmenu/dmenu.c:100-113`.
- **DM2.5** Escape calls `cleanup()` then `exit(1)` (`refs/dmenu/dmenu.c:449-451`). Ctrl-`[` does the same (`refs/dmenu/dmenu.c:390-392`). Ctrl-`c` and Ctrl-`g` are remapped to `XK_Escape` before the switch, so they take the same exit-1 path (`refs/dmenu/dmenu.c:347`; `refs/dmenu/dmenu.c:351`).
- **DM2.6** A `DestroyNotify` for the menu window calls `cleanup()` then `exit(1)`. `refs/dmenu/dmenu.c:587-591`.
- **DM2.7** Index output option: not found. Searching `refs/dmenu/dmenu.c` and `refs/dmenu/dmenu.1` for `index` returns nothing.
- **DM2.8** Multi-select is only the Ctrl-Return "print and continue" behaviour; there is no combined multi-item output at exit and no ballot/selection list. `refs/dmenu/dmenu.c:494-499`.
- **DM2.9** No explicit flush is done: `puts` writes to `stdout`, and every terminating path calls `exit`, which flushes stdio buffers. `refs/dmenu/dmenu.c:493-500`; `refs/dmenu/dmenu.c:449-451`.

### 1.3 CLI flags

- **DM3.1** Flags: `-b` bottom, `-f` grab keyboard before reading stdin, `-i` case-insensitive, `-l lines` vertical list, `-m monitor`, `-p prompt`, `-fn font`, `-nb`/`-nf`/`-sb`/`-sf`/`-ob`/`-of` colors, `-w windowid`, `-v` version. `-v` prints `dmenu-<VERSION>` with `puts` and exits 0 immediately. Options taking an argument are parsed with `atoi` (`-l`, `-m`). An option that is the last argument without a value, or an unknown option, calls `usage()` which calls `die(...)` (stderr + exit 1). `refs/dmenu/dmenu.c:736-774`; `refs/dmenu/dmenu.c:723-727`; `refs/dmenu/dmenu.1:42-91`.
- **DM3.2** Preselected item / initial filter option: not found. The input buffer `text` starts empty (`static char text[BUFSIZ] = ""`). `refs/dmenu/dmenu.c:37`.
- **DM3.3** Password mode: not found. Searching `refs/dmenu/dmenu.c` and `refs/dmenu/dmenu.1` for `password` returns nothing.
- **DM3.4** Placeholder text option: not found. Searching `refs/dmenu/dmenu.c` and `refs/dmenu/dmenu.1` for `placeholder` returns nothing.
- **DM3.5** History: not found. Searching `refs/dmenu/dmenu.c` and `refs/dmenu/dmenu.1` for `history` returns nothing.

### 1.4 Matching and sorting

- **DM4.1** `match()` copies `text` into a local buffer and tokenizes it on single spaces with `strtok(buf, " ")`. An item is kept only if every token is found by `fstrstr` in the item text. Surviving items are appended to three lists in one pass: exact matches (where `fstrncmp(text, item->text, strlen(text)+1)` is 0, comparing the whole input against the item), then prefix matches (where `tokv[0]` is a prefix of the item, compared over `len = strlen(tokv[0])`), then the remaining substring matches. The three lists are then concatenated in the order exact → prefix → substring, preserving the original item order within each bucket. `refs/dmenu/dmenu.c:230-282`.
- **DM4.2** When there are no tokens (`tokc == 0`), every item is an "exact" match and the list keeps input order. `refs/dmenu/dmenu.c:246-263`.
- **DM4.3** Default matching uses case-sensitive `strncmp`/`strstr` (`refs/dmenu/dmenu.c:58-59`). `-i` switches the function pointers to `strncasecmp` and `cistrstr` (`refs/dmenu/dmenu.c:745-747`); `cistrstr` folds bytes through `tolower` (`refs/dmenu/dmenu.c:115-131`).
- **DM4.4** Substring only; no fuzzy, regex, scoring or result sorting: not found. Searching `refs/dmenu/dmenu.c` for `fuzzy`, `regex`, `score` and `sort` returns nothing beyond the three-bucket classification above.
- **DM4.5** After matching, `curr = sel = matches` and `calcoffsets()` computes the visible page. `refs/dmenu/dmenu.c:280-281`.

### 1.5 Keyboard and mouse

- **DM5.1** Fully keyboard controlled; the documented keys are listed in `refs/dmenu/dmenu.1:93-201`. Tab copies the selected item's text into the input field (`strnlen`/`memcpy`, clamped to `sizeof text - 1`) and re-matches. `refs/dmenu/dmenu.c:517-524`.
- **DM5.2** Key handling is a large switch over the keysym with three modifier groups: no modifier, `ControlMask` (`refs/dmenu/dmenu.c:343-395`) and `Mod1Mask` (`refs/dmenu/dmenu.c:396-413`). Notable bindings: `C-k` truncates after the cursor, `C-u` deletes to the start, `C-w` deletes a word (using `worddelimiters`, default `" "`), `C-y`/`C-Y` pastes primary/clipboard, `C-j`/`C-m` become Return, `C-n`/`C-p` become Down/Up, `M-h`/`M-l` become Up/Down, `M-j`/`M-k` become Next/Prior, `M-g`/`M-G` become Home/End. `refs/dmenu/dmenu.c:343-525`; `refs/dmenu/config.def.h:19-23`.
- **DM5.3** No mouse handling: the created window's event mask is only `ExposureMask | KeyPressMask | VisibilityChangeMask`. `refs/dmenu/dmenu.c:694`. Searching `refs/dmenu/dmenu.c` for `ButtonPress`, `PointerMotion`, `ButtonRelease` and `XSelectInput` on the menu window returns nothing beyond the embedding path. The man page states dmenu "is completely controlled by the keyboard". `refs/dmenu/dmenu.1:94`.
- **DM5.4** Two non-key events are handled: `FocusIn` regrabs focus when the focus window is not the menu (`refs/dmenu/dmenu.c:596-600`), and `VisibilityNotify` raises the window when it is not `VisibilityUnobscured` (`refs/dmenu/dmenu.c:608-611`).

### 1.6 UI

- **DM6.1** X11 only, using Xlib and Xft (guarded Xinerama support). `refs/dmenu/dmenu.c:12-18`; window creation `refs/dmenu/dmenu.c:691-708`.
- **DM6.2** Override-redirect window (`swa.override_redirect = True`); placed at the top or bottom of the monitor depending on `topbar`. With Xinerama the width is the chosen monitor's width and the monitor is chosen from `-m`, else from the Xinerama screen intersecting the focused window, else from the pointer position; without Xinerama it uses the embedding/parent window geometry. `refs/dmenu/dmenu.c:638-697`; `refs/dmenu/dmenu.c:741-742`.
- **DM6.3** One font (`monospace:size=10` default) and three color schemes (normal, selected, out), each a foreground/background pair. `refs/dmenu/config.def.h:5-15`.
- **DM6.4** `-w windowid` embeds the menu into another X window with `XReparentWindow` and selects focus. `refs/dmenu/dmenu.c:709-718`; `refs/dmenu/dmenu.c:771-772`.
- **DM6.5** Icons and preview: not found (see DM1.6).

### 1.7 Behaviour on edge cases

- **DM7.1** Stdin is read completely before the menu is set up and shown (`readstdin` then `setup`/`run`), unless `-f` is given and stdin is not a tty, in which case the keyboard is grabbed first and then stdin is read. `refs/dmenu/dmenu.c:797-805`. The man page warns `-f` "will lock up X until stdin reaches end-of-file". `refs/dmenu/dmenu.1:47-49`.
- **DM7.2** On empty input `items` stays NULL (the sentinel write is guarded by `if (items)`), no matches are produced, and the menu shows only the prompt; Return then prints the typed text. `refs/dmenu/dmenu.c:248-282`; `refs/dmenu/dmenu.c:572-575`; `refs/dmenu/dmenu.c:491-493`.
- **DM7.3** Focus handling: `XGrabKeyboard` is retried up to 1000 times (1 ms sleeps) and then `die("cannot grab keyboard")`; `grabfocus` retries input-focus 100 times (10 ms sleeps) and then `die("cannot grab focus")`. Both return early when `embed` is set. `refs/dmenu/dmenu.c:212-228`; `refs/dmenu/dmenu.c:195-210`.
- **DM7.4** Failures (no locale, no display, no embedding-window attributes, no fonts, allocation) call `die` with a message on stderr. `die` also appends `strerror(errno)` when the format ends in `:`, prints a newline, and exits 1. `refs/dmenu/dmenu.c:776-789`; `refs/dmenu/util.c:10-29`.
- **DM7.5** The input field is capped at `sizeof text - 1` = `BUFSIZ - 1` bytes; `insert` silently refuses to grow beyond that. `refs/dmenu/dmenu.c:284-295`.

### 1.8 Process model and result return

- **DM8.1** Single run; no daemon or IPC: not found. Searching `refs/dmenu/dmenu.c` for `daemon`, `fork`, `socket` and `lock` returns nothing.
- **DM8.2** The result is returned as plain text on stdout, which the caller captures. `refs/dmenu/dmenu.c:493`; `refs/dmenu/dmenu.1:33-36`.

---

## 2. fuzzel (FZ), `refs/fuzzel/`, `--dmenu` mode

### 2.1 Input protocol

- **FZ1.1** `--dmenu`/`-d` sets `conf.dmenu.enabled = true`; the delimiter defaults to `'\n'`. `--dmenu0` also enables dmenu mode and sets `conf.dmenu.delim = '\0'`. `refs/fuzzel/main.c:1747-1757`; `refs/fuzzel/config.c:1677-1684`.
- **FZ1.2** Input is streamed: stdin is set `O_NONBLOCK` (error logged, then out) and a `poll` loop reads chunks into a buffer that doubles as needed (`alloc_size` starts at 16384); complete entries are consumed and a final partial line is kept until more data arrives or stdin closes, at which point it is treated as a complete line. Entries are pushed to the application list and an `EVENT_APPS_SOME_LOADED` is sent as they load. `refs/fuzzel/dmenu.c:26-263`; `refs/fuzzel/main.c:607-613`.
- **FZ1.3** Per-item icons use Rofi's extended dmenu protocol: append `\0icon\x1f<icon-name>` after the entry text; the icon name must be non-empty (`extra_len > 6`) and comma-separated fallback names are tried in order. Icons are not supported with `--dmenu0`. `refs/fuzzel/dmenu.c:128-153`; `refs/fuzzel/dmenu.c:299-346`; `refs/fuzzel/doc/fuzzel.1.scd:492-506`. Only `icon` is recognised: searching `refs/fuzzel/dmenu.c` for `display`, `meta`, `info`, `urgent`, `active` and `nonselectable` returns nothing.
- **FZ1.4** `--with-nth` displays chosen columns, `--match-nth` matches on chosen columns, `--nth-delimiter` sets the column character (must be a single ASCII character, default tab). A numeric argument becomes the format `{N}`; a free-form argument is used verbatim; `0` means unset. `refs/fuzzel/main.c:1769-1836`; `refs/fuzzel/doc/fuzzel.1.scd:513-592`.
- **FZ1.5** Every delimited chunk counts as one ordinal position even when dropped (e.g. invalid multibyte data), so `--index` stays aligned; the counter is advanced on the drop path too. `refs/fuzzel/dmenu.c:166-182`.
- **FZ1.6** In dmenu mode `match_fields` is forced to `MATCH_NTH` when `--match-nth` was given and `MATCH_NAME` otherwise. `refs/fuzzel/main.c:2234-2237`.

### 2.2 Output and exit codes

- **FZ2.1** Text mode prints the full input line; when no entry is selected the prompt text is printed instead (`app == NULL` → `prompt_text(prompt)`), and the output is written with `printf("%s\n", text)` only when the multibyte conversion succeeds. `refs/fuzzel/dmenu.c:265-289`.
- **FZ2.2** `--index` prints the selected entry's zero-based index (`printf("%zd\n", index)`). `refs/fuzzel/dmenu.c:291-293`; `refs/fuzzel/doc/fuzzel.1.scd:508-511`.
- **FZ2.3** `--accept-nth` prints only the chosen columns (applied inside `dmenu_execute` before the text is emitted). `refs/fuzzel/wayland.c:657-660`; `refs/fuzzel/dmenu.c:276-280`.
- **FZ2.4** Accept exits 0, or a custom code when a custom keybinding was used; `execute_selected` sets `exit_code` to `custom_success_exit_code` (or `EXIT_SUCCESS`). `refs/fuzzel/wayland.c:648-688`.
- **FZ2.5** Cancel exits 2 in dmenu mode (`BIND_ACTION_CANCEL` sets `status = EXIT` and, when dmenu is enabled, `exit_code = 2`); right-click does the same. `refs/fuzzel/wayland.c:702-706`; `refs/fuzzel/wayland.c:1263-1268`.
- **FZ2.6** Keyboard focus loss exits by default (`exit_on_kb_focus_loss` defaults true); the handler sets `status = EXIT`, and in dmenu mode the process `exit_code` was initialised to `EXIT_FAILURE` (1). `refs/fuzzel/config.c:1727`; `refs/fuzzel/config.c:1044-1045`; `refs/fuzzel/wayland.c:553-554`; `refs/fuzzel/wayland.c:3232`.
- **FZ2.7** Custom keybindings `custom-1`..`custom-19` execute the selection and exit with code `10 + idx` (`idx = action - BIND_ACTION_CUSTOM_1`). `refs/fuzzel/wayland.c:882-904`; `refs/fuzzel/doc/fuzzel.ini.5.scd:666-690`.
- **FZ2.8** `--only-match` forbids custom input and always returns an entry: with no matches the execute binding does nothing; the exception is the `execute-input` binding, which executes the typed input. `refs/fuzzel/wayland.c:826-848`; `refs/fuzzel/doc/fuzzel.1.scd:594-600`.
- **FZ2.9** Multi-select: not found. Searching `refs/fuzzel/dmenu.c`, `refs/fuzzel/main.c`, `refs/fuzzel/config.c`, `refs/fuzzel/wayland.c` and `refs/fuzzel/doc/fuzzel.1.scd` for `multi` returns no multi-select feature.
- **FZ2.10** Output is plain `printf`; each successful emit ends with `\n` and no explicit `fflush` is performed (the process exits normally afterwards). `refs/fuzzel/dmenu.c:282-293`.

### 2.3 CLI flags

- **FZ3.1** dmenu flags: `-d`/`--dmenu`, `--dmenu0` (sets `delim = '\0'`), `--index`, `--with-nth`, `--accept-nth`, `--match-nth`, `--nth-delimiter`, `--only-match`, `--mesg`, `--mesg-mode`, `-R`/`--no-run-if-empty`. `refs/fuzzel/main.c:947-958`; `refs/fuzzel/main.c:442-459`; `refs/fuzzel/main.c:1747-1850`.
- **FZ3.2** Prompt and input flags: `-p`/`--prompt` (default `"> "`), `--prompt-only` (does not wait for stdin in dmenu mode, implies `--lines=0`, disables the match counter and `--no-run-if-empty`, and closes stdin), `--placeholder`, `--search`, `--password[=CHARACTER]` (`*` by default). `refs/fuzzel/main.c:364-369`; `refs/fuzzel/main.c:2239-2244`.
- **FZ3.3** Layout flags: `-l`/`--lines`, `--minimal-lines` (dmenu only; sets the effective line count to `min(apps->count, lines)`), `--hide-prompt`, `-w`/`--width`, `-a`/`--anchor`, `--x-margin`, `--y-margin`, `-x`/`-y`/`-P` padding. `refs/fuzzel/main.c:384-396`; `refs/fuzzel/main.c:687-692`.
- **FZ3.4** Theme flags: font, colors, `--selection-radius`, `-B`/`--border-width`, `-r`/`--border-radius`, `-C`/`--border-color`, `--counter`, `--layer`, `--line-height`, `--letter-spacing`. `refs/fuzzel/main.c:397-427`.
- **FZ3.5** History: not found. Searching `refs/fuzzel/dmenu.c`, `refs/fuzzel/main.c`, `refs/fuzzel/config.c` and `refs/fuzzel/doc/*.scd` for `history` returns only a documentation note that a caller may point `--cache` at a browser-history file, not a history feature.
- **FZ3.6** A `dmenu` symlink makes fuzzel start in dmenu mode without the flag (exact basename comparison `strcmp(name, "dmenu") == 0`). `refs/fuzzel/main.c:1051-1061`; `refs/fuzzel/doc/fuzzel.1.scd:488-490`.

### 2.4 Matching and sorting

- **FZ4.1** Match mode is `exact|fzf|fuzzy`; default is `fzf` (config default `MATCH_MODE_FZF`). The mode is dispatched per token. `refs/fuzzel/config.c:1667`; `refs/fuzzel/match.c:898-925`.
- **FZ4.2** `fzf` is a greedy subsequence match: at each step it scans forward for the longest run of consecutive equal characters and advances past it, so all of the needle must appear in order. `exact` is a `memmem` substring test. `fuzzy` first tries `exact`, then uses a Levenshtein-distance match. `refs/fuzzel/match.c:123-199`; `refs/fuzzel/match.c:115-121`; `refs/fuzzel/match.c:201-229`; `refs/fuzzel/match.c:912-924`.
- **FZ4.3** Ranking tracks a `score` (the longest consecutive match length on the title) and a `word_boundary` flag (whether the first match starts after a space). The comparator orders exact `matched_type` first, then higher score, then word-boundary matches, then fewer match positions. Sorting uses `qsort` when `sort_result` is enabled. `refs/fuzzel/match.c:812-840`; `refs/fuzzel/match.c:1308-1362`; `refs/fuzzel/match.c:1497-1501`; `refs/fuzzel/match.c:1657-1661`.
- **FZ4.4** `--no-sort` disables result sorting (`conf.sort_result = false`). `refs/fuzzel/main.c:1921-1924`.
- **FZ4.5** `--select`/`--select-index` preselect, `--auto-select` accepts a single remaining match. `refs/fuzzel/main.c:379-383`; `refs/fuzzel/main.c:944`; `refs/fuzzel/main.c:1980-1982`.

### 2.5 Keyboard and mouse

- **FZ5.1** Keyboard is handled via libxkbcommon bindings; default bindings are registered by `add_default_key_bindings` (Escape/Ctrl-g/Ctrl-c/Ctrl-[ cancel, etc.), and the action dispatch handles cursor movement, list navigation, execute, execute-input, page movement and the custom-1..19 bindings. `refs/fuzzel/config.c:1530-1634`; `refs/fuzzel/wayland.c:690-912`; `refs/fuzzel/key-binding.c`.
- **FZ5.2** Mouse: left button selects and accepts the clicked row, right button cancels (exit 2 in dmenu mode), middle button pastes the primary selection; scroll moves the selection. `--no-mouse` sets `enable_mouse = false`. When `enable_mouse` is false, `wl_pointer_button` returns immediately. `refs/fuzzel/wayland.c:1242-1274`; `refs/fuzzel/main.c:1984-1987`; `refs/fuzzel/config.c:1053-1054`.

### 2.6 UI

- **FZ6.1** Wayland only, drawn on a `zwlr_layer_shell_v1` surface (bound at registry time, surface created with `zwlr_layer_shell_v1_get_layer_surface`). `refs/fuzzel/wayland.c:2500-2514`; `refs/fuzzel/wayland.c:3299-3302`.
- **FZ6.2** `--layer top|overlay` (default overlay), anchor, margins, width, padding, border width/radius, colors, `--counter`. Layer size/margin/anchor are applied via `zwlr_layer_surface_v1_set_size`/`_set_margin`/`_set_anchor`. `refs/fuzzel/main.c:376-427`; `refs/fuzzel/wayland.c:2092-2102`.
- **FZ6.3** PNG/SVG icons via the icon theme; `-I`/`--no-icons` disables them, and `--icon-theme` picks the theme. `refs/fuzzel/main.c:359-360`; `refs/fuzzel/dmenu.c:128-153`.
- **FZ6.4** Preview: not found. Searching `refs/fuzzel/*.c` and `refs/fuzzel/doc/*.scd` for `preview` returns nothing.

### 2.7 Behaviour on edge cases

- **FZ7.1** `-R`/`--no-run-if-empty` exits immediately without showing the UI when stdin is empty: on `EVENT_APPS_ALL_LOADED`, if `exit_immediately_if_empty && apps->count == 0`, `process_event` returns false and the main loop terminates. `refs/fuzzel/main.c:681-683`; `refs/fuzzel/doc/fuzzel.1.scd:602-604`.
- **FZ7.2** When stdin closes with a final partial line, that chunk is treated as a complete entry (a synthetic delimiter is placed at the end of the buffer). `refs/fuzzel/dmenu.c:116-123`.
- **FZ7.3** Focus loss exits unless `--no-exit-on-keyboard-focus-loss` is given (sets `exit_on_kb_focus_loss = false`). `refs/fuzzel/main.c:1742-1744`; `refs/fuzzel/config.c:1044-1045`; `refs/fuzzel/config.c:1727`.
- **FZ7.4** Errors (stdin non-blocking, poll, read) are reported through `LOG_ERRNO`. `refs/fuzzel/dmenu.c:37-41`; `refs/fuzzel/dmenu.c:58-62`; `refs/fuzzel/dmenu.c:81-85`.
- **FZ7.5** Very long input is handled by doubling the read buffer; invalid-UTF-8 chunks are dropped but still advance the index. `refs/fuzzel/dmenu.c:69-76`; `refs/fuzzel/dmenu.c:157-182`.

### 2.8 Process model and result return

- **FZ8.1** Single run; no daemon or IPC: not found. Searching `refs/fuzzel` for `daemon` returns nothing.
- **FZ8.2** dmenu mode uses its own cache location and does not thrash the normal application cache: `read_cache`/`write_cache` return early when the path is NULL and dmenu is set. `refs/fuzzel/main.c:90-96`; `refs/fuzzel/main.c:218-224`.
- **FZ8.3** The selected text or index is printed to stdout by `dmenu_execute`. `refs/fuzzel/dmenu.c:265-297`.
- **FZ8.4** Single-instance lock: before initialising the UI, fuzzel acquires a non-blocking exclusive `flock` on `$XDG_RUNTIME_DIR/fuzzel-$WAYLAND_DISPLAY.lock`; if the lock cannot be acquired it logs `"failed to acquire lock: fuzzel already running?"` and jumps to the exit path (the lock file is left in place). `refs/fuzzel/main.c:2287-2294`; `refs/fuzzel/main.c:533-560`; `refs/fuzzel/doc/fuzzel.1.scd:692-694`.

---

## 3. bemenu (BM), `refs/bemenu/`

### 3.1 Input protocol

- **BM1.1** Items are read from stdin in a `getline` loop, one newline-separated item per line; a trailing `\n` is replaced by `\0`, and all lines are read before the menu runs. On `ferror(stdin)` it prints `"getline failed"` to stderr and returns. `refs/bemenu/client/bemenu.c:13-39`.
- **BM1.2** No delimiter option and no NUL-separated mode: not found. Searching `refs/bemenu/client` and `refs/bemenu/lib` for `delimiter` and `nul` returns nothing relevant (only the tokenizer's own delimiter documentation). `refs/bemenu/client/common/common.c:164-245`.
- **BM1.3** Per-item extra data (icons, markup, metadata): not found. Searching `refs/bemenu/client` and `refs/bemenu/lib` for `icon`, `markup`, `meta`, `preview` and `placeholder` returns nothing; an item holds only `text` plus an opaque `userdata` pointer. `refs/bemenu/lib/item.c:6-58`; `refs/bemenu/lib/internal.h`.
- **BM1.4** Empty lines are not skipped: a bare `\n` is copied as text `""`. `refs/bemenu/client/bemenu.c:22-31`.
- **BM1.5** `bemenu-run` builds the list from `$PATH` entries: it walks each `PATH` component (defaults `/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/bin:/sbin` when `$PATH` is empty), adds every non-directory, non-dot entry from each directory, `qsort`s the combined list and removes consecutive duplicates. `refs/bemenu/client/bemenu-run.c:37-129`.

### 3.2 Output and exit codes

- **BM2.1** The selected item's text is printed with `printf("%s\n", text)` (or an empty string when the text is NULL) for each item passed to the callback. `refs/bemenu/client/bemenu.c:41-47`.
- **BM2.2** Multi-select: Return/Ctrl-Return/Ctrl-m and `CUSTOM_1..10` add the highlighted item to the menu's selection list (if not already selected); at exit, `run_menu` prints every selected item in the order it was selected. `refs/bemenu/lib/menu.c:1261-1278`; `refs/bemenu/client/common/common.c:689-708`.
- **BM2.3** A normal selection exits 0 (`BM_RUN_RESULT_SELECTED → EXIT_SUCCESS`). `refs/bemenu/client/bemenu.c:64-66`.
- **BM2.4** Custom key bindings `CUSTOM_1`..`CUSTOM_10` exit with codes 10..19. Bound to `M-[1-9]`/`M-0`. `refs/bemenu/client/bemenu.c:68-77`; `refs/bemenu/man/bemenu.1.scd.in:307-313`.
- **BM2.5** Any other result (cancel or error) returns `EXIT_FAILURE` (1). `refs/bemenu/client/bemenu.c:79-81`.
- **BM2.6** Index output option: not found. `-I`/`--index` only preselects a row (it sets `client->selected`, later `bm_menu_set_highlighted_index`). `refs/bemenu/client/common/common.c:180`; `refs/bemenu/client/common/common.c:280`; `refs/bemenu/client/common/common.c:378-380`.
- **BM2.7** When nothing is selected, the filter text can be returned as the selection: Shift-Return (or Insert) frees the selection list and then, if no selected items exist, the filter is copied into `filter_item` and added to the selection (Ctrl-Return paths return `BM_RUN_RESULT_SELECTED`). Escape cancels instead. `refs/bemenu/lib/menu.c:1280-1320`; `refs/bemenu/man/bemenu.1.scd.in:269-275`.
- **BM2.8** Exit status is documented in the man page. `refs/bemenu/man/bemenu.1.scd.in` (EXIT STATUS section).

### 3.3 CLI flags

- **BM3.1** Flags: `-h`/`--help`, `-v`/`--version`, `-i`/`--ignorecase`, `-F`/`--filter`, `-w`/`--wrap`, `-l`/`--list` (with an optional `up` suffix for up-scrolling), `-p`/`--prompt`, `-P`/`--prefix`, `-I`/`--index`, `-x`/`--password`, `-s`/`--no-spacing`, `-C`/`--no-cursor`, `-T`/`--no-touch`, `-K`/`--no-keyboard`, `--binding vim`, `--fixed-height`, `--scrollbar none|always|autohide`, `--counter always`, `-e`/`--vim-esc-exits`, `-N`/`--vim-normal-mode`, `--accept-single`, `--ifne`, `--single-instance`, `--fork`, `--no-exec`, `--auto-select`. `refs/bemenu/client/common/common.c:164-245`; `refs/bemenu/client/common/common.c:265-543`.
- **BM3.2** Backend flags: `-b` bottom, `-c` center, `-f` grab, `-n` no-overlap, `-m` monitor (accepts an index, `focused`, `all` or a monitor name), `-H` line height, `-M` margin, `-W` width factor, `-B` border, `-R` border radius, `--ch`/`--cw` cursor size, `--hp` horizontal padding, `--fn` font, and the full colour set (`--tb`,`--tf`,`--fb`,`--ff`,`--cb`,`--cf`,`--nb`,`--nf`,`--hb`,`--hf`,`--fbb`,`--fbf`,`--sb`,`--sf`,`--ab`,`--af`,`--scb`,`--scf`,`--bdr`). `refs/bemenu/client/common/common.c:206-242`; `refs/bemenu/client/common/common.c:265-334`.
- **BM3.3** Password mode is `none|hide|indicator` (default `none`); an unrecognised value falls back to `none`. `refs/bemenu/client/common/common.c:181`; `refs/bemenu/client/common/common.c:414-416`; `refs/bemenu/lib/bemenu.h:191-200`.
- **BM3.4** Placeholder: no dedicated option; `-f`/`--grab` sets the filter to `"Loading..."`, renders once, then clears the filter, so the temporary text appears before stdin is read. `refs/bemenu/client/common/common.c:609-614`.
- **BM3.5** History: not found. Searching `refs/bemenu/client` and `refs/bemenu/lib` for `history` returns nothing.
- **BM3.6** `BEMENU_OPTS` is parsed first (via `tokenize_quoted_to_argv`), then the command-line arguments. `refs/bemenu/client/common/common.c:549-558`.

### 3.4 Matching

- **BM4.1** Filter modes are `BM_FILTER_MODE_DMENU` and `BM_FILTER_MODE_DMENU_CASE_INSENSITIVE` (plus the enumerator `BM_FILTER_MODE_LAST`, which behaves like `BM_FILTER_MODE_DMENU`). `refs/bemenu/lib/bemenu.h:162-170`.
- **BM4.2** Input is tokenized on spaces and matched as substrings, mirroring the vanilla dmenu filter: every token must match, then survivors are placed into exact matches (whole filter equals the whole item), prefix matches (`tokv[0]` prefix), and the rest, in that order, keeping input order within each bucket. `refs/bemenu/lib/filter.c:46-153`.
- **BM4.3** Fuzzy or regex matching: not found. Searching `refs/bemenu/client` and `refs/bemenu/lib` for `fuzzy` and `regex` returns nothing.
- **BM4.4** `-i` selects the case-insensitive filter mode (`bm_filter_dmenu_case_insensitive`, using `bm_strupstr`/`bm_strnupcmp`). `refs/bemenu/client/common/common.c:353-355`; `refs/bemenu/lib/filter.c:177-181`.
- **BM4.5** When the filter is only extended relative to the previous one, `filter_dmenu_fun` filters the already-filtered item list instead of the full list. `refs/bemenu/lib/filter.c:100-104`.

### 3.5 Keyboard and mouse

- **BM5.1** Keyboard keys are documented in `refs/bemenu/man/bemenu.1.scd.in:255-313`, with an alternative vim binding set (`--binding vim`). Notable: Shift-Tab copies the highlighted item into the filter; Escape/C-g cancel; Ctrl-Return/Ctrl-m print the selection plus the highlighted item; Shift-Return/Insert print the filter; Ctrl-w clears the filter; Ctrl-y/Ctrl-Y paste primary/clipboard. `refs/bemenu/lib/menu.c:1240-1330`; `refs/bemenu/client/common/common.c:525-531`.
- **BM5.2** Pointer and touch can be disabled with `-C`/`--no-cursor` and `-T`/`--no-touch`; keyboard with `-K`/`--no-keyboard`. In `run_menu` the corresponding `poll_*` calls are skipped. `refs/bemenu/client/common/common.c:183-185`; `refs/bemenu/client/common/common.c:678-686`.

### 3.6 UI

- **BM6.1** Multiple renderers: wayland (layer-shell), x11, and curses. The renderer is chosen by `bm_get_renderers`; `BEMENU_BACKEND` (read with `secure_getenv`) forces one by name, otherwise only renderers with priority `BM_PRIO_GUI` are auto-selected. The x11 backend declines auto-selection when `WAYLAND_DISPLAY`/`WAYLAND_SOCKET` is set and `BEMENU_BACKEND` is unset. `refs/bemenu/lib/menu.c:62-90`; `refs/bemenu/lib/renderers/x11/x11.c:280-284`; `refs/bemenu/client/common/common.c:199-207`.
- **BM6.2** Wayland rendering uses `zwlr_layer_surface_v1`: size is set on a configure/render, and anchor/size/margin are applied on window setup. `refs/bemenu/lib/renderers/wayland/window.c:260-291`; `refs/bemenu/lib/renderers/wayland/window.c:361-452`.
- **BM6.3** Theme options include colors, line height, cursor size, border size/radius, scrollbar, counter, spacing, prefix and font. `refs/bemenu/client/common/common.c:206-242`; `refs/bemenu/client/common/common.c:456-524`.
- **BM6.4** Icons and preview: not found (see BM1.3).

### 3.7 Behaviour on edge cases

- **BM7.1** All stdin is read before display; `--grab` renders a `"Loading..."` filter first (see BM3.4). `refs/bemenu/client/bemenu.c:61`; `refs/bemenu/client/common/common.c:609-614`.
- **BM7.2** `--ifne` returns cancel (`BM_RUN_RESULT_CANCEL`, printed by nothing and mapped to `EXIT_FAILURE`) without showing the menu when the filtered item count is 0. `refs/bemenu/client/common/common.c:645-647`.
- **BM7.3** `--accept-single` and `--auto-select` select immediately when one item remains: `--accept-single` does so before the run loop, `--auto-select` is checked at the top of every loop iteration. `refs/bemenu/client/common/common.c:649-652`; `refs/bemenu/client/common/common.c:661-672`.
- **BM7.4** `--single-instance` takes an exclusive `flock` (non-blocking) on `<XDG_RUNTIME_DIR>/bemenu.lock` (or `/tmp/bemenu.lock` when the variable is unset); if the lock is already held it prints `"bemenu instance is already running"` to stderr and exits `EXIT_FAILURE`. `refs/bemenu/client/common/common.c:622-634`.
- **BM7.5** A closed wayland layer surface destroys the surface and calls `exit(1)`. Focus-loss cancel semantics were not found: searching `refs/bemenu/lib/renderers/wayland` for `leave`, `focus` and `cancel` returns no exit-on-focus-loss path. `refs/bemenu/lib/renderers/wayland/window.c:323-330`.

### 3.8 Process model and result return

- **BM8.1** Single run. `--single-instance` is a mutual-exclusion lock, not a daemon. `refs/bemenu/client/common/common.c:622-634`.
- **BM8.2** `bemenu` prints the selection(s) to stdout. `refs/bemenu/client/bemenu.c:41-47`.
- **BM8.3** `bemenu-run` forks by default unless the selected renderer is a terminal backend (`client->fork = force_fork || renderer_priority != BM_PRIO_TERMINAL`); `--fork` forces forking and `--no-exec` prints the selection instead of exec'ing it. When forking, the child calls `setsid` and redirects stdout/stderr to `/dev/null` before `execvp`. `refs/bemenu/client/common/common.c:571`; `refs/bemenu/client/bemenu-run.c:133-172`.

---

## 4. rofi (RO), `refs/rofi/`, `-dmenu` mode

### 4.1 Input protocol

- **RO1.1** Items come from stdin (or `-input`), split by `-sep` (default `'\n'`) using `getdelim` in sync mode. Each segment becomes a `DmenuScriptEntry`. `refs/rofi/source/modes/dmenu.c:246-261`; `refs/rofi/source/modes/dmenu.c:550-556`.
- **RO1.2** Reading is asynchronous by default: `pd->async = TRUE`, a reader thread streams blocks of up to 1024 lines or 0.1 s worth to the UI through a `GAsyncQueue`. `-sync`, `-dump`, `-select`, `-no-custom`, `-only-match`, `-selected-row` or `config.auto_select` force `pd->async = FALSE` (a complete read before showing). `refs/rofi/source/modes/dmenu.c:262-356`; `refs/rofi/source/modes/dmenu.c:536-545`.
- **RO1.3** `-input file` reads from a file instead of stdin, for both async (opened `O_RDONLY | O_NONBLOCK | O_CLOEXEC`) and sync (`fopen`) paths. `refs/rofi/source/modes/dmenu.c:612-627`; `refs/rofi/source/modes/dmenu.c:642-661`.
- **RO1.4** Per-row extras after a NUL are parsed as `key\x1fvalue` pairs by `dmenuscript_parse_entry_extras`: `icon` (comma-separated fallbacks, stored as a string vector), `display`, `meta`, `info`, `nonselectable`, `permanent`, `urgent`, `active`. `nonselectable`/`permanent`/`urgent`/`active` are true only when the value is case-insensitively `"true"`; unknown keys are ignored. `refs/rofi/source/modes/script.c:89-131`; `refs/rofi/source/modes/dmenu.c:130-159`; `refs/rofi/source/modes/dmenu.c:161-195`.
- **RO1.5** Non-UTF-8 row bytes are forced through `rofi_force_utf8` before use. `refs/rofi/source/modes/dmenu.c:155-156`; `refs/rofi/source/modes/dmenu.c:190-191`.
- **RO1.6** `-markup-rows` treats entries as Pango markup; matching strips the markup first with `pango_parse_markup`. `refs/rofi/source/modes/dmenu.c:992-994`; `refs/rofi/source/modes/dmenu.c:683-688`.
- **RO1.7** `-display-columns` and `-display-column-separator` restrict the displayed columns. `-display-columns` splits on commas and defaults the separator to `"\t"`, which `-display-column-separator` (a regex) can override. `refs/rofi/source/modes/dmenu.c:662-667`; `refs/rofi/source/modes/dmenu.c:365-413`.
- **RO1.8** NUL-separated input is possible by choosing a NUL separator: `-sep` is parsed by `find_arg_char` → `helper_parse_char`, whose `case '0'` returns `'\0'`, so `-sep '\0'` sets `pd->separator = '\0'`. `refs/rofi/source/helper.c:383-430`; `refs/rofi/source/modes/dmenu.c:556`.

### 4.2 Output and exit codes

- **RO2.1** The selected entry is printed through the output format, default `"s"`. `refs/rofi/source/modes/dmenu.c:560`; `refs/rofi/source/modes/dmenu.c:812-830`.
- **RO2.2** `-format` letters: `s` selected string, `i` 0-based index, `d` 1-based index, `q` shell-quoted string, `p` markup-stripped string, `f` filter, `F` quoted filter; any other character is printed literally. `rofi_output_formatted_line` writes each item to stdout, then a newline, then flushes. `refs/rofi/source/helper.c:1708-1746`; `refs/rofi/doc/rofi-dmenu.5.markdown:120-133`.
- **RO2.3** `-multi-select` toggles rows: a custom action on a highlighted row flips its bit in `selected_list`, updates a `"n/total"` overlay and moves the selection to the next line; on exit `dmenu_print_results` prints every selected row, each prefixed with the selected or unselected ballot string. `refs/rofi/source/modes/dmenu.c:922-949`; `refs/rofi/source/modes/dmenu.c:812-830`; `refs/rofi/source/modes/dmenu.c:987-990`.
- **RO2.4** Exit codes: `retv == FALSE` → `EXIT_FAILURE` (1); `retv >= 10` → `retv` (custom keybinding); otherwise → `EXIT_SUCCESS` (0). Custom keybindings set `retv = 10 + (mretv & MENU_LOWER_MASK)`. `refs/rofi/source/modes/dmenu.c:800-806`; `refs/rofi/source/modes/dmenu.c:894-896`; `refs/rofi/source/modes/dmenu.c:962-967`; `refs/rofi/doc/rofi-dmenu.5.markdown:224-228`.
- **RO2.5** Custom (typed) input is returned when nothing matches, unless `-only-match`/`-no-custom` (`pd->only_selected`). `refs/rofi/source/modes/dmenu.c:956-960`; `refs/rofi/source/modes/dmenu.c:995-1000`.
- **RO2.6** `-select string` preselects the first match (`helper_token_match` over the item), `-selected-row` selects by index. `refs/rofi/source/modes/dmenu.c:1011-1024`; `refs/rofi/source/modes/dmenu.c:558`.
- **RO2.7** `-dump` prints the filtered list and quits. `refs/rofi/source/modes/dmenu.c:1025-1040`.
- **RO2.8** `nonselectable` rows are never returned: Enter on such a row frees the input and returns without printing. `refs/rofi/source/modes/dmenu.c:886-891`; `refs/rofi/source/modes/dmenu.c:915-921`.

### 4.3 CLI flags

- **RO3.1** Flags: `-dmenu`, `-p prompt`, `-l lines`, `-b` bottom, `-i`, `-sep`, `-input`, `-password`, `-markup-rows`, `-multi-select`, `-sync`, `-only-match`, `-no-custom`, `-select`, `-selected-row`, `-format`, `-u`/`-a` ranges, `-mesg`, `-window-title`, `-w`, `-display-columns`, `-display-column-separator`, `-ballot-selected-str`, `-ballot-unselected-str`, `-ellipsize-mode`, `-keep-right`. `refs/rofi/source/modes/dmenu.c:1071-1126`; `refs/rofi/source/modes/dmenu.c:604-606`; `refs/rofi/source/modes/dmenu.c:1045-1060`.
- **RO3.2** Password mode: `-password` adds `MENU_PASSWORD` to the menu flags, which masks the input. `refs/rofi/source/modes/dmenu.c:1005-1007`.
- **RO3.3** Placeholder option: not found. Searching `refs/rofi/source/modes/dmenu.c` and `refs/rofi/doc/rofi-dmenu.5.markdown` for `placeholder` returns nothing.
- **RO3.4** History: rofi has a history file (`refs/rofi/source/history.c`), but dmenu mode contains no history reference: searching `refs/rofi/source/modes/dmenu.c` for `history` returns nothing.
- **RO3.5** `-b` sets `config.location = 6` (bottom); `-window-title` overrides the mode display name; `-keep-right`/`-ellipsize-mode` set the list ellipsisation. `refs/rofi/source/modes/dmenu.c:594-606`; `refs/rofi/source/modes/dmenu.c:1041-1060`.

### 4.4 Matching and sorting

- **RO4.1** Matching methods: Normal, Regex, Glob, Fuzzy, Prefix (`MM_NORMAL`,`MM_REGEX`,`MM_GLOB`,`MM_FUZZY`,`MM_PREFIX`). They are compiled to GRegexes with the appropriate transformation. `refs/rofi/include/settings.h:38-45`; `refs/rofi/source/helper.c:245-285`.
- **RO4.2** Tokens are matched case-sensitively by default (`config.case_sensitive = TRUE`); `-i` sets `config.case_sensitive = FALSE`. `refs/rofi/source/modes/dmenu.c:607-611`.
- **RO4.3** Each token is compiled to a regex (with the configured method); a leading negate character (`config.matching_negate_char`) sets the matcher's `invert` flag, and a Regex that fails to compile falls back to a literal-escaped regex. `refs/rofi/source/helper.c:245-285`.
- **RO4.4** Sorting methods: normal, fzf, fzf-v2 (`SORT_NORMAL`, `SORT_FZF`, `SORT_FZF_V2`). `refs/rofi/include/settings.h:47-50`.
- **RO4.5** Rows with `permanent == TRUE` always match. Otherwise, when an entry does not match, the hidden `meta` field is tried as a fallback for that token (`test = helper_token_match(ftokens, meta)` when `test == tokens[j]->invert` and a meta value exists). `refs/rofi/source/modes/dmenu.c:678-681`; `refs/rofi/source/modes/dmenu.c:689-709`.

### 4.5 Keyboard and mouse

- **RO4.5a** Keyboard bindings drive the view; custom commands cause exit code `10 + index` (see RO2.4). The full keybind list lives in the main rofi configuration and was not enumerated here. `refs/rofi/source/modes/dmenu.c:894-896`; `refs/rofi/source/modes/dmenu.c:962-967`.
- **RO4.5b** Mouse handling is provided by the display layer and the widget system. Motion and button events are dispatched per scope (`SCOPE_MOUSE_LISTVIEW`, `_LISTVIEW_ELEMENT`, `_EDITBOX`, `_SCROLLBAR`, `_MODE_SWITCHER`) via `widget_find_mouse_target`/`widget_trigger_action`. A click on a listview element invokes `rofi_view_listview_mouse_activated_cb`, which sets `MENU_OK` (or `MENU_CUSTOM_ACTION` for a custom click), records the selected line and quits the view (i.e. click accepts). `refs/rofi/source/view.c:1396-1460`; `refs/rofi/source/view.c:1642-1653`; `refs/rofi/source/view.c:1781-1782`.

### 4.6 UI

- **RO6.1** Two display backends: XCB (X11) and Wayland (`DISPLAY_XCB`, `DISPLAY_WAYLAND`); selectable at build time via the `wayland`/`xcb` meson options. `refs/rofi/include/settings.h:52-55`; `refs/rofi/meson_options.txt:6-7`.
- **RO6.2** The Wayland backend binds `zwlr_layer_shell_v1` (`wl_registry_bind`). The X11 path uses an override-redirect window and takes input focus: `rofi_view_create` calls `display_set_input_focus` when the menu is not a normal window, and `xcb_display_set_input_focus` stores the previous focus for revert and calls `xcb_set_input_focus` (skipped when `config.steal_focus` is not TRUE). `refs/rofi/source/wayland/display.c:1662-1665`; `refs/rofi/source/view.c:1953-1958`; `refs/rofi/source/xcb/display.c:2009-2030`.
- **RO6.3** Appearance comes from rasi themes; the dmenu man page states the basic command-line flags are obeyed but theme-related flags are not. `refs/rofi/doc/rofi-dmenu.5.markdown:14-17`.
- **RO6.4** Icons are fetched per row when a row has an `icon_name` (the fetcher is wired into `dmenu_get_icon`). `refs/rofi/source/modes/dmenu.c:720-769`.
- **RO6.5** Rows can be marked active or urgent by index ranges (`-a`, `-u`; `get_index` allows negative indices relative to the length) or by per-row `active`/`urgent` extras. `refs/rofi/source/modes/dmenu.c:415-470`.
- **RO6.6** Preview: not found. Searching `refs/rofi/source/modes/dmenu.c` and `refs/rofi/doc/rofi-dmenu.5.markdown` for `preview` returns nothing.

### 4.7 Behaviour on edge cases

- **RO7.1** In async mode the UI appears before stdin finishes, showing a `"Loading.. "` overlay while `pd->loading` is set. `refs/rofi/source/modes/dmenu.c:1064-1066`.
- **RO7.2** `-only-match`/`-no-custom` with an empty list returns immediately (no view is created). `refs/rofi/source/modes/dmenu.c:995-1000`.
- **RO7.3** `-auto-select` with a single entry prints it and returns. `refs/rofi/source/modes/dmenu.c:1001-1004`.
- **RO7.4** Failure to open an `-input` file shows an error dialog and returns (both async and sync paths). `refs/rofi/source/modes/dmenu.c:617-625`; `refs/rofi/source/modes/dmenu.c:648-656`.
- **RO7.5** Focus-loss behaviour: the Wayland keyboard `leave` handler is an empty no-op (`// TODO?`), and searching `refs/rofi/source` for `FOCUS_OUT`, `FocusOut`, `focus_out` and `exit-on-focus` finds no exit-on-focus-loss path. rofi does not appear to terminate on focus loss.
- **RO7.6** Async reads grow the line buffer in 2048-byte increments; the leftover partial buffer is flushed as an entry when stdin closes or on a 0.25 s select timeout. `refs/rofi/source/modes/dmenu.c:292-300`; `refs/rofi/source/modes/dmenu.c:322-350`.

### 4.8 Process model and result return

- **RO8.1** Single run; no daemon or IPC: not found. Searching `refs/rofi/source` for a daemon or socket path in dmenu mode returns nothing.
- **RO8.2** dmenu mode is auto-selected when `argv[0]`'s basename is exactly `dmenu` (symlink), or when `-dmenu` is given. `refs/rofi/source/rofi.c:1044-1058`.
- **RO8.3** Results are printed to stdout via the format string and flushed. `refs/rofi/source/helper.c:1708-1746`.

---

## 5. fsel (FS), `refs/fsel/`, dmenu mode

### 5.1 Input protocol

- **FS1.1** dmenu mode requires piped stdin unless `--prompt-only`; all lines are read into memory before the UI starts (`stdin.lock().lines().collect()`). `refs/fsel/src/modes/dmenu/run.rs:23-35`; `refs/fsel/src/modes/dmenu/parse.rs:7-17`.
- **FS1.2** `--dmenu0` reads NUL-separated input, drops empty fields, and is otherwise parsed like newline input. `refs/fsel/src/modes/dmenu/parse.rs:19-32`.
- **FS1.3** Empty or whitespace-only lines are skipped when building items (`.filter(|(_, line)| !line.trim().is_empty())`). `refs/fsel/src/modes/dmenu/parse.rs:40-45`.
- **FS1.4** Lines are split into columns by `--delimiter` (default a single space); `--with-nth` shows a subset of the 1-based columns. `refs/fsel/src/modes/dmenu/parse.rs:35-46`; `refs/fsel/src/cli/types/opts.rs:244`.
- **FS1.5** Per-item icon/markup/metadata protocol: not found. Searching `refs/fsel/src/modes/dmenu` and `refs/fsel/src/cli` for `icon`, `markup`, `meta`, `urgent`, `active` returns nothing for dmenu rows.
- **FS1.6** Each item keeps a 1-based original line number (`Item::new(line, idx + 1, …)`; `line_number` is documented as 1-based). `refs/fsel/src/common/item/mod.rs:10-42`.
- **FS1.7** Invalid UTF-8 is not handled specially in the dmenu path: `lines()` on stdin yields an `io::Error`, which is wrapped as `"Failed to read from stdin"`.

### 5.2 Output and exit codes

- **FS2.1** The selected original line is printed (`item.original_line.clone()`). `refs/fsel/src/modes/dmenu/events.rs:207-217`.
- **FS2.2** `--index` prints the 0-based index within the shown list (`selected.to_string()`); `--index-original` prints the original 1-based line number. `refs/fsel/src/modes/dmenu/events.rs:208-211`.
- **FS2.3** `--accept-nth` prints only the chosen columns (`get_accept_nth_output`). `refs/fsel/src/modes/dmenu/events.rs:212-213`.
- **FS2.4** Typed input is returned when nothing is selected and `--only-match` is not set. `refs/fsel/src/modes/dmenu/events.rs:196-198`.
- **FS2.5** `--only-match`: Enter with no match keeps the menu open (`LoopOutcome::Continue`). `refs/fsel/src/modes/dmenu/events.rs:200-204`.
- **FS2.6** Cancel (the exit binding) returns `LoopOutcome::Exit`, prints nothing, and the process still exits success: dmenu mode always returns `ExitCode::SUCCESS`. There is no distinct cancel exit code. `refs/fsel/src/modes/dmenu/events.rs:15-31`; `refs/fsel/src/modes/dmenu/run.rs:178-182`; `refs/fsel/src/app/mod.rs:32-35`; `refs/fsel/src/main.rs:3-11`.
- **FS2.7** Custom exit-code keys: not found. Searching `refs/fsel/src/modes/dmenu` and `refs/fsel/src/cli` for custom exit codes returns nothing.
- **FS2.8** Multi-select: not found. Searching `refs/fsel/src/modes/dmenu` for `multi` returns only multiline-layout code.
- **FS2.9** Output is written with `println!` (adds a newline). `refs/fsel/src/modes/dmenu/run.rs:178-180`.

### 5.3 CLI flags

- **FS3.1** dmenu flags: `--dmenu`, `--dmenu0`, `--password[=CHAR]`, `--index`, `--index-original`, `--with-nth`, `--accept-nth`, `--match-nth`, `--delimiter`, `--only-match`, `--exit-if-empty`, `--select`, `--select-index`, `--auto-select`, `--prompt-only`, `--preview`, `--panel`, `--panel-edit`. `refs/fsel/src/cli/help.rs:145-163`; `refs/fsel/src/cli/parse/overrides.rs:146-217`.
- **FS3.2** `-ss SEARCH` pre-fills the search box (`ui.query = search.clone()`). `refs/fsel/src/cli/help.rs:110`; `refs/fsel/src/modes/dmenu/run.rs:198-200`.
- **FS3.3** A prompt string flag: not found. The input panel title is fixed to `" Input "` in prompt-only mode and `" Filter "` otherwise. `refs/fsel/src/modes/dmenu/options.rs:133-139`.
- **FS3.4** History in dmenu mode: not found. Searching `refs/fsel/src/modes/dmenu` and `refs/fsel/src/ui/dmenu_ui` for `history` returns only clipboard-preview test code, not a dmenu history feature.
- **FS3.5** Password mode uses `--password[=CHAR]`, masking each character with the mask character (`*` by default). `refs/fsel/src/modes/dmenu/options.rs:141-145`.

### 5.4 Matching and sorting

- **FS4.1** `--match-mode` selects fuzzy or exact (default fuzzy); fuzzy uses the `nucleo` matcher. `refs/fsel/src/cli/help.rs:142`; `refs/fsel/src/modes/dmenu/run.rs:195`; `refs/fsel/src/ui/dmenu_ui/filter.rs:1-27`.
- **FS4.2** `--match-nth` restricts matching to chosen columns (`calculate_score_with_match_nth`). `refs/fsel/src/ui/dmenu_ui/filter.rs:12-17`.
- **FS4.3** Shown items are sorted by score descending, tie-broken by ascending line number. `refs/fsel/src/ui/dmenu_ui/filter.rs:71-72`; `refs/fsel/src/common/item/mod.rs:90-97`.
- **FS4.4** `--select` preselects the first case-insensitive contains-match; `--select-index` preselects by index (only if in range). `refs/fsel/src/modes/dmenu/run.rs:204-216`.
- **FS4.5** `--auto-select` selects when the filtered list reaches one row. `refs/fsel/src/modes/dmenu/events.rs:219-223`.

### 5.5 Keyboard and mouse

- **FS5.1** Key bindings are configurable; defaults handle exit, select, backspace, left/right/up/down. Special keys (Esc, Enter, Backspace, arrows) are tried first with the configured modifier and then with `KeyModifiers::NONE` as a fallback. `refs/fsel/src/modes/dmenu/events.rs:15-126`.
- **FS5.2** Mouse: motion highlights the hovered row, left click prints the selection, scroll up/down moves the scroll offset (and re-highlights). `--disable-mouse` / `--dmenu-disable-mouse` disables pointer input. `refs/fsel/src/modes/dmenu/events.rs:148-185`; `refs/fsel/src/modes/dmenu/options.rs:62`.
- **FS5.3** Keyboard focus-loss handling: not found (terminal application; searching `refs/fsel/src/modes/dmenu` and `refs/fsel/src/ui` for `focus` returns no focus-loss path).

### 5.6 UI

- **FS6.1** Terminal UI using ratatui and crossterm, drawn on stderr (`CrosstermBackend::new(io::stderr())`); not layer-shell or X11. `refs/fsel/src/modes/dmenu/run.rs:65-68`.
- **FS6.2** Panels: information, items, input, plus custom command panels and a preview command; a graphics adapter detects terminal image protocols (via `ratatui-image` `Picker`). `refs/fsel/src/modes/dmenu/options.rs:10-55`; `refs/fsel/src/ui/graphics.rs:1-60`.
- **FS6.3** Options include colors, borders, radius, selection marker, layout rotation, item width and padding. `refs/fsel/src/modes/dmenu/options.rs:23-52`.
- **FS6.4** Icons: desktop icons exist for launcher mode; dmenu rows carry no icon data (see FS1.5). Preview is a command run per selected row (`--preview`, supporting `{{}}`, `{{q}}`, `{{n}}`). `refs/fsel/src/cli/help.rs:160`.

### 5.7 Behaviour on edge cases

- **FS7.1** `--exit-if-empty` quits (returns `Ok(())`) when stdin is empty or all lines are blank. `refs/fsel/src/modes/dmenu/run.rs:37-45`.
- **FS7.2** Stdin is fully read before the UI starts, so there is no early-close streaming; a final partial line is a normal line. `refs/fsel/src/modes/dmenu/parse.rs:13-17`.
- **FS7.3** Unless `--prompt-only`, a non-piped stdin is an error: `"dmenu mode requires input from stdin"`. `refs/fsel/src/modes/dmenu/run.rs:23-26`.
- **FS7.4** Failures print the error (`eprintln!("{error:?}")`) and exit 1. `refs/fsel/src/main.rs:3-11`.
- **FS7.5** Terminal state is restored on exit via a scopeguard (`defer!`) and a final `shutdown_terminal`. `refs/fsel/src/modes/dmenu/run.rs:56-63`; `refs/fsel/src/modes/dmenu/run.rs:174-176`.

### 5.8 Process model and result return

- **FS8.1** Single run; no daemon or IPC: not found. Searching `refs/fsel/src` for a daemon/socket path returns nothing.
- **FS8.2** dmenu mode is auto-enabled when `argv[0]` ends with `dmenu` (`program_name.ends_with("dmenu")`). `refs/fsel/src/cli/parse.rs:26-33`; `refs/fsel/create_dmenu_symlink.sh`.
- **FS8.3** The result is printed with `println!`. `refs/fsel/src/modes/dmenu/run.rs:178-180`.

---

## 6. Comparison

Yes means the feature is present in the cited code. No means nothing was found in the cited paths. Partial means some part is present but not the whole.

| Feature | DM | FZ | BM | RO | FS |
|---|---|---|---|---|---|
| Newline-separated stdin input | Yes (DM1.1) | Yes (FZ1.1) | Yes (BM1.1) | Yes (RO1.1) | Yes (FS1.1) |
| NUL-separated input | No | Yes (FZ1.1, `--dmenu0`) | No | Yes (RO1.8, `-sep '\0'`) | Yes (FS1.2, `--dmenu0`) |
| Custom input delimiter | No | No | No | Yes (RO1.1, `-sep`) | Yes (FS1.4, `--delimiter`) |
| Per-item icons / extra data | No | Yes (FZ1.3, icon only) | No | Yes (RO1.4) | No |
| Markup rows | No | No | No | Yes (RO1.6) | No |
| Column (nth) display/output/match | No | Yes (FZ1.4, FZ2.3) | No | Yes (RO1.7) | Yes (FS1.4, FS2.3, FS4.2) |
| Output selected text | Yes (DM2.1) | Yes (FZ2.1) | Yes (BM2.1) | Yes (RO2.1) | Yes (FS2.1) |
| Index output | No | Yes (FZ2.2) | No | Yes (RO2.2) | Yes (FS2.2) |
| Output format string | No | No | No | Yes (RO2.2) | No |
| Multi-select | Partial (DM2.8, print-and-continue) | No | Yes (BM2.2) | Yes (RO2.3) | No |
| Custom exit-code keys | Yes (DM2.5, cancel key only) | Yes (FZ2.7, 10-28) | Yes (BM2.4, 10-19) | Yes (RO2.4, 10-28) | No |
| Distinct cancel exit code | Yes (DM2.5, 1) | Yes (FZ2.5, 2) | Yes (BM2.5, 1) | Yes (RO2.4, 1) | No (FS2.6, exits 0) |
| Prompt flag | Yes (DM3.1) | Yes (FZ3.2) | Yes (BM3.1) | Yes (RO3.1) | No (FS3.3) |
| Preselect / initial filter | No (DM3.2) | Yes (FZ3.2, FZ4.5) | Yes (BM3.1, BM3.4) | Yes (RO2.6) | Yes (FS4.4) |
| Case-insensitive flag | Yes (DM3.1) | No (`--match-mode` only) | Yes (BM3.1) | Yes (RO3.1) | Partial (`--match-mode` exact/fuzzy) |
| Line-count flag | Yes (DM3.1, `-l`) | Yes (FZ3.3, `-l`) | Yes (BM3.1, `-l`) | Yes (RO3.1, `-l`) | Partial (panel height options) |
| Password mode | No | Yes (FZ3.2) | Yes (BM3.3) | Yes (RO3.2) | Yes (FS3.1, FS3.5) |
| Placeholder | No | Yes (FZ3.2) | Partial (BM3.4) | No | No |
| Tokenized substring match | Yes (DM4.1) | Yes (FZ4.1 exact) | Yes (BM4.2) | Yes (RO4.1 Normal) | Yes (FS4.1 exact) |
| Fuzzy match | No | Yes (FZ4.1) | No | Yes (RO4.1) | Yes (FS4.1) |
| Regex match | No | No | No | Yes (RO4.1) | No |
| Score-based ranking / sort | No | Yes (FZ4.3) | No | Yes (RO4.4) | Yes (FS4.3) |
| History | No | No | No | No (dmenu mode) | No |
| Mouse support | No (DM5.3) | Yes (FZ5.2) | Yes (BM5.2, can disable) | Yes (RO4.5b) | Yes (FS5.2) |
| Wayland layer-shell UI | No | Yes (FZ6.1) | Yes (BM6.2) | Yes (RO6.2) | No |
| X11 UI | Yes (DM6.1) | No | Yes (BM6.1) | Yes (RO6.1) | No |
| Terminal UI | No | No | Yes (BM6.1 curses) | No | Yes (FS6.1) |
| Icons | No | Yes (FZ6.3) | No | Yes (RO6.4) | No (dmenu mode) |
| Preview | No | No | No | No | Yes (FS6.4, command preview) |
| Empty-input fast exit | No | Yes (FZ7.1, `-R`) | Yes (BM7.2, `--ifne`) | Yes (RO7.2) | Yes (FS7.1) |
| Exits on keyboard focus loss | No (keyboard grab) | Yes (FZ7.3) | No (BM7.5) | No (RO7.5) | No (FS5.3) |
| Streams stdin while showing | No (DM7.1) | Yes (FZ1.2) | No (BM7.1) | Yes (RO1.2) | No (FS7.2) |
| Single-instance / daemon | No | Partial (FZ8.4 lock) | Partial (BM7.4 lock) | No | No |
| Error output on failure | Yes (DM7.4, `die`) | Yes (FZ7.4, log) | Yes (BM7.4, stderr) | Yes (RO7.4, dialog) | Yes (FS7.4, stderr) |

Note: dmenu has no custom exit codes beyond its cancel key; the table marks DM custom keys as the Escape/Ctrl-`[` failure path only. rofi's mouse handling is now cited (RO4.5b) and its focus-loss behaviour (RO7.5) was resolved to "not found" by search.
