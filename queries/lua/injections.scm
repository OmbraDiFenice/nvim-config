(
 (comment content: (_) @injection.language)
 (field value: (string content: (_) @injection.content))
 (#lua-match? @injection.language "^%s*lang%s*:%s*(.*)")
 (#gsub! @injection.language "^%s*lang%s*:%s*(.*)" "%1")
)
