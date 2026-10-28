# oh-my-terminal

Un solo script que deja Ghostty exactamente como lo configuré: paleta de marca,
letra legible, tabs compactos y dos perfiles intercambiables (`personal` y
`stream`) con el comando `g`.

```bash
./install.sh
```

Pensado para Arch + Omarchy (Hyprland). Fuera de Omarchy funciona igual; la
regla de Hyprland se omite si no encuentra `hyprland.lua`.

## Qué instala

| Archivo del repo | Destino | Para qué |
|---|---|---|
| `ghostty/config` | `~/.config/ghostty/config` | Base: fuente, teclas, cursor, carga del tema de Omarchy y de los perfiles |
| `ghostty/personal.conf` | `~/.config/ghostty/personal.conf` | Perfil diario: paleta, `font-size = 12`, padding, tabs |
| `ghostty/stream.conf` | `~/.config/ghostty/stream.conf` | Perfil de transmisión: `font-size = 18`, fondo opaco, contraste alto |
| `ghostty/tabs.css` | `~/.config/ghostty/tabs.css` | Tabs compactos con línea ámbar en el activo |
| `bin/gperfil` | `~/.local/bin/gperfil` | Cambia de perfil recargando Ghostty |
| `shell/g.bash` | bloque en `~/.bashrc` | `g personal` / `g stream` (el resto sigue siendo git) |
| `hypr/stream-rule.lua` | bloque en `~/.config/hypr/hyprland.lua` | Quita la transparencia por defecto de Omarchy en la ventana `stream` |

Además crea `~/.config/ghostty/active-profile.conf` (vacío = perfil personal),
que `gperfil` reescribe y que **no** está en el repo.

## Uso

```bash
g personal      # perfil de uso diario
g stream        # perfil de transmisión (en las terminales abiertas)
g -n stream     # stream en una ventana nueva, con su propia clase
g status        # cualquier otra cosa va a git
gperfil         # menú interactivo (gum)
```

`g stream` cambia **todas** las ventanas de Ghostty abiertas, porque recarga la
config. Con `g -n stream` la ventana nueva es una instancia aparte
(`oh-my-terminal.stream`) y es la única que se ve con el perfil de transmisión;
es la opción para grabar, porque ahí la regla de Hyprland sí aplica.

## Opciones del instalador

```bash
./install.sh --dry-run     # muestra qué haría, sin tocar nada
./install.sh --link        # enlaza los archivos al repo en vez de copiarlos
./install.sh --no-reload   # no recarga las ventanas de Ghostty abiertas
./install.sh --no-deps     # no instala paquetes que falten (solo avisa)
```

- **Dependencias:** si faltan `ghostty`, la fuente `ttf-jetbrains-mono-nerd` o
  `gum`, el instalador los instala con `omarchy pkg add` (o `sudo pacman -S` si
  no es Omarchy) y pide tu contraseña. Sin Ghostty no puede continuar; sin
  `gum` o sin fuente solo avisa.

- **Idempotente:** puedes correrlo cuantas veces quieras; lo que ya está igual
  se reporta como «sin cambios».
- **Respaldos:** todo archivo que vaya a reemplazarse y sea distinto se guarda
  como `<archivo>.bak.<timestamp>`.
- **`--link`:** editar un archivo del repo cambia tu terminal directamente
  (recarga con Ctrl+Shift+, o `pkill -USR2 -x ghostty`). Si mueves el repo,
  vuelve a correr el instalador.
- Valida con `ghostty +validate-config` antes de terminar y falla si hay errores.

## Paleta

Es la paleta de marca de mi canal de YouTube.

| | |
|---|---|
| Fondo `#0D0F12` (grafito) | Texto `#E6E6E0` (hueso) |
| Acento / cursor `#FFB13D` (ámbar) | Hielo `#7FD6FF` |
| Verde `#7FA88A` | Rojo `#E2776B` (rojoApagado aclarado: el original da 4:1) |
| Azul `#7FA8FF` y magenta `#C3A3E8` (derivados; la paleta no los tiene) | Grises `#13161B` `#8A8F98` `#B8BCC4` |

Todos los colores de texto superan 5:1 de contraste sobre el fondo.

## Cosas a saber

- El tema de Omarchy (`omarchy theme set`) cambia el resto del escritorio, pero
  `personal.conf` se carga después y conserva la paleta en Ghostty.
- La fuente es `JetBrainsMono Nerd Font`. Solo trae Regular y Bold: pedir
  `Medium` o `ExtraBold` hace que el negrita caiga a Regular.
- En `~/.bashrc` el bloque va entre `# >>> oh-my-terminal >>>` y
  `# <<< oh-my-terminal <<<`; el instalador lo actualiza ahí mismo y lo deja
  antes de `# Attach ble.sh`, que debe seguir siendo lo último.
- Si ya tienes una función `g` propia fuera de ese bloque, el instalador no la
  toca y avisa.
- `Ctrl+V` pega solo en el perfil stream. Para tenerlo siempre, mueve esa línea
  (`keybind = ctrl+v=paste_from_clipboard`) de `stream.conf` a `personal.conf`.

## Licencia

[MIT](LICENSE)
