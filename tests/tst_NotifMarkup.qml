import QtQuick
import QtTest
import "../shell/modules/notifications/NotifMarkup.js" as M

TestCase {
    name: "NotifMarkup"

    function test_allowed_tags_pass() {
        compare(M.toStyled("<b>a</b> <i>b</i> <u>c</u>"), "<b>a</b> <i>b</i> <u>c</u>")
    }
    function test_other_tags_are_escaped() {
        compare(M.toStyled("<font color=red>x</font>"), "&lt;font color=red&gt;x&lt;/font&gt;")
        compare(M.toStyled("<h1>t</h1>"), "&lt;h1&gt;t&lt;/h1&gt;")
    }
    function test_image_becomes_its_alt_text_and_never_loads() {
        compare(M.toStyled('<img src="file:///x.png" alt="chart"/>!'), "chart!")
        verify(M.toStyled('<img src="http://x/y.png"/>').indexOf("<img") < 0)
    }
    function test_links_keep_safe_targets_only() {
        compare(M.toStyled('<a href="https://x.org/?a=1&amp;b=2">go</a>'), '<a href="https://x.org/?a=1&amp;b=2">go</a>')
        compare(M.toStyled('<a href="javascript:alert(1)">go</a>'), "go")
        verify(M.openable("mailto:a@b.c"))
        verify(!M.openable("javascript:alert(1)"))
    }
    function test_stray_symbols_and_entities() {
        compare(M.toStyled("a < b & c &amp; d"), "a &lt; b &amp; c &amp; d")
    }
    function test_unbalanced_tags_are_closed() {
        compare(M.toStyled("<b>x<i>y"), "<b>x<i>y</i></b>")
        compare(M.toStyled("x</b>"), "x")
    }
    function test_plain() { compare(M.toPlain("<b>a</b>b"), "ab") }
}
