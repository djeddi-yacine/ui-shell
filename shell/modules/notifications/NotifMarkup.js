.pragma library

// Notification body markup (freedesktop Notifications spec, section 4) turned into the StyledText
// subset Qt draws: <b>, <i>, <u>, <a href> and <img> (shown as its alt text, never loaded).
// Everything else is escaped, so a sender can never reach a tag Qt would act on (fonts, images,
// headings). Links keep only http, https, mailto and file targets.

const entity = /^&(amp|lt|gt|quot|apos|#[0-9]+|#x[0-9a-fA-F]+);/
const tag = /^<(\/?)(b|i|u|a|img)(\s[^<>]*)?(\/?)>/i
const safeLink = /^(https?:\/\/|mailto:|file:\/\/)[^\s"'<>]+$/i

function attribute(text, name) {
    const match = new RegExp("\\b" + name + "\\s*=\\s*(\"([^\"]*)\"|'([^']*)')", "i").exec(text ?? "")
    return match ? (match[2] ?? match[3]) : ""
}
function escapeText(text) {
    return text.replace(/&(?!(amp|lt|gt|quot|apos|#[0-9]+|#x[0-9a-fA-F]+);)/g, "&amp;")
               .replace(/</g, "&lt;").replace(/>/g, "&gt;")
}

// Returns StyledText for `body`. Unbalanced <b>, <i>, <u>, <a> are closed at the end.
function toStyled(body) {
    let out = ""
    const open = []
    let at = 0
    const text = String(body ?? "")
    while (at < text.length) {
        const rest = text.slice(at)
        if (rest[0] === "<") {
            const match = tag.exec(rest)
            if (match) {
                const closing = match[1] === "/"
                const name = match[2].toLowerCase()
                at += match[0].length
                if (name === "img") {
                    if (!closing) out += escapeText(attribute(match[3], "alt"))
                } else if (closing) {
                    const i = open.lastIndexOf(name)
                    if (i >= 0) { out += open.splice(i).reverse().map(n => "</" + n + ">").join("") }
                } else if (name === "a") {
                    const href = attribute(match[3], "href").replace(/&amp;/g, "&")
                    if (safeLink.test(href)) { out += '<a href="' + href.replace(/&/g, "&amp;") + '">'; open.push("a") }
                } else {
                    out += "<" + name + ">"
                    open.push(name)
                }
                continue
            }
            out += "&lt;"
            at += 1
        } else if (rest[0] === "&") {
            const match = entity.exec(rest)
            out += match ? match[0] : "&amp;"
            at += match ? match[0].length : 1
        } else {
            out += rest[0] === ">" ? "&gt;" : rest[0]
            at += 1
        }
    }
    return out + open.reverse().map(n => "</" + n + ">").join("")
}

// The same text with every tag removed: for a server or a card that shows plain text.
function toPlain(body) {
    return String(body ?? "").replace(/<[^>]*>/g, "")
}

// True when `link` may be opened (the sanitizer already limits hrefs; this guards the click).
function openable(link) { return safeLink.test(String(link ?? "")) }
