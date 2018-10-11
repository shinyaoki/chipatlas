creature=$1
today=$(date "+%Y%m%d")

cd /home/okishinya/Collabo/yojima/share/ChipAtlasAnnotation/
mkdir -p label_feature/${creature}
mkdir -p label_feature/${creature}/${today}
mkdir -p word_data/${creature}
mkdir -p word_data/${creature}/${today}

