# Record the default umask value on the 1st run
[ -z "${UMASK_DEFAULT:-""}" ] && export UMASK_DEFAULT="$(builtin umask)"
export UMASK_OVERRIDE="${UMASK_OVERRIDE:-""}"

__umask_default() {
  export UMASK=$UMASK_DEFAULT
}

__umask_override() {
  printf "\033[0;2m%s\033[0m: \033[91;2m%s\033[0m=>\033[92;2m%s\033[0m\n" "Overriding default umask" "$UMASK_DEFAULT" "$UMASK_OVERRIDE"
  export UMASK=$UMASK_OVERRIDE
}

_umask_hook() {
  if [ -n "$UMASK_OVERRIDE" -a "$UMASK_OVERRIDE" != "$UMASK_DEFAULT" ]; then
    for d in $UMASK_OVERRIDE_DIRS; do
      case $PWD/ in
        $d/*) __umask_override;;
        *) __umask_default;;
      esac
    done
  fi
  umask "$UMASK"
}

# Append `;` if PROMPT_COMMAND is not empty
PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND;}_umask_hook"
