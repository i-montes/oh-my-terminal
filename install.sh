#!/usr/bin/env bash
# oh-my-terminal: deja Ghostty exactamente como lo configuramos.
#
#   ./install.sh              instala (copia los archivos)
#   ./install.sh --link       enlaza los archivos al repo en vez de copiarlos
#   ./install.sh --dry-run    muestra qué haría sin tocar nada
#   ./install.sh --no-reload  no recarga las ventanas de Ghostty abiertas
#   ./install.sh --no-deps    no instala paquetes que falten (solo avisa)
#
# Si faltan ghostty, la fuente JetBrainsMono Nerd Font o gum, los instala con
# `omarchy pkg add` (o `sudo pacman -S` si no es Omarchy). Pedirá tu contraseña.
#
# Es idempotente: puedes correrlo las veces que quieras. Todo archivo que
# vaya a reemplazarse y sea distinto se respalda como <archivo>.bak.<fecha>.

set -euo pipefail

AQUI=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
GHOSTTY_DIR=$CONFIG_HOME/ghostty
BIN_DIR=$HOME/.local/bin
BASHRC=$HOME/.bashrc
HYPR_LUA=$CONFIG_HOME/hypr/hyprland.lua
TS=$(date +%s)

MARCA_INI='# >>> oh-my-terminal >>>'
MARCA_FIN='# <<< oh-my-terminal <<<'

modo=copiar
dry=0
recargar=1
instalar_deps=1
for arg in "$@"; do
  case $arg in
    --link) modo=enlazar ;;
    --dry-run) dry=1 ;;
    --no-reload) recargar=0 ;;
    --no-deps) instalar_deps=0 ;;
    -h | --help) sed -n '2,15p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Opción desconocida: $arg" >&2; exit 1 ;;
  esac
done

ok() { printf '  \033[32m✓\033[0m %s\n' "$*"; }
nota() { printf '  \033[33m!\033[0m %s\n' "$*"; }
titulo() { printf '\n\033[1m%s\033[0m\n' "$*"; }

hacer() {
  if ((dry)); then printf '  (simulado) %s\n' "$*"; else "$@"; fi
}

# instalar_archivo <origen> <destino> [modo]
instalar_archivo() {
  local src=$1 dst=$2 perm=${3:-644}
  if [[ $modo == enlazar && $perm == 644 ]]; then
    if [[ -L $dst && $(readlink -f "$dst") == "$(readlink -f "$src")" ]]; then
      ok "$dst (ya enlazado)"; return
    fi
  elif [[ -f $dst && ! -L $dst ]] && cmp -s "$src" "$dst"; then
    ok "$dst (sin cambios)"; return
  fi
  if [[ -e $dst || -L $dst ]]; then
    hacer mv "$dst" "$dst.bak.$TS"
    nota "respaldo: $dst.bak.$TS"
  fi
  hacer mkdir -p "$(dirname "$dst")"
  if [[ $modo == enlazar && $perm == 644 ]]; then
    hacer ln -s "$src" "$dst"
    ok "$dst → $src"
  else
    hacer install -m "$perm" "$src" "$dst"
    ok "$dst"
  fi
}

# --- 0. Requisitos ----------------------------------------------------------
instalar_paquetes() {
  if command -v omarchy >/dev/null; then
    hacer omarchy pkg add "$@"
  elif command -v pacman >/dev/null; then
    hacer sudo pacman -S --needed "$@"
  else
    nota "no sé instalar paquetes en este sistema; instala a mano: $*"
    return 1
  fi
}

tiene_fuente() {
  # (se guarda antes en una variable: con pipefail, `grep -q` corta fc-list y falla)
  local familias
  familias=$(fc-list : family 2>/dev/null || true)
  [[ ${familias,,} == *"jetbrainsmono nerd font"* ]]
}

titulo "Requisitos"
faltan=()
command -v ghostty >/dev/null || faltan+=(ghostty)
tiene_fuente || faltan+=(ttf-jetbrains-mono-nerd)
command -v gum >/dev/null || faltan+=(gum)

