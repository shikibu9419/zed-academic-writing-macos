# Merge one zaw Zed-config snippet into the user's existing config.
#
# Input (stdin) : the user's existing config (object for settings, array for
#                 tasks/keymap; {} or [] when absent).
# --argjson incoming : the rendered snippet (same shape).
# --arg kind         : "settings" | "tasks" | "keymap".
#
# Output: { result, entries } where entries is a stream of
#   {t:"add"|"warn", m:"..."} describing what changed / conflicted.
#
# Policy: never change an existing user value. Missing keys/entries are
# added; scalar conflicts keep the user's value and emit a warning. This
# mirrors the precedence of jq's `*` operator when the existing config is
# the right-hand operand ($incoming * existing).

def kp2s($p): ($p | map(tostring) | join("."));

def diff_obj($e; $i; $p):
  ($i | keys_unsorted[]) as $k
  | ($p + [$k]) as $kp
  | if ($e | has($k) | not) then
      {t: "add", m: "add \(kp2s($kp))"}
    elif (($e[$k] | type) == "object" and ($i[$k] | type) == "object") then
      diff_obj($e[$k]; $i[$k]; $kp)
    elif ($e[$k] == $i[$k]) then
      empty
    else
      {t: "warn", m: "\(kp2s($kp)) already set to \($e[$k] | tojson) (snippet wants \($i[$k] | tojson)) — kept yours"}
    end;

if $kind == "settings" then
  # Migrate only the exact Skim default shipped by earlier zaw versions.
  # Custom viewer settings retain the usual conflict/backup behavior.
  (.lsp.texlab.settings.texlab.forwardSearch == {
    executable: "/Applications/Skim.app/Contents/SharedSupport/displayline",
    args: ["-r", "-z", "-b", "%l", "%p", "%f"]
  }) as $migrate
  | (if $migrate then del(.lsp.texlab.settings.texlab.forwardSearch) else . end)
  | (if has("enable_pdf_preview") then
       $incoming + {enable_pdf_preview: .enable_pdf_preview}
     else $incoming end) as $settings
  |
  {
    result: ($settings * .),
    entries: [diff_obj(.; $settings; [])]
  }

elif $kind == "tasks" then
  . as $ex
  | ($ex | map(.label)) as $labels
  | {
      result: ($ex + [$incoming[] | select((.label) as $l | ($labels | index($l)) == null)]),
      entries: [
        $incoming[] as $t
        | ($ex | map(select(.label == $t.label)) | .[0]) as $cur
        | if $cur == null then {t: "add", m: "add task \($t.label | tojson)"}
          elif $cur == $t then empty
          else {t: "warn", m: "task \($t.label | tojson) already exists with a different definition — kept yours"}
          end
      ]
    }

else  # keymap
  . as $ex
  | {
      result: (
        reduce $incoming[] as $blk ($ex;
          (map(.context) | index($blk.context)) as $idx
          | if $idx == null then
              . + [$blk]
            else
              .[$idx].bindings = (
                (.[$idx].bindings // {}) as $cur
                | reduce ($blk.bindings // {} | to_entries[]) as $e ($cur;
                    if .[$e.key] == null then . + {($e.key): $e.value} else . end)
              )
            end)
      ),
      entries: [
        $incoming[] as $blk
        | ($ex | map(select(.context == $blk.context)) | .[0]) as $curblk
        | if $curblk == null then
            {t: "add", m: "add keymap context \($blk.context | tojson)"}
          else
            ($curblk.bindings // {}) as $cb
            | ($blk.bindings // {} | to_entries[]) as $e
            | if $cb[$e.key] == null then
                {t: "add", m: "add binding \($e.key | tojson) in context \($blk.context | tojson)"}
              elif $cb[$e.key] == $e.value then
                empty
              else
                {t: "warn", m: "binding \($e.key | tojson) in context \($blk.context | tojson) already set to \($cb[$e.key] | tojson) (snippet wants \($e.value | tojson)) — kept yours"}
              end
          end
      ]
    }
end
