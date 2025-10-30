#!/bin/bash

## setup command:
##   wget https://raw.githubusercontent.com/emilnabil/download-plugins/refs/heads/main/EmilPanelPro/emilpanelpro.sh -O - | /bin/sh

TMPPATH="/tmp/EmilPanelPro"
STATUS=""
OSTYPE=""
INSTALLER=""
PYTHON_CMD=""
PYTHON_VERSION=""
PACKAGE_SIX=""
PACKAGE_REQUESTS=""
PLUGIN_ARCHIVE="EmilPanelPro.tar.gz"

if [ -d "/usr/lib64" ]; then
    PLUGINPATH="/usr/lib64/enigma2/python/Plugins/Extensions/EmilPanelPro"
else
    PLUGINPATH="/usr/lib/enigma2/python/Plugins/Extensions/EmilPanelPro"
fi

# اكتشاف نظام التشغيل
if [ -f /var/lib/dpkg/status ]; then
    STATUS="/var/lib/dpkg/status"
    OSTYPE="DreamOs"
    INSTALLER="apt-get"
elif [ -f /var/lib/opkg/status ]; then
    STATUS="/var/lib/opkg/status"
    OSTYPE="Dream"
    INSTALLER="opkg"
else
    echo "✘ Unsupported package system."
    exit 1
fi

# اكتشاف البايثون
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

# تحديد إصدار البايثون بدقة
PY_VER=$($PYTHON_CMD -c 'import sys; print("{}.{}".format(sys.version_info[0], sys.version_info[1]))' 2>/dev/null)

if [ $? -ne 0 ]; then
    echo "✘ Failed to determine Python version"
    exit 1
fi

if echo "$PY_VER" | grep -q "^2\."; then
    PYTHON_VERSION="py2"
    PACKAGE_SIX=""
    PACKAGE_REQUESTS="python-requests"
    echo "✔ Python 2 detected"
elif echo "$PY_VER" | grep -q "^3\.13"; then
    PYTHON_VERSION="py3.13"
    PACKAGE_SIX="python3-six"
    PACKAGE_REQUESTS="python3-requests"
    echo "✔ Python 3.13 detected"
elif echo "$PY_VER" | grep -q "^3\.12"; then
    PYTHON_VERSION="py3.12"
    PACKAGE_SIX="python3-six"
    PACKAGE_REQUESTS="python3-requests"
    echo "✔ Python 3.12 detected"
elif echo "$PY_VER" | grep -q "^3\.11"; then
    PYTHON_VERSION="py3.11"
    PACKAGE_SIX="python3-six"
    PACKAGE_REQUESTS="python3-requests"
    echo "✔ Python 3.11 detected"
elif echo "$PY_VER" | grep -q "^3\.10"; then
    PYTHON_VERSION="py3.10"
    PACKAGE_SIX="python3-six"
    PACKAGE_REQUESTS="python3-requests"
    echo "✔ Python 3.10 detected"
elif echo "$PY_VER" | grep -q "^3\.9"; then
    PYTHON_VERSION="py3.9"
    PACKAGE_SIX="python3-six"
    PACKAGE_REQUESTS="python3-requests"
    echo "✔ Python 3.9 detected"
elif echo "$PY_VER" | grep -q "^3\.8"; then
    PYTHON_VERSION="py3.8"
    PACKAGE_SIX="python3-six"
    PACKAGE_REQUESTS="python3-requests"
    echo "✔ Python 3.8 detected"
elif echo "$PY_VER" | grep -q "^3\.7"; then
    PYTHON_VERSION="py3.7"
    PACKAGE_SIX="python3-six"
    PACKAGE_REQUESTS="python3-requests"
    echo "✔ Python 3.7 detected"
elif echo "$PY_VER" | grep -q "^3\.6"; then
    PYTHON_VERSION="py3.6"
    PACKAGE_SIX="python3-six"
    PACKAGE_REQUESTS="python3-requests"
    echo "✔ Python 3.6 detected"
