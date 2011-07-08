# encoding: utf-8

# How to UPDATE indices base
# 1. Download fresh base from http://info.russianpost.ru/database/ops.html
# 2. Transfer from DBF to sqlite3 with command: LANG="ru_RU.CP866" sqlite3-dbf PIndx08.dbf | iconv -f cp866 -t utf8 | sqlite3 pindx08.sqlite3
# (You can downlaod sqlite3-dbf from here: http://mobigroup.ru/debian/pool-squeeze/main/s/sqlite3-dbf/
# 3. Merge table into database: 
# > sqlite3 db/development.sqlite3
# sqlite> attach '../Downloads/pindx08.sqlite3' as toMerge;
# sqlite> delete from post_indices;
# sqlite> insert into post_indices select * from toMerge.pindx08;
# sqlite> .quit

# Tables structure in sqlite3: select * from sqlite_master;

class PostIndex < ActiveRecord::Base


end
