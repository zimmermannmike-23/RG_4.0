#!/usr/bin/env bash
# deploy.sh — RebalGold (RG_4.0) nach GitHub Pages deployen
# Nutzung: ./deploy.sh ~/Downloads/RebalGold-v3_65.html
set -euo pipefail

if [ -z "${1:-}" ]; then
  echo "Nutzung: ./deploy.sh <Pfad-zur-neuen-index.html>"
  exit 1
fi

SRC="$1"
if [ ! -f "$SRC" ]; then
  echo "Fehler: Datei nicht gefunden: $SRC"
  exit 1
fi

# Sicherstellen, dass wir im Repo-Root stehen (Ordner mit .git)
if [ ! -d ".git" ]; then
  echo "Fehler: Kein Git-Repo im aktuellen Verzeichnis. Erst 'cd' ins geklonte RG_4.0-Verzeichnis."
  exit 1
fi

# Versionsnummer aus der neuen Datei auslesen, für die Commit-Message
VERSION=$(grep -o "APP_VERSION='[0-9.]*'" "$SRC" | head -1 | grep -o "[0-9.]*" || echo "unbekannt")

# Zuerst den Stand von GitHub holen (z. B. Uploads über die Webseite)
echo "→ Hole aktuellen Stand von GitHub..."
git pull --rebase origin main

cp "$SRC" index.html
echo "✓ index.html aktualisiert (v${VERSION})"

echo "{\"version\":\"${VERSION}\"}" > version.json
echo "✓ version.json aktualisiert (für den Update-Banner in der App)"

# sw.js mitnehmen, falls vorhanden (Offline-Modus)
git add index.html version.json
if [ -f sw.js ]; then git add sw.js; fi

# Nur committen, wenn sich etwas geändert hat — sonst trotzdem weiter zum Push
if git diff --cached --quiet; then
  echo "• Keine neuen Änderungen — pushe den vorhandenen Stand"
else
  git commit -m "Deploy v${VERSION}"
fi

# Auf beide Branches pushen, damit main und master synchron bleiben
for BRANCH in main master; do
  echo "→ Push auf ${BRANCH}..."
  git push origin "HEAD:${BRANCH}"
done

echo ""
echo "✓ Deployment abgeschlossen. Live in ca. 30–60 Sekunden unter:"
echo "  https://zimmermannmike-23.github.io/RG_4.0/"