else
    PYTHON_VERSION="py3"
    PACKAGE_SIX="python3-six"
    PACKAGE_REQUESTS="python3-requests"
    echo "✔ Python $PY_VER detected (general)"
fi

echo "Installing dependencies..."
$INSTALLER update -q >/dev/null 2>&1

# تثبيت الاعتماديات
if [ -n "$PACKAGE_SIX" ] && ! grep -qs "Package: $PACKAGE_SIX" "$STATUS"; then
    echo "Installing $PACKAGE_SIX..."
    $INSTALLER install -y "$PACKAGE_SIX" >/dev/null 2>&1 || echo "⚠ Failed to install $PACKAGE_SIX"
fi

if [ -n "$PACKAGE_REQUESTS" ] && ! grep -qs "Package: $PACKAGE_REQUESTS" "$STATUS"; then
    echo "Installing $PACKAGE_REQUESTS..."
    $INSTALLER install -y "$PACKAGE_REQUESTS" >/dev/null 2>&1 || echo "⚠ Failed to install $PACKAGE_REQUESTS"
fi

# تنظيف وتهيئة المجلدات
rm -rf /usr/lib/enigma2/python/Plugins/Extensions/EmilPanelPro 
rm -rf "$TMPPATH" "$PLUGINPATH"
mkdir -p "$TMPPATH" "$PLUGINPATH"

cd "$TMPPATH" || exit 1

# تحديد رابط التحميل المناسب
if [ "$OSTYPE" = "DreamOs" ]; then
    URL="https://github.com/emilnabil/EmilPanelPro/raw/refs/heads/main/dream/EmilPanelPro.tar.gz"
else
    # استخدام الإصدار المحدد إذا كان موجوداً
    if [ "$PYTHON_VERSION" != "py3" ] && [ "$PYTHON_VERSION" != "py2" ]; then
        URL="https://github.com/emilnabil/EmilPanelPro/raw/refs/heads/main/${PYTHON_VERSION}/EmilPanelPro.tar.gz"
    else
        URL="https://github.com/emilnabil/EmilPanelPro/raw/refs/heads/main/py3/EmilPanelPro.tar.gz"
    fi
fi

echo "Downloading EmilPanelPro ($PYTHON_VERSION)..."
echo "Download URL: $URL"
if wget -q "$URL" -O "$TMPPATH/$PLUGIN_ARCHIVE"; then
    echo "✔ Download successful"
else
    echo "✘ Download failed from: $URL"
    # محاولة الرابط البديل
    ALT_URL="https://github.com/emilnabil/EmilPanelPro/raw/refs/heads/main/py3/EmilPanelPro.tar.gz"
    echo "Trying alternative URL: $ALT_URL"
    if wget -q "$ALT_URL" -O "$TMPPATH/$PLUGIN_ARCHIVE"; then
        echo "✔ Alternative download successful"
    else
        echo "✘ All download attempts failed"
        exit 1
    fi
fi

# التحقق من صحة الأرشيف
if ! tar -tzf "$PLUGIN_ARCHIVE" >/dev/null 2>&1; then
    echo "✘ Invalid or corrupted archive"
    exit 1
fi

# عرض محتويات الأرشيف لفهم الهيكل
echo "Archive contents:"
tar -tzf "$PLUGIN_ARCHIVE" | head -10

# استخراج الملفات
echo "Extracting files..."
if tar -xzf "$TMPPATH/$PLUGIN_ARCHIVE" -C /; then
    echo "✔ Extraction successful"
else
    echo "✘ Extraction failed"
    exit 1
fi

sync
echo "#########################################################"

# البحث عن جميع ملفات plugin في /tmp بعد الاستخراج
echo "Searching for plugin files in /tmp..."
find /tmp -name "plugin*" -type f 2>/dev/null