if ((${#faltan[@]})); then
  nota "faltan: ${faltan[*]}"
  if ((instalar_deps)); then
    instalar_paquetes "${faltan[@]}" || nota "no se pudieron instalar todos los paquetes"
  else
    nota "(--no-deps) no se instalan"
  fi
fi

if command -v ghostty >/dev/null; then
  ok "ghostty $(ghostty --version | sed -n 's/^Ghostty //p;q')"
elif ((dry)); then
  nota "ghostty (se instalaría)"
else
  echo "Ghostty no está instalado." >&2; exit 1
fi
if tiene_fuente; then
  ok "fuente JetBrainsMono Nerd Font"
elif ((dry)) && [[ " ${faltan[*]} " == *" ttf-jetbrains-mono-nerd "* ]]; then
  nota "fuente JetBrainsMono Nerd Font (se instalaría)"
else
  nota "falta la fuente JetBrainsMono Nerd Font (en Arch: ttf-jetbrains-mono-nerd)"
fi
if command -v gum >/dev/null; then
  ok "gum (menú de gperfil)"
elif ((dry)) && [[ " ${faltan[*]} " == *" gum "* ]]; then
  nota "gum (se instalaría)"
else
  nota "gum no está instalado: gperfil usará un menú numérico"
fi

# --- 1. Config de Ghostty ----------------------------------------------------
titulo "Config de Ghostty → $GHOSTTY_DIR"
for f in config personal.conf stream.conf tabs.css; do
  instalar_archivo "$AQUI/ghostty/$f" "$GHOSTTY_DIR/$f"
done
# Lo escribe gperfil; vacío = perfil personal. No se pisa si ya existe.
if [[ -e $GHOSTTY_DIR/active-profile.conf ]]; then
  ok "$GHOSTTY_DIR/active-profile.conf (se conserva)"
else
  hacer mkdir -p "$GHOSTTY_DIR"
  hacer touch "$GHOSTTY_DIR/active-profile.conf"
  ok "$GHOSTTY_DIR/active-profile.conf (perfil personal)"
fi

# --- 2. Comando gperfil ------------------------------------------------------
titulo "Comando gperfil → $BIN_DIR"
instalar_archivo "$AQUI/bin/gperfil" "$BIN_DIR/gperfil" 755
case :$PATH: in
  *":$BIN_DIR:"*) ;;
  *) nota "$BIN_DIR no está en tu PATH" ;;
esac

# --- 3. Función g en ~/.bashrc -----------------------------------------------
titulo "Comando g → $BASHRC"
bloque=$(mktemp)
trap 'rm -f "$bloque" "${tmp:-}"' EXIT
{ echo "$MARCA_INI"; cat "$AQUI/shell/g.bash"; echo "$MARCA_FIN"; } >"$bloque"
touch "$BASHRC"

actual=$(awk -v i="$MARCA_INI" -v f="$MARCA_FIN" '$0==i{d=1} d{print} $0==f{d=0}' "$BASHRC")
if [[ $actual == "$(cat "$bloque")" ]]; then
  ok "función g (sin cambios)"
elif [[ -z $actual ]] && grep -qE '^g\(\) *\{' "$BASHRC"; then
  nota "ya hay una función g propia en $BASHRC; no la toco (quítala y vuelve a correr esto)"
else
  tmp=$(mktemp)
  # Quita el bloque anterior (si lo había) e inserta el nuevo antes de
  # "Attach ble.sh", que debe seguir siendo la última sección; si no existe,
  # lo deja al final.
  awk -v i="$MARCA_INI" -v f="$MARCA_FIN" '$0==i{d=1} !d{print} $0==f{d=0}' "$BASHRC" >"$tmp"
  if grep -q '^# Attach ble.sh' "$tmp"; then
    awk -v b="$bloque" '/^# Attach ble.sh/ && !hecho {while ((getline l < b) > 0) print l; print ""; hecho=1} {print}' "$tmp" >"$tmp.2"
    mv "$tmp.2" "$tmp"
  else
    { echo; cat "$bloque"; } >>"$tmp"
  fi
  if ! bash -n "$tmp"; then echo "El .bashrc resultante no es válido; no se modificó." >&2; exit 1; fi
  [[ -s $BASHRC ]] && { hacer cp "$BASHRC" "$BASHRC.bak.$TS"; nota "respaldo: $BASHRC.bak.$TS"; }
  hacer cp "$tmp" "$BASHRC"
  ok "función g instalada (abre una terminal nueva o: source ~/.bashrc)"
fi

# --- 4. Regla de Hyprland para el perfil stream ------------------------------
titulo "Regla de Hyprland (stream sin transparencia)"
if [[ ! -f $HYPR_LUA ]]; then
  nota "no hay $HYPR_LUA: omito la regla (sin Hyprland el perfil stream funciona igual)"
elif grep -qF 'imontes\\.stream' "$HYPR_LUA"; then
  ok "regla ya presente en $HYPR_LUA"
else
  hacer cp "$HYPR_LUA" "$HYPR_LUA.bak.$TS"
  nota "respaldo: $HYPR_LUA.bak.$TS"
  if ((dry)); then
    echo "  (simulado) agregar regla a $HYPR_LUA"
  else
    { echo; echo "--${MARCA_INI#\#}"; cat "$AQUI/hypr/stream-rule.lua"; echo "--${MARCA_FIN#\#}"; } >>"$HYPR_LUA"
    errores=$(hyprctl configerrors 2>/dev/null || true)
    [[ -n ${errores//[[:space:]]/} ]] && nota "hyprctl configerrors: $errores"
  fi
  ok "regla agregada"
fi

# --- 5. Validar y recargar ---------------------------------------------------
titulo "Validación"
if ((dry)); then
  echo "  (simulado) ghostty +validate-config"
elif ghostty +validate-config >/dev/null 2>&1; then
  ok "ghostty +validate-config sin errores"
else
  echo "ghostty +validate-config reporta errores:" >&2
  ghostty +validate-config >&2 || true
  exit 1
fi

if ((recargar)) && pgrep -x ghostty >/dev/null; then
  hacer pkill -USR2 -x ghostty
  ok "Ghostty recargado"
fi

titulo "Listo"
echo "  g personal    perfil de uso diario"
echo "  g stream      perfil de transmisión"
echo "  g -n stream   stream en una ventana nueva"
