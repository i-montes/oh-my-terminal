# "g" — `g personal` / `g stream` cambian el perfil de Ghostty (ver gperfil);
# `g -n stream` abre una ventana nueva con ese perfil. Todo lo demás sigue siendo
# git, como el alias g='git' de Omarchy (que se reemplaza aquí).
unalias g 2>/dev/null
g() {
  case ${1-} in
    personal | stream) gperfil "$@" ;;
    -n) gperfil "$@" ;;
    *) git "$@" ;;
  esac
}
