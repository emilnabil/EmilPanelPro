#!/bin/bash

## setup command:
##   wget https://github.com/emilnabil/EmilPanelPro/raw/refs/heads/main/emilpanelpro.sh -O - | /bin/sh

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
    OSTYPE="OpenSource"
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

# استخراج الملفات
echo "Extracting files..."
if tar -xzf "$TMPPATH/$PLUGIN_ARCHIVE" -C /; then
    echo "✔ Extraction successful"
else
    echo "✘ Extraction failed"
    exit 1
fi

# تحميل ملف plugin المناسب بناءً على نوع الصورة وإصدار البايثون
echo "Downloading appropriate plugin file..."

if [ "$OSTYPE" = "DreamOs" ]; then
    # صورة دريم بوكس الرسمية
    PLUGIN_URL="https://github.com/emilnabil/EmilPanelPro/raw/refs/heads/main/dream/plugin_dream.pyo"
    PLUGIN_FILE="plugin.pyo"
    echo "✔ DreamOS image detected, downloading plugin_dream.pyo"
    
elif [ "$OSTYPE" = "OpenSource" ]; then
    # صور الاوبن سورس
    case "$PYTHON_VERSION" in
        "py2")
            PLUGIN_URL="https://github.com/emilnabil/EmilPanelPro/raw/refs/heads/main/py2/plugin_py2.pyo"
            PLUGIN_FILE="plugin.pyo"
            echo "✔ Open Source image with Python 2, downloading plugin_py2.pyo"
            ;;
        "py3.13")
            PLUGIN_URL="https://github.com/emilnabil/EmilPanelPro/raw/refs/heads/main/py3/plugin_py3.13.pyc"
            PLUGIN_FILE="plugin.pyc"
            echo "✔ Open Source image with Python 3.13, downloading plugin_py3.13.pyc"
            ;;
        "py3.12")
            PLUGIN_URL="https://github.com/emilnabil/EmilPanelPro/raw/refs/heads/main/py3/plugin_py3.12.pyc"
            PLUGIN_FILE="plugin.pyc"
            echo "✔ Open Source image with Python 3.12, downloading plugin_py3.12.pyc"
            ;;
        "py3.11")
            PLUGIN_URL="https://github.com/emilnabil/EmilPanelPro/raw/refs/heads/main/py3/plugin_py3.11.pyc"
            PLUGIN_FILE="plugin.pyc"
            echo "✔ Open Source image with Python 3.11, downloading plugin_py3.11.pyc"
            ;;
        "py3.10")
            PLUGIN_URL="https://github.com/emilnabil/EmilPanelPro/raw/refs/heads/main/py3/plugin_py3.10.pyc"
            PLUGIN_FILE="plugin.pyc"
            echo "✔ Open Source image with Python 3.10, downloading plugin_py3.10.pyc"
            ;;
        "py3.9")
            PLUGIN_URL="https://github.com/emilnabil/EmilPanelPro/raw/refs/heads/main/py3/plugin_py3.9.pyc"
            PLUGIN_FILE="plugin.pyc"
            echo "✔ Open Source image with Python 3.9, downloading plugin_py3.9.pyc"
            ;;
        "py3.8")
            PLUGIN_URL="https://github.com/emilnabil/EmilPanelPro/raw/refs/heads/main/py3/plugin_py3.8.pyc"
            PLUGIN_FILE="plugin.pyc"
            echo "✔ Open Source image with Python 3.8, downloading plugin_py3.8.pyc"
            ;;
        "py3.7")
            PLUGIN_URL="https://github.com/emilnabil/EmilPanelPro/raw/refs/heads/main/py3/plugin_py3.7.pyc"
            PLUGIN_FILE="plugin.pyc"
            echo "✔ Open Source image with Python 3.7, downloading plugin_py3.7.pyc"
            ;;
        "py3.6")
            PLUGIN_URL="https://github.com/emilnabil/EmilPanelPro/raw/refs/heads/main/py3/plugin_py3.6.pyc"
            PLUGIN_FILE="plugin.pyc"
            echo "✔ Open Source image with Python 3.6, downloading plugin_py3.6.pyc"
            ;;
        *)
            # إصدارات بايثون أخرى - استخدام الإصدار العام
            PLUGIN_URL="https://github.com/emilnabil/EmilPanelPro/raw/refs/heads/main/py3/plugin_py3.pyc"
            PLUGIN_FILE="plugin.pyc"
            echo "✔ Open Source image with $PYTHON_VERSION, downloading general plugin_py3.pyc"
            ;;
    esac
fi

# تحميل ملف plugin
if wget -q "$PLUGIN_URL" -O "$PLUGINPATH/$PLUGIN_FILE"; then
    echo "✔ Plugin file downloaded successfully: $PLUGIN_FILE"
else
    echo "⚠ Failed to download plugin file from: $PLUGIN_URL"
    # محاولة تحميل الإصدار العام كبديل
    if [ "$OSTYPE" = "DreamOs" ]; then
        ALT_PLUGIN_URL="https://github.com/emilnabil/EmilPanelPro/raw/refs/heads/main/dream/plugin_dream.pyo"
        if wget -q "$ALT_PLUGIN_URL" -O "$PLUGINPATH/$PLUGIN_FILE"; then
            echo "✔ Alternative plugin file downloaded successfully"
        else
            echo "✘ All plugin download attempts failed"
        fi
    else
        ALT_PLUGIN_URL="https://github.com/emilnabil/EmilPanelPro/raw/refs/heads/main/py3/plugin_py3.pyc"
        if wget -q "$ALT_PLUGIN_URL" -O "$PLUGINPATH/$PLUGIN_FILE"; then
            echo "✔ Alternative plugin file downloaded successfully"
        else
            echo "✘ All plugin download attempts failed"
        fi
    fi
fi

sync
echo "#########################################################"
echo "#              EmilPanelPro Installation                #"
echo "#                 Completed Successfully!              #"
echo "#########################################################"
echo "# Plugin path: $PLUGINPATH"
echo "# Python version: $PY_VER"
echo "# Image type: $OSTYPE"
echo "#########################################################"
rm -rf /tmp/EmilPanelPro*
sleep 2 
exit 0