# نسخ الملفات المناسبة
PLUGIN_SOURCE=""
PLUGIN_TARGET="$PLUGINPATH/plugin.pyc"

# البحث عن الملف المناسب حسب إصدار البايثون
if [ "$OSTYPE" = "DreamOs" ] && [ -f "/tmp/plugin_dream.pyo" ]; then
    PLUGIN_SOURCE="/tmp/plugin_dream.pyo"
    PLUGIN_TARGET="$PLUGINPATH/plugin.pyo"
    echo "✔ Found DreamOS plugin: $PLUGIN_SOURCE"
elif [ -f "/tmp/plugin_${PYTHON_VERSION}.pyc" ]; then
    PLUGIN_SOURCE="/tmp/plugin_${PYTHON_VERSION}.pyc"
    echo "✔ Found specific plugin for $PYTHON_VERSION: $PLUGIN_SOURCE"
elif [ -f "/tmp/plugin.pyc" ]; then
    PLUGIN_SOURCE="/tmp/plugin.pyc"
    echo "✔ Found general plugin.pyc"
elif [ -f "/tmp/plugin.pyo" ]; then
    PLUGIN_SOURCE="/tmp/plugin.pyo"
    PLUGIN_TARGET="$PLUGINPATH/plugin.pyo"
    echo "✔ Found plugin.pyo"
else
    # البحث عن أي ملف plugin
    PLUGIN_SOURCE=$(find /tmp -maxdepth 1 -name "plugin*" -type f 2>/dev/null | head -1)
    if [ -n "$PLUGIN_SOURCE" ]; then
        echo "✔ Found plugin file: $PLUGIN_SOURCE"
    else
        echo "⚠ No plugin files found in /tmp"
    fi
fi

# نسخ الملف إذا وجد
if [ -n "$PLUGIN_SOURCE" ] && [ -f "$PLUGIN_SOURCE" ]; then
    cp -f "$PLUGIN_SOURCE" "$PLUGIN_TARGET"
    echo "✔ Copied $(basename $PLUGIN_SOURCE) to $(basename $PLUGIN_TARGET)"
else
    echo "⚠ No plugin file available to copy"
fi

# التحقق من المحتويات النهائية
echo "Final plugin directory contents:"
ls -la "$PLUGINPATH/" 2>/dev/null || echo "Directory is empty"

# تعيين الصلاحيات
chmod -R 755 "$PLUGINPATH"
find "$PLUGINPATH" -name "*.py" -exec chmod +x {} \; 2>/dev/null
find "$PLUGINPATH" -name "*.pyo" -exec chmod +x {} \; 2>/dev/null
find "$PLUGINPATH" -name "*.pyc" -exec chmod +x {} \; 2>/dev/null

# التحقق النهائي من التثبيت
if [ -f "$PLUGINPATH/plugin.py" ] || [ -f "$PLUGINPATH/plugin.pyc" ] || [ -f "$PLUGINPATH/plugin.pyo" ]; then
    echo "✔ Plugin installation verified successfully"
else
    echo "✘ ERROR: No main plugin file found after installation"
    exit 1
fi

sleep 3
echo "> Cleaning all temporary files..."
rm -rf /tmp/EmilPanelPro*
rm -f /tmp/plugin* /tmp/*.pyc /tmp/*.pyo

sync
echo ""
echo "#########################################################"
echo "#  ✔ EmilPanelPro INSTALLED SUCCESSFULLY               #"
echo "#         Uploaded by Emil Nabil                       #"
echo "#    Python version: $PYTHON_VERSION                   #"
echo "#    OS type: $OSTYPE                                  #"
echo "#########################################################"
echo ""

echo "Restarting device..."
sleep 3

if command -v systemctl >/dev/null 2>&1; then
    killall -9 enigma2 >/dev/null 2>&1
    systemctl restart enigma2
else
    killall -9 enigma2 >/dev/null 2>&1
    /usr/bin/enigma2 &
fi

exit 0



