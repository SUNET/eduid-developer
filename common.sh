
DEFAULT="~/work/NORDUnet"

function get_code_path {
  if [[ "$EDUID_SRC_PATH" ]]; then
    echo "$EDUID_SRC_PATH"
  else
    echo "$DEFAULT"
  fi
}
