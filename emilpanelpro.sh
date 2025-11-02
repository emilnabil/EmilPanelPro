#!/bin/bash
###################################################################################
## setup command:
##   wget https://github.com/emilnabil/EmilPanelPro/raw/refs/heads/main/emilpanelpro.sh -O - | /bin/sh
###################################################################################

TMPPATH="/tmp/EmilStore"
STATUS=""
OSTYPE=""
INSTALLER=""
PYTHON_CMD=""
PYTHON_VERSION=""
PACKAGE_REQUESTS=""
PLUGIN_ARCHIVE="EmilStore.tar.gz"

if [ -d "/usr/lib64" ]; then
    PLUGINPATH="/usr/lib64/enigma2/python/Plugins/Extensions/EmilStore"
else
    PLUGINPATH="/usr/lib/enigma2/python/Plugins/Extensions/EmilStore"
fi

# Detect OS type
if [ -f /var/lib/dpkg/status ]; then
    STATUS="/var/lib/dpkg/status"
    OSTYPE="DreamOs"
    INSTALLER="apt-get"
elif [ -f /var/lib/opkg/status ]; then
    STATUS="/var/lib/opkg/status"
    OSTYPE="OpenSource"
    INSTALLER="opkg"
else
    echo "✘ Unsupported package system."
    exit 1
fi

# Detect Python
if command -v python3 >/dev/null 2>&1; then
    PYTHON_CMD="python3"
elif command -v python >/dev/null 2>&1; then
    PYTHON_CMD="python"
elif command -v python2 >/dev/null 2>&1; then
    PYTHON_CMD="python2"
else
    echo "✘ Python not found."
    exit 1
fi

PY_VER=$($PYTHON_CMD -c 'import sys; print("{}.{}".format(sys.version_info[0], sys.version_info[1]))' 2>/dev/null)
[ $? -ne 0 ] && echo "✘ Failed to determine Python version" && exit 1

# Force Python 2 for OpenATV 6.4
if grep -qi "openatv *6\.4" /etc/issue 2>/dev/null \
   || grep -qi "openatv *6\.4" /etc/image-version 2>/dev/null \
   || grep -qi "oe-alliance *4\.4" /etc/image-version 2>/dev/null \
   || [ -f /etc/opkg/all-feed.conf ] && grep -qi "6\.4" /etc/opkg/all-feed.conf 2>/dev/null; then
    echo "⚠ Detected OpenATV 6.4 → forcing Python 2 mode"
    PYTHON_VERSION="py2"
    PY_VER="2.7"
else
    if echo "$PY_VER" | grep -q "^2\."; then
        PYTHON_VERSION="py2"
        PACKAGE_REQUESTS="python-requests"
        echo "✔ Python 2 detected"
    else
        PYTHON_VERSION="py3"
        PACKAGE_REQUESTS="python3-requests"
        echo "✔ Python $PY_VER detected"
    fi
fi

echo "Installing dependencies..."
$INSTALLER update -q >/dev/null 2>&1

if [ -n "$PACKAGE_REQUESTS" ] && ! grep -qs "Package: $PACKAGE_REQUESTS" "$STATUS"; then
    echo "Installing $PACKAGE_REQUESTS..."
    $INSTALLER install -y "$PACKAGE_REQUESTS" >/dev/null 2>&1 || echo "⚠ Failed to install $PACKAGE_REQUESTS"
fi

# Cleanup and prepare folders
rm -rf /usr/lib/enigma2/python/Plugins/Extensions/EmilPanelPro
rm -rf "$TMPPATH" "$PLUGINPATH"
mkdir -p "$TMPPATH" "$PLUGINPATH"
cd "$TMPPATH" || exit 1

# Download plugin package
if [ "$OSTYPE" = "DreamOs" ]; then
    URL="https://github.com/emilnabil/EmilPanelPro/raw/refs/heads/main/dream/EmilPanelPro.tar.gz"
else
    URL="https://github.com/emilnabil/EmilPanelPro/raw/refs/heads/main/EmilStore.tar.gz"
fi

echo "Downloading EmilPanelPro ($PYTHON_VERSION)..."
if wget -q "$URL" -O "$TMPPATH/$PLUGIN_ARCHIVE"; then
    echo "✔ Download successful"
else
    echo "✘ Download failed from: $URL"
    ALT_URL="https://github.com/emilnabil/EmilPanelPro/raw/refs/heads/main/EmilStore.tar.gz"
    echo "Trying alternative URL..."
    wget -q "$ALT_URL" -O "$TMPPATH/$PLUGIN_ARCHIVE" || { echo "✘ All download attempts failed"; exit 1; }
fi

tar -tzf "$PLUGIN_ARCHIVE" >/dev/null 2>&1 || { echo "✘ Invalid or corrupted archive"; exit 1; }
echo "Extracting files..."
tar -xzf "$TMPPATH/$PLUGIN_ARCHIVE" -C / || { echo "✘ Extraction failed"; exit 1; }

echo "Downloading plugin file for $OSTYPE / $PYTHON_VERSION..."

if [ "$OSTYPE" = "DreamOs" ]; then
    wget -q "https://github.com/emilnabil/EmilPanelPro/raw/refs/heads/main/dream/plugin.pyi" -O "$PLUGINPATH/plugin.pyi"
    echo "✔ DreamOS plugin.pyi downloaded"
else
    if [ "$PYTHON_VERSION" = "py2" ]; then
        wget -q "https://github.com/emilnabil/EmilPanelPro/raw/refs/heads/main/py2/plugin.pyo" -O "$PLUGINPATH/plugin.pyo"
        echo "✔ Open Source Python 2 plugin.pyo downloaded"
    else
        PY3_MAJOR=$(echo "$PY_VER" | cut -d'.' -f1)
        PY3_MINOR=$(echo "$PY_VER" | cut -d'.' -f2)
        PY3_FOLDER="py${PY3_MAJOR}.${PY3_MINOR}"
        wget -q "https://github.com/emilnabil/EmilPanelPro/raw/refs/heads/main/${PY3_FOLDER}/plugin.pyc" -O "$PLUGINPATH/plugin.pyc"
        echo "✔ Open Source Python $PY3_FOLDER plugin.pyc downloaded"
    fi
fi

sync
echo "#########################################################"
echo "#              EmilPanelPro Installation                #"
echo "#              Completed Successfully!                  #"
echo "#########################################################"
echo "# Plugin path: $PLUGINPATH"
echo "# Python version: $PY_VER"
echo "# Image type: $OSTYPE"
echo "#########################################################"

rm -rf /tmp/EmilStore* "$TMPPATH"
sleep 2
exit 0


