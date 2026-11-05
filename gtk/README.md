# GTK

GTK-specific theme integration belongs here.

The implementation should consume the shared style vocabulary from [`STYLE.md`](../STYLE.md) and avoid defining an independent color, shape, or typography system.

Future GTK output must explicitly set project-owned control corners to zero, preserve visible keyboard focus, and use the shared semantic colors. A GTK application theme renderer is not implemented yet; the shell's QML style does not automatically theme GTK applications.
