#!/bin/bash

# CONFIG
MOUNT_DIR="/your/mount/point"   # バックアップを保存するディレクトリのマウント先
SRC_DIR="/want/to/backup/dir"   # バックアップしたいディレクトリ
BK_DIR="backupdir"              # バックアップ時に作成するディレクトリ名
EXCLUDE_FILE=""                 # 除外ファイル指定、rsyncコマンドで指定します。例 : --exclude=your/path

W_DIR=`echo $SRC_DIR | awk -F/ '{print $(NF)}'`

# マウントポイントを確認し、マウントされていなければマウントする
check_mount() {
    df | grep "$MOUNT_DIR" > /dev/null
    if [ $? -ne 0 ]; then
        mount $MOUNT_DIR || exit 1
    else
        break
    fi
}

# 古いバックアップファイルを削除する
rm_old_backups() {
    BK_COUNT=`ls -1 $MOUNT_DIR/$BK_DIR/*.tar.gz 2>/dev/null | wc -l`
    if [ "$BK_COUNT" -ge 3 ]; then
        ls -1t $MOUNT_DIR/$BK_DIR/*.tar.gz | tail -n +4 | while read file; do
            rm -f "$file"
        done
    fi
}

# バックアップを作成する
create_backup() {
    rsync -av $EXCLUDE_FILE $SRC_DIR $MOUNT_DIR/$BK_DIR
    tar cfz $MOUNT_DIR/$BK_DIR/"$W_DIR"_`date +"%Y%m%d"`.tar.gz -C $MOUNT_DIR/$BK_DIR $W_DIR
    rm -rf $MOUNT_DIR/$BK_DIR/$W_DIR/*
}

main() {
    check_mount  # マウントを確認し、必要ならマウント
    mkdir -p $MOUNT_DIR/$BK_DIR  # バックアップディレクトリの作成
    rm_old_backups  # 古いバックアップの削除
    create_backup  # 新しいバックアップの作成
    umount $MOUNT_DIR || exit 1  # マウント解除
}

main
